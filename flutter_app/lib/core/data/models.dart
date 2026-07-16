import 'package:flutter/foundation.dart';

/// Sleep stage. Mirrors the hypnogram stage enum.
enum SleepStage { awake, light, deep, rem }

/// A single hypnogram segment.
@immutable
class StageSegment {
  final DateTime start;
  final Duration duration;
  final SleepStage stage;
  const StageSegment({required this.start, required this.duration, required this.stage});
}

/// A heart-rate sample.
@immutable
class HrSample {
  final DateTime time;
  final double bpm;
  const HrSample(this.time, this.bpm);
}

/// A night of sleep.
@immutable
class SleepRecord {
  final DateTime date; // logical night (the morning date)
  final DateTime bedtime;
  final DateTime wake;
  final Duration timeInBed;
  final Duration asleep;
  final Duration deep;
  final Duration rem;
  final Duration light;
  final Duration awake;
  final double efficiency; // 0..1
  final Duration need; // sleep need
  final double respiratoryRate; // rpm
  final List<StageSegment> hypnogram;
  final List<double> restlessness; // 0..1 per epoch (motion strip)
  final int disturbances;

  /// True when this night was staged on motion too sparse to trust the staging
  /// (#345, [SleepStager.motionSparseOver]) — a night with real holes in the
  /// banked data. The stages, totals and [efficiency] are unchanged and remain
  /// the engine's honest best read; this says only how far they can be believed,
  /// so a confident 85–100 Rest is not claimed on data that cannot earn it.
  /// Upstream's rule is the same — the engine emits the tier, no stage is faked,
  /// and the UI surfaces it.
  final bool motionSparse;

  const SleepRecord({
    required this.date,
    required this.bedtime,
    required this.wake,
    required this.timeInBed,
    required this.asleep,
    required this.deep,
    required this.rem,
    required this.light,
    required this.awake,
    required this.efficiency,
    required this.need,
    required this.respiratoryRate,
    this.hypnogram = const [],
    this.restlessness = const [],
    this.disturbances = 0,
    this.motionSparse = false,
  });

  /// Sleep performance = asleep / need, clamped to 100.
  double get performance =>
      need.inMinutes == 0 ? 0 : (asleep.inMinutes / need.inMinutes * 100).clamp(0, 100);
}

/// A workout / activity session.
@immutable
class Workout {
  final String id;
  final String sport;
  final DateTime start;
  final Duration duration;
  final double avgHr;
  final double maxHr;
  final double effort; // strain 0..21
  final int calories; // kcal
  final double? distanceKm;
  final List<Duration> zoneDurations; // 5 zones

  const Workout({
    required this.id,
    required this.sport,
    required this.start,
    required this.duration,
    required this.avgHr,
    required this.maxHr,
    required this.effort,
    required this.calories,
    this.distanceKm,
    this.zoneDurations = const [],
  });
}

/// A vital reading with a recent series (for the health/vitals tiles).
@immutable
class VitalReading {
  final String label;
  final double value;
  final String unit;
  final DateTime asOf;
  final List<double> series;
  const VitalReading({
    required this.label,
    required this.value,
    required this.unit,
    required this.asOf,
    this.series = const [],
  });
}

/// Nights of valid HRV a personal baseline needs before recovery is scoreable.
/// Matches `baselineProvisionalMinNights` in analytics/baselines.dart.
const int recoveryCalibrationNightsNeeded = 4;

/// The per-day summary record — the spine of the whole app.
@immutable
class DayRecord {
  final DateTime date;
  final double charge; // recovery 0..100 (population mean while calibrating)

  /// Non-null ONLY while the personal HRV baseline is still seeding: the count of
  /// valid HRV nights collected so far (0..[recoveryCalibrationNightsNeeded]).
  /// The UI shows "Calibrating N/4 nights" instead of [charge] when this is set.
  ///
  /// Null does NOT mean [charge] is a score — check [chargeScored] for that.
  /// A calibrated wearer whose night produced no usable HRV/RHR has no count to
  /// report and is not calibrating anything; that night sets [chargeNoData].
  final int? chargeCalibrationNights;

  /// True when recovery is unscoreable for THIS night even though the baseline
  /// is not seeding — sparse RR (RMSSD needs >= 20 clean beats), no sleep window,
  /// the strap not worn, or a baseline gone stale. [charge] is then a filler
  /// population mean and must be rendered as "no data", never as a score and
  /// never as calibration progress.
  final bool chargeNoData;

  final double effort; // day strain 0..21
  final double rest; // sleep performance 0..100
  final double stress; // 0..100
  final double hrv; // ms (RMSSD)
  final double rhr; // bpm
  final double respiratoryRate; // rpm
  final double skinTempDelta; // °C vs baseline
  final double spo2; // %
  final int steps;
  final int calories; // kcal
  final int fitnessAge; // years
  /// Energy 0..100 — [charge] re-expressed, so it inherits [charge]'s contract
  /// EXACTLY: on a calibrating or no-data night this is the rounded population-mean
  /// FILLER (58), not a reading. Gate every render on [chargeScored], never on
  /// `vitality != 0` — an unscored night is not 0% energy, and "0%" is a worse lie
  /// than the 58 it would replace.
  final int vitality;
  final double hydration; // 0..1
  final SleepRecord? sleep;
  final List<Workout> workouts;
  final List<HrSample> hr; // day HR thread (sampled)

  const DayRecord({
    required this.date,
    required this.charge,
    this.chargeCalibrationNights,
    this.chargeNoData = false,
    required this.effort,
    required this.rest,
    required this.stress,
    required this.hrv,
    required this.rhr,
    required this.respiratoryRate,
    required this.skinTempDelta,
    required this.spo2,
    required this.steps,
    required this.calories,
    required this.fitnessAge,
    required this.vitality,
    required this.hydration,
    this.sleep,
    this.workouts = const [],
    this.hr = const [],
  });

  /// Copy with overrides — used by alternative [AnalysisEngine]s to re-score a
  /// subset of fields (e.g. HRV / respiratory rate / charge) while keeping the
  /// shared scaffolding (sleep, effort, HR thread) from a base computation.
  DayRecord copyWith({
    double? charge,
    double? effort,
    double? rest,
    double? stress,
    double? hrv,
    double? rhr,
    double? respiratoryRate,
    double? skinTempDelta,
    double? spo2,
    int? steps,
    int? calories,
    int? fitnessAge,
    int? vitality,
    double? hydration,
    SleepRecord? sleep,
    List<Workout>? workouts,
    List<HrSample>? hr,
  }) =>
      DayRecord(
        date: date,
        charge: charge ?? this.charge,
        // Carried through by default: an alt engine that also needs N nights to
        // score recovery is calibrating in the same window (see OpenStrapEngine),
        // and a night that sourced no HRV sources none for any engine either.
        chargeCalibrationNights: chargeCalibrationNights,
        chargeNoData: chargeNoData,
        effort: effort ?? this.effort,
        rest: rest ?? this.rest,
        stress: stress ?? this.stress,
        hrv: hrv ?? this.hrv,
        rhr: rhr ?? this.rhr,
        respiratoryRate: respiratoryRate ?? this.respiratoryRate,
        skinTempDelta: skinTempDelta ?? this.skinTempDelta,
        spo2: spo2 ?? this.spo2,
        steps: steps ?? this.steps,
        calories: calories ?? this.calories,
        fitnessAge: fitnessAge ?? this.fitnessAge,
        vitality: vitality ?? this.vitality,
        hydration: hydration ?? this.hydration,
        sleep: sleep ?? this.sleep,
        workouts: workouts ?? this.workouts,
        hr: hr ?? this.hr,
      );

  /// True while the HRV baseline is still seeding — the UI shows a
  /// "Calibrating N/[recoveryCalibrationNightsNeeded]" state instead of a number.
  bool get chargeCalibrating => chargeCalibrationNights != null;

  /// True when [charge] is a genuine recovery score. The ONLY safe gate for
  /// rendering it as a number: the two unscored reasons ([chargeCalibrating],
  /// [chargeNoData]) are mutually exclusive but both leave [charge] a filler.
  bool get chargeScored => !chargeCalibrating && !chargeNoData;
}

/// User profile — drives HR-max, sleep-need, units.
@immutable
class UserProfile {
  final String name;
  final int age;
  final bool male;
  final double weightKg;
  final double heightCm;
  final int? hrMaxOverride;
  final bool metric;

  const UserProfile({
    this.name = 'Athlete',
    this.age = 30,
    this.male = true,
    this.weightKg = 78,
    this.heightCm = 180,
    this.hrMaxOverride,
    this.metric = true,
  });

  UserProfile copyWith({int? age, bool? male, double? weightKg, double? heightCm, int? hrMaxOverride, bool? metric, String? name}) =>
      UserProfile(
        name: name ?? this.name,
        age: age ?? this.age,
        male: male ?? this.male,
        weightKg: weightKg ?? this.weightKg,
        heightCm: heightCm ?? this.heightCm,
        hrMaxOverride: hrMaxOverride ?? this.hrMaxOverride,
        metric: metric ?? this.metric,
      );
}
