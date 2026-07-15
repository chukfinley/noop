/// WorkoutTypeClassifier — COARSE workout-type classifier over ALREADY-CAPTURED signals.
///
/// Faithful Dart port of `WorkoutTypeClassifier.kt` (#439), itself the Kotlin twin of
/// `StrandAnalytics/WorkoutTypeClassifier.swift` (#414) — same constants, same ramp/plateau
/// memberships, same per-class weights and confidence chain, so the same [WorkoutClassFeatures]
/// vector scores identically on all three platforms.
///
/// Given a detected workout window, this predicts a BROAD activity class — walk / run / strength /
/// cycle / ski / other — plus a confidence, from four signal families this app already decodes and
/// stores, with no raw IMU:
///   1. HR profile over the window (mean/peak/%HRR, HR variability shape) — `hrSample`.
///   2. Activity-class tick composition — `stepSample.activityClass` (0 still / 1 walk / 2 run,
///      community finding #316) — the on-device per-tick gait classifier, rolled up to a window.
///   3. Gravity-derived posture/motion variance — the per-record L2 gravity-delta intensity series
///      over `gravitySample`, read as a SHAPE signal rather than a threshold gate.
///   4. Duration and calories.
///
/// ---------------------------------------------------------------------------
/// ADVISORY ONLY — NEVER OVERRIDES THE USER. This is the whole point of the feature.
/// ---------------------------------------------------------------------------
/// A caller may use this to LABEL or SUGGEST a class on a *detected* window. It must NEVER:
///   * overwrite or "correct" a sport the user selected themselves (`workout.sport`);
///   * gate or feed a downstream score (Charge/recovery, Effort/strain, sleep need, …);
///   * be presented as a fact rather than a suggestion.
/// [WorkoutClassPrediction.isAdvisory] is a permanent, always-true marker documenting that
/// contract at the call site, and [suggestionFor] is the ONLY sanctioned entry point for applying a
/// prediction to a workout: it returns null the moment the user has set a sport of their own.
///
/// BROAD ONLY. This deliberately does NOT attempt fine-grained sport discrimination (e.g. basketball
/// vs tennis) — that needs raw high-rate IMU (type-43, ~100 Hz) this app does not capture. The
/// gravity/step inputs here are the DECODED, already-stored ~1 Hz streams; nothing here reads raw
/// motion buffers.
///
/// NOT a spectral/autocorrelation estimate. The gravity stream is ~1 Hz, well below the Nyquist rate
/// a real gait/pedal cadence needs (~1.5–3 Hz for walk/run strides). Per the repo's derived-signal
/// rule (and the withdrawn PPG→HR estimate, #194), autocorrelation or spectral analysis on a fixed
/// low sample rate can manufacture a peak at the RECORD period that looks physiological but isn't —
/// so this file never does that. [WorkoutClassFeatures.motionCV] is a coefficient-of-variation
/// burstiness/regularity statistic, NOT a frequency estimate.
///
/// SHIP STATUS: first-pass HEURISTIC (documented, clamped ramp thresholds below), validated so far
/// ONLY against synthetic fixtures that each recover a distinct injected pattern. Real-world accuracy
/// against labeled workouts is an explicit follow-up, not done here. [WorkoutClassPrediction.scores]
/// reports every candidate's raw match score precisely so a later pass can compute top-k / confusion
/// against real labels without re-deriving anything.
///
/// PORT NOTES (this Dart port vs the Kotlin/Swift originals):
///   * The Kotlin reads `List<HrSample>` / `List<GravitySample>` / `List<StepSample>`; this port
///     takes PARALLEL arrays (`tsSec` + values), matching [StrainScorer] / `RecoveryScorer` here.
///   * Upstream's extractor calls `WorkoutDetector.activitySeries` / `WorkoutDetector.deriveRestingHR`.
///     This port HAS NO `WorkoutDetector` (no auto workout detection exists here yet), so both are
///     reimplemented locally — see [WorkoutTypeFeatureExtractor.gravityActivitySeries] and
///     [WorkoutTypeFeatureExtractor.deriveRestingHR] — to the same documented definitions. When a
///     detector is ported, those two should collapse back onto it.
library;

import 'dart:math' as math;

import 'package:noop/core/analytics/strain_scorer.dart';

/// A BROAD workout activity class. Deliberately coarse — see the file header for why finer-grained
/// sport discrimination is out of scope without raw IMU. [raw] preserves the exact lowercase wire
/// string the Swift `rawValue` / Kotlin `raw` use, so a stored label round-trips across platforms.
enum CoarseWorkoutClass {
  walk('walk'),
  run('run'),
  strength('strength'),
  cycle('cycle'),
  ski('ski'),

  /// No candidate cleared the plausibility/margin bar — genuinely unclear, or a shape (e.g. swim,
  /// row, court sport) this MVP doesn't model. Never a wrong specific guess dressed up.
  other('other');

  const CoarseWorkoutClass(this.raw);

  /// The cross-platform wire string.
  final String raw;
}

/// The feature vector a classifier scores. Built once per detected workout window so real labeled
/// workouts can be scored later WITHOUT re-deriving anything from raw streams — construct this
/// directly from a labeled workout's own summary stats to validate, or run
/// [WorkoutTypeFeatureExtractor] over its stored streams. Mirrors Kotlin `WorkoutClassFeatures`.
class WorkoutClassFeatures {
  /// Window length (`end - start`), seconds.
  final double durationSec;

  // --- HR profile ---
  final double meanHR;
  final int peakHR;

  /// Mean Karvonen %HRR over the window, 0..100, or null when resting/max HR couldn't be resolved.
  final double? meanHRRPct;

  /// Coefficient of variation (stdev/mean) of the window's HR samples. Low = steady sustained effort
  /// (run/walk/cycle); high = saw-tooth (sets-then-rest strength, or intermittent ski runs).
  final double hrCV;

  // --- Activity-class tick composition (stepSample.activityClass: 0 still / 1 walk / 2 run) ---

  /// Fraction of ticks WITH a decoded activity class reading "still" / "walk" / "run" respectively
  /// (sum to ~1 when [tickCoverage] > 0; all 0 when no tick in the window carried a class).
  final double stillFraction;
  final double walkFraction;
  final double runFraction;

  /// How much of the window is actually backed by a decoded activity-class tick, clamped [0, 1]
  /// (classified ticks per second of window). Low/zero on a WHOOP 4.0 or any capture predating the
  /// @63 decode — the classifier falls back to HR+motion-only scoring below
  /// [WorkoutTypeClassifier.minTickCoverage].
  final double tickCoverage;

  // --- Gravity-derived posture / motion shape ---

  /// Variance of the per-record L2 gravity-delta intensity series over the window — a coarse
  /// posture/impact-variability proxy.
  final double motionVariance;

  /// Coefficient of variation of that same intensity series — burstiness/regularity, NOT a cadence
  /// estimate (see file header). Low = smooth continuous motion (cycle); high = stop-start bursts
  /// (strength sets, or ski runs broken up by lift rides).
  final double motionCV;

  // --- Energy ---

  /// Estimated kcal / minute over the window (`caloriesKcal / (durationSec/60)`), or null when no
  /// calorie estimate was available.
  final double? kcalPerMin;

  const WorkoutClassFeatures({
    required this.durationSec,
    required this.meanHR,
    required this.peakHR,
    required this.meanHRRPct,
    required this.hrCV,
    this.stillFraction = 0.0,
    this.walkFraction = 0.0,
    this.runFraction = 0.0,
    this.tickCoverage = 0.0,
    this.motionVariance = 0.0,
    this.motionCV = 0.0,
    this.kcalPerMin,
  });
}

/// A predicted coarse class + confidence for one workout window. ADVISORY ONLY — see file header.
class WorkoutClassPrediction {
  final CoarseWorkoutClass predictedClass;

  /// 0..1. Reflects BOTH how cleanly the winner beat the runner-up (margin) and how complete the
  /// inputs were (tick coverage, %HRR availability) — never higher than the evidence supports.
  final double confidence;

  /// Every scored candidate's raw match score (0..1), keyed by class. Always covers
  /// walk/run/strength/cycle/ski — [CoarseWorkoutClass.other] has no prototype score and is never a
  /// key here; it is only ever [predictedClass]. Kept so a later validation pass can check top-k /
  /// confusion against real labels, not just the single winner.
  final Map<CoarseWorkoutClass, double> scores;

  const WorkoutClassPrediction(this.predictedClass, this.confidence, this.scores);

  /// Permanently true. A structural, greppable reminder at every call site that this prediction is a
  /// SUGGESTION: it must never overwrite a user-set sport, and never gate a downstream score. See
  /// [suggestionFor] — the only sanctioned way to apply one to a workout.
  bool get isAdvisory => true;
}

/// Anything that can turn a feature vector into a prediction. [WorkoutTypeClassifier] (the heuristic)
/// is the only implementation today; a future ML model — trained on real labels, or fed richer
/// raw-IMU-derived features through a wider [WorkoutClassFeatures] — implements the SAME interface so
/// call sites built against it don't change. Mirrors Kotlin `WorkoutTypeClassifying`.
abstract class WorkoutTypeClassifying {
  const WorkoutTypeClassifying();

  WorkoutClassPrediction classify(WorkoutClassFeatures features);
}

/// Thin instance adapter over [WorkoutTypeClassifier]'s heuristic, for callers that want the
/// interface seam (dependency injection, swapping in a future model) rather than calling the class
/// directly. Stateless; [WorkoutTypeClassifier.classify] is equally fine to call directly.
class HeuristicWorkoutClassifier extends WorkoutTypeClassifying {
  const HeuristicWorkoutClassifier();

  @override
  WorkoutClassPrediction classify(WorkoutClassFeatures features) =>
      WorkoutTypeClassifier.classify(features);
}

/// The ADVISORY, OPT-IN gate — the only sanctioned way to turn a [prediction] into a label on a
/// workout. Returns the suggested class, or null when no suggestion may be offered.
///
/// This is where the "never overrides the user" contract is ENFORCED rather than merely documented:
///
///   * [userSport] — whatever the user themselves selected (`workout.sport`). If they have set
///     ANYTHING non-empty, this returns null. Their choice is final and is never second-guessed,
///     no matter how confident the heuristic is.
///   * [optedIn] — the feature is opt-in, matching the upstream auto-detector's non-destructive
///     pattern. Default false: absent an explicit yes, there is no suggestion.
///   * A [CoarseWorkoutClass.other] verdict is not a suggestion and returns null.
///
/// The caller still owns whether to show it and must present it as a suggestion.
CoarseWorkoutClass? suggestionFor(
  WorkoutClassPrediction prediction, {
  String? userSport,
  bool optedIn = false,
}) {
  if (!optedIn) return null;
  // The user's own selection always wins — never overridden, never "corrected".
  if (userSport != null && userSport.trim().isNotEmpty) return null;
  if (prediction.predictedClass == CoarseWorkoutClass.other) return null;
  return prediction.predictedClass;
}

/// The heuristic. Mirrors Kotlin `WorkoutTypeClassifier` — same constants, same scores.
class WorkoutTypeClassifier {
  WorkoutTypeClassifier._();

  // ---- Constants (first-pass heuristic — see file header; tune against real labels later) ----

  /// Below this fraction of the window backed by a decoded activity-class tick, walk/run scoring
  /// falls back to HR+motion-only (ticks are too sparse/absent — e.g. a WHOOP 4.0 — to trust).
  static const double minTickCoverage = 0.15;

  /// A candidate's top raw score must clear this to be reported as anything other than
  /// [CoarseWorkoutClass.other].
  static const double minPlausibleScore = 0.40;

  /// The winner must beat the runner-up by at least this much (both 0..1 scores) or the call is too
  /// close and reports [CoarseWorkoutClass.other] instead of an arbitrary tie-break.
  static const double minMargin = 0.05;

  // ---- Public API ----

  /// Score [features] against every candidate class and return the winner (or
  /// [CoarseWorkoutClass.other] when nothing clears [minPlausibleScore]/[minMargin]) plus a
  /// confidence reflecting both the margin and how complete the inputs were.
  static WorkoutClassPrediction classify(WorkoutClassFeatures features) {
    final scores = allScores(features);

    // Stable descending rank (ties → earlier insertion order wins), matching Kotlin's
    // `sortedByDescending`. Dart's List.sort is NOT stable, so rank on (-value, index) explicitly.
    final entries = scores.entries.toList();
    final indexed = <(int, CoarseWorkoutClass, double)>[
      for (var i = 0; i < entries.length; i++) (i, entries[i].key, entries[i].value),
    ];
    indexed.sort((a, b) {
      final byValue = b.$3.compareTo(a.$3);
      return byValue != 0 ? byValue : a.$1.compareTo(b.$1);
    });

    if (indexed.isEmpty) {
      return WorkoutClassPrediction(CoarseWorkoutClass.other, 0.0, scores);
    }
    final top = indexed.first;
    final second = indexed.length > 1 ? indexed[1].$3 : 0.0;
    final margin = math.max(0.0, top.$3 - second);
    final marginFactor = 0.5 + 0.5 * math.min(1.0, margin);
    var confidence = top.$3 * marginFactor;

    // Data-completeness dampener: never let a prediction read more confident than the inputs backing
    // it. Neither known → floor at 0.70×; both known → no penalty.
    final hrrKnown = features.meanHRRPct != null;
    final ticksKnown = features.tickCoverage >= minTickCoverage;
    var completeness = 0.70;
    if (hrrKnown) completeness += 0.15;
    if (ticksKnown) completeness += 0.15;
    confidence = math.min(1.0, math.max(0.0, confidence * completeness));

    if (top.$3 < minPlausibleScore || margin < minMargin) {
      return WorkoutClassPrediction(CoarseWorkoutClass.other, confidence, scores);
    }
    return WorkoutClassPrediction(top.$2, confidence, scores);
  }

  /// Every concrete class's raw [0,1] match score. Exposed (not just the winner) so validation
  /// against real labels can check top-k, not only top-1. Insertion order matches the Kotlin
  /// `linkedMapOf` so tie-breaking is identical.
  static Map<CoarseWorkoutClass, double> allScores(WorkoutClassFeatures f) => {
        CoarseWorkoutClass.walk: walkScore(f),
        CoarseWorkoutClass.run: runScore(f),
        CoarseWorkoutClass.strength: strengthScore(f),
        CoarseWorkoutClass.cycle: cycleScore(f),
        CoarseWorkoutClass.ski: skiScore(f),
      };

  // ---- Ramp helpers (fuzzy-membership style, matching the documented-threshold style elsewhere
  // in this package rather than an opaque weighted model) ----

  /// 0 at/below [lo], 1 at/above [hi], linear between. `hi <= lo` degenerates to a step at [hi].
  static double rampUp(double x, double lo, double hi) {
    if (hi <= lo) return x >= hi ? 1.0 : 0.0;
    return math.min(1.0, math.max(0.0, (x - lo) / (hi - lo)));
  }

  /// Mirror of [rampUp]: 1 at/below [lo], 0 at/above [hi].
  static double rampDown(double x, double lo, double hi) => 1.0 - rampUp(x, lo, hi);

  /// Trapezoid membership: 0 below [a], ramps to 1 over [a,b], flat 1 over [b,c], ramps to 0 over
  /// [c,d], 0 above [d]. Requires `a <= b <= c <= d`.
  static double plateau(double x, double a, double b, double c, double d) =>
      math.min(rampUp(x, a, b), rampDown(x, c, d));

  /// How strongly the activity-class ticks should be trusted vs. falling back to HR+motion-only.
  /// 0 with no/negligible tick coverage, ramping to 1 once coverage reaches [minTickCoverage].
  static double tickReliability(WorkoutClassFeatures f) =>
      rampUp(f.tickCoverage, minTickCoverage * 0.3, minTickCoverage);

  /// "No walk/run gait" evidence for the non-foot classes (strength/cycle/ski). When ticks are too
  /// sparse to trust, this returns a NEUTRAL 0.5 rather than penalizing — an absent signal must not
  /// read as evidence against a class (a WHOOP 4.0 capture has no @63 activity class at all).
  static double gaitAbsenceScore(WorkoutClassFeatures f) {
    if (f.tickCoverage < minTickCoverage) return 0.5;
    return rampUp(f.stillFraction, 0.40, 0.75);
  }

  // ---- Per-class scoring ----

  /// RUN: dominant run-classified ticks when available; else a smooth (low-`hrCV`), elevated-%HRR,
  /// higher-impact (higher `motionVariance`) fallback signature.
  static double runScore(WorkoutClassFeatures f) {
    final tick = rampUp(f.runFraction, 0.15, 0.55);
    final hr = rampUp(f.meanHRRPct ?? 55.0, 45.0, 75.0);
    final motion = plateau(f.motionVariance, 0.05, 0.10, 0.35, 0.60);
    final smooth = rampDown(f.hrCV, 0.05, 0.12);
    final tickWeighted = 0.55 * tick + 0.25 * hr + 0.15 * motion + 0.05 * smooth;
    final fallback = 0.45 * hr + 0.35 * motion + 0.20 * smooth;
    final rel = tickReliability(f);
    return tickWeighted * rel + fallback * (1 - rel);
  }

  /// WALK: dominant walk-classified ticks when available; else a LOW-moderate %HRR band (walking
  /// rarely pushes %HRR high) with modest motion variance (rhythmic but low-impact gait).
  static double walkScore(WorkoutClassFeatures f) {
    final tick = rampUp(f.walkFraction, 0.15, 0.55);
    final hr = plateau(f.meanHRRPct ?? 30.0, 5.0, 15.0, 35.0, 55.0);
    final motion = plateau(f.motionVariance, 0.005, 0.02, 0.07, 0.12);
    final tickWeighted = 0.60 * tick + 0.25 * hr + 0.15 * motion;
    final fallback = 0.55 * hr + 0.45 * motion;
    final rel = tickReliability(f);
    return tickWeighted * rel + fallback * (1 - rel);
  }

  /// STRENGTH: no walk/run gait, BURSTY HR (sets separated by rest reads as high `hrCV`, unlike a
  /// steady cardio effort), typically a lower sustained kcal/min than continuous cardio, and LOW
  /// motion variance — a rack of lifts swings the wrist/torso through gravity far less than dynamic
  /// ski turns or terrain do, which is what separates strength from ski's similarly-bursty-but-more-
  /// mobile signature.
  static double strengthScore(WorkoutClassFeatures f) {
    final noGait = gaitAbsenceScore(f);
    final bursty = rampUp(f.hrCV, 0.06, 0.16);
    final hr = plateau(f.meanHRRPct ?? 45.0, 15.0, 30.0, 80.0, 100.0);
    final lowBurnRate = rampDown(f.kcalPerMin ?? 6.0, 6.0, 11.0);
    final lowMotion = rampDown(f.motionVariance, 0.05, 0.15);
    // `bursty` carries the most weight deliberately: it's the one genuinely distinctive signal here
    // (HR sawtooth from sets-then-rest). hr/lowBurnRate are generic enough (moderate HR, moderate
    // burn rate) that other steady-effort classes match them too, so a SMOOTH window (bursty ≈ 0)
    // must not still score as strength just by having plausible HR/motion levels.
    return 0.45 * bursty + 0.20 * noGait + 0.20 * lowMotion + 0.10 * hr + 0.05 * lowBurnRate;
  }

  /// CYCLE: no walk/run gait, SMOOTH sustained elevated HR (low `hrCV`, unlike strength's sets), and
  /// low motion variance — the torso/wrist stays comparatively still relative to on-foot gait.
  static double cycleScore(WorkoutClassFeatures f) {
    final noGait = gaitAbsenceScore(f);
    final smooth = rampDown(f.hrCV, 0.04, 0.10);
    final hr = rampUp(f.meanHRRPct ?? 55.0, 35.0, 65.0);
    final stablePosture = rampDown(f.motionVariance, 0.02, 0.08);
    return 0.30 * noGait + 0.30 * smooth + 0.25 * hr + 0.15 * stablePosture;
  }

  /// SKI: no walk/run gait, HIGHER and more variable posture signal than cycling (turns/terrain,
  /// standing rather than seated), and a wide, intermittent HR pattern (runs interspersed with
  /// lift-ride rest — more variable than cycle's steady spin, but not as short-cycle-bursty as
  /// strength's sets).
  static double skiScore(WorkoutClassFeatures f) {
    final noGait = gaitAbsenceScore(f);
    final variablePosture = plateau(f.motionVariance, 0.06, 0.14, 0.45, 0.70);
    final hr = plateau(f.meanHRRPct ?? 45.0, 20.0, 35.0, 85.0, 100.0);
    final intermittent = plateau(f.hrCV, 0.05, 0.09, 0.20, 0.32);
    return 0.30 * noGait + 0.30 * variablePosture + 0.20 * hr + 0.20 * intermittent;
  }
}

/// One entry of the gravity-derived motion-intensity series: a timestamp and the L2 norm of the
/// gravity vector's change since the previous record.
class GravityIntensity {
  final int ts; // unix seconds
  final double intensity; // |Δgravity| (g)
  const GravityIntensity(this.ts, this.intensity);
}

/// Builds a [WorkoutClassFeatures] vector for a `[start, end]` window from the decoded streams this
/// app already stores (`hrSample`, `gravitySample`, `stepSample`) — no new store, no new decode.
/// Pure/deterministic; slices the caller's lists to the window itself so callers can pass a whole
/// day's streams or an already-sliced window interchangeably. Mirrors Kotlin
/// `WorkoutTypeFeatureExtractor`.
///
/// PORT NOTE: upstream delegates to `WorkoutDetector.activitySeries` / `.deriveRestingHR`. This port
/// has no `WorkoutDetector`, so both are reimplemented here to the same documented definitions.
class WorkoutTypeFeatureExtractor {
  WorkoutTypeFeatureExtractor._();

  /// Percentile of the window's own HR used as the resting-HR fallback when the caller supplies
  /// none — the same 10th-percentile definition upstream's `WorkoutDetector.deriveRestingHR` uses.
  static const double restingHRPercentile = 10.0;

  /// The per-record L2 gravity-delta intensity series — upstream's `WorkoutDetector.activitySeries`.
  ///
  /// For each record after the first, the intensity is the Euclidean norm of the gravity vector's
  /// change since the previous record, timestamped at the CURRENT record. The first record has no
  /// predecessor and contributes 0.0 — which is why callers should pass gravity from a little BEFORE
  /// the window where possible, so the first in-window delta isn't a false 0 (this matches upstream
  /// behaviour either way, since the series is built over the full list and filtered afterwards).
  ///
  /// [tsSec] / [x] / [y] / [z] are parallel, time-ordered arrays.
  static List<GravityIntensity> gravityActivitySeries(
    List<int> tsSec,
    List<double> x,
    List<double> y,
    List<double> z,
  ) {
    final out = <GravityIntensity>[];
    for (var i = 0; i < tsSec.length; i++) {
      if (i == 0) {
        out.add(GravityIntensity(tsSec[i], 0.0));
        continue;
      }
      final dx = x[i] - x[i - 1];
      final dy = y[i] - y[i - 1];
      final dz = z[i] - z[i - 1];
      out.add(GravityIntensity(tsSec[i], math.sqrt(dx * dx + dy * dy + dz * dz)));
    }
    return out;
  }

  /// Resting-HR fallback derived from a window's own HR: the [restingHRPercentile]th percentile.
  /// Returns 0.0 for an empty series (the caller then can't form a valid HR reserve and %HRR drops).
  static double deriveRestingHR(List<double> bpm) {
    if (bpm.isEmpty) return 0.0;
    final sorted = List<double>.from(bpm)..sort();
    return StrainScorer.percentile(sorted, restingHRPercentile);
  }

  /// Extract the feature vector for the window `[start, end]` (unix SECONDS, inclusive).
  ///
  /// Returns null when the window is degenerate (`end <= start`) or holds no HR samples — it never
  /// fabricates a vector from nothing.
  ///
  /// [hrTsSec]/[hrBpm] are parallel; likewise the gravity and step arrays. [stepActivityClass]
  /// carries the @63 enum (0 still / 1 walk / 2 run), null per tick when invalid/absent — an empty
  /// step stream (pre-#316 firmware, or a WHOOP 4.0) simply yields `tickCoverage` 0 and the
  /// classifier falls back to HR+motion.
  ///
  /// [restingHR] — day resting-HR baseline; null → derived from the window's own HR via
  /// [deriveRestingHR]. [maxHR] — HRmax; null → [StrainScorer.estimateHRmax] over the window's HR.
  /// [caloriesKcal] — the window's estimated calories, if already computed; null → `kcalPerMin` null.
  static WorkoutClassFeatures? extract({
    required List<int> hrTsSec,
    required List<double> hrBpm,
    required int start,
    required int end,
    List<int> gravityTsSec = const [],
    List<double> gravityX = const [],
    List<double> gravityY = const [],
    List<double> gravityZ = const [],
    List<int> stepTsSec = const [],
    List<int?> stepActivityClass = const [],
    double? restingHR,
    double? maxHR,
    double? caloriesKcal,
  }) {
    if (end <= start) return null;

    // HR window (kept ts-paired, then time-ordered — callers may pass an unsorted day).
    final win = <(int, double)>[];
    for (var i = 0; i < hrTsSec.length; i++) {
      final ts = hrTsSec[i];
      if (ts >= start && ts <= end) win.add((ts, hrBpm[i]));
    }
    if (win.isEmpty) return null;
    win.sort((a, b) => a.$1.compareTo(b.$1));
    final bpms = [for (final s in win) s.$2];

    final durationSec = (end - start).toDouble();
    final meanHR = mean(bpms);
    final peakHR = bpms.reduce(math.max).round();
    final hrCV = meanHR > 0 ? stddev(bpms) / meanHR : 0.0;

    // %HRR: caller-supplied resting/max HR, else derive from the window's own HR.
    final restHR = restingHR ?? deriveRestingHR(bpms);
    final estimated = StrainScorer.estimateHRmax(bpms, null).$1;
    final effMaxHR = maxHR ?? (estimated > 0 ? estimated : null);
    double? meanHRRPct;
    if (effMaxHR != null && effMaxHR > restHR) {
      final hrReserve = effMaxHR - restHR;
      meanHRRPct = mean([for (final b in bpms) StrainScorer.pctHRR(b, restHR, hrReserve)]);
    }

    // Gravity-derived motion shape.
    final intensitySeries = [
      for (final g in gravityActivitySeries(gravityTsSec, gravityX, gravityY, gravityZ))
        if (g.ts >= start && g.ts <= end) g.intensity,
    ];
    final motionMean = mean(intensitySeries);
    final motionVariance = variance(intensitySeries);
    final motionCV = motionMean > 0 ? stddev(intensitySeries) / motionMean : 0.0;

    // Activity-class tick composition.
    final validTicks = <int>[];
    for (var i = 0; i < stepTsSec.length; i++) {
      final ts = stepTsSec[i];
      if (ts < start || ts > end) continue;
      final cls = i < stepActivityClass.length ? stepActivityClass[i] : null;
      if (cls != null) validTicks.add(cls);
    }
    final tickCoverage =
        math.min(1.0, validTicks.length.toDouble() / math.max(1.0, durationSec));
    var stillFraction = 0.0, walkFraction = 0.0, runFraction = 0.0;
    if (validTicks.isNotEmpty) {
      final n = validTicks.length.toDouble();
      stillFraction = validTicks.where((c) => c == 0).length / n;
      walkFraction = validTicks.where((c) => c == 1).length / n;
      runFraction = validTicks.where((c) => c == 2).length / n;
    }

    final kcalPerMin = caloriesKcal == null ? null : caloriesKcal / (durationSec / 60.0);

    return WorkoutClassFeatures(
      durationSec: durationSec,
      meanHR: meanHR,
      peakHR: peakHR,
      meanHRRPct: meanHRRPct,
      hrCV: hrCV,
      stillFraction: stillFraction,
      walkFraction: walkFraction,
      runFraction: runFraction,
      tickCoverage: tickCoverage,
      motionVariance: motionVariance,
      motionCV: motionCV,
      kcalPerMin: kcalPerMin,
    );
  }

  // ---- Small stats helpers (population variance/stdev; no external dependency) ----

  static double mean(List<double> xs) {
    if (xs.isEmpty) return 0.0;
    var sum = 0.0;
    for (final x in xs) {
      sum += x;
    }
    return sum / xs.length.toDouble();
  }

  static double variance(List<double> xs) {
    if (xs.length <= 1) return 0.0;
    final m = mean(xs);
    var acc = 0.0;
    for (final x in xs) {
      acc += (x - m) * (x - m);
    }
    return acc / xs.length.toDouble();
  }

  static double stddev(List<double> xs) => math.sqrt(variance(xs));
}
