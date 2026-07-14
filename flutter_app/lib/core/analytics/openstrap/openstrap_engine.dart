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
    final rrTs = <double>[]; // beat-second (unix seconds) per RR interval
    final rrMsAll = <double>[]; // the RR interval (ms)
    for (final d in days) {
      for (final s in d.samples) {
        for (final rr in s.rrIntervals) {
          rrTs.add(s.ts.toDouble());
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
      final rr = <double>[];
      for (var i = 0; i < rrTs.length; i++) {
        if (rrTs[i] >= startSec && rrTs[i] < endSec) rr.add(rrMsAll[i]);
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
