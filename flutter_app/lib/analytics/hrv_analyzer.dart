import 'dart:math' as math;

/// HrvAnalyzer — RMSSD + SDNN from RR intervals with cleaning.
///
/// Faithful Dart port of the Kotlin `HrvAnalyzer`
/// (`com.noop.analytics.HrvAnalyzer`), itself a port of
/// StrandAnalytics/HRVAnalyzer.swift. The Task Force (1996) RMSSD and SDNN
/// definitions are reproduced exactly:
///
///   RMSSD = sqrt( mean( (NN[i+1] − NN[i])^2 ) )           (Task Force 1996)
///   SDNN  = sample standard deviation of NN (ddof = 1)     (Task Force 1996)
///
/// Cleaning pipeline:
///   1. Range filter: drop intervals outside [rrMinMs, rrMaxMs] = [300, 2000] ms.
///   2. Ectopic rejection: drop beats whose RR deviates > ~20% from a local
///      median (Malik-style filter).
///   3. Require >= minBeats (20) valid intervals before a trustworthy result.
///
/// This Dart port covers the raw-value analysis surface (the RrInterval-based
/// windowed/rolling methods live in the data layer and are not ported here).

/// Result of an HRV computation over a window. Mirrors Kotlin `HrvResult`.
class HrvResult {
  /// RMSSD in milliseconds, or null when too few valid beats.
  final double? rmssd;

  /// SDNN (sample SD, ddof=1) in milliseconds, or null when too few valid beats.
  final double? sdnn;

  /// Mean NN interval (ms) over the cleaned beats, or null.
  final double? meanNN;

  /// pNN50: % of successive |ΔNN| > 50 ms, or null.
  final double? pnn50;

  /// Count of RR intervals supplied to the analysis (before cleaning).
  final int nInput;

  /// Count of clean NN intervals after range + ectopic filtering.
  final int nClean;

  const HrvResult({
    this.rmssd,
    this.sdnn,
    this.meanNN,
    this.pnn50,
    required this.nInput,
    required this.nClean,
  });

  /// An empty/insufficient-data result that preserves the input count.
  factory HrvResult.empty(int nInput) => HrvResult(nInput: nInput, nClean: 0);
}

/// Pure-Dart RMSSD/SDNN analyzer with a Malik/range cleaning pipeline.
class HrvAnalyzer {
  HrvAnalyzer._();

  /// Minimum plausible RR interval (ms) — 300 ms ≈ 200 bpm.
  static const double rrMinMs = 300.0;

  /// Maximum plausible RR interval (ms) — 2000 ms ≈ 30 bpm.
  static const double rrMaxMs = 2000.0;

  /// Minimum valid intervals required for a trustworthy RMSSD/SDNN.
  static const int minBeats = 20;

  /// Malik-style ectopic threshold: a beat deviating more than this fraction
  /// from the local median is rejected. 0.20 == 20%.
  static const double ectopicThreshold = 0.20;

  /// Half-width (in beats) of the local-median window used for ectopic
  /// rejection. A window of 2*radius+1 beats (5 beats at radius 2) matches the
  /// common Malik moving-window implementations.
  static const int ectopicWindowRadius = 2;

  /// Default ceiling on the fraction of input beats the cleaning pipeline may
  /// reject before a SPOT reading is refused as too noisy. 0.35 == refuse once
  /// more than 35% of beats were dropped as out-of-range or ectopic, even if
  /// [minBeats] clean intervals survive — a quiet honesty gate on a short live
  /// capture.
  static const double defaultSpotMaxRejectedFraction = 0.35;

  // ── Primitive Task Force statistics (no filtering) ─────────────────────────

  /// Task Force (1996) RMSSD over already-clean NN intervals (ms). Returns null
  /// when fewer than 2 values (no successive differences).
  ///
  /// [maxSuccessiveDiffMs] is an optional, additive artifact guard: successive
  /// differences whose magnitude exceeds it are dropped before squaring. With
  /// the default `null` no diff is dropped and the result is byte-identical to
  /// the unfiltered formula (denominator nn.length−1).
  static double? rmssdRaw(List<double> nn, {double? maxSuccessiveDiffMs}) {
    if (nn.length < 2) return null;
    var sumSq = 0.0;
    var n = 0;
    for (var i = 1; i < nn.length; i++) {
      final d = nn[i] - nn[i - 1];
      if (maxSuccessiveDiffMs != null && d.abs() > maxSuccessiveDiffMs)
        continue;
      sumSq += d * d;
      n++;
    }
    if (n < 1) return null;
    return math.sqrt(sumSq / n.toDouble());
  }

  /// Sample standard deviation (ddof = 1) of NN intervals (ms). Returns null for
  /// fewer than 2 values. Matches neurokit2 HRV_SDNN. No filtering applied.
  static double? sdnnRaw(List<double> nn) {
    if (nn.length < 2) return null;
    final mean = _sum(nn) / nn.length.toDouble();
    var ss = 0.0;
    for (final v in nn) {
      final d = v - mean;
      ss += d * d;
    }
    return math.sqrt(ss / (nn.length - 1).toDouble());
  }

  // ── Cleaning ───────────────────────────────────────────────────────────────

  /// Range filter: keep only intervals in [rrMinMs, rrMaxMs], preserving order.
  static List<double> rangeFilter(List<double> rr) =>
      rr.where((it) => it >= rrMinMs && it <= rrMaxMs).toList();

  /// Malik-style ectopic rejection: drop any beat that deviates from its local
  /// median by more than [ectopicThreshold] (20%). The local median is taken
  /// over a centered window of `2*ectopicWindowRadius+1` beats (excluding the
  /// beat under test). Beats with too small a neighbourhood are kept.
  static List<double> rejectEctopic(List<double> nn) {
    if (nn.length <= ectopicWindowRadius) return nn;
    final kept = <double>[];
    for (var i = 0; i < nn.length; i++) {
      final lo = math.max(0, i - ectopicWindowRadius);
      final hi = math.min(nn.length - 1, i + ectopicWindowRadius);
      final neighbours = <double>[];
      for (var j = lo; j <= hi; j++) {
        if (j != i) neighbours.add(nn[j]);
      }
      if (neighbours.length < 2) {
        kept.add(nn[i]);
        continue;
      }
      final med = median(neighbours);
      if (med <= 0) {
        kept.add(nn[i]);
        continue;
      }
      final deviation = (nn[i] - med).abs() / med;
      if (deviation <= ectopicThreshold) {
        kept.add(nn[i]);
      }
      // else: drop this beat as ectopic.
    }
    return kept;
  }

  /// Full clean: range filter → ectopic rejection. Returns the clean NN series.
  static List<double> cleanRR(List<double> rr) =>
      rejectEctopic(rangeFilter(rr));

  // ── Raw analysis ─────────────────────────────────────────────────────────

  /// Compute HRV from raw RR-interval values (ms), applying the full cleaning
  /// pipeline. Returns an empty result when fewer than [minBeats] survive.
  ///
  /// [maxRejectedFraction] is a SPOT-ONLY honesty gate. When non-null, the
  /// reading is ALSO refused (empty result) if the fraction of input beats
  /// dropped by cleaning exceeds this value — even when [minBeats] clean
  /// intervals survive — because a short live capture that threw away most of
  /// its beats is too noisy to trust. null (the default) skips the gate.
  static HrvResult analyzeRaw(
    List<double> rawRR, {
    double? maxRejectedFraction,
  }) {
    final nInput = rawRR.length;
    final clean = cleanRR(rawRR);
    if (clean.length < minBeats) {
      return HrvResult.empty(nInput);
    }
    // Spot-only: refuse when too large a fraction of beats was noise
    // (out-of-range or ectopic). Only applied when a ceiling is supplied;
    // nInput > 0 holds implicitly (clean.length ≥ minBeats > 0).
    if (maxRejectedFraction != null && nInput > 0) {
      final rejectedFraction =
          1.0 - clean.length.toDouble() / nInput.toDouble();
      if (rejectedFraction > maxRejectedFraction) {
        return HrvResult.empty(nInput);
      }
    }
    final rmssd = rmssdRaw(clean);
    final sdnn = sdnnRaw(clean);
    final mean = _sum(clean) / clean.length.toDouble();

    // pNN50 over the clean NN series.
    var nn50 = 0;
    for (var i = 1; i < clean.length; i++) {
      if ((clean[i] - clean[i - 1]).abs() > 50.0) nn50 += 1;
    }
    final pnn50 = nn50.toDouble() / (clean.length - 1).toDouble() * 100.0;

    return HrvResult(
      rmssd: rmssd,
      sdnn: sdnn,
      meanNN: mean,
      pnn50: pnn50,
      nInput: nInput,
      nClean: clean.length,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Median of a non-empty list. (Caller guarantees non-empty.) Returns 0.0 for
  /// an empty input, matching the Swift `n == 0 → 0` guard.
  static double median(List<double> values) {
    final s = List<double>.from(values)..sort();
    final n = s.length;
    if (n == 0) return 0.0;
    return n % 2 == 1 ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2.0;
  }

  static double _sum(List<double> values) {
    var total = 0.0;
    for (final v in values) {
      total += v;
    }
    return total;
  }
}
