/// ChargeTerms — the Recovery Index + Activity Balance terms for Charge (#417 / #436).
///
/// Dart port of the two OPTIONAL Oura-Readiness-style terms `RecoveryScorer.kt` (#436, the Kotlin
/// twin of `StrandAnalytics/RecoveryScorer.swift` #417) adds to Charge:
///
///   overnight resting-HR DECLINE slope ("Recovery Index")   → [wRecoveryIndex]   = 0.05
///   previous-day Effort vs personal baseline
///   ("Activity Balance" / "Previous Day Activity")          → [wActivityBalance] = 0.05
///
/// WHY: an Oura-reference validation found Charge (the HRV/RHR-led recovery score in
/// `recovery_scorer.dart`) already tracks Oura's Readiness well (r≈0.71), covering HRV Balance, RHR,
/// Body Temp and Previous-Night Sleep. Two of Readiness's eight contributors were still missing, and
/// both are pure ALGORITHM gaps over data this app already stores — no new capture needed:
///   1. Recovery Index — how fast resting HR *declines* through the night (a slope). The app stores
///      the full in-bed HR series but `RecoveryScorer` only ever read the overnight FLOOR (the min of
///      5-minute bin means, via `restingHR`), never the trend that reaches it.
///   2. Activity Balance — Charge had no input from yesterday's training load at all.
///
/// NAMING (this port): upstream's "Charge" is the RECOVERY score and upstream's "Effort" is the
/// STRAIN score. This Dart port uses the same two names — see `recovery_scorer.dart` ("NOOP
/// \"Charge\"") and `strain_scorer.dart` ("NOOP \"Effort\""), and the `dailyMetrics.charge` /
/// `dailyMetrics.effort` columns. So these terms belong to RECOVERY, not to `StrainScorer`.
///
/// ---------------------------------------------------------------------------
/// STATUS: DORMANT + NOT YET WIRED. Read this before using.
/// ---------------------------------------------------------------------------
/// Upstream folds both terms directly into `RecoveryScorer.recovery(...)` as new optional,
/// null-default parameters, and adds a `"strain"` MetricCfg to `Baselines`. That renormalizing
/// `terms` loop lives INSIDE `recovery(...)`, so a term cannot be added to it from another file.
///
/// This file therefore carries everything that IS portable standalone — the slope function, both
/// term transforms, the weights, and the strain baseline config — fully tested and ready to wire,
/// while `recovery_scorer.dart` and `baselines.dart` are owned elsewhere. The remaining wiring is
/// mechanical and additive; see the file-level report / [foldInto] for the exact shape.
///
/// Upstream is itself dormant here ("no caller on either platform supplies the new signals") and
/// notes that switching these terms on for live Charge is a scoring change to the flagship metric,
/// so it needs a default-off/experimental toggle or validated marginal impact. Nothing in this file
/// changes any existing score: it is additive, and every entry point is opt-in.
library;

import 'dart:math' as math;

import 'package:noop/core/analytics/baselines.dart';
import 'package:noop/core/analytics/recovery_scorer.dart';

/// A baseline config for daily Effort/strain — upstream's `"strain"` `MetricCfg` (#436).
///
/// Bounds match [StrainScorer.maxStrain]'s 0–100 output scale (the Charge/Effort/Rest redesign's
/// rescale of the historical 0–21 axis). `floorSpread` is deliberately WIDER than the physiological
/// metrics (5.0, vs ~1–2% of range elsewhere) because day-to-day training load is EXPECTED to swing
/// hard — a rest day vs a hard day is a normal, large delta — and a tight floor would make the
/// z-score hypersensitive to routine training variation.
///
/// NOT YET REGISTERED: upstream adds this under the key [strainMetricKey] in `Baselines.metricCfg`.
/// `baselines.dart` is owned elsewhere, so this constant stands ready but is not in
/// `Baselines.configs` yet. Every `Baselines.configs` consumer is a lookup-by-key (no enumerators),
/// so adding the entry is inert for existing metrics.
const MetricConfig strainCfg = MetricConfig(0, 100, 5);

/// The `Baselines.configs` key the [strainCfg] entry should be registered under.
const String strainMetricKey = 'strain';

/// The two Charge terms from #417 / #436. Pure, deterministic, side-effect-free: all timestamps are
/// passed in, nothing reads a clock.
class ChargeTerms {
  ChargeTerms._();

  // ---- Recovery Index ----

  /// Recovery-Index weight (overnight resting-HR DECLINE slope — Oura's "Recovery Index"
  /// contributor). Small and additive like [RecoveryScorer.wSkinTemp]: folds in only when a slope is
  /// supplied. Mirrors Kotlin `RecoveryScorer.wRecoveryIndex`.
  static const double wRecoveryIndex = 0.05;

  /// Recovery-Index slope scale (bpm/hour): a slope this many bpm/hour steeper than flat (0)
  /// costs/earns ≈ 1 z-unit before weighting. Resting HR falling through the night is the
  /// physiologically expected, good pattern; flat or rising (illness, alcohol, a late stimulant,
  /// restlessness) is not. The SIGN carries the meaning (negative = declining = good), unlike
  /// skin-temp's symmetric |deviation| penalty. Mirrors Kotlin
  /// `RecoveryScorer.recoveryIndexScaleBpmPerHr`.
  static const double recoveryIndexScaleBpmPerHr = 2.0;

  /// Minimum 5-minute bins ([RecoveryScorer.restingHRWindowS]'s SAME binning) required before a slope
  /// is trusted — below this, too little of the night has elapsed to fit a trend, and a 1–2-point
  /// regression is noise, not a night-long pattern. 6 bins = 30 minutes of binned coverage, a
  /// deliberately low floor so a short/partial night still gets a number rather than a routine null.
  /// Mirrors Kotlin `RecoveryScorer.recoveryIndexMinBins`.
  static const int recoveryIndexMinBins = 6;

  /// Overnight resting-HR DECLINE slope (bpm/hour) across the in-bed window — the "Recovery Index"
  /// component of Oura's Readiness that Charge lacked (it previously only read the overnight FLOOR
  /// via [RecoveryScorer.restingHR], never the trend that reaches it).
  ///
  /// Computed as the least-squares slope of the SAME non-overlapping 5-minute HR bin means
  /// [RecoveryScorer.restingHR] uses ([RecoveryScorer.restingHRWindowS]) against each bin's midpoint
  /// time (hours from [start]). NEGATIVE = declining (HR falling through the night — the expected,
  /// good pattern); POSITIVE = rising (restlessness, illness, alcohol, a late stimulant).
  ///
  /// Returns null when fewer than [recoveryIndexMinBins] bins have data (too little of the window to
  /// fit a trend) or there are no samples at all — it never fabricates a slope from a sliver of the
  /// night. Returns 0.0 on a degenerate fit (all bins at the same instant: no time spread).
  ///
  /// [tsSec] & [bpm] are parallel, time-ordered arrays (this port's convention — the Kotlin takes
  /// `List<HrSample>`). [start] / [end] are wall-clock unix SECONDS.
  static double? recoveryIndexSlope(
    List<int> tsSec,
    List<double> bpm,
    int start,
    int end,
  ) {
    // Segment: samples whose ts ∈ [start, end], keeping ts/bpm paired.
    final segTs = <int>[];
    final segBpm = <double>[];
    for (var i = 0; i < tsSec.length; i++) {
      final ts = tsSec[i];
      if (ts >= start && ts <= end) {
        segTs.add(ts);
        segBpm.add(bpm[i]);
      }
    }
    if (segTs.isEmpty) return null;

    // Same non-overlapping 5-minute binning as restingHR: both read the identical underlying
    // series, one as a floor, one as a trend across it.
    final tHours = <double>[];
    final meanBpm = <double>[];
    var t = start;
    while (t < end) {
      final binEnd = t + RecoveryScorer.restingHRWindowS;
      var sum = 0.0;
      var count = 0;
      for (var i = 0; i < segTs.length; i++) {
        final ts = segTs[i];
        if (ts >= t && ts < binEnd) {
          sum += segBpm[i];
          count++;
        }
      }
      if (count > 0) {
        final midpointS =
            (t - start).toDouble() + RecoveryScorer.restingHRWindowS / 2.0;
        tHours.add(midpointS / 3600.0);
        meanBpm.add(sum / count.toDouble());
      }
      t += RecoveryScorer.restingHRWindowS;
    }
    if (tHours.length < recoveryIndexMinBins) return null;

    // Least-squares slope: Σ((t−t̄)(y−ȳ)) / Σ((t−t̄)²), bpm per hour.
    final n = tHours.length.toDouble();
    var tSum = 0.0, ySum = 0.0;
    for (var i = 0; i < tHours.length; i++) {
      tSum += tHours[i];
      ySum += meanBpm[i];
    }
    final tBar = tSum / n;
    final yBar = ySum / n;
    var num = 0.0, den = 0.0;
    for (var i = 0; i < tHours.length; i++) {
      final dt = tHours[i] - tBar;
      num += dt * (meanBpm[i] - yBar);
      den += dt * dt;
    }
    // Degenerate (all bins at the same instant): no time spread to fit against.
    if (den <= 1e-9) return 0.0;
    return num / den;
  }

  /// The Recovery-Index term's contribution as a (z, weight) pair, ready to append to the
  /// `terms` list in [RecoveryScorer.recovery].
  ///
  /// No baseline needed — a fixed, documented scale, the same style as the existing
  /// `sleepPerf`/`skinTempDev` terms. Negative slope (declining HR) → positive z (supports recovery);
  /// positive slope (rising HR) → negative z (limits it). Returns null when [slope] is null, which is
  /// how the term DROPS and the remaining weights renormalize — leaving the score byte-identical to
  /// before the term existed.
  static (double, double)? recoveryIndexTerm(double? slope) {
    if (slope == null) return null;
    return (-slope / recoveryIndexScaleBpmPerHr, wRecoveryIndex);
  }

  // ---- Activity Balance / previous-day Effort ----

  /// Activity-Balance / previous-day-Effort weight (collapses Oura's "Previous Day Activity" and
  /// "Activity Balance" readiness contributors into one term). Small and additive like
  /// [RecoveryScorer.wSkinTemp]: folds in only when BOTH a previous-day Effort value and its personal
  /// EWMA baseline ([strainCfg]) are supplied. Mirrors Kotlin `RecoveryScorer.wActivityBalance`.
  static const double wActivityBalance = 0.05;

  /// The Activity-Balance term's contribution as a (z, weight) pair, ready to append to the `terms`
  /// list in [RecoveryScorer.recovery].
  ///
  /// [priorDayEffort] is yesterday's Effort/strain (0–100, from `StrainScorer.strain`). LOWER vs
  /// [effortBaseline] supports recovery — the same "lower is better" direction as the RHR/resp terms,
  /// so the z is of (μ − x). A harder-than-normal day yesterday pulls Charge down; a lighter one
  /// supports it.
  ///
  /// Needs BOTH the value and a baseline, matching the existing resp pattern: returns null (term
  /// drops, weights renormalize) when either is null.
  static (double, double)? activityBalanceTerm(
    double? priorDayEffort,
    DriverBaseline? effortBaseline,
  ) {
    if (priorDayEffort == null || effortBaseline == null) return null;
    return (
      RecoveryScorer.zScore(
        effortBaseline.mean,
        priorDayEffort,
        effortBaseline.spread,
      ),
      wActivityBalance,
    );
  }

  // ---- Composition helper (the wiring seam) ----

  /// Re-score a Charge value that [RecoveryScorer.recovery] already produced, with the two new terms
  /// folded in — WITHOUT modifying `recovery_scorer.dart`.
  ///
  /// This is a TRANSITIONAL seam, not the end state. Upstream folds both terms into the `terms` list
  /// inside `recovery(...)` itself; when the owner of `recovery_scorer.dart` adds the three optional
  /// null-default parameters (`recoveryIndexSlope`, `effortBaseline`, `priorDayEffort`), this helper
  /// should be deleted and [recoveryIndexTerm] / [activityBalanceTerm] called directly from that
  /// `terms` loop.
  ///
  /// It works by inverting the logistic back to the composite z, re-weighting that z together with
  /// the new terms, and re-squashing — algebraically identical to having folded the terms in
  /// upstream, PROVIDED [baseWeight] is the total weight of the terms that produced [baseScore].
  /// That value is only known to the caller, which is exactly why this is a stopgap: inside
  /// `recovery(...)` it is simply `totalWeight`.
  ///
  /// Returns [baseScore] unchanged when neither new term is present, so the default path is a no-op.
  /// Returns null when [baseScore] is null (cold-start: `recovery` refused to score).
  static double? foldInto({
    required double? baseScore,
    required double baseWeight,
    double? recoveryIndexSlopeValue,
    double? priorDayEffort,
    DriverBaseline? effortBaseline,
  }) {
    if (baseScore == null) return null;
    final extra = <(double, double)>[
      ?recoveryIndexTerm(recoveryIndexSlopeValue),
      ?activityBalanceTerm(priorDayEffort, effortBaseline),
    ];
    if (extra.isEmpty) return baseScore;
    if (baseWeight <= 0.0) return baseScore;

    // Invert the logistic: score = 100 / (1 + exp(-k(z - z0))) → z.
    // Guard the ends: a saturated score carries no recoverable z.
    if (baseScore <= 0.0 || baseScore >= 100.0) return baseScore;
    final baseZ = RecoveryScorer.logisticZ0 +
        math.log(baseScore / (100.0 - baseScore)) / RecoveryScorer.logisticK;

    var weightedSum = baseZ * baseWeight;
    var totalWeight = baseWeight;
    for (final t in extra) {
      weightedSum += t.$1 * t.$2;
      totalWeight += t.$2;
    }
    final z = weightedSum / totalWeight;
    final score = 100.0 /
        (1.0 + math.exp(-RecoveryScorer.logisticK * (z - RecoveryScorer.logisticZ0)));
    return math.max(0.0, math.min(100.0, score));
  }
}
