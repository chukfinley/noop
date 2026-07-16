import 'dart:math' as math;

import 'package:noop/core/analytics/daily_pipeline.dart';
import 'package:noop/core/analytics/engine.dart';
import 'package:noop/core/analytics/raw_samples.dart';
import 'package:noop/core/data/models.dart';
import 'package:noop/core/state/prefs.dart' show HrvWindow;

import 'vendor/clinical/hrv_time.dart';
import 'vendor/clinical/readiness_lnrmssd.dart';
import 'vendor/foundations/rr_correction.dart';
import 'vendor/respiration/resp_rate.dart';

/// The OpenStrap analysis engine — the same raw strap stream scored with the
/// (MIT-licensed) `openstrap_analytics` methods instead of our own model:
///
///  * **HRV** — Lipponen–Tarvainen RR-artifact correction ([correctRr]) → robust
///    nocturnal RMSSD (median of cleaned 5-min-window RMSSDs, [nocturnalRmssd]).
///    This rejects ectopic/missed beats our raw RMSSD would swallow, so the HRV
///    number differs from [NoopEngine]'s.
///  * **Respiratory rate** — RSA HF-peak on native beat times (Lomb–Scargle,
///    [rsaRespRate]). Fills a metric NoopEngine leaves as "coming soon".
///  * **Charge (recovery)** — Plews lnRMSSD readiness ([readinessLnRmssd]): a
///    z-score of tonight's ln(RMSSD) against the trailing personal baseline,
///    mapped to 0..100. Needs [readinessLnRmssdMinNights] nights to warm up; the
///    first nights fall back to the shared base recovery so the day still scores.
///
/// Sleep (strap `sleep_state`), day strain, resting HR, the HR thread and stress
/// are taken verbatim from the shared [DailyPipeline] pass — OpenStrap doesn't
/// improve on those given our inputs, so they stay identical across engines.
class OpenStrapEngine extends AnalysisEngine {
  const OpenStrapEngine();

  @override
  String get id => 'openstrap';

  @override
  String get displayName => 'OpenStrap';

  @override
  String get blurb =>
      'Kubios-style RR-cleaned HRV, RSA respiratory rate & Plews readiness.';

  @override
  List<DayRecord> analyze(
    List<RawDay> days,
    UserProfile profile, {
    HrvWindow hrvWindow = HrvWindow.wholeNight,
  }) {
    // Shared scaffolding: sleep window, effort, RHR, HR thread, stress.
    final base = DailyPipeline(profile, hrvWindow: hrvWindow).run(days);
    if (base.isEmpty) return base;

    // Flatten every synced second's RR beats into one chronological stream so a
    // night's window (which straddles midnight) pulls beats from either day.
    //
    // `chronological` records whether the flattened stamps actually came out
    // non-decreasing, which is what lets the per-night window below be found by
    // binary search instead of scanned. Both producers promise it — [RawDay]
    // documents its samples as "oldest → newest", [AnalysisEngine.analyze] takes
    // its days the same way, and the live producer sorts (`_buildDays` walks
    // local midnights in order; `_buildDaySamples` sorts its per-second keys) —
    // but a promise in a doc comment is not the same as a checked fact, and a
    // binary search over an unsorted list does not fail loudly, it silently
    // returns the wrong beats and therefore the wrong HRV. The check is one
    // compare per beat inside a loop that is already O(beats), so verifying costs
    // nothing measurable and removes the need to trust the contract.
    final rrTs = <double>[]; // beat-second (unix seconds) per RR interval
    final rrMsAll = <double>[]; // the RR interval (ms)
    var chronological = true;
    for (final d in days) {
      for (final s in d.samples) {
        final ts = s.ts.toDouble();
        for (final rr in s.rrIntervals) {
          if (rrTs.isNotEmpty && ts < rrTs.last) chronological = false;
          rrTs.add(ts);
          rrMsAll.add(rr);
        }
      }
    }

    final lnHistory = <double>[]; // trailing nightly ln(RMSSD), oldest→newest
    final out = <DayRecord>[];
    for (final rec in base) {
      final sleep = rec.sleep;
      if (sleep == null) {
        out.add(rec);
        continue;
      }
      final startSec = sleep.bedtime.millisecondsSinceEpoch ~/ 1000;
      final endSec = sleep.wake.millisecondsSinceEpoch ~/ 1000;

      // RR beats inside this night's window, in order.
      //
      // This used to scan the WHOLE flattened stream once per night, which made
      // the selection quadratic in history: every night re-walked every beat the
      // strap has ever synced, though each keeps only its own ~8 h of them.
      // Measured on synthetic days at offload density (one beat per second across
      // an 8 h night), the select loop alone — no correction, no Lomb-Scargle:
      //
      //   history   beats     iterations   scan      binary search
      //    7 days   0.20 M      1.4 M        17 ms     2 ms
      //   30 days   0.86 M     25.9 M       248 ms     2 ms
      //   60 days   1.73 M    103.7 M      1176 ms     8 ms
      //   90 days   2.59 M    233.3 M      3441 ms    15 ms   (229x)
      //
      // On a non-decreasing stream the window is a CONTIGUOUS run, so its ends are
      // a binary search and the beats are the slice between them: the same set in
      // the same order — `rrTs[i] >= startSec` holds precisely for
      // `i >= lowerBound(startSec)` and `rrTs[i] < endSec` precisely for
      // `i < lowerBound(endSec)`, both because the stamps only climb. The beats
      // handed to [correctRr] are byte-identical, so every score is unchanged.
      // Pinned by test/analytics/openstrap_window_equivalence_test.dart.
      //
      // Be clear about what this does NOT fix, because a "229x" flatters it badly
      // out of context: this loop was never why the engine is slow. The VENDORED
      // per-night math dwarfs it — on the same input, ONE night costs ~3.8 s:
      // [rsaRespRate] 3066 ms (Lomb-Scargle over three frequency grids, 300 + 450
      // + 700, against all ~28.8 k of the night's beats — ~42 M evaluations),
      // [correctRr] 720 ms, [nocturnalRmssd] 7 ms. End to end `analyze` measured
      // 21.5 s at 7 days and 80 s at 30, against which this loop's 17 ms / 248 ms
      // is inside the noise: the before/after full-engine runs differ by ~5 % in
      // BOTH directions, so at real history sizes the win is unmeasurable. It is
      // kept because it is free and because it is the only term that grows
      // SUPER-linearly — everything else is linear in nights, so the scan is what
      // would eventually dominate a multi-year store.
      //
      // The cost that actually matters is [rsaRespRate], and it is not fixable
      // here: making it cheap means shortening the RSA analysis window or thinning
      // the grid, which changes the reported respiratory rate. That is a
      // correctness decision, it lives in `vendor/`, and it is deliberately not
      // smuggled in behind a performance patch. Until then, selecting this engine
      // on a large store costs minutes per load — which is exactly why the reload
      // metering in main.dart derives its cooldown from the MEASURED load time
      // rather than a constant.
      //
      // If the stamps did NOT come out sorted we keep the old scan rather than
      // sort them: a stable sort by stamp would reorder beats within a second
      // relative to what the scan produced, and [correctRr] is order-sensitive,
      // so "fixing" the order would quietly change the HRV of the very input we
      // could not vouch for. Slow and identical beats fast and different.
      final List<double> rr;
      if (chronological) {
        final lo = _lowerBound(rrTs, startSec.toDouble());
        final hi = _lowerBound(rrTs, endSec.toDouble());
        // `hi < lo` is unreachable for a well-formed night (wake after bedtime)
        // but `sublist` throws on it where the scan simply selected nothing, so
        // the empty case is spelled out rather than left to chance.
        rr = hi > lo ? rrMsAll.sublist(lo, hi) : <double>[];
      } else {
        rr = <double>[];
        for (var i = 0; i < rrTs.length; i++) {
          if (rrTs[i] >= startSec && rrTs[i] < endSec) rr.add(rrMsAll[i]);
        }
      }
      if (rr.length < 20) {
        out.add(rec);
        continue;
      }

      // Lipponen–Tarvainen artifact correction → cleaned NN + beat times.
      final corr = correctRr(rr);
      if (corr.nn.length < 6) {
        out.add(rec);
        continue;
      }

      // Robust nocturnal RMSSD (median of 5-min-window RMSSDs on cleaned NN).
      final hrvM = nocturnalRmssd(corr.nn, corr.nnTimesMs);
      final rmssd = hrvM.value;

      // RSA respiratory rate (Lomb–Scargle HF-peak).
      final respM = rsaRespRate(
        corr.nn,
        corr.nnTimesMs,
        artifactFraction: 1 - corr.cleanFraction,
      );
      final resp = respM.value?.brpm;

      // Plews lnRMSSD readiness → charge. Baseline must exclude tonight, so push
      // tonight before calling (the vendored fn takes tonight as the last item).
      double? charge;
      if (rmssd != null && rmssd > 0) {
        lnHistory.add(math.log(rmssd));
        final meanNn = corr.nn.reduce((a, b) => a + b) / corr.nn.length;
        final readyM = readinessLnRmssd(lnHistory, meanNnTodayMs: meanNn);
        final z = readyM.value?.z;
        if (z != null) {
          // z≈0 → baseline recovery (~50); ±2 SD spans most of the 0..100 range.
          charge = (50 + 22 * z).clamp(1.0, 99.0);
        }
      }

      out.add(rec.copyWith(
        hrv: rmssd, // null → keep base HRV
        respiratoryRate: resp, // null → keep base (coming-soon 0)
        charge: charge, // null (warm-up) → keep base recovery
      ));
    }
    return out;
  }
}

/// Index of the first element of the NON-DECREASING [xs] that is `>= target`
/// (`xs.length` when every element is smaller) — the standard lower bound.
///
/// Duplicates matter here and are handled by construction: a synced second can
/// carry up to three RR beats, which flatten to three entries with the SAME
/// stamp. Lower bound lands on the first of an equal run, so a window
/// `[lowerBound(start), lowerBound(end))` takes either all of a second's beats or
/// none of them — never a partial second, which is what a naive "find any match"
/// binary search would give.
int _lowerBound(List<double> xs, double target) {
  var lo = 0;
  var hi = xs.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (xs[mid] < target) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}
