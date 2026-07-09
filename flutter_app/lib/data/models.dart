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

/// The per-day summary record — the spine of the whole app.
@immutable
class DayRecord {
  final DateTime date;
  final double charge; // recovery 0..100
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
  final int vitality; // 0..100
  final double hydration; // 0..1
  final SleepRecord? sleep;
  final List<Workout> workouts;
  final List<HrSample> hr; // day HR thread (sampled)

  const DayRecord({
    required this.date,
    required this.charge,
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
