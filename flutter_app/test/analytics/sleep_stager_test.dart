import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/sleep_stager.dart';

/// Port of the intent of `MotionCorroboratedWakeTest.kt` / `MotionCorroboratedWakeTests.swift`
/// (upstream #465, fixes #462) onto the simplified Dart heuristic, plus the whole-bridged-night
/// window invariant #445 relies on.
///
/// The rule under test: elevated HR ALONE must never score WAKE. A night that holds resting HR up
/// without the wearer getting up (a supplement protocol, a fever, a hot room, alcohol) must not be
/// shredded into WASO — the wrist has to actually move for a wake call to stand.

const _epoch = SleepStager.epochSec;
const _t0 = 1750000000; // fixed epoch base — no clock reads, staging stays deterministic

/// A 4-hour night (480 epochs) of asleep-flagged epochs at [restHr] bpm, carrying a block of
/// [hotHr] bpm from [hotLo] to [hotHi] (relative epoch indices). Movement is the strap's |accel|
/// in g: ~1 g of gravity on a motionless wrist, never ~0. [moved] makes the hot block a real
/// excursion; otherwise the wrist is still for the whole night.
({List<int> ts, List<double?> hr, List<double> mv, List<bool> asleep}) _night({
  required bool moved,
  double restHr = 50,
  double hotHr = 70,
  int hotLo = 200,
  int hotHi = 260,
  List<int> seam = const <int>[],
}) {
  const n = 480;
  final ts = <int>[];
  final hr = <double?>[];
  final mv = <double>[];
  final asleep = <bool>[];
  for (var i = 0; i < n; i++) {
    ts.add(_t0 + i * _epoch);
    final hot = i >= hotLo && i < hotHi;
    final inSeam = seam.isNotEmpty && i >= seam[0] && i < seam[1];
    hr.add(hot || inSeam ? hotHr : restHr);
    // A still wrist is not a CONSTANT wrist: carry a small deterministic wobble so the night has a
    // real (non-degenerate) motion scale for the MAD floor to calibrate against.
    final quiet = 1.0 + 0.002 * (i % 5);
    mv.add((moved && hot) || inSeam ? 2.0 : quiet);
    asleep.add(!inSeam);
  }
  return (ts: ts, hr: hr, mv: mv, asleep: asleep);
}

SleepResult _detect(({List<int> ts, List<double?> hr, List<double> mv, List<bool> asleep}) n) {
  final r = SleepStager.detect(
    epochTs: n.ts,
    epochHr: n.hr,
    epochMovement: n.mv,
    dayHrMin: 50,
    epochAsleep: n.asleep,
  );
  expect(r, isNotNull, reason: 'the synthetic 4 h night must be detected');
  return r!;
}

void main() {
  group('motionQuiescent (night-relative motion floor, #462)', () {
    test('a still wrist reads quiescent for the whole night', () {
      // |accel| ~1 g of gravity throughout: nothing moved, so every epoch is quiescent.
      final q = SleepStager.motionQuiescent(List<double>.filled(100, 1.0));
      expect(q.every((x) => x), isTrue);
    });

    test('a real excursion is not quiescent, the night around it still is', () {
      final mv = List<double>.filled(100, 1.0);
      mv[40] = 2.5; // the wearer turned over
      final q = SleepStager.motionQuiescent(mv);
      expect(q[40], isFalse);
      expect(q.where((x) => x).length, 99);
    });

    test('the floor is night-relative, not an absolute g bar', () {
      // Same night, decoded on a strap whose gravity scale reads ~8 g at rest. An absolute
      // threshold would call every epoch "moving"; the night's own median must absorb the scale.
      final mv = List<double>.filled(100, 8.0);
      mv[40] = 9.5;
      final q = SleepStager.motionQuiescent(mv);
      expect(q[40], isFalse);
      expect(q.where((x) => x).length, 99);
    });

    test('sensor wobble on a still night stays under the MAD gate', () {
      final mv = <double>[for (var i = 0; i < 100; i++) 1.0 + 0.002 * (i % 5)];
      expect(SleepStager.motionQuiescent(mv).every((x) => x), isTrue);
    });

    test('empty in, empty out', () {
      expect(SleepStager.motionQuiescent(const <double>[]), isEmpty);
    });
  });

  group('motion-corroborated wake (#462)', () {
    test('elevated HR on a motionless wrist does NOT score WAKE', () {
      // The #462 night: HR held 20 bpm over baseline for 30 min with the wrist never moving.
      // Pre-fix this scored a 30-min WAKE block purely on the cardiac evidence.
      final r = _detect(_night(moved: false));
      expect(r.awakeSec, 0);
      expect(r.disturbances, 0);
      expect(r.hypnogram.any((s) => s.stage == SleepStageK.awake), isFalse);
      // Nothing was invented in its place: the block is still scored as sleep, and the
      // elevated-HR epochs read REM exactly as V2's unclamped REM emission would have them.
      expect(r.asleepSec, r.inBedSec);
      expect(r.efficiency, 1.0);
      expect(r.remSec, greaterThan(0));
    });

    test('the same elevated HR WITH wrist motion still scores WAKE', () {
      // The corroboration is real, not a blanket suppression: once the wrist actually moves,
      // the identical cardiac evidence calls wake exactly as before.
      final r = _detect(_night(moved: true));
      expect(r.awakeSec, 60 * _epoch); // the 60-epoch hot block, 30 min
      expect(r.disturbances, 1);
      expect(r.efficiency, lessThan(1.0));
    });

    test('a motionless night is not staged worse than a moving one', () {
      // Directional guarantee: corroboration only ever REMOVES wake, never adds it.
      final still = _detect(_night(moved: false));
      final moving = _detect(_night(moved: true));
      expect(still.awakeSec, lessThan(moving.awakeSec));
      expect(still.asleepSec, greaterThan(moving.asleepSec));
      expect(still.inBedSec, moving.inBedSec); // same window either way
    });

    test('low, flat HR on a still wrist is untouched (no wake to suppress)', () {
      // The clamp keeps the wake-SUPPRESSING half of the cardiac evidence: a quiet night has no
      // wake before or after the fix.
      final r = _detect(_night(moved: false, hotHr: 50));
      expect(r.awakeSec, 0);
      expect(r.deepSec, greaterThan(0));
    });
  });

  group('window spans the whole bridged night (#445)', () {
    // A split night: the wearer is up for 5 min mid-night (within the 10-min bridge tolerance),
    // so the two fragments are ONE night. Totals and hypnogram must span the whole thing, not
    // stop at the winning fragment.
    test('hypnogram + totals cover onset → final wake, seam included', () {
      final r = _detect(_night(moved: true, seam: const [200, 210]));

      expect(r.startTs, _t0);
      expect(r.endTs, _t0 + 480 * _epoch);
      expect(r.inBedSec, 480 * _epoch);

      // The hypnogram is gapless and spans the full window.
      expect(r.hypnogram.first.startTs, r.startTs);
      var cursor = r.startTs;
      for (final s in r.hypnogram) {
        expect(s.startTs, cursor, reason: 'segments must be contiguous');
        cursor += s.durationSec;
      }
      expect(cursor, r.endTs, reason: 'the hypnogram must close at the window end');

      // Every second of the night is accounted for by exactly one stage.
      expect(r.lightSec + r.deepSec + r.remSec + r.awakeSec, r.inBedSec);

      // The seam is scored as wake, and real sleep is banked on BOTH sides of it — the Asleep
      // total is not truncated at the first fragment.
      final seamTs = _t0 + 200 * _epoch;
      expect(r.awakeSec, greaterThan(0));
      expect(
        r.hypnogram.any((s) => s.startTs < seamTs && s.stage != SleepStageK.awake),
        isTrue,
        reason: 'sleep before the seam counts',
      );
      expect(
        r.hypnogram.any((s) => s.startTs >= seamTs && s.stage != SleepStageK.awake),
        isTrue,
        reason: 'sleep after the seam counts',
      );
    });
  });
}
