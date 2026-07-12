/// Riverpod wiring for the LIVE-HR re-broadcaster (Wave E1).
///
/// INERT UNTIL ENABLED: the broadcaster is constructed lazily and touches no radio at
/// construction. Nothing advertises until [hrBroadcastEnabledProvider] flips to true, so
/// the existing widget/smoke tests (MockRepository, no device) stay green. When the
/// toggle is on, the broadcaster is start()ed and each [liveHrProvider] sample is
/// forwarded via `notify`; when off it stop()s.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../transport/whoop_providers.dart' show liveHrProvider;
import 'hr_broadcaster.dart';

/// The user toggle: "Broadcast heart rate". OFF by default. Persisted/consumed by the
/// device settings screen (a sibling agent redesigns that screen and imports THIS name).
final hrBroadcastEnabledProvider = StateProvider<bool>((ref) => false);

/// The [HrBroadcaster] singleton. Pure construction — no radio, no advertising — until
/// [hrBroadcastControllerProvider] drives it in response to the enabled toggle.
final hrBroadcasterProvider = Provider<HrBroadcaster>((ref) {
  final broadcaster = HrBroadcaster();
  ref.onDispose(broadcaster.dispose);
  return broadcaster;
});

/// Reactive glue between the toggle, the live HR stream, and the broadcaster.
///
/// Watching this provider (the device screen does, alongside the toggle) activates the
/// wiring:
///   - toggle true  -> [HrBroadcaster.start] + forward the latest [liveHrProvider] bpm
///     via [HrBroadcaster.update] on every sample;
///   - toggle false -> [HrBroadcaster.stop] (advertising torn down, stale HR cleared).
///
/// Re-runs whenever the toggle or the live bpm changes, so each fresh sample is pushed
/// out to subscribed centrals while enabled, and nothing is pushed while disabled.
final hrBroadcastControllerProvider = Provider<void>((ref) {
  final broadcaster = ref.watch(hrBroadcasterProvider);
  final enabled = ref.watch(hrBroadcastEnabledProvider);
  if (!enabled) {
    broadcaster.stop();
    return;
  }
  // start() is idempotent, so calling it on every re-run while enabled is safe.
  broadcaster.start();
  final bpm = ref.watch(liveHrProvider).valueOrNull;
  broadcaster.update(bpm);
});
