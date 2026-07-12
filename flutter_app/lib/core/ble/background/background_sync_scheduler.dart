/// Registration + main-isolate wiring for the WorkManager killed-app WHOOP sync.
///
/// This is the MAIN-isolate half of the killed-app sync (the headless half lives in
/// `background_sync_worker.dart`). It:
///   • initialises WorkManager with the headless [callbackDispatcher],
///   • registers/cancels the single periodic sync job ([registerBackgroundSyncWork] /
///     [cancelBackgroundSyncWork]),
///   • runs the app-alive heartbeat ([startForegroundHeartbeat]) that the headless task reads to
///     decide whether to skip (the concurrency guard — see the worker's doc comment).
///
/// Everything is a strict no-op off Android (desktop/web/iOS) and, because `main()` is the only
/// caller and tests never call `main()`, none of it runs under `flutter test`.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/db/database.dart';
import '../../state/providers.dart' show databaseProvider;
import '../transport/whoop_providers.dart' show readPairedStrap;
import 'background_sync_service.dart' show backgroundSyncEnabledProvider;
import 'background_sync_worker.dart';

/// Android's periodic-work minimum is 15 minutes; anything lower is clamped to it by the OS.
const Duration _kSyncFrequency = Duration(minutes: 15);

/// Only Android has a killed-app periodic path we can trust. iOS BGTaskScheduler is best-effort
/// and unreliable for BLE offload (see the worker doc), so we do not register periodic work there.
bool get _supported => !kIsWeb && Platform.isAndroid;

Timer? _heartbeatTimer;
bool _wmInitialised = false;

/// From `main()`: initialise WorkManager and register the periodic killed-app sync when everything
/// lines up — Android + a strap remembered + background sync enabled — and start the app-alive
/// heartbeat so the headless task skips while this process is alive. A strict no-op otherwise.
/// Safe to `unawaited(...)`; never throws.
Future<void> maybeRegisterBackgroundSyncWork(ProviderContainer container) async {
  if (!_supported) return;
  if (readPairedStrap() == null) return; // nothing to sync
  if (!container.read(backgroundSyncEnabledProvider)) return; // user opt-out

  // Heartbeat: stamp liveness now + every ~60s for as long as this process lives, so the headless
  // task's guard sees a fresh beat and skips (this main isolate already owns BLE).
  startForegroundHeartbeat(container.read(databaseProvider));

  try {
    await _ensureWorkManagerInitialised();
    await registerBackgroundSyncWork();
  } catch (e, st) {
    debugPrint('maybeRegisterBackgroundSyncWork failed: $e\n$st');
  }
}

Future<void> _ensureWorkManagerInitialised() async {
  if (_wmInitialised) return;
  await Workmanager().initialize(callbackDispatcher);
  _wmInitialised = true;
}

/// Register (or refresh) the single periodic sync job. Idempotent: [ExistingPeriodicWorkPolicy.keep]
/// leaves an already-scheduled job untouched (preserving its timing) rather than resetting the
/// clock every launch. Constraints: `requiresBatteryNotLow` keeps the OS from waking us on a
/// critical battery (there is no WorkManager "requires Bluetooth" constraint — the worker checks
/// the adapter at runtime instead). No network constraint: an offload is pure BLE.
Future<void> registerBackgroundSyncWork() async {
  if (!_supported) return;
  await _ensureWorkManagerInitialised();
  await Workmanager().registerPeriodicTask(
    kBgSyncUniqueName,
    kBgSyncTaskName,
    frequency: _kSyncFrequency,
    constraints: Constraints(
      networkType: NetworkType.notRequired,
      requiresBatteryNotLow: true,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

/// Cancel the periodic sync job and stop the heartbeat. Call when the user disables background sync
/// or unpairs the strap. No-op off Android.
Future<void> cancelBackgroundSyncWork() async {
  stopForegroundHeartbeat();
  if (!_supported) return;
  try {
    await Workmanager().cancelByUniqueName(kBgSyncUniqueName);
  } catch (e) {
    debugPrint('cancelBackgroundSyncWork failed: $e');
  }
}

/// Start (or restart) the main-isolate liveness heartbeat: write it once immediately, then every
/// ~60s. The headless WorkManager task reads this to skip while the app process is alive (the
/// concurrency guard). No-op off Android. Idempotent — cancels any prior timer first.
void startForegroundHeartbeat(AppDatabase db) {
  if (!_supported) return;
  _heartbeatTimer?.cancel();
  unawaited(writeAppAliveHeartbeat(db));
  _heartbeatTimer = Timer.periodic(
    const Duration(seconds: 60),
    (_) => unawaited(writeAppAliveHeartbeat(db)),
  );
}

/// Stop the liveness heartbeat (lets its timestamp go stale so the headless task may take over).
void stopForegroundHeartbeat() {
  _heartbeatTimer?.cancel();
  _heartbeatTimer = null;
}
