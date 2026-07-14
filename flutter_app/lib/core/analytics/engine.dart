import 'package:noop/core/analytics/raw_samples.dart';
import 'package:noop/core/data/models.dart';
import 'package:noop/core/state/prefs.dart' show HrvWindow;

/// A pluggable analysis engine: one algorithm family that scores the SAME raw
/// per-day sensor stream ([RawDay]) into the app-wide [DayRecord] spine.
///
/// The app can hold several engines at once (see [engineRegistry]). They all run
/// over the identical raw data — nothing is deleted or re-synced — and each
/// produces its own set of scored days. The UI picks which engine's scores to
/// show via `selectedEngineProvider`, so the user can flip between algorithms
/// (our own [NoopEngine], the ported OpenStrapEngine, …) with no re-analysis.
abstract class AnalysisEngine {
  const AnalysisEngine();

  /// Stable identifier, persisted as the user's chosen engine. Never rename an
  /// existing id — a stored preference points at it.
  String get id;

  /// Human-facing name shown in the engine switcher.
  String get displayName;

  /// One-line description of what makes this algorithm different.
  String get blurb;

  /// Score every day oldest → newest. MUST be pure: same raw input → same
  /// output, no I/O, no shared mutable state between calls (so all engines can
  /// run over one snapshot independently).
  List<DayRecord> analyze(
    List<RawDay> days,
    UserProfile profile, {
    HrvWindow hrvWindow = HrvWindow.wholeNight,
  });
}
