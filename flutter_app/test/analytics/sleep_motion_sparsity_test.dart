import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/daily_pipeline.dart';
import 'package:noop/core/analytics/raw_samples.dart';
import 'package:noop/core/analytics/sleep_stager.dart';
import 'package:noop/core/data/models.dart';

/// Motion-sparsity invariants for the epoch movement channel (#345, #462).
///
/// The defect these pin: `_buildEpochs` used to fill an epoch with no motion
/// sample with the SENTINEL 5.0, encoding "unknown" as a large magnitude. The
/// stager's motion tiers are night-relative by contract (median + MAD), so the
/// sentinel did not stay local to its own epoch — it dragged the scale every
/// OTHER epoch is judged against, and the #462 motion-corroborated-wake guard
/// inverted: a still wrist read as moving, and ordinary overnight HR excursions
/// were scored as awakenings.
const _t0 = 1750000000;
const _e = SleepStager.epochSec;

/// A night that MUST score identically however densely the strap banked it: the
/// wrist is still from end to end, the strap reports asleep throughout, and HR
/// carries the ordinary overnight excursions every real night has (a 3-minute
/// lift to ~70 bpm every 20 minutes, off a ~50 bpm floor).
///
/// Nobody wakes up on this night. Only the SAMPLING RATE changes: [rowEverySec]
/// = 1 banks a row per second (every 30 s epoch full); 90 or 120 leaves most
/// epochs with no sample at all — the offload/backfill case that fired the
/// sentinel. Physiology fixed, sampling varied ⇒ the sleep must not move.
RawDay _stillNight({required int rowEverySec}) {
  final samples = <RawSample>[];
  for (var i = -3600; i < 8 * 3600; i++) {
    if (i % rowEverySec != 0) continue;
    final inNight = i >= 0;
    final lift = inNight && ((i ~/ 60) % 20) < 3;
    samples.add(RawSample(
      ts: _t0 + i,
      hr: inNight ? (lift ? 70 : 50 + ((i * 31) % 3)) : 52,
      spo2: 0,
      rrCount: 1,
      rr1: 1150 + ((i * 17) % 60),
      rr2: 0,
      rr3: 0,
      // Still wrist all night: 1 g resting magnitude + a little sensor noise.
      movement: 1.0 + 0.001 * ((i * 7919) % 13),
      sleepState: inNight ? 1 : 0,
    ));
  }
  return RawDay(DateTime.fromMillisecondsSinceEpoch((_t0 - 3600) * 1000), samples);
}

SleepRecord _sleepOf(RawDay day) {
  final recs = DailyPipeline(const UserProfile()).run([day]);
  expect(recs, isNotEmpty, reason: 'the night should score at all');
  final s = recs.first.sleep;
  expect(s, isNotNull, reason: 'the strap reported asleep — expect a window');
  return s!;
}

void main() {
  group('sparse-motion vs dense-motion equivalence (the sentinel defect)', () {
    // The measurement that found the bug, run through the REAL producer. Before
    // the fix these read, against an identical dense night of 0 disturbances:
    //   row/90s  -> asleep=455min awake=24min disturbances=48 efficiency=0.95
    //   row/120s -> asleep=454min awake=24min disturbances=48 efficiency=0.95
    // 48 phantom awakenings on a night nobody woke up. The mechanism is the
    // median hijack: past ~half the window the sentinel BECOMES the median, so
    // every genuinely still epoch sits 5.0 away from it, the MAD collapses to 0,
    // and the quiescent gate (MAD × 4 = 0) admits nothing. `still` goes false
    // for the whole night and the cardiac wake branch fires unopposed.
    test('a still night scores the same however sparsely it was banked', () {
      final dense = _sleepOf(_stillNight(rowEverySec: 1));

      expect(dense.disturbances, 0,
          reason: 'nobody woke up on this night — the dense read must agree');

      for (final every in [30, 60, 90, 120, 180]) {
        final sparse = _sleepOf(_stillNight(rowEverySec: every));
        expect(sparse.disturbances, dense.disturbances,
            reason: 'row/${every}s manufactured awakenings the dense night does '
                'not have — the motion channel is leaking sampling rate into '
                'sleep staging');
        expect(sparse.awake, dense.awake,
            reason: 'row/${every}s disagrees with dense on WASO');
        // The window is bounded by the FIRST and LAST banked row, so thinning the
        // rows shortens it by up to one banking interval at each end — a sampling
        // boundary effect, not staging. The tolerance tracks that interval; the
        // equivalence that actually pins the defect (disturbances / WASO /
        // efficiency, above) is asserted EXACTLY and needs no tolerance at all.
        expect((sparse.asleep - dense.asleep).inSeconds.abs(),
            lessThanOrEqualTo(2 * every + _e),
            reason: 'row/${every}s disagrees with dense on asleep total by more '
                'than the banking interval can account for');
        expect(sparse.efficiency, closeTo(dense.efficiency, 0.01),
            reason: 'row/${every}s disagrees with dense on efficiency');
      }
    });

    test('a REAL awakening is still called on a sparsely-banked night', () {
      // The fix must not buy quiet by going blind: a genuine awakening — the
      // wrist plainly moving AND HR up — still has to register. Otherwise
      // "no phantom disturbances" would just mean "no disturbances at all".
      final samples = <RawSample>[];
      for (var i = -3600; i < 8 * 3600; i += 60) {
        final inNight = i >= 0;
        final awake = i >= 4 * 3600 && i < 4 * 3600 + 15 * 60; // 15 min, real
        samples.add(RawSample(
          ts: _t0 + i,
          hr: !inNight ? 52 : (awake ? 78 : 50 + ((i * 31) % 3)),
          spo2: 0,
          rrCount: 1,
          rr1: awake ? 770 : 1150,
          rr2: 0,
          rr3: 0,
          movement: awake ? 1.0 + 0.30 * ((i ~/ 60) % 3) : 1.0 + 0.001 * ((i * 7919) % 13),
          sleepState: inNight ? 1 : 0,
        ));
      }
      final s = _sleepOf(
          RawDay(DateTime.fromMillisecondsSinceEpoch((_t0 - 3600) * 1000), samples));
      expect(s.disturbances, greaterThan(0),
          reason: 'a real awakening (wrist moving + HR up) must still be called');
      expect(s.awake.inMinutes, greaterThanOrEqualTo(5),
          reason: 'the real awakening should land in WASO, not be waved through');
    });
  });

  group('epoch movement channel contract', () {
    test('a missing sample is neither quiescent nor an excursion', () {
      // The dead-band idiom: absence of data corroborates nothing either way. It
      // is not stillness (we did not observe a still wrist) and not motion.
      final mv = <double?>[0.0, 0.0, null, 0.0, 5.0, null, 0.0, 0.0, 0.0, 0.0];
      final quiet = SleepStager.motionQuiescent(mv);
      final moved = SleepStager.motionExcursion(mv);
      for (final i in [2, 5]) {
        expect(quiet[i], isFalse, reason: 'a null epoch must not read as still');
        expect(moved[i], isFalse, reason: 'a null epoch must not read as moved');
      }
      expect(quiet[0], isTrue, reason: 'a real still epoch must still read still');
    });

    test('dropouts do not move the scale the real epochs are judged by', () {
      // The invariant the sentinel broke. Inserting UNKNOWN epochs must not
      // change any verdict about the epochs that ARE known — whatever the
      // dropout rate. With the 5.0 sentinel this failed the moment dropouts
      // passed ~half the window (the median jumped to the sentinel).
      final real = <double?>[for (var i = 0; i < 40; i++) 0.001 * (i % 5)];
      final baseline = SleepStager.motionQuiescent(real);

      // Same 40 real epochs, now 75% buried in dropouts.
      final padded = <double?>[];
      final realIdx = <int>[];
      for (final m in real) {
        realIdx.add(padded.length);
        padded.add(m);
        padded.addAll(<double?>[null, null, null]);
      }
      final withGaps = SleepStager.motionQuiescent(padded);
      for (var i = 0; i < real.length; i++) {
        expect(withGaps[realIdx[i]], baseline[i],
            reason: 'dropouts changed the verdict for real epoch $i — the '
                'night-relative scale is being polluted by missing data');
      }
    });

    test('an all-null window degrades to no verdicts, not to false ones', () {
      final mv = <double?>[null, null, null, null];
      expect(SleepStager.motionQuiescent(mv), everyElement(isFalse));
      expect(SleepStager.motionExcursion(mv), everyElement(isFalse));
    });
  });

  group('sparse-motion low confidence (#345)', () {
    test('coverage below half the window is sparse', () {
      // 40 epochs, 16 sampled (0.4) — under the 0.5 span fraction.
      final mv = <double?>[for (var i = 0; i < 40; i++) i % 5 < 2 ? 0.01 : null];
      expect(SleepStager.motionSparseOver(mv), isTrue);
      // 40 epochs, 24 sampled (0.6), no long run of holes → dense.
      final ok = <double?>[for (var i = 0; i < 40; i++) i % 5 < 3 ? 0.01 : null];
      expect(SleepStager.motionSparseOver(ok), isFalse);
    });

    test('a clumped night with a >20min hole is sparse despite good coverage', () {
      // Upstream tests the LARGEST gap, not the median, precisely for this: a
      // 4.0 offload banks motion in clumps, so overall coverage looks fine while
      // a run-breaking hole hides inside. 200 epochs, only 50 missing (75%
      // coverage) — but they are consecutive, 25 min > the 20 min bridge.
      final mv = <double?>[
        for (var i = 0; i < 200; i++) (i >= 100 && i < 150) ? null : 0.01,
      ];
      expect(mv.whereType<double>().length / mv.length, greaterThan(0.5));
      expect(SleepStager.motionSparseOver(mv), isTrue);
    });

    test('a hole inside the 20min bridge tolerance is not sparse', () {
      // 20 min exactly = _maxGapEpochs (40 epochs) — the line the stager already
      // draws between "got up for a moment" and "the night ended". Sparsity must
      // agree with it rather than draw a second, different line.
      final mv = <double?>[
        for (var i = 0; i < 200; i++) (i >= 100 && i < 140) ? null : 0.01,
      ];
      expect(SleepStager.motionSparseOver(mv), isFalse);
    });

    test('a densely banked night is not flagged, a holed one is', () {
      expect(_sleepOf(_stillNight(rowEverySec: 1)).motionSparse, isFalse,
          reason: 'a per-second night has full motion coverage');
      // rowEverySec 90 > the 30 s epoch, so ~2 of every 3 epochs bank nothing:
      // coverage ~0.33, under the 0.5 fraction.
      expect(_sleepOf(_stillNight(rowEverySec: 90)).motionSparse, isTrue,
          reason: 'a night staged on ~1/3 motion coverage cannot earn a '
              'confident Rest — flag it rather than fake stages');
    });

    test('the flag is confidence-only — it never moves a score', () {
      // #345 downgrades belief, never the number. The sparse night above must
      // still report the SAME sleep as the dense one (the equivalence test);
      // this pins that the flag itself changes nothing about the totals.
      final dense = _sleepOf(_stillNight(rowEverySec: 1));
      final sparse = _sleepOf(_stillNight(rowEverySec: 90));
      expect(sparse.motionSparse, isTrue);
      expect(sparse.disturbances, dense.disturbances);
      expect(sparse.efficiency, closeTo(dense.efficiency, 0.01));
    });
  });
}
