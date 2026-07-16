import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/sleep_stager.dart';

/// Port of the intent of `MotionCorroboratedWakeTest.kt` / `MotionCorroboratedWakeTests.swift`
/// (upstream #465, fixes #462) onto the simplified Dart heuristic, plus the whole-bridged-night
/// window invariant #345 relies on. (The split-night issue is #345; #445 is upstream's unrelated
/// strap-log PII redaction — the label here was simply wrong. `split_night_test.dart` carries the
/// substantive #345 coverage.)
///
/// The rule under test: elevated HR ALONE must never score WAKE. A night that holds resting HR up
/// without the wearer getting up (a supplement protocol, a fever, a hot room, alcohol) must not be
/// shredded into WASO — the wrist has to actually move for a wake call to stand.

const _epoch = SleepStager.epochSec;
const _t0 = 1750000000; // fixed epoch base — no clock reads, staging stays deterministic

/// A 4-hour night (480 epochs) of asleep-flagged epochs at [restHr] bpm, carrying a block of
/// [hotHr] bpm from [hotLo] to [hotHi] (relative epoch indices). [moved] makes the hot block a real
/// excursion; otherwise the wrist is still for the whole night.
///
/// Movement carries NO fixed unit by contract — `detect` only ever measures it night-relatively, so
/// a fixture may pick any scale. [mvFloor]/[mvMoved] name the two levels explicitly:
///   * mvFloor 1.0 (default) = a raw |accel|-in-g trace, gravity included, still wrist ~1 g;
///   * mvFloor 0.0           = what `DailyPipeline._buildEpochs` really hands over — gravity removed
///                             and the day's quiet level subtracted, still wrist ~0, ~0.3 at peak.
/// Both must stage identically; that is pinned below.
({List<int> ts, List<double?> hr, List<double> mv, List<bool> asleep}) _night({
  required bool moved,
  double restHr = 50,
  double hotHr = 70,
  int hotLo = 200,
  int hotHi = 260,
  List<int> seam = const <int>[],
  double mvFloor = 1.0,
  double mvMoved = 2.0,
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
    final quiet = mvFloor + 0.002 * (i % 5);
    mv.add((moved && hot) || inSeam ? mvMoved : quiet);
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
      // A flat trace: nothing moved, so every epoch is quiescent.
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

    test('the floor is night-relative, not an absolute bar', () {
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

  group('motionExcursion (the clearly-moved tier)', () {
    // The weak-cardiac wake branch needs "the wrist unmistakably moved", which is strictly stronger
    // than "not quiescent". It used to be an absolute `mv >= 0.12 * 4` (0.48) bar — anchored to
    // nothing, and DEAD on the real producer's gravity-removed, quiet-subtracted motion, which peaks
    // around 0.3 across a whole day and sits at ~0 asleep. This tier is night-relative instead.

    test('a still night has no excursions', () {
      final mv = <double>[for (var i = 0; i < 100; i++) 1.0 + 0.002 * (i % 5)];
      expect(SleepStager.motionExcursion(mv).any((x) => x), isFalse);
    });

    test('a real excursion is flagged and the quiet night around it is not', () {
      final mv = <double>[for (var i = 0; i < 100; i++) 1.0 + 0.002 * (i % 5)];
      mv[40] = 2.5; // the wearer turned over
      final e = SleepStager.motionExcursion(mv);
      expect(e[40], isTrue);
      expect(e.where((x) => x).length, 1);
    });

    test('the tier fires at PRODUCTION scale, where the old absolute 0.48 bar was dead', () {
      // Exactly the real producer's numbers: still ~0, a genuine excursion ~0.3. `0.3 >= 0.48` is
      // false, so the old bar never fired here — the branch was unreachable code on live data.
      final mv = <double>[for (var i = 0; i < 100; i++) 0.002 * (i % 5)];
      mv[40] = 0.3;
      expect(mv[40], lessThan(0.48), reason: 'the old absolute bar could not have fired');
      expect(SleepStager.motionExcursion(mv)[40], isTrue);
    });

    test('the tier is night-relative, not an absolute bar', () {
      // A strap whose gravity decode reads ~8 g at rest: the night's own median absorbs the scale.
      final mv = <double>[for (var i = 0; i < 100; i++) 8.0 + 0.002 * (i % 5)];
      mv[40] = 9.5;
      expect(SleepStager.motionExcursion(mv)[40], isTrue);
      expect(SleepStager.motionExcursion(mv).where((x) => x).length, 1);
    });

    test('an excursion is ALWAYS non-quiescent — the two tiers cannot contradict', () {
      // Both read off the same median + MAD, the excursion gate being the wider one. Nothing may
      // ever be "clearly moved" and "did not move" at once, whatever the trace.
      for (final mv in <List<double>>[
        <double>[for (var i = 0; i < 100; i++) 1.0 + 0.002 * (i % 5)],
        <double>[for (var i = 0; i < 100; i++) 0.002 * (i % 5)]..[40] = 0.3,
        <double>[for (var i = 0; i < 60; i++) i.toDouble()],
        List<double>.filled(50, 2.0),
        <double>[1, 1, 1, 1, 5, 1, 1, 900, 1, 1],
      ]) {
        final q = SleepStager.motionQuiescent(mv);
        final e = SleepStager.motionExcursion(mv);
        for (var i = 0; i < mv.length; i++) {
          expect(e[i] && q[i], isFalse, reason: 'epoch $i cannot be both');
        }
      }
    });

    test('a zero-MAD trace flags nothing — this tier fails safe', () {
      // No motion scale to measure against. Since this tier can only ever ADD wake, a degenerate
      // trace must promote NOTHING rather than promote every off-floor epoch.
      final mv = List<double>.filled(100, 1.0);
      mv[40] = 9.9; // MAD is still 0: half the deviations are exactly 0
      expect(SleepStager.motionExcursion(mv).any((x) => x), isFalse);
    });

    test('empty in, empty out', () {
      expect(SleepStager.motionExcursion(const <double>[]), isEmpty);
    });
  });

  group('movement scale invariance', () {
    test('the same night stages identically at |accel| scale and at production scale', () {
      // The stager measures movement ONLY night-relatively, so an affine shift of the whole trace —
      // exactly what removing gravity is — must change nothing. This is the property that lets the
      // producer and the stager disagree about units without a bug; the old absolute `_moveWake`
      // broke it, which is why the wake branch died and the resp gate went blind.
      final raw = _detect(_night(moved: true)); // still ~1.0 g, moved 2.0
      final prod = _detect(_night(moved: true, mvFloor: 0.0, mvMoved: 1.0)); // gravity removed

      expect(prod.awakeSec, raw.awakeSec);
      expect(prod.asleepSec, raw.asleepSec);
      expect(prod.deepSec, raw.deepSec);
      expect(prod.remSec, raw.remSec);
      expect(prod.lightSec, raw.lightSec);
      expect(prod.disturbances, raw.disturbances);
      expect(prod.hypnogram.length, raw.hypnogram.length);
      for (var i = 0; i < raw.hypnogram.length; i++) {
        expect(prod.hypnogram[i].stage, raw.hypnogram[i].stage);
        expect(prod.hypnogram[i].startTs, raw.hypnogram[i].startTs);
        expect(prod.hypnogram[i].durationSec, raw.hypnogram[i].durationSec);
      }
    });
  });

  group('weak cardiac evidence + an unmistakable excursion scores WAKE', () {
    // The second wake branch: HR only just over baseline (well under the +12 bpm the first branch
    // needs), but the wrist plainly moved. On production-scale movement the old absolute bar made
    // this branch unreachable, so a mild-HR awakening with real thrashing was never called.

    test('a mild HR lift WITH a real excursion is awake, at production scale', () {
      final r = _detect(_night(
        moved: true,
        hotHr: 55, // +5 over baseline: under the +12 the strong-cardiac branch needs
        mvFloor: 0.0,
        mvMoved: 0.3, // a real excursion in the producer's units — and < the old 0.48 bar
      ));
      expect(r.awakeSec, 60 * _epoch, reason: 'the 60-epoch block moved and ran hot');
      expect(r.disturbances, 1);
    });

    test('the SAME mild HR lift on a still wrist is not awake', () {
      // Corroboration is real, not a blanket promotion: without the motion there is no wake.
      final r = _detect(_night(moved: false, hotHr: 55, mvFloor: 0.0, mvMoved: 0.3));
      expect(r.awakeSec, 0);
      expect(r.disturbances, 0);
      expect(r.asleepSec, r.inBedSec);
    });
  });

  group('respiratory rate is never fabricated', () {
    // `detect` cannot measure respiration and must not pretend to. It sees HR already averaged into
    // 30 s epochs; adult respiration is 12–20 br/min (0.2–0.33 Hz) against a 0.033 Hz sample rate,
    // i.e. ~15–20x above Nyquist. The estimator removed from here counted maxima of that epoch
    // series and divided by minutes — at most 1.0 br/min — which its own clamp(8, 22) then pinned
    // to EXACTLY 8.0. It could only ever emit null or that fabricated 8.0, and the 8.0 fed both the
    // Recovery `resp` term and the resp baseline.

    List<double?> _hrSeries(double Function(int i) f) => <double?>[for (var i = 0; i < 480; i++) f(i)];

    SleepResult _detectHr(List<double?> hr) {
      final r = SleepStager.detect(
        epochTs: <int>[for (var i = 0; i < 480; i++) _t0 + i * _epoch],
        epochHr: hr,
        epochMovement: <double>[for (var i = 0; i < 480; i++) 0.002 * (i % 5)],
        dayHrMin: 49,
        epochAsleep: List<bool>.filled(480, true),
      );
      expect(r, isNotNull);
      return r!;
    }

    test('no respiratory rate on the input that used to force the fabricated 8.0', () {
      // The fastest oscillation the epoch grid can carry (a peak every 2 epochs) — the removed
      // estimator's absolute best case, which returned exactly 8.0.
      expect(_detectHr(_hrSeries((i) => 52 + (i.isEven ? 3.0 : -3.0))).respRate, isNull);
    });

    test('no respiratory rate from ordinary sleeping-HR wander either', () {
      // A gentle drift across the night: the shape of real 30 s-mean HR, and the shape that used to
      // trip the peak counter into emitting 8.0 on roughly one night in five.
      expect(_detectHr(_hrSeries((i) => 50 + 2.0 * math.sin(i / 9.0))).respRate, isNull);
    });

    test('a REAL 15 br/min modulation is not recoverable — the grid aliased it away', () {
      // 0.25 Hz sampled at 0.033 Hz. Pinned so nobody tries to "unlock" respRate by tuning a gate:
      // the information is not in the input. OpenStrapEngine measures it off the raw RR intervals.
      expect(_detectHr(_hrSeries((i) => 52 + 3.0 * math.sin(2 * math.pi * 0.25 * i * _epoch))).respRate,
          isNull);
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

  group('window spans the whole bridged night (#345)', () {
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
