import 'dart:math' as math;
import 'package:noop/core/analytics/baselines.dart';
import 'package:noop/core/analytics/engines.dart';
import 'package:noop/core/data/models.dart';

/// Sync state surfaced on Today/Health.
enum SyncState { synced, syncing, needsStrap }

/// The data seam. The Flutter UI reads everything through this interface;
/// today it is backed by [MockRepository], later by a Kotlin-native
/// implementation over a platform channel (sync + heavy calc stay native).
abstract class Repository {
  UserProfile get profile;
  SyncState get syncState;

  /// Strap battery, 0..1.
  double get strapBattery;

  /// All day records, oldest → newest.
  List<DayRecord> get days;

  /// Convenience: the most recent day.
  DayRecord get today;

  /// Flat workout list, newest first.
  List<Workout> get workouts;

  /// Latest vital readings for the health screen.
  List<VitalReading> get vitals;
}

/// Deterministic mock data driven through the real scoring engines, so the
/// numbers are internally consistent (Charge computed from HRV/RHR baselines,
/// Rest from sleep stages, Stress from trailing means, Effort from TRIMP).
class MockRepository implements Repository {
  MockRepository({int seed = 7, this.dayCount = 90}) {
    _generate(seed);
  }

  final int dayCount;

  @override
  final UserProfile profile = const UserProfile(name: 'Alex');

  @override
  final SyncState syncState = SyncState.synced;

  @override
  final double strapBattery = 0.78;

  final List<DayRecord> _days = [];
  final List<Workout> _workouts = [];
  final List<VitalReading> _vitals = [];

  @override
  List<DayRecord> get days => _days;
  @override
  DayRecord get today => _days.last;
  @override
  List<Workout> get workouts => _workouts;
  @override
  List<VitalReading> get vitals => _vitals;

  static const _sports = ['Running', 'Cycling', 'Strength', 'HIIT', 'Yoga', 'Swimming', 'Walking'];

  void _generate(int seed) {
    final rnd = math.Random(seed);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: dayCount - 1));

    final hrvBase = BaselineState();
    final rhrBase = BaselineState();
    final respBase = BaselineState();

    // Rolling raw histories for stress + sleep-need.
    final rhrHist = <double>[];
    final hrvHist = <double>[];
    final sleepMinHist = <double>[];

    double wander(double base, double amp) => base + (rnd.nextDouble() - 0.5) * 2 * amp;

    for (var d = 0; d < dayCount; d++) {
      final date = start.add(Duration(days: d));

      // Nightly raw signals (slow drift + noise).
      final drift = math.sin(d / 11.0) * 6;
      final hrv = wander(66 + drift, 8).clamp(30, 120).toDouble();
      final rhr = wander(52 - drift * 0.4, 3).clamp(40, 75).toDouble();
      final resp = wander(14.6, 0.9).clamp(11, 19).toDouble();
      final skinTempDev = wander(0, 0.35);

      // Sleep.
      final asleepMin = wander(418, 55).clamp(280, 540).toDouble();
      final efficiency = wander(0.88, 0.06).clamp(0.72, 0.98).toDouble();
      final deepMin = asleepMin * wander(0.16, 0.03);
      final remMin = asleepMin * wander(0.22, 0.04);
      final lightMin = asleepMin - deepMin - remMin;
      final needMin = sleepNeedMin(null, sleepMinHist);

      // Fold baselines BEFORE scoring today (matches nightly pipeline order).
      Baselines.update(hrvBase, 'hrv', hrv);
      Baselines.update(rhrBase, 'resting_hr', rhr);
      Baselines.update(respBase, 'resp', resp);

      final rest = restScore(
            asleepSec: asleepMin * 60,
            needSec: needMin * 60,
            efficiency01: efficiency,
            deepSec: deepMin * 60,
            remSec: remMin * 60,
            consistency01: 0.72,
          ) ??
          0;

      final charge = recoveryScore(
            RecoveryInput(
              hrv: hrv,
              rhr: rhr,
              resp: resp,
              sleepPerf01: rest / 100,
              skinTempDevC: skinTempDev,
            ),
            hrvBase,
            rhrBase,
            respBase,
          ) ??
          recoveryPopulationMean;

      // Stress from trailing 30 days (ending yesterday).
      double stress = 1.5;
      if (rhrHist.length >= 7) {
        final w = math.min(30, rhrHist.length);
        final rh = rhrHist.sublist(rhrHist.length - w);
        final hv = hrvHist.sublist(hrvHist.length - w);
        stress = stressScore(
          todayRhr: rhr,
          meanRhr: _mean(rh),
          sdRhr: _sd(rh),
          todayHrv: hrv,
          meanHrv: _mean(hv),
          sdHrv: _sd(hv),
        );
      }
      final stress100 = (stress / 3 * 100).clamp(0, 100).toDouble();

      // Workouts on ~45% of days.
      final dayWorkouts = <Workout>[];
      final hasWorkout = rnd.nextDouble() < 0.45;
      double effort;
      if (hasWorkout) {
        final w = _makeWorkout(rnd, date);
        dayWorkouts.add(w);
        // Day effort ≈ session effort plus baseline activity.
        effort = math.min(100, w.effort + wander(18, 6));
      } else {
        effort = wander(28, 12).clamp(4, 70).toDouble();
      }

      final steps = (wander(8200, 3500)).clamp(1500, 20000).round();
      final calories = (1500 + steps * 0.045 + effort * 6).round();

      final sleep = _makeSleep(rnd, date, asleepMin, efficiency, deepMin, remMin, lightMin,
          needMin, resp, buildDetail: d >= dayCount - 3);

      final hr = d == dayCount - 1 ? _makeHrThread(rnd, date, rhr) : const <HrSample>[];

      _days.add(DayRecord(
        date: date,
        charge: double.parse(charge.toStringAsFixed(1)),
        effort: double.parse(effort.toStringAsFixed(1)),
        rest: double.parse(rest.toStringAsFixed(1)),
        stress: double.parse(stress100.toStringAsFixed(1)),
        hrv: double.parse(hrv.toStringAsFixed(1)),
        rhr: double.parse(rhr.toStringAsFixed(1)),
        respiratoryRate: double.parse(resp.toStringAsFixed(1)),
        skinTempDelta: double.parse(skinTempDev.toStringAsFixed(2)),
        spo2: wander(97, 1).clamp(94, 100),
        steps: steps,
        calories: calories,
        fitnessAge: (profile.age - (charge - 58) / 8).round().clamp(18, 80),
        vitality: charge.clamp(0, 100).round(),
        hydration: wander(0.7, 0.2).clamp(0.2, 1.0),
        sleep: sleep,
        workouts: dayWorkouts,
        hr: hr,
      ));
      _workouts.addAll(dayWorkouts);

      rhrHist.add(rhr);
      hrvHist.add(hrv);
      sleepMinHist.add(asleepMin);
    }

    _workouts.sort((a, b) => b.start.compareTo(a.start));
    _buildVitals();
  }

  Workout _makeWorkout(math.Random rnd, DateTime date) {
    final sport = _sports[rnd.nextInt(_sports.length)];
    final durMin = (25 + rnd.nextInt(80)).toDouble();
    final maxHr = hrMax(profile.age).toDouble();
    final avg = (maxHr * (0.62 + rnd.nextDouble() * 0.2));
    final peak = math.min(maxHr, avg + 15 + rnd.nextDouble() * 20);
    // Synthesize a per-session effort via TRIMP over a coarse HR profile.
    final samples = <double>[];
    final times = <double>[];
    final base = date.add(const Duration(hours: 17)).millisecondsSinceEpoch ~/ 1000;
    for (var m = 0; m < durMin; m++) {
      final bpm = avg + math.sin(m / 6) * 12 + (rnd.nextDouble() - 0.5) * 8;
      samples.add(bpm.clamp(60, maxHr));
      times.add((base + m * 60).toDouble());
    }
    final effort = strainScore(
          bpm: samples,
          times: times,
          age: profile.age,
          restingHr: 52,
        ) ??
        20;
    // HR-zone durations.
    final zones = List<Duration>.filled(5, Duration.zero);
    for (final b in samples) {
      final z = hrZoneFor(b, maxHr);
      if (z >= 1) zones[z - 1] += const Duration(minutes: 1);
    }
    final dist = (sport == 'Running' || sport == 'Cycling' || sport == 'Walking' || sport == 'Swimming')
        ? durMin / 60 * (sport == 'Cycling' ? 24 : sport == 'Swimming' ? 3 : 9)
        : null;
    return Workout(
      id: '${date.millisecondsSinceEpoch}-$sport',
      sport: sport,
      start: date.add(Duration(hours: 7 + rnd.nextInt(12))),
      duration: Duration(minutes: durMin.round()),
      avgHr: avg.roundToDouble(),
      maxHr: peak.roundToDouble(),
      effort: effort.toDouble(),
      calories: (durMin * (6 + rnd.nextDouble() * 6)).round(),
      distanceKm: dist == null ? null : double.parse(dist.toStringAsFixed(1)),
      zoneDurations: zones,
    );
  }

  SleepRecord _makeSleep(
    math.Random rnd,
    DateTime date,
    double asleepMin,
    double efficiency,
    double deepMin,
    double remMin,
    double lightMin,
    double needMin,
    double resp, {
    required bool buildDetail,
  }) {
    final bedtime = DateTime(date.year, date.month, date.day)
        .subtract(Duration(minutes: (asleepMin / efficiency).round()))
        .add(const Duration(hours: 6, minutes: 30));
    final wake = DateTime(date.year, date.month, date.day, 6, 45);

    final hypnogram = <StageSegment>[];
    final restlessness = <double>[];
    if (buildDetail) {
      var t = bedtime;
      final total = wake.difference(bedtime);
      var elapsed = Duration.zero;
      final stages = [SleepStage.light, SleepStage.deep, SleepStage.light, SleepStage.rem];
      var i = 0;
      while (elapsed < total) {
        final stage = i < 2
            ? stages[i % stages.length]
            : (rnd.nextDouble() < 0.12
                ? SleepStage.awake
                : stages[rnd.nextInt(stages.length)]);
        final segMin = stage == SleepStage.awake ? 4 + rnd.nextInt(8) : 18 + rnd.nextInt(40);
        final dur = Duration(minutes: segMin);
        hypnogram.add(StageSegment(start: t, duration: dur, stage: stage));
        t = t.add(dur);
        elapsed += dur;
        i++;
      }
      final epochs = total.inMinutes ~/ 5;
      for (var e = 0; e < epochs; e++) {
        restlessness.add((rnd.nextDouble() * 0.6 + math.sin(e / 3) * 0.2).abs().clamp(0, 1));
      }
    }

    return SleepRecord(
      date: date,
      bedtime: bedtime,
      wake: wake,
      timeInBed: Duration(minutes: (asleepMin / efficiency).round()),
      asleep: Duration(minutes: asleepMin.round()),
      deep: Duration(minutes: deepMin.round()),
      rem: Duration(minutes: remMin.round()),
      light: Duration(minutes: lightMin.round()),
      awake: Duration(minutes: (asleepMin / efficiency - asleepMin).round()),
      efficiency: efficiency,
      need: Duration(minutes: needMin.round()),
      respiratoryRate: resp,
      hypnogram: hypnogram,
      restlessness: restlessness,
      disturbances: 2 + rnd.nextInt(6),
    );
  }

  List<HrSample> _makeHrThread(math.Random rnd, DateTime date, double rhr) {
    final out = <HrSample>[];
    final startTime = DateTime(date.year, date.month, date.day);
    for (var m = 0; m < 24 * 60; m += 5) {
      final hour = m / 60;
      // Low overnight, higher daytime, an afternoon workout bump.
      var bpm = rhr + 6;
      if (hour > 7 && hour < 22) bpm += 12 + math.sin(hour) * 6;
      if (hour > 17 && hour < 18) bpm += 45; // workout
      bpm += (rnd.nextDouble() - 0.5) * 8;
      out.add(HrSample(startTime.add(Duration(minutes: m)), bpm.clamp(42, 180)));
    }
    return out;
  }

  void _buildVitals() {
    List<double> series(double Function(DayRecord) f) =>
        _days.sublist(_days.length - 30).map(f).toList();
    final t = today;
    final now = DateTime.now();
    _vitals.addAll([
      VitalReading(label: 'HRV', value: t.hrv, unit: 'ms', asOf: now, series: series((d) => d.hrv)),
      VitalReading(label: 'Resting HR', value: t.rhr, unit: 'bpm', asOf: now, series: series((d) => d.rhr)),
      VitalReading(label: 'Respiratory', value: t.respiratoryRate, unit: 'rpm', asOf: now, series: series((d) => d.respiratoryRate)),
      VitalReading(label: 'Blood O₂', value: t.spo2, unit: '%', asOf: now, series: series((d) => d.spo2)),
      VitalReading(label: 'Skin temp', value: t.skinTempDelta, unit: '°C', asOf: now, series: series((d) => d.skinTempDelta)),
    ]);
  }

  static double _mean(List<double> xs) => xs.reduce((a, b) => a + b) / xs.length;
  static double _sd(List<double> xs) {
    if (xs.length < 2) return 0;
    final m = _mean(xs);
    final v = xs.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / (xs.length - 1);
    return math.sqrt(v);
  }
}
