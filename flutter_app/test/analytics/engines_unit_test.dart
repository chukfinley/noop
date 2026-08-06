import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/baselines.dart';
import 'package:noop/core/analytics/hrv_analyzer.dart';
import 'package:noop/core/analytics/recovery_scorer.dart';
import 'package:noop/core/analytics/strain_scorer.dart';

/// Regression guards for the ported NOOP analytics. These pin the Kotlin
/// algorithms to fixed, hand-computed numbers so any accidental change to a
/// formula/constant fails here BEFORE the real-data pipeline or the app.
void main() {
  group('HrvAnalyzer (Task Force RMSSD/SDNN)', () {
    // 21 clean RR intervals (300..2000 ms, no ectopics). Expected values
    // computed independently: rmssd=13.1339, sdnn=8.5843, meanNN=803.0952.
    const rr = <double>[
      800, 820, 810, 790, 805, 815, 800, 795, 810, 800, 790, //
      805, 800, 815, 795, 800, 810, 790, 800, 805, 810
    ];

    test('rmssd/sdnn/meanNN match reference', () {
      final r = HrvAnalyzer.analyzeRaw(rr);
      expect(r.nInput, 21);
      expect(r.nClean, 21); // nothing rejected
      expect(r.rmssd!, closeTo(13.1339, 1e-3));
      expect(r.sdnn!, closeTo(8.5843, 1e-3));
      expect(r.meanNN!, closeTo(803.0952, 1e-3));
    });

    test('range filter drops out-of-band beats', () {
      final clean = HrvAnalyzer.cleanRR([100, 800, 810, 5000, 805]);
      expect(clean, [800, 810, 805]); // 100 and 5000 removed
    });

    test('too few beats → empty result', () {
      final r = HrvAnalyzer.analyzeRaw([800, 810, 790]);
      expect(r.rmssd, isNull);
      expect(r.nClean, 0);
    });

    test('gap-aware cleaning flags a break across every dropped beat (#204)', () {
      // 100 and 5000 are out of range and dropped; each leaves a "break" before
      // the next surviving beat, so a successive difference can't span the gap.
      final c = HrvAnalyzer.cleanRRWithBreaks([100, 800, 810, 5000, 805]);
      expect(c.nn, [800, 810, 805]);
      expect(c.brokenBefore, [true, false, true]);
    });

    test('a dropped beat cannot inflate RMSSD (#204)', () {
      // A perfectly steady 800 ms series (RMSSD 0) with one out-of-range spike
      // wedged in. Naively bridging the gap would count 800→800 = 0 here, but
      // the guarantee we pin is: cleaning removes the spike AND the surviving
      // series stays RMSSD 0 — the spike never leaks into the measure.
      final steady = List<double>.filled(24, 800.0);
      final withSpike = [...steady.sublist(0, 12), 5000.0, ...steady.sublist(12)];
      final r = HrvAnalyzer.analyzeRaw(withSpike);
      expect(r.nClean, 24); // the spike was dropped
      expect(r.rmssd, closeTo(0.0, 1e-9)); // and contributed nothing
    });
  });

  group('StrainScorer (Edwards TRIMP → Effort 0..100)', () {
    test('tanaka HRmax', () {
      expect(StrainScorer.tanakaHRmax(30), closeTo(187.0, 1e-9));
    });

    test('flat 75%HRR for 10 min → Effort 38.66', () {
      // age30 → HRmax 187, RHR 60 → HRR 127. bpm at 75%HRR = 155.25.
      const bpm0 = 60 + 0.75 * 127; // 155.25
      final ts = List<int>.generate(600, (i) => i);
      final bpm = List<double>.filled(600, bpm0.toDouble());
      final e = StrainScorer.strain(
        tsSec: ts,
        bpm: bpm,
        maxHR: 187,
        restingHR: 60,
      );
      // TRIMP = zoneWeight(3) * 600 samples * (1/60 min) = 30 → 38.66.
      expect(e!, closeTo(38.66, 1e-2));
    });

    test('below-threshold sample count → null (not enough data)', () {
      final e = StrainScorer.strain(
        tsSec: [0, 1, 2],
        bpm: [120, 120, 120],
        maxHR: 187,
        restingHR: 60,
      );
      expect(e, isNull);
    });

    test('per-sample durations: each covers gap to next, clamped, last reused '
        '(#950)', () {
      // ts gaps: 30s→0.5min · 60s→1.0min · 0s(coincident)→fallback ·
      // 8910s→148.5min clamped to maxSampleGapMin (2.0); the final reading has
      // no successor so it reuses the gap before it (2.0).
      final d = StrainScorer.sampleDurationsMinutes([0, 30, 90, 90, 9000]);
      expect(d.length, 5);
      expect(d[0], closeTo(0.5, 1e-9));
      expect(d[1], closeTo(1.0, 1e-9));
      expect(d[2], closeTo(StrainScorer.fallbackSampleMin, 1e-9));
      expect(d[3], closeTo(StrainScorer.maxSampleGapMin, 1e-9));
      expect(d[4], closeTo(StrainScorer.maxSampleGapMin, 1e-9));
    });

    test('uniform spacing → every duration identical, TRIMP unchanged (#950 '
        'identity)', () {
      // The whole point of #950: on a uniformly spaced stream the per-sample
      // durations collapse to the old single value, so Effort does not move.
      final ts = List<int>.generate(600, (i) => i);
      final d = StrainScorer.sampleDurationsMinutes(ts);
      expect(d.length, 600);
      for (final x in d) {
        expect(x, closeTo(StrainScorer.fallbackSampleMin, 1e-12));
      }
    });

    test('a dropout gap cannot invent hours of Effort (#950 clamp)', () {
      // A 25-sample burst at 180 bpm (94%HRR → Edwards zone 5) taken 1 s apart,
      // then a single multi-hour dropout. Crediting the last pre-gap reading with
      // the whole hole would explode TRIMP; the 2-min clamp bounds it.
      final ts = [
        for (var i = 0; i < 25; i++) i, // 1 Hz burst
        10000, // ~2.7 h dropout after the burst
      ];
      final bpm = List<double>.filled(ts.length, 180);
      final e = StrainScorer.strain(
        tsSec: ts,
        bpm: bpm,
        maxHR: 187,
        restingHR: 60,
      )!;
      // Durations: 24×(1/60) + 2.0 (clamped gap) + 2.0 (reused) = 4.4 min.
      // TRIMP = zone5(=5) × 4.4 = 22.0 → 100·ln(23)/ln(7201).
      final expected = 100.0 *
          math.log(22.0 + 1.0) /
          math.log(StrainScorer.strainDenominator);
      expect(e, closeTo(expected, 1e-2));
    });
  });

  group('RecoveryScorer', () {
    test('resting HR = sustained floor', () {
      final ts = List<int>.generate(600, (i) => i);
      final bpm = List<double>.filled(600, 50);
      expect(RecoveryScorer.restingHR(ts, bpm, 0, 600), 50);
    });

    test('z=0 (on baseline) → 57.93% (population anchor)', () {
      final r = RecoveryScorer.recovery(
        hrv: 100,
        rhr: 50,
        hrvBaseline: const DriverBaseline(100, 8),
        rhrBaseline: const DriverBaseline(50, 3),
      );
      expect(r!, closeTo(57.9324, 1e-3));
    });

    test('cold-start (HRV baseline unusable) → null', () {
      final r = RecoveryScorer.recovery(
        hrv: 100,
        rhr: 50,
        hrvBaseline: const DriverBaseline(100, 8),
        hrvBaselineUsable: false,
      );
      expect(r, isNull);
    });

    test('band thresholds', () {
      expect(RecoveryScorer.band(20), 'red');
      expect(RecoveryScorer.band(50), 'yellow');
      expect(RecoveryScorer.band(80), 'green');
    });
  });

  group('Baselines (EWMA centre + spread)', () {
    test('folds a constant → baseline converges, status progresses', () {
      final s = BaselineState();
      for (var i = 0; i < 3; i++) {
        Baselines.update(s, 'hrv', 60);
      }
      expect(s.status, BaselineStatus.calibrating);
      expect(s.usable, isFalse);
      for (var i = 0; i < 12; i++) {
        Baselines.update(s, 'hrv', 60);
      }
      expect(s.baseline, closeTo(60, 1e-6));
      expect(s.status, BaselineStatus.trusted);
      expect(s.usable, isTrue);
      // On baseline → z ≈ 0.
      expect(Baselines.zScore(60, s).abs(), lessThan(1e-6));
    });
  });
}
