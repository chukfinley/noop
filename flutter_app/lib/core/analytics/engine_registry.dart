import 'package:noop/core/analytics/engine.dart';
import 'package:noop/core/analytics/noop_engine.dart';
import 'package:noop/core/analytics/openstrap/openstrap_engine.dart';

/// Every analysis engine the app ships, in display order. The FIRST entry is the
/// default when no preference is stored (and the fallback when a stored engine id
/// no longer exists). All of them run over the same raw sync — see [LiveRepository].
const List<AnalysisEngine> engineRegistry = <AnalysisEngine>[
  NoopEngine(),
  OpenStrapEngine(),
];

/// The default engine id — the first registered engine.
String get defaultEngineId => engineRegistry.first.id;

/// Look an engine up by id, falling back to the default when unknown.
AnalysisEngine engineById(String? id) {
  for (final e in engineRegistry) {
    if (e.id == id) return e;
  }
  return engineRegistry.first;
}
