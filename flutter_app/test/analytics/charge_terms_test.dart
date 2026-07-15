import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/baselines.dart';
import 'package:noop/core/analytics/charge_terms.dart';
import 'package:noop/core/analytics/recovery_scorer.dart';
import 'package:noop/core/analytics/strain_scorer.dart';

/// Tests for the Recovery Index + Activity Balance Charge terms (#417 / #436).
///
/// Per the repo's derived-signal validation rule, the slope is exercised with MULTIPLE distinct
/// injected slopes (not one lucky example), each recovered within tolerance and strictly ordered.
void main() {
  /// A synthetic night: [hours] long at 1 Hz from [start], HR starting at [startBpm] and moving by
  /// [slopeBpmPerHr] per hour.
  ({List<int> ts, List<double> bpm}) night({
    int start = 0,
    double hours = 6.0,
    double startBpm = 60,
    double slopeBpmPerHr = 0,
  }) {
    final ts = <int>[];
    final bpm = <double>[];
    final n = (hours * 3600).round();
    for (var i = 0; i < n; i++) {
      ts.add(start + i);
      bpm.add(startBpm + slopeBpmPerHr * (i / 3600.0));
    }
    return (ts: ts, bpm: bpm);
  }

  group('recoveryIndexSlope', () {
    test('null with no samples in the window', () {
      expect(ChargeTerms.recoveryIndexSlope(const [], const [], 0, 3600), isNull);
      final n = night();
      // Window entirely outside the data.
      expect(ChargeTerms.recoveryIndexSlope(n.ts, n.bpm, 100000, 200000), isNull);
    });

    test('null below recoveryIndexMinBins of coverage — never a slope from a sliver', () {
      // 5 bins = 25 min < the 6-bin (30 min) floor.
      final n = night(hours: 25 / 60.0, slopeBpmPerHr: -4);
      expect(ChargeTerms.recoveryIndexSlope(n.ts, n.bpm, 0, (25 * 60)), isNull);

      // 6 bins exactly → a number.
      final six = night(hours: 30 / 60.0, slopeBpmPerHr: -4);
      expect(ChargeTerms.recoveryIndexSlope(six.ts, six.bpm, 0, 30 * 60), isNotNull);
    });

    test('recovers MULTIPLE distinct injected slopes, each within 0.3 bpm/hr', () {
      for (final injected in [0.0, -1.0, -4.0, 2.0, 5.5]) {
        final n = night(hours: 6, startBpm: 70, slopeBpmPerHr: injected);
        final got = ChargeTerms.recoveryIndexSlope(n.ts, n.bpm, 0, 6 * 3600);
        expect(got, isNotNull, reason: 'slope $injected should be resolvable');
        expect(got!, closeTo(injected, 0.3), reason: 'injected $injected');
      }
    });

    test('recovered slopes are strictly ordered (steeper decline → more negative)', () {
      double slopeFor(double injected) {
        final n = night(hours: 6, startBpm: 70, slopeBpmPerHr: injected);
        return ChargeTerms.recoveryIndexSlope(n.ts, n.bpm, 0, 6 * 3600)!;
      }

      final steep = slopeFor(-4);
      final mild = slopeFor(-1);
      final flat = slopeFor(0);
      final rising = slopeFor(2);
      expect(steep, lessThan(mild));
      expect(mild, lessThan(flat));
      expect(flat, lessThan(rising));
    });

    test('sign convention: declining HR is NEGATIVE, rising is POSITIVE', () {
      final declining = night(hours: 6, startBpm: 75, slopeBpmPerHr: -3);
      expect(ChargeTerms.recoveryIndexSlope(declining.ts, declining.bpm, 0, 6 * 3600)!,
          lessThan(0));
      final rising = night(hours: 6, startBpm: 55, slopeBpmPerHr: 3);
      expect(ChargeTerms.recoveryIndexSlope(rising.ts, rising.bpm, 0, 6 * 3600)!,
          greaterThan(0));
    });

    test('a flat night → ~0 slope, finite, never NaN', () {
      // Note: the `den <= 1e-9` degenerate-fit guard in recoveryIndexSlope is defensive only and is
      // unreachable in practice (mirrored from upstream) — clearing the 6-bin floor requires 6
      // distinct bin midpoints, which always gives a non-zero time spread. A flat night is the
      // closest reachable case: a well-defined fit whose slope is legitimately ~0.
      final n = night(hours: 6, startBpm: 60, slopeBpmPerHr: 0);
      final got = ChargeTerms.recoveryIndexSlope(n.ts, n.bpm, 0, 6 * 3600)!;
      expect(got.isNaN, isFalse);
      expect(got, closeTo(0.0, 1e-6));
    });

    test('uses the SAME 5-minute binning restingHR uses', () {
      // Both read the identical underlying series — one as a floor, one as a trend across it.
      expect(RecoveryScorer.restingHRWindowS, 300);
      final n = night(hours: 6, startBpm: 70, slopeBpmPerHr: -6);
      // 6 h of data with a -6 bpm/hr decline: floor should be near the END value (70-36=34)...
      expect(RecoveryScorer.restingHR(n.ts, n.bpm, 0, 6 * 3600), closeTo(34, 1));
      // ...and the slope should recover the decline.
      expect(ChargeTerms.recoveryIndexSlope(n.ts, n.bpm, 0, 6 * 3600)!, closeTo(-6.0, 0.3));
    });

    test('is deterministic — same input, same output', () {
      final n = night(hours: 6, slopeBpmPerHr: -2.5);
      final a = ChargeTerms.recoveryIndexSlope(n.ts, n.bpm, 0, 6 * 3600);
      final b = ChargeTerms.recoveryIndexSlope(n.ts, n.bpm, 0, 6 * 3600);
      expect(a, b);
    });
  });

  group('recoveryIndexTerm', () {
    test('null slope → null term (drops, weights renormalize)', () {
      expect(ChargeTerms.recoveryIndexTerm(null), isNull);
    });

    test('declining slope → POSITIVE z (supports recovery)', () {
      final t = ChargeTerms.recoveryIndexTerm(-4.0)!;
      expect(t.$1, closeTo(2.0, 1e-9)); // -(-4)/2.0
      expect(t.$2, ChargeTerms.wRecoveryIndex);
    });

    test('rising slope → NEGATIVE z (limits recovery)', () {
      expect(ChargeTerms.recoveryIndexTerm(3.0)!.$1, closeTo(-1.5, 1e-9));
    });

    test('flat slope → neutral z', () {
      expect(ChargeTerms.recoveryIndexTerm(0.0)!.$1, 0.0);
    });

    test('the documented scale: recoveryIndexScaleBpmPerHr bpm/hr ≈ 1 z-unit', () {
      expect(ChargeTerms.recoveryIndexTerm(-ChargeTerms.recoveryIndexScaleBpmPerHr)!.$1,
          closeTo(1.0, 1e-9));
    });

    test('weights match upstream', () {
      expect(ChargeTerms.wRecoveryIndex, 0.05);
      expect(ChargeTerms.recoveryIndexScaleBpmPerHr, 2.0);
      expect(ChargeTerms.recoveryIndexMinBins, 6);
      // Same small, additive weight precedent as the existing skin-temp term.
      expect(ChargeTerms.wRecoveryIndex, RecoveryScorer.wSkinTemp);
    });
  });

  group('activityBalanceTerm', () {
    const baseline = DriverBaseline(50.0, 5.0); // mean Effort 50, spread 5

    test('both-or-neither: needs the value AND the baseline', () {
      expect(ChargeTerms.activityBalanceTerm(null, baseline), isNull);
      expect(ChargeTerms.activityBalanceTerm(60.0, null), isNull);
      expect(ChargeTerms.activityBalanceTerm(null, null), isNull);
      expect(ChargeTerms.activityBalanceTerm(60.0, baseline), isNotNull);
    });

    test('lower-is-better: a rest day supports recovery, a hard day limits it', () {
      final restDay = ChargeTerms.activityBalanceTerm(20.0, baseline)!.$1;
      final atBaseline = ChargeTerms.activityBalanceTerm(50.0, baseline)!.$1;
      final hardDay = ChargeTerms.activityBalanceTerm(90.0, baseline)!.$1;
      expect(restDay, greaterThan(0));
      expect(atBaseline, closeTo(0.0, 1e-9));
      expect(hardDay, lessThan(0));
    });

    test('monotonic across the range: rest → easy → baseline → hard → very hard', () {
      final zs = [10.0, 30.0, 50.0, 70.0, 95.0]
          .map((e) => ChargeTerms.activityBalanceTerm(e, baseline)!.$1)
          .toList();
      for (var i = 1; i < zs.length; i++) {
        expect(zs[i], lessThan(zs[i - 1]), reason: 'harder day must not raise the term');
      }
    });

    test('direction mirrors the RHR term exactly', () {
      // RHR is also "lower vs baseline is better" → z of (μ − x).
      const b = DriverBaseline(50.0, 5.0);
      expect(
        ChargeTerms.activityBalanceTerm(70.0, b)!.$1,
        closeTo(RecoveryScorer.zScore(b.mean, 70.0, b.spread), 1e-12),
      );
    });

    test('weight matches upstream', () {
      expect(ChargeTerms.wActivityBalance, 0.05);
      expect(ChargeTerms.activityBalanceTerm(60.0, baseline)!.$2, 0.05);
    });
  });

  group('strainCfg (the "strain" Baselines entry, #436)', () {
    test('bounds match the 0–100 Effort scale', () {
      expect(strainCfg.minVal, 0);
      expect(strainCfg.maxVal, 100);
      // Bounds track the Effort scale's 0–100 output, per #436.
      expect(strainCfg.maxVal, StrainScorer.maxStrain);
    });

    test('floorSpread is wider than the physiological metrics (training swings hard)', () {
      expect(strainCfg.floorSpread, 5.0);
      expect(strainCfg.floorSpread, greaterThan(Baselines.configs['resting_hr']!.floorSpread));
      expect(strainCfg.floorSpread, greaterThan(Baselines.configs['resp']!.floorSpread));
    });

    test('NOT yet registered in Baselines.configs — wiring is owned elsewhere', () {
      // Documents the current, deliberate state (see charge_terms.dart header). When the owner of
      // baselines.dart registers it, flip this to expect the entry to be present.
      expect(Baselines.configs.containsKey(strainMetricKey), isFalse);
    });

    test('an Effort baseline built with strainCfg scores rest/hard days with the right signs', () {
      final s = BaselineState();
      // 20 nights of ~50 Effort → a settled baseline around 50.
      for (var i = 0; i < 20; i++) {
        Baselines.update(s, strainMetricKey, 50.0);
      }
      expect(s.baseline, closeTo(50.0, 1.0));
      expect(s.usable, isTrue);

      final b = DriverBaseline.of(s);
      expect(ChargeTerms.activityBalanceTerm(15.0, b)!.$1, greaterThan(0)); // rest day
      expect(ChargeTerms.activityBalanceTerm(85.0, b)!.$1, lessThan(0)); // hard day
    });
  });

  group('foldInto — the transitional wiring seam', () {
    test('no new terms → the score is returned UNCHANGED (default path is a no-op)', () {
      expect(ChargeTerms.foldInto(baseScore: 58.0, baseWeight: 0.90), 58.0);
      expect(
        ChargeTerms.foldInto(
          baseScore: 58.0,
          baseWeight: 0.90,
          recoveryIndexSlopeValue: null,
          priorDayEffort: null,
          effortBaseline: null,
        ),
        58.0,
      );
    });

    test('a null base score (cold start) stays null', () {
      expect(
        ChargeTerms.foldInto(baseScore: null, baseWeight: 0.90, recoveryIndexSlopeValue: -4),
        isNull,
      );
    });

    test('a steeper overnight decline raises Charge; a rising HR lowers it', () {
      const base = 58.0;
      const w = 0.90;
      final declining = ChargeTerms.foldInto(
          baseScore: base, baseWeight: w, recoveryIndexSlopeValue: -4)!;
      final flat =
          ChargeTerms.foldInto(baseScore: base, baseWeight: w, recoveryIndexSlopeValue: 0)!;
      final rising =
          ChargeTerms.foldInto(baseScore: base, baseWeight: w, recoveryIndexSlopeValue: 3)!;
      expect(declining, greaterThan(flat));
      expect(flat, greaterThan(rising));
    });

    test('a hard previous day lowers Charge; a rest day raises it', () {
      const base = 58.0;
      const w = 0.90;
      const b = DriverBaseline(50.0, 5.0);
      final rest =
          ChargeTerms.foldInto(baseScore: base, baseWeight: w, priorDayEffort: 15, effortBaseline: b)!;
      final atBase =
          ChargeTerms.foldInto(baseScore: base, baseWeight: w, priorDayEffort: 50, effortBaseline: b)!;
      final hard =
          ChargeTerms.foldInto(baseScore: base, baseWeight: w, priorDayEffort: 90, effortBaseline: b)!;
      expect(rest, greaterThan(atBase));
      expect(hard, lessThan(atBase));
    });

    test('an at-baseline prior day only DILUTES (z=0 pulls the composite toward 0)', () {
      // The term is present with z=0, so the composite z shrinks toward 0 → score moves toward the
      // logistic's z=0 anchor rather than staying put.
      const b = DriverBaseline(50.0, 5.0);
      final green = ChargeTerms.foldInto(
          baseScore: 90.0, baseWeight: 0.90, priorDayEffort: 50, effortBaseline: b)!;
      expect(green, lessThan(90.0)); // pulled down toward the middle
      final red = ChargeTerms.foldInto(
          baseScore: 10.0, baseWeight: 0.90, priorDayEffort: 50, effortBaseline: b)!;
      expect(red, greaterThan(10.0)); // pulled up toward the middle
    });

    test('is algebraically equivalent to folding the terms into recovery() directly', () {
      // Build a Charge the normal way, then fold a slope in; compare against recomputing the whole
      // composite by hand with the extra term. This is the property that lets the owner of
      // recovery_scorer.dart move these terms inline without changing any number.
      const hrvB = DriverBaseline(60.0, 6.0);
      const rhrB = DriverBaseline(55.0, 3.0);
      final base = RecoveryScorer.recovery(
        hrv: 70,
        rhr: 52,
        hrvBaseline: hrvB,
        rhrBaseline: rhrB,
        sleepPerf: 0.9,
      )!;
      // recovery() used: HRV (0.55) + RHR (0.20) + sleep (0.15) = 0.90 total weight.
      const baseWeight = RecoveryScorer.wHRV + RecoveryScorer.wRHR + RecoveryScorer.wSleep;

      const slope = -4.0;
      final folded =
          ChargeTerms.foldInto(baseScore: base, baseWeight: baseWeight, recoveryIndexSlopeValue: slope)!;

      // Hand-compute the same composite with the Recovery-Index term included.
      final terms = <(double, double)>[
        (RecoveryScorer.zScore(70, hrvB.mean, hrvB.spread), RecoveryScorer.wHRV),
        (RecoveryScorer.zScore(rhrB.mean, 52, rhrB.spread), RecoveryScorer.wRHR),
        ((0.9 - RecoveryScorer.sleepPerfCenter) / RecoveryScorer.sleepPerfScale,
            RecoveryScorer.wSleep),
        ChargeTerms.recoveryIndexTerm(slope)!,
      ];
      var ws = 0.0, tw = 0.0;
      for (final t in terms) {
        ws += t.$1 * t.$2;
        tw += t.$2;
      }
      final z = ws / tw;
      final expected = 100.0 /
          (1.0 + math.exp(-RecoveryScorer.logisticK * (z - RecoveryScorer.logisticZ0)));
      expect(folded, closeTo(expected, 1e-9));
    });

    test('both terms together fold in additively', () {
      const b = DriverBaseline(50.0, 5.0);
      final both = ChargeTerms.foldInto(
        baseScore: 58.0,
        baseWeight: 0.90,
        recoveryIndexSlopeValue: -4,
        priorDayEffort: 15,
        effortBaseline: b,
      )!;
      final onlySlope =
          ChargeTerms.foldInto(baseScore: 58.0, baseWeight: 0.90, recoveryIndexSlopeValue: -4)!;
      // Both good signals should beat one good signal alone.
      expect(both, greaterThan(onlySlope));
      expect(both, inInclusiveRange(0.0, 100.0));
    });

    test('saturated / invalid base scores pass through rather than producing NaN', () {
      expect(ChargeTerms.foldInto(baseScore: 0.0, baseWeight: 0.9, recoveryIndexSlopeValue: -4), 0.0);
      expect(
          ChargeTerms.foldInto(baseScore: 100.0, baseWeight: 0.9, recoveryIndexSlopeValue: -4), 100.0);
      expect(ChargeTerms.foldInto(baseScore: 58.0, baseWeight: 0.0, recoveryIndexSlopeValue: -4), 58.0);
    });

    test('output is always a valid Charge in [0, 100]', () {
      const b = DriverBaseline(50.0, 5.0);
      for (final slope in [-50.0, -4.0, 0.0, 4.0, 50.0]) {
        for (final effort in [0.0, 50.0, 100.0]) {
          final v = ChargeTerms.foldInto(
            baseScore: 58.0,
            baseWeight: 0.90,
            recoveryIndexSlopeValue: slope,
            priorDayEffort: effort,
            effortBaseline: b,
          )!;
          expect(v, inInclusiveRange(0.0, 100.0));
          expect(v.isNaN, isFalse);
        }
      }
    });
  });
}
