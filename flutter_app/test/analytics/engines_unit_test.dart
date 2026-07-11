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
