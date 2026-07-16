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
/// STATUS: WIRED, DEFAULT-OFF. Read this before turning it on.
/// ---------------------------------------------------------------------------
/// Verified against the real upstream v9.0.0 source (`RecoveryScorer.kt` /
/// `RecoveryScorer.swift`), not just its release notes:
///
///   * Upstream folds both terms into `recovery(...)` as optional, NULL-DEFAULT parameters
///     (`recoveryIndexSlope`, `effortBaseline`, `priorDayEffort`), and registers a `"strain"`
///     `MetricCfg` in `Baselines`. The `"strain"` entry IS landed upstream — this port now carries
///     it too (see [Baselines.configs] / [strainCfg]).
///   * Upstream ships NO production caller that supplies any of the three: a grep over both
///     platforms finds only the internal `recovery(...)` overload forwarding them, plus tests.
///     Upstream's own header says "dormant until a caller supplies them", and upstream's test
///     header states the central pinned claim outright: *"Both terms are DORMANT (null-default);
///     the central claim pinned here is that every existing caller's score is byte-identical to
///     before they existed."*
///
/// So "dormant" is upstream's INTENT, not an unfinished port. This port keeps that intent while
/// making the code reachable: [DailyPipeline] supplies all three from real data, gated on
/// `DailyPipeline.experimentalChargeTerms`, which DEFAULTS TO FALSE. Off, Charge is byte-identical
/// to before this file existed — the same guarantee upstream pins. Nothing in the shipping app
/// turns it on: `NoopEngine` does not pass the flag, so only tests do. That mirrors upstream
/// exactly, where only tests pass the parameters.
///
/// BEFORE TURNING IT ON — a real, unresolved defect in the upstream design, not in this port:
/// [recoveryIndexTerm] is NOT CENTERED. Its neutral point is a slope of 0 (a flat overnight HR),
/// but a flat overnight HR is not typical — a healthy night's resting HR DECLINES, so a normal
/// night scores ≈ +1 z on this term rather than ≈ 0. Unlike `sleepPerf` (centered on a "good night"
/// at [RecoveryScorer.sleepPerfCenter] = 0.85) and `skinTempDev` (centered on 0 deviation, which IS
/// typical), this term's fixed scale has no centering constant, so it acts mostly as a CONSTANT
/// UPWARD SHIFT of Charge rather than as a discriminator between good and bad nights. Charge is
/// calibrated so z = 0 → 58% ([RecoveryScorer.populationMean]); an uncentered term breaks that
/// anchor.
///
/// Measured on an otherwise exactly-average night (composite z = 0 → the 57.93 anchor, baseWeight
/// 0.95): a physiologically TYPICAL −2 bpm/h decline scores z = +1.0 on this term and lifts Charge
/// to 59.87 (+1.94), while the whole spread between that typical night and a poor −0.5 bpm/h night
/// is just 1.45 points. The constant offset is LARGER than the term's entire discriminative range —
/// i.e. it mostly re-anchors the flagship metric upward and only incidentally tells good nights
/// from bad. Fixing it needs either a centering constant (a number nobody has measured — inventing
/// one here would be a fabrication) or a personal EWMA baseline for the slope, i.e. a
/// `'recovery_index'` entry in [Baselines.configs] fed by a real nightly slope history. Until one
/// of those exists AND the marginal impact is validated on real nights, the flag stays off.
library;

import 'dart:math' as math;

import 'package:noop/core/analytics/baselines.dart';
import 'package:noop/core/analytics/recovery_scorer.dart';

/// The baseline config for daily Effort/strain — upstream's `"strain"` `MetricCfg` (#436).
///
/// A convenience ACCESSOR onto the registry entry, mirroring upstream's
/// `val strainCfg: MetricCfg get() = metricCfg.getValue("strain")`. It is deliberately not a
/// second copy of the numbers: [Baselines.configs] is the single source of truth, so the config
/// [Baselines.update] folds with and the config this term z-scores against cannot drift apart.
/// See [Baselines.configs] for why the bounds and the wide `floorSpread` are what they are.
MetricConfig get strainCfg => Baselines.configs[strainMetricKey]!;

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
