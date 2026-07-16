import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/engine_registry.dart';
import 'package:noop/core/analytics/raw_samples.dart';
import 'package:noop/core/data/db/database.dart';
import 'package:noop/core/data/live_repository.dart';
import 'package:noop/core/data/models.dart';

/// Pins the day-read rewrite (per-day windowed reads + once-per-day local-time
/// bucketing, schema v5) to the behaviour of the full-table read it replaced.
///
/// The rewrite is a PERFORMANCE change and must be a scoring no-op: same raw rows
/// in, byte-identical [DayRecord]s out. It re-derives a second's calendar day from
/// the other end — the old code asked every second "which local day are you?" via
/// two `DateTime` constructions each; the new code asks each local day "which
/// seconds are yours?" via an indexed `ts` window. That is only equivalent if the
/// day BOUNDS are exactly the old per-second grouping's edges, so this test drives
/// the real [LiveRepository.load] against an oracle that is the OLD algorithm,
/// transcribed verbatim below, and compares the scored output.
///
/// The seeds deliberately include the shapes the windowing could plausibly break:
/// a day boundary (a second either side of local midnight must land in different
/// days, and never in both), a gap day with no rows at all (which must produce no
/// RawDay, not an empty one), a gravity/sleep-state-only second (no HR — must
/// still seed a sample), an RR-only second, and a bpm=0 row (which must NOT seed
/// a sample of its own).

// ── The oracle: `_buildDays` EXACTLY as it was before the rewrite ─────────────
// Four full-table reads, one map keyed by unix-second across the WHOLE store, and
// a per-second `DateTime.fromMillisecondsSinceEpoch` + `DateTime(y, m, d)` to
// derive each second's bucket key. Kept verbatim (not refactored) so it stays a
// faithful reference rather than a second copy of the new logic.
Future<List<RawDay>> oracleBuildDays(AppDatabase db) async {
  final hrRows = await db.select(db.whoopHrSamples).get();
  if (hrRows.isEmpty) return const [];
  final rrRows = await db.select(db.whoopRrIntervals).get();
  final gravRows = await db.select(db.whoopGravitySamples).get();
  final sleepStateRows = await db.select(db.whoopSleepStateSamples).get();

  final byTs = <int, _OracleBuilder>{};
  _OracleBuilder at(int ts) => byTs.putIfAbsent(ts, () => _OracleBuilder(ts));

  for (final r in hrRows) {
    if (r.bpm > 0) at(r.ts).hr = r.bpm;
  }
  for (final r in rrRows) {
    if (r.rrMs > 0) at(r.ts).rr.add(r.rrMs);
  }
  for (final r in sleepStateRows) {
    at(r.ts).sleepState = r.state;
  }
  for (final r in gravRows) {
    at(r.ts).mv = math.sqrt(r.x * r.x + r.y * r.y + r.z * r.z);
  }

  final buckets = <int, List<RawSample>>{};
  final tss = byTs.keys.toList()..sort();
  for (final ts in tss) {
    final local = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final key =
        DateTime(local.year, local.month, local.day).millisecondsSinceEpoch;
    (buckets[key] ??= <RawSample>[]).add(byTs[ts]!.build());
  }
  final keys = buckets.keys.toList()..sort();
  return [
    for (final k in keys)
      RawDay(DateTime.fromMillisecondsSinceEpoch(k), buckets[k]!),
  ];
}

class _OracleBuilder {
  _OracleBuilder(this.ts);
  final int ts;
  int hr = 0;
  double? mv;
  int? sleepState;
  final List<int> rr = [];
  RawSample build() => RawSample(
        ts: ts,
        hr: hr,
        sleepState: sleepState,
        spo2: 0,
        rrCount: rr.length > 3 ? 3 : rr.length,
        rr1: rr.isNotEmpty ? rr[0] : 0,
        rr2: rr.length > 1 ? rr[1] : 0,
        rr3: rr.length > 2 ? rr[2] : 0,
        movement: mv,
      );
}

/// A total, order-sensitive signature of a scored day — every field the UI can
/// render, including the sleep record and the HR thread. Compared as strings so a
/// mismatch names the day and the field rather than just "not equal".
String daySig(DayRecord d) {
  final s = d.sleep;
  return [
    'date=${d.date.toIso8601String()}',
    'charge=${d.charge}',
    'calNights=${d.chargeCalibrationNights}',
    'noData=${d.chargeNoData}',
    'effort=${d.effort}',
    'rest=${d.rest}',
    'stress=${d.stress}',
    'hrv=${d.hrv}',
    'rhr=${d.rhr}',
    'resp=${d.respiratoryRate}',
    'spo2=${d.spo2}',
    'vitality=${d.vitality}',
    if (s == null)
      'sleep=null'
    else
      'sleep=[bed=${s.bedtime.toIso8601String()} wake=${s.wake.toIso8601String()} '
          'tib=${s.timeInBed.inSeconds} asleep=${s.asleep.inSeconds} '
          'deep=${s.deep.inSeconds} rem=${s.rem.inSeconds} light=${s.light.inSeconds} '
          'awake=${s.awake.inSeconds} eff=${s.efficiency} need=${s.need.inSeconds} '
          'resp=${s.respiratoryRate} dist=${s.disturbances} sparse=${s.motionSparse} '
          'hypno=${s.hypnogram.map((h) => '${h.start.millisecondsSinceEpoch}/'
              '${h.duration.inSeconds}/${h.stage}').join(',')} '
          'restless=${s.restlessness.join(',')}]',
    'hr=${d.hr.map((h) => '${h.time.millisecondsSinceEpoch}:${h.bpm}').join(',')}',
  ].join(' | ');
}

/// Seed a store shaped to stress the day-windowing specifically.
Future<void> seedTrickyStore(AppDatabase db, {String device = 'eq'}) async {
  final hr = <WhoopHrSamplesCompanion>[];
  final rr = <WhoopRrIntervalsCompanion>[];
  final grav = <WhoopGravitySamplesCompanion>[];
  final st = <WhoopSleepStateSamplesCompanion>[];

  // Days 03-01, 03-02 and 03-05 carry a full night+day. Each also pushes ONE
  // second into the following local day (the boundary probe below), so rows exist
  // on 03-01..03-03 and 03-05..03-06 — leaving 03-04 with no rows whatsoever. That
  // gap is the point: the walk iterates every local day in the span, so an unworn
  // day must produce no RawDay rather than an empty one.
  for (final dayOffset in [0, 1, 4]) {
    final base = DateTime(2026, 3, 1)
            .add(Duration(days: dayOffset))
            .millisecondsSinceEpoch ~/
        1000;

    // Night 00:30 → 07:30 @30 s, low still-wrist HR + RR + strap "asleep".
    for (var t = base + 1800; t < base + 7 * 3600 + 1800; t += 30) {
      final bpm = (50 + 3 * math.sin((t - base) / 60.0)).round();
      hr.add(WhoopHrSamplesCompanion.insert(deviceId: device, ts: t, bpm: bpm));
      rr.add(WhoopRrIntervalsCompanion.insert(
          deviceId: device, ts: t, rrMs: (60000 / bpm).round()));
      grav.add(WhoopGravitySamplesCompanion.insert(
          deviceId: device, ts: t, x: 0.0, y: 0.0, z: 1.0));
      st.add(WhoopSleepStateSamplesCompanion.insert(
          deviceId: device, ts: t, state: 2));
    }
    // Daytime 08:00 → 23:00 @5 min.
    for (var t = base + 8 * 3600; t < base + 23 * 3600; t += 300) {
      final h = (t - base) / 3600.0;
      hr.add(WhoopHrSamplesCompanion.insert(
          deviceId: device, ts: t, bpm: (75 + 8 * math.sin(h)).round()));
      grav.add(WhoopGravitySamplesCompanion.insert(
          deviceId: device, ts: t, x: 0.25, y: 0.1, z: 1.0));
      st.add(WhoopSleepStateSamplesCompanion.insert(
          deviceId: device, ts: t, state: 0));
    }

    // ── The day EDGE: the last second of this local day and the first second of
    // the next. A window that is inclusive on both ends, or that adds a flat
    // 86400, would put one of these in the wrong day — or in both.
    final nextMidnight = DateTime(2026, 3, 1)
            .add(Duration(days: dayOffset + 1))
            .millisecondsSinceEpoch ~/
        1000;
    hr.add(WhoopHrSamplesCompanion.insert(
        deviceId: device, ts: nextMidnight - 1, bpm: 61));
    hr.add(WhoopHrSamplesCompanion.insert(
        deviceId: device, ts: nextMidnight, bpm: 62));

    // A bpm=0 row — present in the table, but must NOT seed a sample by itself.
    hr.add(WhoopHrSamplesCompanion.insert(
        deviceId: device, ts: base + 7 * 3600 + 1801, bpm: 0));
    // Gravity + sleep-state on a second with NO heart rate — must still seed one.
    grav.add(WhoopGravitySamplesCompanion.insert(
        deviceId: device, ts: base + 7 * 3600 + 1802, x: 0.0, y: 0.1, z: 0.99));
    st.add(WhoopSleepStateSamplesCompanion.insert(
        deviceId: device, ts: base + 7 * 3600 + 1802, state: 1));
    // An RR-only second — no HR row at all.
    rr.add(WhoopRrIntervalsCompanion.insert(
        deviceId: device, ts: base + 7 * 3600 + 1803, rrMs: 995));
    // Multiple RR beats on ONE second (the >3 clamp path).
    for (final ms in [980, 990, 1000, 1010]) {
      rr.add(WhoopRrIntervalsCompanion.insert(
          deviceId: device, ts: base + 3600, rrMs: ms));
    }
  }

  await db.batch((b) {
    b.insertAll(db.whoopHrSamples, hr);
    b.insertAll(db.whoopRrIntervals, rr);
    b.insertAll(db.whoopGravitySamples, grav);
    b.insertAll(db.whoopSleepStateSamples, st);
  });
}

void main() {
  test('windowed day-read scores IDENTICALLY to the old full-table read',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await seedTrickyStore(db);

    // Oracle: old grouping → the same engine → reference scores.
    final oracleDays = await oracleBuildDays(db);
    final expected = engineRegistry.first
        .analyze(oracleDays, const UserProfile())
        .map(daySig)
        .toList();

    // Actual: the real repository, which now walks day windows off the ts index.
    final repo = await LiveRepository.load(db);
    final actual = repo.days.map(daySig).toList();

    expect(actual.length, expected.length,
        reason: 'the windowed walk must yield the same number of scored days');
    for (var i = 0; i < expected.length; i++) {
      expect(actual[i], expected[i], reason: 'scored day $i differs');
    }
  });

  test('day windows partition the store — every synced second lands in exactly '
      'one day, and the empty gap day yields no RawDay', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await seedTrickyStore(db);

    // The walk must agree with the oracle on WHICH local days exist, not merely on
    // how they score — a day emitted or dropped wrongly would still "score" fine.
    final repo = await LiveRepository.load(db);
    final oracleDays = await oracleBuildDays(db);
    String key(DateTime d) => '${d.year}-${d.month}-${d.day}';

    // 03-04 carries no row at all (see the seed) and must simply be absent, while
    // 03-03 and 03-06 exist as one-sample boundary days.
    final oracleDates = oracleDays.map((d) => key(d.date)).toList();
    expect(oracleDates, isNot(contains('2026-3-4')),
        reason: 'a day with no rows must produce no RawDay at all');
    expect(oracleDates, containsAll(['2026-3-3', '2026-3-6']),
        reason: 'the second pushed past midnight makes its own day');
    // The scored days are a subset (the pipeline drops days under a minute of HR),
    // but the walk must never invent or lose one relative to the oracle's grouping.
    expect(repo.days.map((d) => key(d.date)),
        everyElement(isIn(oracleDates)));

    // No second is duplicated or lost across the day boundary.
    final all = <int>[];
    for (final d in oracleDays) {
      all.addAll(d.samples.map((s) => s.ts));
    }
    expect(all.toSet().length, all.length, reason: 'a second in two days');
    expect(all, orderedEquals(all.toList()..sort()));
  });

  test('empty store → no days (the cold-start path is unchanged)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = await LiveRepository.load(db);
    expect(repo.days, isEmpty);
  });

  test('rows with NO heart rate anywhere → no days (HR-less store bails)',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    // Gravity only — the old code bailed on an empty hrSample before reading
    // anything else, and the walk must agree rather than emit unscoreable days.
    final base = DateTime(2026, 5, 1).millisecondsSinceEpoch ~/ 1000;
    await db.batch((b) {
      b.insertAll(db.whoopGravitySamples, [
        for (var t = base; t < base + 3600; t += 30)
          WhoopGravitySamplesCompanion.insert(
              deviceId: 'g', ts: t, x: 0.0, y: 0.0, z: 1.0),
      ]);
    });
    expect(await oracleBuildDays(db), isEmpty);
    final repo = await LiveRepository.load(db);
    expect(repo.days, isEmpty);
  });
}
