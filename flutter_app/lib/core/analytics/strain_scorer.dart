import 'dart:math' as math;

/// StrainScorer — cardiovascular load (NOOP "Effort") on a 0–100 logarithmic scale.
///
/// Faithful Dart port of StrainScorer.kt. INDEPENDENT implementation of published
/// exercise-physiology methods (WHOOP-*like*, not a reproduction of the proprietary
/// algorithm; not medical advice).
///
/// Pipeline:
///   1. Heart-Rate Reserve (Karvonen): HRR = HRmax − RHR.
///   2. Per-sample intensity as %HRR = (HR − RHR) / HRR × 100, clamped 0..100.
///   3. TRIMP accumulated over the window:
///        a. Edwards 5-zone summation (default).
///        b. Banister exponential.
///   4. Logarithmic compression onto [0, 100]:
///        effort = 100 × ln(TRIMP + 1) / ln(D),  D = strainDenominator.
///
/// References: Karvonen 1957 (%HRR); Edwards 1993 (5-zone TRIMP); Banister 1991
/// (exponential TRIMP, b = 1.92 men / 1.67 women); Tanaka 2001 (HRmax = 208 − 0.7×age).
///
/// The Kotlin operates on the Room `HrSample` (ts:Long unix seconds, bpm:Int); this
/// Dart port takes PARALLEL arrays (`tsSec`, `bpm`) instead.

/// TRIMP accumulation method.
enum StrainMethod { edwards, banister }

class StrainScorer {
  StrainScorer._();

  // ---- Constants (strain.py) ----

  /// Minimum HR readings before computing strain on a DENSE stream (≈10 min at 1 Hz).
  static const int minReadings = 600;

  /// Sparse-stream acceptance (#482/#480): accept once the HR series SPANS at least
  /// [minSpanSeconds] of wall-clock with a small sample floor.
  static const int minSparseReadings = 20;

  /// Wall-clock coverage (seconds) qualifying a sparse stream. 600 s = 10 min.
  static const int minSpanSeconds = 600;

  /// Top of the Effort scale (was 21.0 — rescaled to 0–100 for "Effort").
  static const double maxStrain = 100.0;

  /// Logarithmic-map denominator D. D = 7200 + 1 = 7201 makes ln(7201)/ln(7201) = 1.
  static const double strainDenominator = 7201.0;

  static double get lnStrainDenominator => math.log(strainDenominator);

  /// Fallback per-sample duration (minutes) — 1 s at 1 Hz.
  static const double fallbackSampleMin = 1.0 / 60.0;

  static const int defaultAge = 30;
  static const double defaultRestingHR = 60.0;

  /// Minimum HR samples before the observed high-percentile HRmax is trusted.
  static const int hrmaxMinSamples = 600;

  /// Upper percentile for the observed-HRmax estimate.
  static const double hrmaxPercentile = 99.5;

  /// Banister coefficients.
  static const double banisterScale = 0.64;
  static const double banisterBMen = 1.92;
  static const double banisterBWomen = 1.67;

  /// Edwards zone cut-offs as (%HRR threshold, weight), highest-first.
  static const List<(double, int)> edwardsZones = [
    (90.0, 5),
    (80.0, 4),
    (70.0, 3),
    (60.0, 2),
    (50.0, 1),
  ];

  // ---- HRmax helpers ----

  /// Tanaka (2001): HRmax = 208 − 0.7 × age (gender-independent).
  static double tanakaHRmax(double age) => 208.0 - 0.7 * age;

  /// Classic 220 − age. Last-resort fallback only.
  static int defaultMaxHR([int age = defaultAge]) => 220 - age;

  /// Linear-interpolated percentile of an already-sorted sequence (numpy-style).
  static double percentile(List<double> sortedValues, double pct) {
    final n = sortedValues.length;
    if (n == 0) return 0.0;
    if (n == 1) return sortedValues[0];
    final position = (pct / 100.0) * (n - 1).toDouble();
    final lower = position.toInt();
    final upper = math.min(lower + 1, n - 1);
    final frac = position - lower.toDouble();
    return sortedValues[lower] +
        frac * (sortedValues[upper] - sortedValues[lower]);
  }

  /// Estimate a personalized HRmax from a trailing HR series.
  /// Returns (hrmax bpm, source) where source ∈ {"observed", "tanaka", "unknown"}.
  static (double, String) estimateHRmax(List<double> hrHistory, double? age) {
    final n = hrHistory.length;
    final tanaka = age == null ? null : tanakaHRmax(age);

    if (n >= hrmaxMinSamples) {
      final sorted = List<double>.from(hrHistory)..sort();
      final observed = percentile(sorted, hrmaxPercentile);
      if (tanaka == null) return (observed, 'observed');
      return observed >= tanaka ? (observed, 'observed') : (tanaka, 'tanaka');
    }
    if (tanaka != null) return (tanaka, 'tanaka');
    return (0.0, 'unknown');
  }

  // ---- Karvonen %HRR and Edwards zone weight ----

  /// Karvonen %HRR, clamped [0, 100].
  static double pctHRR(double bpm, double restingHR, double hrReserve) {
    final pct = (bpm - restingHR) / hrReserve * 100.0;
    if (pct < 0) return 0.0;
    if (pct > 100) return 100.0;
    return pct;
  }

  /// Edwards 5-zone weight (0–5) from %HRR (unclamped).
  static int zoneWeight(double bpm, double restingHR, double hrReserve) {
    final pct = (bpm - restingHR) / hrReserve * 100.0;
    for (final (threshold, weight) in edwardsZones) {
      if (pct >= threshold) return weight;
    }
    return 0;
  }

  // ---- TRIMP accumulation ----

  /// Infer per-sample duration (minutes) from the first two timestamps. Falls
  /// back to 1 s when fewer than two samples or coincident timestamps.
  static double sampleDurationMinutes(List<int> tsSec) {
    if (tsSec.length < 2) return fallbackSampleMin;
    final deltaS = (tsSec[1] - tsSec[0]).toDouble().abs();
    return deltaS > 0 ? deltaS / 60.0 : fallbackSampleMin;
  }

  static double edwardsTRIMP(
    List<double> bpm,
    double restingHR,
    double hrReserve,
    double sampleDurationMin,
  ) {
    var weighted = 0;
    for (final b in bpm) {
      weighted += zoneWeight(b, restingHR, hrReserve);
    }
    return weighted.toDouble() * sampleDurationMin;
  }

  static double banisterTRIMP(
    List<double> bpm,
    double restingHR,
    double hrReserve,
    double sampleDurationMin,
    double b,
  ) {
    var acc = 0.0;
    for (final s in bpm) {
      final x = pctHRR(s, restingHR, hrReserve) / 100.0;
      if (x > 0) acc += sampleDurationMin * x * banisterScale * math.exp(b * x);
    }
    return acc;
  }

  // ---- Logarithmic map ----

  /// Map accumulated TRIMP onto [0, 100] via 100 × ln(TRIMP+1) / ln(D), 2 dp.
  /// TRIMP ≤ 0 → 0.
  static double trimpToStrain(
    double trimp, [
    double denominator = strainDenominator,
  ]) {
    if (trimp <= 0) return 0.0;
    final value = maxStrain * math.log(trimp + 1.0) / math.log(denominator);
    return (value * 100).round() / 100.0;
  }

  // ---- Public API ----

  /// Cardiovascular Effort (0–100) from an HR series. APPROXIMATE.
  ///
  /// [tsSec] & [bpm] are parallel, time-ordered arrays. Returns null when there
  /// isn't yet enough data to trust the number — fewer than [minReadings] samples
  /// AND less than [minSpanSeconds] of HR coverage (the sparse-strap path, #482) —
  /// or when maxHR ≤ restingHR (invalid HRR).
  static double? strain({
    required List<int> tsSec,
    required List<double> bpm,
    double? maxHR,
    double restingHR = defaultRestingHR,
    StrainMethod method = StrainMethod.edwards,
    String sex = 'male',
    double denominator = strainDenominator,
  }) {
    final effMax = maxHR ?? defaultMaxHR().toDouble();
    // Enough data to trust the score: a dense stream (≥ minReadings) OR a
    // sparse-but-sustained one spanning ≥ minSpanSeconds with a sample floor.
    final bool enoughData;
    if (bpm.length >= minReadings) {
      enoughData = true;
    } else if (bpm.length >= minSparseReadings) {
      final maxTs = tsSec.isEmpty ? 0 : tsSec.reduce(math.max);
      final minTs = tsSec.isEmpty ? 0 : tsSec.reduce(math.min);
      enoughData = (maxTs - minTs) >= minSpanSeconds;
    } else {
      enoughData = false;
    }
    if (!enoughData || effMax <= restingHR) return null;

    final sampleDur = sampleDurationMinutes(tsSec);
    final hrReserve = effMax - restingHR;

    final double trimp;
    switch (method) {
      case StrainMethod.banister:
        final b = sex.toLowerCase().startsWith('f')
            ? banisterBWomen
            : banisterBMen;
        trimp = banisterTRIMP(bpm, restingHR, hrReserve, sampleDur, b);
      case StrainMethod.edwards:
        trimp = edwardsTRIMP(bpm, restingHR, hrReserve, sampleDur);
    }
    return trimpToStrain(trimp, denominator);
  }
}
