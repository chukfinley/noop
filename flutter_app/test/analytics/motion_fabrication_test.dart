import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noop/core/analytics/daily_pipeline.dart';
import 'package:noop/core/analytics/raw_samples.dart';
import 'package:noop/core/data/db/database.dart';
import 'package:noop/core/data/live_repository.dart';
import 'package:noop/core/data/models.dart';

/// Invariants for the per-second MOTION channel's "no sample" encoding (#345,
/// #462).
///
/// The defect these pin: `LiveRepository` merged HR and gravity onto one
/// per-second row and defaulted a row with a heart rate but NO accel sample to
/// `movement: 1.0` — the resting magnitude, i.e. perfectly still. The two
/// channels are not sampled together (a WHOOP 4.0 offload banks HR densely and
/// gravity coarsely), so on a real night MOST seconds were assigned a stillness
/// nobody measured, and `_buildEpochs` counted every one of them as a motion
/// sample.
///
/// Measured through the real producer BEFORE the fix — a 7 h night the strap
/// reported asleep throughout, HR banked every 10 s, gravity every N s:
///
///   gravity   still night                          15-min waking in a gravity hole
///   30s       0 dist, eff 1.000, sparse=false      0 dist, eff 1.000  <- SUPPRESSED
///   90s       0 dist, eff 1.000, sparse=false      (n/a)
///   120s      0 dist, eff 1.000, sparse=false      (n/a)
///
/// Three separate failures in that table: the 90 s and 120 s nights scored
/// IDENTICALLY to the 30 s one (the sparsity was erased before the stager saw
/// it), `motionSparse` could never fire for the exact case #345 wrote it for, and
/// a genuine 15-minute awakening at 78 bpm was scored as 1.000-efficiency sleep
/// because #462's "elevated HR on a still wrist is not an awakening" guard was
/// corroborating against invented stillness.
const _device = 'test-strap';

/// Seed ONE local day shaped like a real WHOOP 4.0 offload: heart rate, RR and
/// the strap's own sleep_state banked DENSELY (every 10 s), gravity banked only
/// every [gravityEverySec]. The strap reports asleep (state 2) for the whole
/// 00:30 → 07:30 window, so the sleep window itself never depends on any of the
/// knobs below — only the STAGING inside it does.
///
/// [awakening] adds a genuine 15-minute waking at 04:30: HR to 78 bpm (well over
/// the wake margin) and a plainly moving wrist. [gravityHole] withholds gravity
/// for exactly that waking — the clumped-offload case where the strap simply did
/// not bank the motion that proves the wearer got up. [hrLift] instead gives an
/// otherwise still night the ordinary overnight HR excursions every real night
/// has (3 min at 70 bpm every 20 min), with no waking at all.
Future<void> _seedOffload(
  AppDatabase db, {
  required int gravityEverySec,
  bool awakening = false,
  bool gravityHole = false,
  bool hrLift = false,
  DateTime? date,
}) async {
  final d = date ?? DateTime(2026, 5, 1);
  final base = d.millisecondsSinceEpoch ~/ 1000;
  const nightStart = 1800; // 00:30
  const nightEnd = 1800 + 7 * 3600; // 07:30
  const awakeFrom = 1800 + 4 * 3600; // 04:30
  const awakeTo = awakeFrom + 15 * 60;

  bool isAwake(int o) => awakening && o >= awakeFrom && o < awakeTo;

  final hr = <WhoopHrSamplesCompanion>[];
  final rr = <WhoopRrIntervalsCompanion>[];
  final grav = <WhoopGravitySamplesCompanion>[];
  final sleep = <WhoopSleepStateSamplesCompanion>[];

  // Dense cardiac + strap state: EVERY epoch of the night carries a heart rate,
  // whatever the gravity rate is. That is the whole point — the rows exist, it is
  // the accel channel inside them that does not.
  for (var o = nightStart; o < nightEnd; o += 10) {
    final t = base + o;
    final lift = hrLift && ((o ~/ 60) % 20) < 3;
    final bpm = isAwake(o) ? 78 : (lift ? 70 : 50 + (o ~/ 10) % 3);
    hr.add(WhoopHrSamplesCompanion.insert(deviceId: _device, ts: t, bpm: bpm));
    rr.add(WhoopRrIntervalsCompanion.insert(
        deviceId: _device, ts: t, rrMs: (60000 / bpm).round()));
    sleep.add(WhoopSleepStateSamplesCompanion.insert(
        deviceId: _device, ts: t, state: 2));
  }

  for (var o = nightStart; o < nightEnd; o += gravityEverySec) {
    final t = base + o;
    if (isAwake(o)) {
      if (gravityHole) continue;
      // A plainly moving wrist: the gravity vector swings well off 1 g.
      grav.add(WhoopGravitySamplesCompanion.insert(
          deviceId: _device,
          ts: t,
          x: 0.35 + 0.2 * ((o ~/ 30) % 3),
          y: 0.1,
          z: 1.0));
    } else {
      // A still wrist really measured: ~1 g plus the strap's own sensor noise.
      // Never EXACTLY 1.0 — that value is what the old default fabricated, and a
      // genuinely still wrist does not read as a perfect resting magnitude.
      grav.add(WhoopGravitySamplesCompanion.insert(
          deviceId: _device, ts: t, x: 0.0, y: 0.0, z: 1.0 + 0.001 * ((o * 7919) % 13)));
    }
  }

  // Daytime tail — clearly awake and moving, so the night is the only window.
  for (var o = 9 * 3600; o < 22 * 3600; o += 300) {
    final t = base + o;
    hr.add(WhoopHrSamplesCompanion.insert(
        deviceId: _device, ts: t, bpm: (78 + 8 * math.sin(o / 3600.0)).round()));
    grav.add(WhoopGravitySamplesCompanion.insert(
        deviceId: _device, ts: t, x: 0.3, y: 0.1, z: 1.0));
    sleep.add(WhoopSleepStateSamplesCompanion.insert(
        deviceId: _device, ts: t, state: 0));
  }

  await db.batch((b) {
    b.insertAll(db.whoopHrSamples, hr);
    b.insertAll(db.whoopRrIntervals, rr);
    b.insertAll(db.whoopGravitySamples, grav);
    b.insertAll(db.whoopSleepStateSamples, sleep);
  });
}

/// Score a seeded offload night through the REAL producer — the drift store and
/// `LiveRepository`, where the fabricated `movement` default lived.
Future<SleepRecord> _sleepOf({
  required int gravityEverySec,
  bool awakening = false,
  bool gravityHole = false,
  bool hrLift = false,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await _seedOffload(db,
      gravityEverySec: gravityEverySec,
      awakening: awakening,
      gravityHole: gravityHole,
      hrLift: hrLift);
  final repo = await LiveRepository.load(db);
  expect(repo.days, hasLength(1), reason: 'one local day of synced rows');
  final s = repo.days.single.sleep;
  expect(s, isNotNull, reason: 'the strap reported asleep — expect a window');
  return s!;
}

void main() {
  group('a second with no accel sample is not a still second', () {
    test('a coarse-gravity night is distinguishable from a dense one', () async {
      // The measurement that pins the erasure. Before the fix all three of these
      // reported motionSparse=false: the 1.0 default made every second that never
      // carried a gravity sample count as a motion sample, so a night banked at
      // 1/3 coverage claimed FULL coverage and #345's guard could not fire for
      // the exact case (dense HR, coarse gravity) it exists for.
      final dense = await _sleepOf(gravityEverySec: 30);
      expect(dense.motionSparse, isFalse,
          reason: 'one gravity sample per 30 s epoch IS full coverage');

      for (final every in [90, 120]) {
        final coarse = await _sleepOf(gravityEverySec: every);
        expect(coarse.motionSparse, isTrue,
            reason: 'gravity every ${every}s over a 30 s epoch grid is ~1/'
                '${every ~/ 30} coverage — a night staged on that cannot earn a '
                'confident Rest, and before the fix it was indistinguishable '
                'from the dense night above');
      }
    });

    test('an all-gravity-less night reports no motion coverage at all', () async {
      // The end of the channel: a day whose rows carry a heart rate and NEVER an
      // accel sample. Coverage is 0, so the staging is maximally unconfident. The
      // old default would have called this night perfectly still, end to end.
      final samples = <RawSample>[];
      for (var i = -3600; i < 8 * 3600; i += 10) {
        final inNight = i >= 0;
        samples.add(RawSample(
          ts: 1750000000 + i,
          hr: inNight ? 50 + ((i * 31) % 3) : 52,
          spo2: 0,
          rrCount: 1,
          rr1: 1150,
          rr2: 0,
          rr3: 0,
          movement: null, // no accel sample this second — the 4.0 gravity gap
          sleepState: inNight ? 1 : 0,
        ));
      }
      final recs = DailyPipeline(const UserProfile())
          .run([RawDay(DateTime.fromMillisecondsSinceEpoch((1750000000 - 3600) * 1000), samples)]);
      final s = recs.first.sleep;
      expect(s, isNotNull);
      expect(s!.motionSparse, isTrue,
          reason: 'a night with NO accel sample anywhere has zero motion '
              'coverage — it must never read as a fully-covered still night');
    });
  });

  group('#462 corroboration runs on measured motion, never invented motion', () {
    test('a real awakening the strap never banked motion for is NOT suppressed',
        () async {
      // The sharpest half of the defect, and it does not need a sparse night to
      // bite: gravity is banked densely all night EXCEPT across the 15 minutes the
      // wearer is actually up. Coverage stays ~96% and the largest hole (15 min)
      // is inside the 20-min bridge, so this night is not even flagged sparse —
      // yet before the fix those 30 epochs were handed a fabricated 1.0, read as
      // PERFECTLY still, and #462 refused to score them awake on cardiac evidence.
      // Measured before the fix: 0 disturbances, 0 min awake, efficiency 1.000 —
      // a 78 bpm waking reported as a flawless night.
      final truth = await _sleepOf(gravityEverySec: 30, awakening: true);
      expect(truth.disturbances, 1,
          reason: 'the dense read is the ground truth: one real awakening');
      expect(truth.awake.inMinutes, 15);

      final hole = await _sleepOf(
          gravityEverySec: 30, awakening: true, gravityHole: true);
      expect(hole.motionSparse, isFalse,
          reason: 'a 15-min hole sits inside the 20-min bridge — this night is '
              'NOT low-confidence, so nothing else was going to catch this');
      expect(hole.disturbances, truth.disturbances,
          reason: 'the wearer got up; the strap merely failed to bank the accel '
              'for it. Unknown motion is not evidence of a still wrist, so #462 '
              'must not veto the wake call');
      expect(hole.awake, truth.awake,
          reason: 'the awakening must land in WASO, not be waved through');
      expect(hole.efficiency, closeTo(truth.efficiency, 0.001));
    });

    test('a real awakening on a coarsely-banked night is not shredded', () async {
      // Before the fix this night read 5 min awake across 10 disturbances against
      // the dense night's 15 min across 1. Two fabrication effects compounded: the
      // 2/3 of epochs with no accel sample read as perfectly still and had their
      // wake vetoed, while the 1/3 that DID bank motion had their real excursion
      // averaged together with the fabricated zeros beside them, diluting it
      // toward the floor. The awakening survived only as a comb whose teeth were
      // the gravity sampling phase.
      final truth = await _sleepOf(gravityEverySec: 30, awakening: true);
      final coarse = await _sleepOf(gravityEverySec: 90, awakening: true);

      expect(coarse.disturbances, truth.disturbances,
          reason: 'one awakening happened; the banking rate must not decide how '
              'many the wearer is told about');
      expect(coarse.awake, truth.awake,
          reason: 'coarse banking must not truncate a real waking to a third of '
              'its length');
    });

    test('a KNOWN-still wrist still vetoes cardiac wake — no invented awakening',
        () async {
      // The other direction, and the one that must not regress: when motion is
      // actually MEASURED and says the wrist did not move, #462 still holds. This
      // night has the ordinary overnight HR excursions every real night carries
      // (3 min at 70 bpm off a ~51 bpm baseline, every 20 min — comfortably over
      // the 12 bpm wake margin) on a wrist that never moves. Nobody wakes up.
      // Telling the truth about missing samples must not turn into manufacturing
      // awakenings wherever HR happens to rise.
      final s = await _sleepOf(gravityEverySec: 30, hrLift: true);
      expect(s.disturbances, 0,
          reason: 'elevated HR on a wrist MEASURED still is not an awakening '
              '(#462) — the veto must survive the nullable motion channel');
      expect(s.awake, Duration.zero);
      expect(s.efficiency, 1.0);
    });
  });
}
