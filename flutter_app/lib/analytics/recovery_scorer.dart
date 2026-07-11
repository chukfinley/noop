import 'dart:math' as math;

import 'baselines.dart';

/// RecoveryScorer — resting HR during sleep + a transparent 0–100 recovery score
/// (NOOP "Charge").
///
/// Faithful Dart port of RecoveryScorer.kt.
///
/// recovery() is a z-score + logistic composite. It is APPROXIMATE — not
/// WHOOP-identical (WHOOP's model is proprietary). It is a transparent,
/// HRV-dominant, baseline-normalized proxy.
///
/// Weighting:
///   higher HRV vs baseline        → higher recovery  (W_HRV   = 0.55, dominant)
///   lower resting HR vs baseline   → higher recovery  (W_RHR   = 0.20)
///   lower resp vs baseline         → higher recovery  (W_RESP  = 0.05)
///   higher sleep performance       → higher recovery  (W_SLEEP = 0.15)
///   skin temp NEAR baseline        → higher recovery  (W_SKIN_TEMP = 0.05)
///
/// The Kotlin operates on the Room `HrSample` (ts:Long unix seconds, bpm:Int);
/// this Dart port takes PARALLEL arrays (`tsSec`, `bpm`) for HR instead.
/// `start` / `end` are wall-clock unix SECONDS.

/// A baseline driver: mean + spread (internal abs-dev units, as in [BaselineState]).
/// Mirrors Kotlin `RecoveryScorer.DriverBaseline`.
class DriverBaseline {
  final double mean, spread;
  const DriverBaseline(this.mean, this.spread);
  factory DriverBaseline.of(BaselineState s) =>
      DriverBaseline(s.baseline, s.spread);
}

class RecoveryScorer {
  RecoveryScorer._();

  // ---- Constants (recovery.py) ----

  static const double wHRV = 0.55;
  static const double wRHR = 0.20;
  static const double wResp = 0.05;
  static const double wSleep = 0.15;

  /// Skin-temperature deviation weight (symmetric illness/overreach penalty).
  static const double wSkinTemp = 0.05;

  /// Skin-temp deviation scale (°C per z-unit). The term is −|skinTempDevC| / scale.
  static const double skinTempDevScale = 1.0;

  /// Logistic spread: ±2 z-units ≈ full Red–Green band (15%–95%).
  static const double logisticK = 1.6;

  /// Logistic offset so Z=0 → 58%.
  static const double logisticZ0 = -0.20;

  /// WHOOP-published population-average recovery (%). Cold-start fallback.
  static const double populationMean = 58.0;

  /// Recovery band thresholds (WHOOP color scheme).
  static const double bandRedMax = 34.0;
  static const double bandYellowMax = 67.0;

  /// Sleep-performance center ("good night" at ~85% efficiency).
  static const double sleepPerfCenter = 0.85;

  /// Sleep-performance scale (±2 z spans the normal range).
  static const double sleepPerfScale = 0.12;

  /// Rolling-mean HR window (seconds) for the resting-HR estimate.
  static const int restingHRWindowS = 5 * 60;

  /// Minimum HR samples a 5-min bin must hold before its mean is eligible to WIN
  /// the resting floor (#686).
  static const int restingHRMinBinSamples = 5;

  /// Minimum in-window HR samples before the quartile blend is trusted (else median).
  static const int robustRestingHRMinSamples = 30;

  /// Physiological resting-HR floor (bpm) below which a bin mean is rejected as a
  /// dropout artifact (#686), never the resting floor.
  static const double restingHRMinPlausibleBpm = 25.0;

  // ---- Resting HR ----

  /// Lowest sustained HR during the in-bed window (bpm, rounded), or null.
  ///
  /// "Sustained" = the minimum of 5-minute non-overlapping bin means of the HR
  /// samples whose ts ∈ [start, end]. [tsSec] & [bpm] are parallel, time-ordered.
  /// Returns null when there are no HR samples in window.
  ///
  /// Artifact hardening (#686): a bin may only WIN the floor when it is BOTH
  /// well-populated (≥ [restingHRMinBinSamples]) AND physiologically plausible
  /// (mean ≥ [restingHRMinPlausibleBpm]). If no bin qualifies, fall back to the
  /// lowest of ALL bin means, else the all-sample mean.
  static int? restingHR(List<int> tsSec, List<double> bpm, int start, int end) {
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

    final means = <double>[]; // every bin mean (legacy floor, the fallback)
    final qualified = <double>[]; // bins eligible to WIN the floor (#686)
    var t = start;
    while (t < end) {
      final binEnd = t + restingHRWindowS;
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
        final mean = sum / count.toDouble();
        means.add(mean);
        if (count >= restingHRMinBinSamples &&
            mean >= restingHRMinPlausibleBpm) {
          qualified.add(mean);
        }
      }
      t += restingHRWindowS;
    }
    final double floor;
    if (qualified.isNotEmpty) {
      floor = qualified.reduce(math.min);
    } else if (means.isNotEmpty) {
      floor = means.reduce(math.min);
    } else {
      var sum = 0.0;
      for (final b in segBpm) {
        sum += b;
      }
      floor = sum / segBpm.length.toDouble();
    }
    return floor.round();
  }

  /// Robust resting-HR estimate: the mean of the 25th percentile and the median of
  /// in-window sleep HR (bpm). Filters out HR ≤ 30 (garbage). Falls back to the
  /// plain median below [robustRestingHRMinSamples] samples, then null.
  static int? restingHRRobust(
    List<int> tsSec,
    List<double> bpm,
    int start,
    int end,
  ) {
    final vals = <double>[];
    for (var i = 0; i < tsSec.length; i++) {
      final ts = tsSec[i];
      if (ts >= start && ts <= end && bpm[i] > 30) {
        vals.add(bpm[i]);
      }
    }
    if (vals.isEmpty) return null;
    vals.sort();
    final median = _percentileSorted(vals, 50.0);
    if (vals.length < robustRestingHRMinSamples) return median.round();
    final p25 = _percentileSorted(vals, 25.0);
    return ((p25 + median) / 2.0).round();
  }

  /// numpy-style linear-interpolated percentile over an already-sorted, non-empty list.
  static double _percentileSorted(List<double> sorted, double pct) {
    final n = sorted.length;
    if (n == 1) return sorted[0];
    final pos = (pct / 100.0) * (n - 1).toDouble();
    final lo = pos.toInt();
    final hi = math.min(lo + 1, n - 1);
    final frac = pos - lo;
    return sorted[lo] + (sorted[hi] - sorted[lo]) * frac;
  }

  // ---- Recovery band ----

  /// WHOOP-style color band for a recovery score [0, 100].
  static String band(double score) {
    if (score < bandRedMax) return 'red';
    if (score < bandYellowMax) return 'yellow';
    return 'green';
  }

  // ---- Recovery score ----

  /// Robust z-score using EWMA spread: (value − mean) / (1.253 × spread).
  static double zScore(double value, double mean, double spread) {
    final sigma = math.max(1.253 * spread, 1e-9);
    return (value - mean) / sigma;
  }

  /// Z-score + logistic recovery score in [0, 100]. APPROXIMATE.
  ///
  /// Returns null when the HRV baseline (dominant driver) is not yet usable, or
  /// no valid driver is available at all.
  ///
  /// RHR & resp are "lower is better" → z of (mean − value). Skin temp is a
  /// SYMMETRIC penalty −|dev| / scale. Sleep is centered at [sleepPerfCenter].
  static double? recovery({
    required double hrv,
    required double rhr,
    double? resp,
    DriverBaseline? hrvBaseline,
    DriverBaseline? rhrBaseline,
    DriverBaseline? respBaseline,
    double? sleepPerf,
    double? skinTempDev,
    bool hrvBaselineUsable = true,
  }) {
    // Cold-start gate: HRV is the dominant driver; if its baseline isn't usable,
    // refuse to score (more honest than a fabricated value).
    if (!hrvBaselineUsable) return null;

    final terms = <(double, double)>[]; // (z, weight)

    // HRV term: higher is better.
    if (hrvBaseline != null) {
      terms.add((zScore(hrv, hrvBaseline.mean, hrvBaseline.spread), wHRV));
    }
    // RHR term: lower is better → (μ − x) / σ.
    if (rhrBaseline != null) {
      terms.add((zScore(rhrBaseline.mean, rhr, rhrBaseline.spread), wRHR));
    }
    // Resp term: lower is better, optional.
    if (resp != null && respBaseline != null) {
      terms.add((zScore(respBaseline.mean, resp, respBaseline.spread), wResp));
    }
    // Sleep-performance term: no baseline needed; centered at sleepPerfCenter.
    if (sleepPerf != null) {
      terms.add(((sleepPerf - sleepPerfCenter) / sleepPerfScale, wSleep));
    }
    // Skin-temp term: SYMMETRIC penalty, no baseline arg.
    if (skinTempDev != null) {
      terms.add((-skinTempDev.abs() / skinTempDevScale, wSkinTemp));
    }

    if (terms.isEmpty) return null;
    var totalWeight = 0.0;
    for (final t in terms) {
      totalWeight += t.$2;
    }
    if (totalWeight <= 0.0) return null;

    var weightedSum = 0.0;
    for (final t in terms) {
      weightedSum += t.$1 * t.$2;
    }
    final z = weightedSum / totalWeight;
    final score = 100.0 / (1.0 + math.exp(-logisticK * (z - logisticZ0)));
    return math.max(0.0, math.min(100.0, score));
  }
}
