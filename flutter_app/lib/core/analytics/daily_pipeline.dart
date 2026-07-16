import 'dart:math' as math;

import 'package:noop/core/data/models.dart';
import 'package:noop/core/state/prefs.dart' show HrvWindow;
import 'package:noop/core/analytics/baselines.dart';
import 'package:noop/core/analytics/charge_terms.dart';
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
  DailyPipeline(
    this.profile, {
    this.hrvWindow = HrvWindow.wholeNight,
    this.experimentalChargeTerms = false,
  });

  final UserProfile profile;

  /// Fold the two experimental Oura-Readiness-style Charge terms (#417/#436) into Charge:
  /// the Recovery-Index overnight HR-decline slope and the Activity-Balance previous-day
  /// Effort term (see [ChargeTerms]).
  ///
  /// DEFAULT FALSE, and nothing in the shipping app sets it — [NoopEngine] does not pass it, so
  /// only tests do. That is upstream's state too: v9.0.0 puts the same three signals on
  /// `RecoveryScorer.recovery(...)` as null-default parameters and ships no production caller
  /// that supplies them ("dormant until a caller supplies them"). Off, every term drops and the
  /// weights renormalize, so Charge is byte-identical to before this flag existed — the exact
  /// invariant upstream's own tests pin, and the one `charge_terms_wiring_test.dart` pins here.
  ///
  /// Do NOT flip this default without reading the "BEFORE TURNING IT ON" block in
  /// `charge_terms.dart`: the Recovery-Index term is uncentered (neutral at a flat overnight HR,
  /// which is not a typical night), so switching it on shifts the flagship Charge upward for
  /// everyone rather than only discriminating good nights from bad.
  final bool experimentalChargeTerms;

  /// Which sleep window nightly HRV is scored over (ryanbr #141). Fixed for the
  /// life of the pipeline — the setting is read once at construction, so a
  /// change re-scores on the next launch (like WHOOP re-anchoring over a few
  /// nights), never mid-run.
  final HrvWindow hrvWindow;

  final BaselineState _hrvBase = BaselineState();
  final BaselineState _rhrBase = BaselineState();
  final BaselineState _respBase = BaselineState();

  /// Personal EWMA baseline of daily Effort — the `'strain'` metric ([strainCfg]) the
  /// Activity-Balance term z-scores against (#436).
  final BaselineState _effortBase = BaselineState();

  /// The previously scored day's Effort, and that day's calendar ordinal.
  ///
  /// Kept as a PAIR because the term is "previous DAY activity": an Effort value alone can't tell
  /// us whether it came from yesterday or from a scored day a fortnight ago (this pipeline skips
  /// no-wear days entirely, so "the last day we scored" is routinely not "yesterday"). The
  /// ordinal lets [_adjacentPriorEffort] drop the term across a gap instead of passing a stale
  /// load off as yesterday's — see the honesty rules: a term with no real input stays null.
  double? _prevDayEffort;
  int? _prevDayIndex;

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
    double? riSlope;
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

      // Recovery-Index slope (#417): the least-squares trend of the SAME 5-minute HR bin means
      // `restingHR` reads as a floor, across the in-bed window. Only computed when the terms are
      // on — it is pure work with no other consumer. Stays null on a night too short to fit a
      // trend (< `ChargeTerms.recoveryIndexMinBins` populated bins), which drops the term.
      if (experimentalChargeTerms) {
        riSlope =
            ChargeTerms.recoveryIndexSlope(tsHr, bpm, sleep.startTs, sleep.endTs);
      }
    }

    // ── Baselines: score against history, THEN fold tonight in ────────────────
    final hrvUsable = _hrvBase.usable;
    // Captured PRE-fold, next to `hrvUsable`, because it answers the same
    // question: was the baseline still seeding at the moment we scored? That —
    // not the post-fold state — is what decides whether tonight is "calibrating"
    // (see the reason block below).
    final hrvSeeding = _hrvBase.status == BaselineStatus.calibrating;
    final rhrBaseline = _rhrBase.usable ? DriverBaseline.of(_rhrBase) : null;
    final respBaseline = _respBase.usable ? DriverBaseline.of(_respBase) : null;
    final respTerm = resp != null && respBaseline != null;
    final baseRecovery = (hrv != null && rhr != null)
        ? RecoveryScorer.recovery(
            hrv: hrv,
            rhr: rhr.toDouble(),
            resp: resp,
            hrvBaseline: DriverBaseline.of(_hrvBase),
            rhrBaseline: rhrBaseline,
            respBaseline: respBaseline,
            sleepPerf: sleepPerf,
            hrvBaselineUsable: hrvUsable,
          )
        : null;

    // ── Experimental Charge terms (#417/#436) — DEFAULT OFF ───────────────────
    // Upstream folds these into `recovery(...)` itself as null-default parameters. We can't:
    // the renormalizing `terms` loop lives inside `recovery(...)` and `recovery_scorer.dart` is
    // not ours to change, so we go through `ChargeTerms.foldInto`, which inverts the logistic
    // back to the composite z, re-weights it with the new terms and re-squashes. That is
    // ALGEBRAICALLY identical to upstream's in-loop fold provided `baseWeight` is the total
    // weight of the terms that actually produced `baseRecovery` — hence `_baseWeight` mirroring
    // the gating just above, and the wiring test that pins the two in step.
    //
    // With the flag off all three inputs are null, `foldInto` short-circuits, and Charge is
    // byte-identical to before — upstream's own pinned invariant.
    final recoveryVal = ChargeTerms.foldInto(
      baseScore: baseRecovery,
      baseWeight: _baseWeight(
        rhrTerm: rhrBaseline != null,
        respTerm: respTerm,
        sleepTerm: sleepPerf != null,
      ),
      recoveryIndexSlopeValue: riSlope,
      priorDayEffort:
          experimentalChargeTerms ? _adjacentPriorEffort(day.date) : null,
      effortBaseline: experimentalChargeTerms && _effortBase.usable
          ? DriverBaseline.of(_effortBase)
          : null,
    );
    // When recovery does not score, `charge` still carries the population mean so
    // downstream numeric fields stay finite — but it is NOT a score and the UI
    // must never render it as one (the fake 58 removed in 2a2eb326).
    final charge = recoveryVal ?? engines.recoveryPopulationMean;

    if (hrv != null) Baselines.update(_hrvBase, 'hrv', hrv);
    if (rhr != null) Baselines.update(_rhrBase, 'resting_hr', rhr.toDouble());
    if (resp != null) Baselines.update(_respBase, 'resp', resp);

    // ── WHY recovery did not score — read AFTER the fold ──────────────────────
    // Recovery is HRV-baseline-dominant, and it can fail to score for two very
    // different reasons. Collapsing them into one "calibrating" state lies to a
    // calibrated wearer, so the reason travels with the record:
    //
    //   * SEEDING — the baseline had not yet reached the seed gate when we
    //     scored ⇒ honest "Calibrating N/4 nights".
    //   * NO DATA — the baseline was ready (or has gone stale), but tonight
    //     produced no usable HRV/RHR: sparse RR (RMSSD needs >= 20 clean beats),
    //     no sleep window, or the strap was not worn. Nothing is calibrating and
    //     nothing is scoreable — say exactly that.
    //
    // Gating on the PRE-fold `hrvSeeding` is what fixes the reported defect: the
    // old code flagged EVERY unscored night as calibrating and reported
    // `min(4, nValid + (hrv != null ? 1 : 0))`, so a fully-calibrated wearer
    // (nValid = 30) with one sparse-RR night read "CALIBRATING 4/4" behind an
    // empty gauge — and a STALE baseline (nValid >= 14, no fold for 14+ nights)
    // read the same. The `min` did not clamp a rounding wart; it MASKED a
    // 30-vs-4 over-statement. Upstream's helper guards the same way (n >= seed
    // → nil).
    //
    // The count is now the authoritative POST-fold `nValid`, never the old
    // `+ 1` PREDICTION of a fold that the bounds gate may refuse — HRV outside
    // 5..250 ms is seen but never folded, so the prediction over-stated N by one
    // on exactly the nights a wearer would most question the number.
    //
    // No clamp is needed and none is used: `hrvSeeding` implies nValid <= 3
    // pre-fold (Baselines.update leaves `calibrating` only below the gate), so
    // the post-fold count is <= 4 by construction. A clamp here would hide a
    // broken invariant rather than surface it; the tests pin it instead.
    final chargeCalibrationNights =
        (recoveryVal == null && hrvSeeding) ? _hrvBase.nValid : null;
    final chargeNoData = recoveryVal == null && !hrvSeeding;

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

    // ── Effort baseline + previous-day carry (#436) ───────────────────────────
    // Deliberately LAGGED by one day: we fold the PREVIOUS day's Effort here, not today's. This
    // is the same "score against history, THEN fold tonight in" order the HRV/RHR/resp baselines
    // use above, applied to the value this term actually z-scores. The value being scored on day
    // N is Effort(N−1), so the baseline it is scored against must cover days 1..N−2 — folding
    // Effort(N−1) before scoring day N would put the value inside its own EWMA mean and pull the
    // z toward 0 (by ~5% at the settled half-life, ~20% during the young-phase adaptation),
    // silently damping exactly the hard-day signal the term exists to carry.
    //
    // The fold is unconditional — not gated on the flag — so `_effortBase` holds the same history
    // either way and switching the flag on can never depend on how long it has been off. It folds
    // EVERY scored day (gaps included, which the EWMA handles via nightsSinceUpdate); only the
    // TERM demands calendar adjacency, in `_adjacentPriorEffort`.
    final prevEffort = _prevDayEffort;
    if (prevEffort != null) {
      Baselines.update(_effortBase, strainMetricKey, prevEffort);
    }
    _prevDayEffort = effort;
    _prevDayIndex = _calendarDayIndex(day.date);

    return DayRecord(
      date: day.date,
      charge: _r1(charge),
      chargeCalibrationNights: chargeCalibrationNights,
      chargeNoData: chargeNoData,
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

  /// The total weight of the terms [RecoveryScorer.recovery] ACTUALLY used for this night — the
  /// `baseWeight` [ChargeTerms.foldInto] needs to recover the composite z from the score.
  ///
  /// This mirrors the term gating at the call site, which is the one fragile seam in going through
  /// `foldInto` instead of upstream's in-loop fold: if `recovery(...)` ever gains or re-gates a
  /// term, this must follow, or the re-weighting silently uses the wrong denominator. The wiring
  /// test pins the mirror by driving the pipeline itself rather than trusting this arithmetic.
  static double _baseWeight({
    required bool rhrTerm,
    required bool respTerm,
    required bool sleepTerm,
  }) {
    // The HRV term is unconditional here: this pipeline always passes a non-null hrvBaseline, and
    // `recovery(...)` refuses to score at all unless the HRV baseline is usable.
    var w = RecoveryScorer.wHRV;
    if (rhrTerm) w += RecoveryScorer.wRHR;
    if (respTerm) w += RecoveryScorer.wResp;
    if (sleepTerm) w += RecoveryScorer.wSleep;
    // wSkinTemp never enters: this pipeline never supplies skinTempDev (no temp channel in the
    // capture — see `skinTempDelta: 0` / "coming soon" below).
    return w;
  }

  /// The previously scored day's Effort, but ONLY when that day really was YESTERDAY.
  ///
  /// Returns null across a gap, which drops the Activity-Balance term and renormalizes the
  /// weights. That is the honest outcome: the term means "previous DAY activity", so after a
  /// week of no wear, the last Effort we happen to hold is not yesterday's training load, and
  /// feeding it in as though it were would fabricate a relationship the data never carried.
  double? _adjacentPriorEffort(DateTime date) {
    final prevIndex = _prevDayIndex;
    final prevEffort = _prevDayEffort;
    if (prevIndex == null || prevEffort == null) return null;
    return _calendarDayIndex(date) - prevIndex == 1 ? prevEffort : null;
  }

  /// A calendar-day ordinal for a [RawDay.date] (local midnight).
  ///
  /// Re-homed onto UTC before differencing ON PURPOSE: two consecutive local midnights are 23 or
  /// 25 hours apart across a DST transition, so differencing the local instants would read
  /// consecutive days as non-adjacent (or a `Duration.inDays` truncation would read them as 0)
  /// exactly twice a year. Only the Y/M/D fields carry meaning here, so normalizing them to UTC
  /// makes adjacency exact everywhere.
  static int _calendarDayIndex(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

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
      // Confidence only (#345) — the stages and totals above are untouched.
      motionSparse: sr.motionSparse,
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
    // sampled epochs) so a still wrist maps to ≈0 and the stager measures motion
    // against the night's own level. Epochs with no samples stay NULL — see the
    // channel's contract in [SleepStager.detect]; "unknown" is not a magnitude.
    final rawMotion = <double?>[];
    for (var b = 0; b < nBins; b++) {
      rawMotion.add(cntMv[b] > 0 ? sumMv[b] / cntMv[b] : null);
    }
    final sampled = rawMotion.whereType<double>().toList()..sort();
    final quiet = sampled.isEmpty ? 0.0 : _percentile(sampled, 10);

    final ts = <int>[];
    final hr = <double?>[];
    final mv = <double?>[];
    // Per-epoch strap asleep verdict: majority of the bin's stateful samples say
    // asleep. A bin with no state sample (a gap) counts as awake, so gaps can't
    // extend a night. Null overall when the day has no strap sleep_state at all.
    final asleep = anyState ? List<bool>.filled(nBins, false) : null;
    for (var b = 0; b < nBins; b++) {
      ts.add(start + b * e);
      final hasHr = cntHr[b] > 0;
      hr.add(hasHr ? sumHr[b] / cntHr[b] : null);
      final m = rawMotion[b];
      // No samples at all → NULL, never a magnitude. This epoch's motion is
      // unknown, and [SleepStager]'s channel is night-relative by contract, so a
      // stand-in value does not stay local to its own epoch: it moves the median
      // + MAD every OTHER epoch is judged against. The 5.0 "forced non-still"
      // sentinel this replaces did exactly that — past ~half the window it
      // dragged the median up to itself, pushed every genuinely still epoch
      // outside the quiescent gate, and inverted the #462 motion corroboration
      // into scoring ordinary overnight HR excursions as awakenings (measured:
      // 48 phantom disturbances on a still night the strap called asleep
      // throughout; see `sleep_motion_sparsity_test.dart`). Its stated purpose —
      // stopping empty epochs being mistaken for sleep — was never served by it
      // either: an epoch with no samples has no HR, and the stager's `sleepy`
      // gate is HR/strap-driven, so a sample-less epoch cannot enter a window on
      // its own account regardless of what we put here.
      mv.add(m == null ? null : math.max(0.0, m - quiet));
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

  /// Per-epoch motion magnitude, NULL where the epoch carried no sample — the
  /// contract [SleepStager.detect] documents. Never a sentinel magnitude.
  final List<double?> mv;

  /// Per-epoch strap-reported asleep mask (#175), or null when this day carries
  /// no strap sleep_state (the stager then uses its HR heuristic).
  final List<bool>? asleep;
  _Epochs(this.ts, this.hr, this.mv, this.asleep);
}
