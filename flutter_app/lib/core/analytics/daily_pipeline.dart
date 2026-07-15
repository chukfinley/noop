import 'dart:math' as math;

import 'package:noop/core/data/models.dart';
import 'package:noop/core/state/prefs.dart' show HrvWindow;
import 'package:noop/core/analytics/baselines.dart';
import 'package:noop/core/analytics/engines.dart' as engines;
import 'package:noop/core/analytics/hrv_analyzer.dart';
import 'package:noop/core/analytics/raw_samples.dart';
import 'package:noop/core/analytics/recovery_scorer.dart';
import 'package:noop/core/analytics/sleep_stager.dart';
import 'package:noop/core/analytics/strain_scorer.dart';

/// Turns one local day of raw strap samples into a scored [DayRecord] by running
/// the ported NOOP analytics — the same pipeline the Kotlin app runs nightly:
///
///   raw per-second HR/RR/accel/SpO2
///     → sleep window + stages          ([SleepStager])
///     → resting HR over the window      ([RecoveryScorer.restingHRRobust])
///     → RMSSD HRV over the window        ([HrvAnalyzer])
///     → personal baselines               ([Baselines])
///     → Charge / Effort / Rest / Stress  ([RecoveryScorer]/[StrainScorer]/engines)
///
/// State (baselines + trailing histories) persists across days, so day N is
/// scored against the wearer's history up to day N-1, exactly like the real app.
class DailyPipeline {
  DailyPipeline(this.profile, {this.hrvWindow = HrvWindow.wholeNight});

  final UserProfile profile;

  /// Which sleep window nightly HRV is scored over (ryanbr #141). Fixed for the
  /// life of the pipeline — the setting is read once at construction, so a
  /// change re-scores on the next launch (like WHOOP re-anchoring over a few
  /// nights), never mid-run.
  final HrvWindow hrvWindow;

  final BaselineState _hrvBase = BaselineState();
  final BaselineState _rhrBase = BaselineState();
  final BaselineState _respBase = BaselineState();

  final List<double> _rhrHist = [];
  final List<double> _hrvHist = [];
  final List<double> _sleepMinHist = [];

  /// Process every day oldest → newest; skips days with no HR at all.
  List<DayRecord> run(List<RawDay> days) {
    final out = <DayRecord>[];
    for (final d in days) {
      final rec = _process(d);
      if (rec != null) out.add(rec);
    }
    return out;
  }

  DayRecord? _process(RawDay day) {
    final s = day.samples;
    // Per-sample arrays (valid HR only) for strain + resting HR.
    final tsHr = <int>[];
    final bpm = <double>[];
    for (final r in s) {
      if (r.hr > 0) {
        tsHr.add(r.ts);
        bpm.add(r.hr.toDouble());
      }
    }
    if (bpm.length < 60) return null; // essentially no wear this day

    final dayHrMin = _percentile(List<double>.from(bpm)..sort(), 5);

    // 30-second epochs across the day span (contiguous; null HR where missing).
    final epochs = _buildEpochs(s);

    final sleep = SleepStager.detect(
      epochTs: epochs.ts,
      epochHr: epochs.hr,
      epochMovement: epochs.mv,
      dayHrMin: dayHrMin,
      // Strap-reported per-epoch asleep mask (#175) when this day carries the
      // band's own sleep_state — its ground truth drives the window, so a day the
      // wearer never slept yields no sleep at all. Null → HR-heuristic fallback.
      epochAsleep: epochs.asleep,
    );

    // ── Nightly physiology from the sleep window ──────────────────────────────
    double? hrv, resp;
    double? sleepPerf;
    int? rhr;
    double sleepSpo2 = 0;
    SleepRecord? sleepRecord;

    if (sleep != null) {
      rhr = RecoveryScorer.restingHRRobust(tsHr, bpm, sleep.startTs, sleep.endTs) ??
          RecoveryScorer.restingHR(tsHr, bpm, sleep.startTs, sleep.endTs);

      // RMSSD over the real beat-to-beat RR intervals inside the window.
      // With the deep-sleep window (ryanbr #141) only beats that fall inside a
      // deep (slow-wave) segment count, matching WHOOP's methodology; otherwise
      // the whole sleep window is used.
      final rr = <double>[];
      final deep = hrvWindow == HrvWindow.deepSleep;
      for (final r in s) {
        if (r.ts < sleep.startTs || r.ts > sleep.endTs) continue;
        if (deep && !_inDeepSegment(sleep, r.ts)) continue;
        rr.addAll(r.rrIntervals);
      }
      // Fall back to the whole-night window if the deep window was too sparse
      // to yield a trustworthy reading, so a night is never dropped outright.
      hrv = HrvAnalyzer.analyzeRaw(rr).rmssd;
      if (deep && hrv == null) {
        final all = <double>[];
        for (final r in s) {
          if (r.ts >= sleep.startTs && r.ts <= sleep.endTs) {
            all.addAll(r.rrIntervals);
          }
        }
        hrv = HrvAnalyzer.analyzeRaw(all).rmssd;
      }
      resp = sleep.respRate;
      sleepSpo2 = _windowSpo2(s, sleep.startTs, sleep.endTs);
      sleepPerf = sleep.efficiency;
      sleepRecord = _buildSleepRecord(day, sleep, resp);
    }

    // ── Baselines: score against history, THEN fold tonight in ────────────────
    final hrvUsable = _hrvBase.usable;
    final recoveryVal = (hrv != null && rhr != null)
        ? RecoveryScorer.recovery(
            hrv: hrv,
            rhr: rhr.toDouble(),
            resp: resp,
            hrvBaseline: DriverBaseline.of(_hrvBase),
            rhrBaseline: _rhrBase.usable ? DriverBaseline.of(_rhrBase) : null,
            respBaseline: _respBase.usable ? DriverBaseline.of(_respBase) : null,
            sleepPerf: sleepPerf,
            hrvBaselineUsable: hrvUsable,
          )
        : null;
    // While the HRV baseline is still calibrating (or a day has no scoreable
    // night), recovery is NOT a real score — the app shows a "calibrating
    // N/needed nights" state instead of a fabricated number. `charge` still
    // carries the population mean so downstream numeric fields stay finite, but
    // [DayRecord.chargeCalibrationNights] flags that it must not be shown as a
    // score. Count includes tonight's night if it produced HRV.
    final charge = recoveryVal ?? engines.recoveryPopulationMean;
    final chargeCalibrationNights = recoveryVal != null
        ? null
        : math.min(baselineProvisionalMinNights,
            _hrvBase.nValid + (hrv != null ? 1 : 0));

    if (hrv != null) Baselines.update(_hrvBase, 'hrv', hrv);
    if (rhr != null) Baselines.update(_rhrBase, 'resting_hr', rhr.toDouble());
    if (resp != null) Baselines.update(_respBase, 'resp', resp);

    // ── Effort (day strain, 0..100) over the full day's HR ───────────────────
    final restHrForStrain = (rhr ?? 60).toDouble();
    final maxHr = StrainScorer.tanakaHRmax(profile.age.toDouble());
    final effort = StrainScorer.strain(
          tsSec: tsHr,
          bpm: bpm,
          maxHR: maxHr,
          restingHR: restHrForStrain,
        ) ??
        0;

    // ── Rest (sleep performance 0..100) from real stages ─────────────────────
    double rest = 0;
    if (sleep != null && sleep.asleepSec > 0) {
      final needMin = engines.sleepNeedMin(null, _sleepMinHist);
      rest = engines.restScore(
            asleepSec: sleep.asleepSec.toDouble(),
            needSec: needMin * 60,
            efficiency01: sleep.efficiency,
            deepSec: sleep.deepSec.toDouble(),
            remSec: sleep.remSec.toDouble(),
            consistency01: 0.7,
          ) ??
          0;
    }

    // ── Stress (0..100) from trailing baselines ──────────────────────────────
    double stress100 = 0;
    if (_rhrHist.length >= 7 && _hrvHist.length >= 7 && rhr != null && hrv != null) {
      final w = math.min(30, math.min(_rhrHist.length, _hrvHist.length));
      final rh = _rhrHist.sublist(_rhrHist.length - w);
      final hv = _hrvHist.sublist(_hrvHist.length - w);
      final stress = engines.stressScore(
        todayRhr: rhr.toDouble(),
        meanRhr: _mean(rh),
        sdRhr: _sd(rh),
        todayHrv: hrv,
        meanHrv: _mean(hv),
        sdHrv: _sd(hv),
      );
      stress100 = (stress / 3 * 100).clamp(0, 100).toDouble();
    }

    // Update trailing histories AFTER stress (which needs history-excluding-today).
    if (rhr != null) _rhrHist.add(rhr.toDouble());
    if (hrv != null) _hrvHist.add(hrv);
    if (sleep != null) _sleepMinHist.add(sleep.asleepSec / 60.0);

    return DayRecord(
      date: day.date,
      charge: _r1(charge),
      chargeCalibrationNights: chargeCalibrationNights,
      effort: _r1(effort),
      rest: _r1(rest),
      stress: _r1(stress100),
      hrv: _r1(hrv ?? 0),
      rhr: (rhr ?? 0).toDouble(),
      respiratoryRate: _r1(resp ?? 0),
      skinTempDelta: 0, // no temp channel in capture → "coming soon" in UI
      spo2: _r1(sleepSpo2),
      steps: 0, // no source → coming soon
      calories: 0, // no source → coming soon
      fitnessAge: 0, // no source → coming soon
      vitality: charge.clamp(0, 100).round(),
      hydration: 0, // no source → coming soon
      sleep: sleepRecord,
      workouts: const [],
      hr: _buildHrThread(tsHr, bpm),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  /// Whether unix-second [ts] falls inside a deep-stage hypnogram segment.
  static bool _inDeepSegment(SleepResult sr, int ts) {
    for (final seg in sr.hypnogram) {
      if (seg.stage != SleepStageK.deep) continue;
      if (ts >= seg.startTs && ts < seg.startTs + seg.durationSec) return true;
    }
    return false;
  }

  SleepRecord _buildSleepRecord(RawDay day, SleepResult sr, double? resp) {
    DateTime t(int ts) => DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    final hypnogram = sr.hypnogram
        .map((seg) => StageSegment(
              start: t(seg.startTs),
              duration: Duration(seconds: seg.durationSec),
              stage: _mapStage(seg.stage),
            ))
        .toList();
    // Sleep-timeline series: the real hypnogram sampled as an up/down line
    // (WHOOP-style) — awake highest, then REM, light, deep lowest — so the Sleep
    // screen's timeline traces the night's actual sleep architecture.
    final restlessness = _hypnogramLine(sr);

    return SleepRecord(
      date: day.date,
      bedtime: t(sr.startTs),
      wake: t(sr.endTs),
      timeInBed: Duration(seconds: sr.inBedSec),
      asleep: Duration(seconds: sr.asleepSec),
      deep: Duration(seconds: sr.deepSec),
      rem: Duration(seconds: sr.remSec),
      light: Duration(seconds: sr.lightSec),
      awake: Duration(seconds: sr.awakeSec),
      efficiency: sr.efficiency,
      need: Duration(minutes: engines.sleepNeedMin(null, _sleepMinHist).round()),
      respiratoryRate: resp ?? 0,
      hypnogram: hypnogram,
      restlessness: restlessness,
      disturbances: sr.disturbances,
    );
  }

  /// Sample the hypnogram every 2 minutes into a 0..1 height line
  /// (awake 1.0 · REM 0.75 · light 0.5 · deep 0.2) for the Sleep timeline.
  static List<double> _hypnogramLine(SleepResult sr) {
    double height(SleepStageK s) => switch (s) {
          SleepStageK.awake => 1.0,
          SleepStageK.rem => 0.75,
          SleepStageK.light => 0.5,
          SleepStageK.deep => 0.2,
        };
    if (sr.hypnogram.isEmpty) return const [];
    const step = 120; // seconds
    final out = <double>[];
    var segIdx = 0;
    for (var t = sr.startTs; t < sr.endTs; t += step) {
      while (segIdx < sr.hypnogram.length - 1 &&
          t >= sr.hypnogram[segIdx].startTs + sr.hypnogram[segIdx].durationSec) {
        segIdx++;
      }
      out.add(height(sr.hypnogram[segIdx].stage));
    }
    return out;
  }

  SleepStage _mapStage(SleepStageK k) {
    switch (k) {
      case SleepStageK.awake:
        return SleepStage.awake;
      case SleepStageK.light:
        return SleepStage.light;
      case SleepStageK.deep:
        return SleepStage.deep;
      case SleepStageK.rem:
        return SleepStage.rem;
    }
  }

  /// A ~5-minute-resolution HR thread across the day for the Today chart.
  List<HrSample> _buildHrThread(List<int> ts, List<double> bpm) {
    if (ts.isEmpty) return const [];
    final out = <HrSample>[];
    const binSec = 300;
    var binStart = ts.first - (ts.first % binSec);
    double sum = 0;
    int n = 0;
    for (var i = 0; i < ts.length; i++) {
      if (ts[i] >= binStart + binSec) {
        if (n > 0) {
          out.add(HrSample(
              DateTime.fromMillisecondsSinceEpoch((binStart + binSec ~/ 2) * 1000),
              sum / n));
        }
        binStart = ts[i] - (ts[i] % binSec);
        sum = 0;
        n = 0;
      }
      sum += bpm[i];
      n++;
    }
    if (n > 0) {
      out.add(HrSample(
          DateTime.fromMillisecondsSinceEpoch((binStart + binSec ~/ 2) * 1000), sum / n));
    }
    return out;
  }

  _Epochs _buildEpochs(List<RawSample> s) {
    if (s.isEmpty) return _Epochs([], [], [], null);
    const e = SleepStager.epochSec;
    final start = s.first.ts - (s.first.ts % e);
    final end = s.last.ts;
    final nBins = ((end - start) ~/ e) + 1;
    final sumHr = List<double>.filled(nBins, 0);
    final cntHr = List<int>.filled(nBins, 0);
    final sumMv = List<double>.filled(nBins, 0);
    final cntMv = List<int>.filled(nBins, 0);
    // Strap sleep_state accounting (#175): per bin, how many samples carried a
    // state and how many of those were "asleep" (state != 0). Only used when the
    // day has ANY stateful sample — else the strap channel is absent and the
    // stager falls back to its HR heuristic.
    final asleepCnt = List<int>.filled(nBins, 0);
    final stateCnt = List<int>.filled(nBins, 0);
    var anyState = false;
    for (final r in s) {
      final b = (r.ts - start) ~/ e;
      if (b < 0 || b >= nBins) continue;
      if (r.hr > 0) {
        sumHr[b] += r.hr;
        cntHr[b]++;
      }
      // `movement` is |accel| in g (~1.0 at rest, gravity). Motion is the
      // deviation from that 1 g resting magnitude, so a still wrist ≈ 0.
      sumMv[b] += (r.movement - 1.0).abs();
      cntMv[b]++;
      final st = r.sleepState;
      if (st != null) {
        anyState = true;
        stateCnt[b]++;
        if (st != 0) asleepCnt[b]++;
      }
    }
    // Per-epoch raw motion = mean deviation from the 1 g resting magnitude.
    // The strap's accel scalar is noisy, so an absolute threshold is unreliable;
    // instead we normalize by the day's quiet-baseline (10th percentile of
    // sampled epochs) so a still wrist maps to ≈0 and the stager's fixed
    // thresholds separate rest from motion. Empty epochs (no samples — daytime
    // gaps in the sparse capture) are forced non-still so they can't be mistaken
    // for sleep.
    final rawMotion = <double?>[];
    for (var b = 0; b < nBins; b++) {
      rawMotion.add(cntMv[b] > 0 ? sumMv[b] / cntMv[b] : null);
    }
    final sampled = rawMotion.whereType<double>().toList()..sort();
    final quiet = sampled.isEmpty ? 0.0 : _percentile(sampled, 10);

    final ts = <int>[];
    final hr = <double?>[];
    final mv = <double>[];
    // Per-epoch strap asleep verdict: majority of the bin's stateful samples say
    // asleep. A bin with no state sample (a gap) counts as awake, so gaps can't
    // extend a night. Null overall when the day has no strap sleep_state at all.
    final asleep = anyState ? List<bool>.filled(nBins, false) : null;
    for (var b = 0; b < nBins; b++) {
      ts.add(start + b * e);
      final hasHr = cntHr[b] > 0;
      hr.add(hasHr ? sumHr[b] / cntHr[b] : null);
      final m = rawMotion[b];
      // No samples at all → treat as awake/active (5.0), never a sleep epoch.
      mv.add(m == null ? 5.0 : math.max(0.0, m - quiet));
      if (asleep != null && stateCnt[b] > 0) {
        asleep[b] = asleepCnt[b] * 2 >= stateCnt[b];
      }
    }
    return _Epochs(ts, hr, mv, asleep);
  }

  double _windowSpo2(List<RawSample> s, int start, int end) {
    double sum = 0;
    int n = 0;
    for (final r in s) {
      if (r.ts < start || r.ts > end) continue;
      if (r.spo2 >= 50 && r.spo2 <= 100) {
        sum += r.spo2;
        n++;
      }
    }
    return n > 0 ? sum / n : 0;
  }

  static double _percentile(List<double> sorted, double pct) {
    if (sorted.isEmpty) return 0;
    if (sorted.length == 1) return sorted.first;
    final pos = (pct / 100) * (sorted.length - 1);
    final lo = pos.floor();
    final hi = math.min(lo + 1, sorted.length - 1);
    return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
  }

  static double _mean(List<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

  static double _sd(List<double> xs) {
    if (xs.length < 2) return 0;
    final m = _mean(xs);
    final v = xs.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / (xs.length - 1);
    return math.sqrt(v);
  }

  static double _r1(double v) => double.parse(v.toStringAsFixed(1));
}

class _Epochs {
  final List<int> ts;
  final List<double?> hr;
  final List<double> mv;

  /// Per-epoch strap-reported asleep mask (#175), or null when this day carries
  /// no strap sleep_state (the stager then uses its HR heuristic).
  final List<bool>? asleep;
  _Epochs(this.ts, this.hr, this.mv, this.asleep);
}
