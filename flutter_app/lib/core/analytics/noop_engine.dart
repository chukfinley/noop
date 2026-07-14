import 'package:noop/core/analytics/daily_pipeline.dart';
import 'package:noop/core/analytics/engine.dart';
import 'package:noop/core/analytics/raw_samples.dart';
import 'package:noop/core/data/models.dart';
import 'package:noop/core/state/prefs.dart' show HrvWindow;

/// Our own algorithm — the ported Kotlin analytics ([DailyPipeline]): RMSSD HRV,
/// robust resting HR, Edwards-TRIMP strain, EWMA personal baselines, recovery
/// model, strap-`sleep_state`-anchored sleep staging. This is the default engine.
class NoopEngine extends AnalysisEngine {
  const NoopEngine();

  @override
  String get id => 'noop';

  @override
  String get displayName => 'NOOP';

  @override
  String get blurb => 'Our own model — WHOOP-style recovery, HRV & strain.';

  @override
  List<DayRecord> analyze(
    List<RawDay> days,
    UserProfile profile, {
    HrvWindow hrvWindow = HrvWindow.wholeNight,
  }) =>
      DailyPipeline(profile, hrvWindow: hrvWindow).run(days);
}
