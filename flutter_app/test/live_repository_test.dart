import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:noop/core/data/db/database.dart';
import 'package:noop/core/data/live_repository.dart';
import 'package:noop/core/state/providers.dart';
import 'package:noop/main.dart';

/// Seed one local day of synthetic strap rows into the WHOOP stream tables:
/// a low-HR overnight window (with beat-to-beat RR + a still gravity vector) so
/// the ported pipeline can stage sleep + derive RHR/HRV, plus a higher-HR
/// daytime tail. Mirrors the shape a real offload lands in.
Future<void> _seedOneDay(AppDatabase db, {String device = 'test-strap'}) async {
  // Local midnight of a fixed date → deterministic bucketing.
  final base = DateTime(2026, 3, 1).millisecondsSinceEpoch ~/ 1000;

  final hr = <WhoopHrSamplesCompanion>[];
  final rr = <WhoopRrIntervalsCompanion>[];
  final grav = <WhoopGravitySamplesCompanion>[];

  // Night 00:30 → 07:30 (7h) at 30-second epochs — well over the stager's
  // ~2h minimum. Low, gently oscillating HR (for the resp proxy), still wrist.
  const step = 30;
  for (var t = base + 1800; t < base + 7 * 3600 + 1800; t += step) {
    final k = (t - base) ~/ step;
    final bpm = (50 + 3 * math.sin(k / 2.0)).round();
    hr.add(WhoopHrSamplesCompanion.insert(deviceId: device, ts: t, bpm: bpm));
    rr.add(WhoopRrIntervalsCompanion.insert(
        deviceId: device, ts: t, rrMs: (60000 / bpm).round()));
    grav.add(WhoopGravitySamplesCompanion.insert(
        deviceId: device, ts: t, x: 0.0, y: 0.0, z: 1.0));
  }

  // Daytime 08:00 → 23:00 at 5-minute buckets — clearly above the sleep floor,
  // with some wrist motion so it can't be mistaken for a second sleep window.
  for (var t = base + 8 * 3600; t < base + 23 * 3600; t += 300) {
    final h = (t - base) / 3600.0;
    final bpm = (75 + 8 * math.sin(h)).round();
    hr.add(WhoopHrSamplesCompanion.insert(deviceId: device, ts: t, bpm: bpm));
    grav.add(WhoopGravitySamplesCompanion.insert(
        deviceId: device, ts: t, x: 0.25, y: 0.1, z: 1.0));
  }

  await db.batch((b) {
    b.insertAll(db.whoopHrSamples, hr);
    b.insertAll(db.whoopRrIntervals, rr);
    b.insertAll(db.whoopGravitySamples, grav);
  });
}

/// Seed a night-shaped LOW-HR window (which the HR heuristic alone would happily
/// stage as sleep) but tag every second with the strap's own sleep_state so the
/// caller controls whether the band says "asleep". [strapAwake] = the whole window
/// carries state 0 (awake) — ground truth the pipeline must honour over the HR
/// signal. Returns the local date seeded.
Future<DateTime> _seedNightWithStrapState(
  AppDatabase db, {
  required bool strapAwake,
  String device = 'test-strap',
  DateTime? date,
}) async {
  final d = date ?? DateTime(2026, 4, 1);
  final base = d.millisecondsSinceEpoch ~/ 1000;
  final hr = <WhoopHrSamplesCompanion>[];
  final rr = <WhoopRrIntervalsCompanion>[];
  final grav = <WhoopGravitySamplesCompanion>[];
  final sleep = <WhoopSleepStateSamplesCompanion>[];

  // 00:30 → 07:30, low still-wrist HR — indistinguishable from sleep to the HR
  // heuristic. state: 0 (awake) when strapAwake, else 2 (a sleep stage).
  const step = 30;
  final state = strapAwake ? 0 : 2;
  for (var t = base + 1800; t < base + 7 * 3600 + 1800; t += step) {
    final k = (t - base) ~/ step;
    final bpm = (50 + 3 * math.sin(k / 2.0)).round();
    hr.add(WhoopHrSamplesCompanion.insert(deviceId: device, ts: t, bpm: bpm));
    rr.add(WhoopRrIntervalsCompanion.insert(
        deviceId: device, ts: t, rrMs: (60000 / bpm).round()));
    grav.add(WhoopGravitySamplesCompanion.insert(
        deviceId: device, ts: t, x: 0.0, y: 0.0, z: 1.0));
    sleep.add(WhoopSleepStateSamplesCompanion.insert(
        deviceId: device, ts: t, state: state));
  }
  // Daytime tail — clearly awake (state 0), higher HR, some motion.
  for (var t = base + 9 * 3600; t < base + 22 * 3600; t += 300) {
    final h = (t - base) / 3600.0;
    hr.add(WhoopHrSamplesCompanion.insert(
        deviceId: device, ts: t, bpm: (78 + 8 * math.sin(h)).round()));
    grav.add(WhoopGravitySamplesCompanion.insert(
        deviceId: device, ts: t, x: 0.3, y: 0.1, z: 1.0));
    sleep.add(WhoopSleepStateSamplesCompanion.insert(
        deviceId: device, ts: t, state: 0));
  }

  await db.batch((b) {
    b.insertAll(db.whoopHrSamples, hr);
    b.insertAll(db.whoopRrIntervals, rr);
    b.insertAll(db.whoopGravitySamples, grav);
    b.insertAll(db.whoopSleepStateSamples, sleep);
  });
  return d;
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('empty DB → empty live repository (starts with no days)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final repo = await LiveRepository.load(db);
    expect(repo.days, isEmpty);
    expect(repo.vitals, isEmpty);
    expect(repo.workouts, isEmpty);
  });

  test('LiveRepository.empty() is a safe, empty cold-start repo', () {
    final repo = LiveRepository.empty();
    expect(repo.days, isEmpty);
    expect(repo.vitals, isEmpty);
  });

  test('seeded strap rows produce a scored DayRecord via the pipeline',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await _seedOneDay(db);

    final repo = await LiveRepository.load(db);
    expect(repo.days.length, 1, reason: 'one local day of synced rows');

    final d = repo.days.single;
    // Every scored field is finite and in range — no NaN, nothing fabricated.
    expect(d.charge, inInclusiveRange(0, 100));
    expect(d.effort, inInclusiveRange(0, 100));
    expect(d.rest, inInclusiveRange(0, 100));
    expect(d.stress, inInclusiveRange(0, 100));
    expect(d.hrv, greaterThanOrEqualTo(0));
    expect(d.rhr, greaterThanOrEqualTo(0));
    expect(d.charge.isNaN, isFalse);
    // Real per-day HR thread was rebuilt from the synced rows.
    expect(d.hr, isNotEmpty);

    // The low-HR night should stage into a sleep window, which yields real
    // resting-HR + HRV from the beat-to-beat RR inside it.
    expect(d.sleep, isNotNull, reason: 'the seeded night should stage');
    expect(d.rhr, greaterThan(0));
    expect(d.hrv, greaterThan(0));
    expect(repo.vitals, isNotEmpty);
  });

  test('strap sleep_state OVERRIDES the HR heuristic — an all-awake day with '
      'sleep-like HR reports NO sleep (#175 ground truth)', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    // A full night of low, still HR — the HR-only stager would call this sleep —
    // but the strap says awake (state 0) the whole time.
    await _seedNightWithStrapState(db, strapAwake: true);

    final repo = await LiveRepository.load(db);
    expect(repo.days.length, 1);
    // The band never slept → NO fabricated sleep window (the exact bug: the app
    // used to claim a night the wearer never had).
    expect(repo.days.single.sleep, isNull,
        reason: 'strap sleep_state=0 must veto the HR-derived sleep window');
  });

  test('strap sleep_state drives a real sleep window when the band DID sleep',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    // Same HR shape, but the strap marks the window as a sleep stage (state 2).
    await _seedNightWithStrapState(db, strapAwake: false);

    final repo = await LiveRepository.load(db);
    final d = repo.days.single;
    expect(d.sleep, isNotNull, reason: 'strap-reported sleep must stage');
    // The window came from the strap mask (~7h seeded), not a fluke.
    expect(d.sleep!.asleep.inHours, greaterThanOrEqualTo(5));
    expect(d.hrv, greaterThan(0));
    expect(d.rhr, greaterThan(0));
  });

  testWidgets('app boots on an EMPTY live repo without crashing (Today shows '
      'the connect state)', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        onboardedProvider.overrideWith((ref) => true),
        repositoryProvider.overrideWithValue(LiveRepository.empty()),
        databaseProvider
            .overrideWithValue(AppDatabase.forTesting(NativeDatabase.memory())),
      ],
      child: const NoopApp(),
    ));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Connect your WHOOP to start'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Swiping across the tabs must not crash on the empty day list either.
    await tester.fling(find.byType(PageView), const Offset(-500, 0), 1500);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
  });
}
