import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noop/core/analytics/sleep_stager.dart';
import 'package:noop/core/data/db/database.dart';
import 'package:noop/core/data/live_repository.dart';
import 'package:noop/core/data/models.dart';

/// Invariants for the STRAP SLEEP-STATE channel (#175) — what it can be asked to
/// decide, and what it structurally cannot.
///
/// These exist because of a standing, recurring proposal: the strap emits its own
/// per-second `sleep_state`, `DailyPipeline` grids it into a per-epoch verdict, and
/// `SleepStager.detect` then spends it ONLY on choosing the sleep window — inside
/// the window it re-derives awake from HR and motion instead. That reads as
/// throwing ground truth away, and repairing it reads as the fix for the
/// coarse-gravity night's cardiac-only wake calls (49 disturbances on a still 7 h
/// night whose dense twin scores 0).
///
/// It is not a fix. These pin the two frame-layout facts that make it unavailable,
/// so it is not re-derived from first principles a fourth time:
///
///   * `sleep_state` is byte 81 of a WHOOP 5.0/MG **v18** record; gravity is bytes
///     45/49/53 of that SAME record, and byte 81 is only reachable on a record long
///     enough to have already yielded byte 45. A strap verdict therefore IMPLIES a
///     motion sample: the epochs lacking motion corroboration are exactly the
///     epochs the strap said nothing about. Staging on the channel means staging on
///     its silence — measured at 279 disturbances / eff 0.334 on the night below.
///   * a WHOOP 4.0 has no such field in any record layout (V24/V12/V5/V7/V9), so
///     the channel is absent entirely on the very device family whose offload
///     profile — HR dense, gravity coarse — produces the night in question.
const _device = 'test-strap';

/// How the strap's own channel is banked for a seeded night.
enum _Strap {
  /// A WHOOP 4.0: no `sleep_state` row is ever written, on any second.
  none,

  /// The REAL co-emission: a state sample exists exactly where a gravity sample
  /// exists, because the two ride the same per-second record. Never denser.
  ridesGravity,
}

/// Seed one local day: a 7 h night (00:30 → 07:30) the wearer sleeps straight
/// through, shaped like a real offload — cardiac banked densely, gravity banked
/// every [gravityEverySec].
///
/// [hrLift] adds the ordinary overnight HR excursions every real night carries
/// (3 min at 70 bpm off a ~51 bpm baseline, every 20 min — comfortably over the
/// 12 bpm wake margin) on a wrist that never moves. Nobody wakes up.
Future<void> _seed(
  AppDatabase db, {
  required int gravityEverySec,
  required _Strap strapState,
  bool hrLift = false,
}) async {
  final base = DateTime(2026, 5, 1).millisecondsSinceEpoch ~/ 1000;
  const nightStart = 1800;
  const nightEnd = 1800 + 7 * 3600;

  final hr = <WhoopHrSamplesCompanion>[];
  final rr = <WhoopRrIntervalsCompanion>[];
  final grav = <WhoopGravitySamplesCompanion>[];
  final sleep = <WhoopSleepStateSamplesCompanion>[];

  // Dense cardiac: EVERY epoch of the night carries a heart rate, whatever the
  // gravity rate is. That is the whole point — the seconds exist; it is the accel
  // inside them that does not.
  for (var o = nightStart; o < nightEnd; o += 10) {
    final t = base + o;
    final lift = hrLift && ((o ~/ 60) % 20) < 3;
    final bpm = lift ? 70 : 50 + (o ~/ 10) % 3;
    hr.add(WhoopHrSamplesCompanion.insert(deviceId: _device, ts: t, bpm: bpm));
    rr.add(WhoopRrIntervalsCompanion.insert(
        deviceId: _device, ts: t, rrMs: (60000 / bpm).round()));
  }

  for (var o = nightStart; o < nightEnd; o += gravityEverySec) {
    final t = base + o;
    // A still wrist really measured: ~1 g plus the strap's own sensor noise.
    grav.add(WhoopGravitySamplesCompanion.insert(
        deviceId: _device,
        ts: t,
        x: 0.0,
        y: 0.0,
        z: 1.0 + 0.001 * ((o * 7919) % 13)));
    // The co-emission. State is banked on the same record as gravity and never on
    // a schedule of its own — seeding it denser than gravity would be seeding a
    // frame layout that does not exist.
    if (strapState == _Strap.ridesGravity) {
      sleep.add(WhoopSleepStateSamplesCompanion.insert(
          deviceId: _device, ts: t, state: 2));
    }
  }

  // Daytime tail — clearly awake and moving, so the night is the only window.
  for (var o = 9 * 3600; o < 22 * 3600; o += 300) {
    final t = base + o;
    hr.add(WhoopHrSamplesCompanion.insert(
        deviceId: _device, ts: t, bpm: (78 + 8 * math.sin(o / 3600.0)).round()));
    grav.add(WhoopGravitySamplesCompanion.insert(
        deviceId: _device, ts: t, x: 0.3, y: 0.1, z: 1.0));
    if (strapState == _Strap.ridesGravity) {
      sleep.add(WhoopSleepStateSamplesCompanion.insert(
          deviceId: _device, ts: t, state: 0));
    }
  }

  await db.batch((b) {
    b.insertAll(db.whoopHrSamples, hr);
    b.insertAll(db.whoopRrIntervals, rr);
    b.insertAll(db.whoopGravitySamples, grav);
    b.insertAll(db.whoopSleepStateSamples, sleep);
  });
}

/// Score a seeded night through the REAL producer — the drift store and
/// `LiveRepository`, not a hand-built epoch array.
Future<SleepRecord> _sleepOf({
  required int gravityEverySec,
  required _Strap strapState,
  bool hrLift = false,
}) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await _seed(db,
      gravityEverySec: gravityEverySec, strapState: strapState, hrLift: hrLift);
  final repo = await LiveRepository.load(db);
  expect(repo.days, hasLength(1), reason: 'one local day of synced rows');
  final s = repo.days.single.sleep;
  expect(s, isNotNull, reason: 'a 7 h night — expect a window');
  return s!;
}

void main() {
  group('the strap verdict cannot rescue an epoch with no motion', () {
    test('the coarse-gravity night has no strap channel to appeal to', () async {
      // The night the strap channel keeps being proposed as the fix for is a WHOOP
      // 4.0 profile — and a 4.0 never emits sleep_state at all. There is no verdict
      // being under-used here; there is no verdict.
      final coarse = await _sleepOf(
          gravityEverySec: 90, strapState: _Strap.none, hrLift: true);
      expect(coarse.disturbances, 49,
          reason: 'the documented coarse-gravity night, scored with no strap '
              'channel present anywhere on the day');
      expect(coarse.awake.inMinutes, 42);
      expect(coarse.motionSparse, isTrue,
          reason: 'this is what motionSparse exists for: the count above is what '
              'the banking rate chose, and the night says so');

      final dense = await _sleepOf(
          gravityEverySec: 30, strapState: _Strap.none, hrLift: true);
      expect(dense.disturbances, 0,
          reason: 'same wearer, same night, gravity banked densely: nobody woke '
              'up. The 49 track gravity SAMPLING PHASE, not physiology');
    });

    test('adding the strap channel to that night rescues none of it', () async {
      // The measurement that closes the proposal. Bank the strap's own verdict the
      // way the strap actually banks it — alongside gravity, because they share a
      // record — and every phantom disturbance survives. The verdict is silent on
      // exactly the epochs whose staging is in doubt, so it has nothing to say
      // about them. All it moves is the window EDGE, by a single epoch, because it
      // now bounds the night at its own 90 s banking granularity instead of the
      // HR heuristic's: asleep 378 -> 377 min. The 49 are untouched.
      final without = await _sleepOf(
          gravityEverySec: 90, strapState: _Strap.none, hrLift: true);
      final withStrap = await _sleepOf(
          gravityEverySec: 90, strapState: _Strap.ridesGravity, hrLift: true);

      expect(withStrap.disturbances, without.disturbances,
          reason: 'the strap verdict cannot reach a motion-less epoch: byte 81 is '
              'unreachable on a record that did not already yield byte 45, so '
              'every uncorroborated epoch is one the strap said NOTHING about');
      expect(withStrap.disturbances, 49, reason: 'unchanged, and still phantom');
      expect(withStrap.awake, without.awake,
          reason: 'and not one minute of the phantom WASO is recovered either');
      expect(withStrap.asleep.inMinutes, closeTo(without.asleep.inMinutes, 1),
          reason: 'the ONLY thing the channel moves is where the night is cut, by '
              'one epoch at its own banking granularity — it picks the window, '
              'which is all it has ever done');
    });

    test('the strap channel never sources a stage it cannot carry', () async {
      // sleep_state is a 2-bit code — `(band81 >> 4) & 3`. Even where it speaks it
      // cannot express light/deep/REM, so no stage may ever be sourced from it: a
      // night staged with the channel present must total exactly as one staged
      // without it.
      final withStrap =
          await _sleepOf(gravityEverySec: 30, strapState: _Strap.ridesGravity);
      final without = await _sleepOf(gravityEverySec: 30, strapState: _Strap.none);
      expect(withStrap.asleep, without.asleep,
          reason: 'the channel picks the WINDOW; it does not stage');
      expect(withStrap.deep, without.deep);
      expect(withStrap.rem, without.rem);
      expect(withStrap.light, without.light);
    });
  });

  group('silence in the strap channel is not a verdict', () {
    // A day that is otherwise an unmistakable single window: flat 60 bpm, still.
    List<int> ts() =>
        [for (var i = 0; i < 2880; i++) i * SleepStager.epochSec];
    List<double?> hr() => List<double?>.filled(2880, 60);
    List<double?> mv() => List<double?>.filled(2880, 0.0);

    test('a channel that says nothing anywhere opens no window', () async {
      // The strap banked no state for any epoch. The channel is PRESENT (non-null
      // array) but empty of verdicts, and `sleepy` asks `== true`, so nothing is
      // sleepy and there is no night. Silence must never read as an asleep report
      // just because the array existed.
      final r = SleepStager.detect(
        epochTs: ts(),
        epochHr: hr(),
        epochMovement: mv(),
        epochAsleep: List<bool?>.filled(2880, null),
      );
      expect(r, isNull,
          reason: 'a present-but-silent channel yields no window — a flat 60 bpm '
              'day must not become a 24 h night because an array was allocated');
    });

    test('silence and an awake report agree for the window, and must', () async {
      // The safety property behind the `bool?` encoding, pinned in the one place it
      // is observable. For choosing the WINDOW a silent epoch and an
      // awake-reported epoch are both non-sleepy — so a gap in the banked stream
      // can no more extend a night than a real wake report can, which is the
      // guarantee the old all-`false` encoding was reaching for and got by luck.
      // The two are kept DISTINGUISHABLE anyway, because they are different
      // evidence: the moment anything downstream stages on the channel, reading
      // silence as an awake report turns every gap into an awakening (measured on
      // the coarse night above: 279 disturbances / 279 min WASO / eff 0.334,
      // against the 49 it was meant to repair).
      final strapAsleepThenSilent = <bool?>[
        for (var i = 0; i < 2880; i++) (i >= 60 && i < 900) ? true : null,
      ];
      final strapAsleepThenAwake = <bool?>[
        for (var i = 0; i < 2880; i++) (i >= 60 && i < 900) ? true : false,
      ];

      final silent = SleepStager.detect(
        epochTs: ts(),
        epochHr: hr(),
        epochMovement: mv(),
        epochAsleep: strapAsleepThenSilent,
      );
      final awake = SleepStager.detect(
        epochTs: ts(),
        epochHr: hr(),
        epochMovement: mv(),
        epochAsleep: strapAsleepThenAwake,
      );

      expect(silent, isNotNull, reason: 'the strap reported a 7 h bout');
      expect(awake, isNotNull);
      expect(silent!.startTs, awake!.startTs,
          reason: 'the bout the strap AFFIRMED bounds the night; what surrounds '
              'it — silence or a wake report — cannot extend it either way');
      expect(silent.endTs, awake.endTs);
      expect(silent.asleepSec, awake.asleepSec);
      expect(silent.disturbances, awake.disturbances,
          reason: 'and neither may manufacture a disturbance out of the '
              'surrounding epochs');
    });
  });
}
