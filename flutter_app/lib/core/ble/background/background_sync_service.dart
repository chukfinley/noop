/// Android background WHOOP sync via a persistent foreground service.
///
/// ## Why a foreground service (and the single-owner rule)
/// Android reclaims a backgrounded app's process within seconds unless a foreground service
/// holds it. So the reliable pattern here is **process-liveness**: run a low-key foreground
/// service that keeps the whole app process alive. Because the process stays up, the MAIN
/// isolate — and with it the already-running [WhoopBleClient] that owns the drift database and
/// the live GATT connection — keeps auto-reconnecting and offloading on its own while the app
/// is backgrounded (not swiped away).
///
/// We deliberately do **not** spin up a second BLE client + drift DB in the service's background
/// isolate: two isolates writing one drift file is fragile and corruption-prone. There is exactly
/// ONE owner (the main isolate). The service isolate ([backgroundSyncCallback]) does almost
/// nothing beyond periodic ticks that it forwards to the main isolate; the main isolate is what
/// actually nudges `connectRemembered()` here in [_nudge].
///
/// ## Limitations (documented, not faked)
///  • **App swiped away / killed:** NOT reliably supported in Flutter. Once the OS kills the
///    process the main-isolate client is gone; there is no trustworthy way to run continuous
///    BLE sync from a dead Flutter app. This service only survives *backgrounding*, not a kill.
///  • **iOS:** no equivalent. iOS forbids arbitrary background execution; the app declares the
///    `bluetooth-central` background mode for best-effort connection-event wakeups / state
///    restoration only. This whole controller is a strict no-op off Android.
///  • **Desktop / web / tests:** no-op (guarded by [isSupported]). Tests never call `main()`,
///    and even if they did, [isSupported] is false off Android, so nothing starts.
library;

import 'dart:async' show StreamSubscription, unawaited;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/prefs.dart';
import '../transport/whoop_ble_client.dart'
    show BleConnectionState, SyncProgress, WhoopBleClient;
import '../transport/whoop_providers.dart' show readPairedStrap, whoopBleClientProvider;
import 'background_sync_task_handler.dart';

/// How often the service isolate nudges the main isolate to reconnect/offload.
const int _kNudgeIntervalMs = 5 * 60 * 1000; // 5 minutes

/// Whether background sync is enabled. Persisted via [Prefs.backgroundSyncEnabled]; when the
/// user has never chosen (null), it defaults **ON if a strap is paired** so it "just works".
/// A settings toggle can `read(...notifier).state = v` and persist via
/// [Prefs.setBackgroundSyncEnabled] in a later pass — this file owns the provider.
final backgroundSyncEnabledProvider = StateProvider<bool>((ref) {
  final explicit = Prefs.instance.backgroundSyncEnabled;
  if (explicit != null) return explicit;
  return readPairedStrap() != null;
});

/// The app-lifetime controller. Built from the root container so its provider reads reach the
/// single, shared [whoopBleClientProvider] (the one owner of the live link + DB).
final backgroundSyncServiceProvider =
    Provider<BackgroundSyncService>((ref) => BackgroundSyncService(ref));

/// Starts the Android foreground service when everything lines up: Android + a strap remembered
/// + background sync enabled. A strict no-op otherwise (desktop/web/iOS, nothing paired, disabled,
/// or in tests — which never call `main()`). Safe to `await` from `main()`.
Future<void> maybeStartBackgroundSync(ProviderContainer container) async {
  if (!BackgroundSyncService.isSupported) return;
  if (readPairedStrap() == null) return; // nothing to keep alive
  if (!container.read(backgroundSyncEnabledProvider)) return;
  await container.read(backgroundSyncServiceProvider).start();
}

/// Controls the `flutter_foreground_task` persistent service and relays its periodic ticks into a
/// main-isolate reconnect/offload nudge. All platform calls are guarded behind [isSupported].
class BackgroundSyncService {
  BackgroundSyncService(this._ref);

  final Ref _ref;
  bool _initialized = false;
  bool _callbackAttached = false;

  /// Watches the live offload so the service can DISMISS ITSELF (and its
  /// notification) the moment a sync finishes, instead of hanging a permanent
  /// "syncing" notification forever. Continued background sync after this is
  /// carried by the periodic WorkManager job (registered whenever background
  /// sync is enabled), so stopping the service here loses no data — the next
  /// backgrounding restarts it (see the app-lifecycle observer in main()).
  StreamSubscription<SyncProgress>? _syncSub;

  /// Only auto-stop after we've actually SEEN an offload run this service
  /// session — otherwise a replayed stale `complete` at subscribe time would
  /// tear the service down before it ever synced.
  bool _sawOffloading = false;

  /// Android-only. Off Android/web (desktop, iOS, tests) every method is a no-op.
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Initialise + start the foreground service (idempotent — restarts if already running).
  Future<void> start() async {
    if (!isSupported) return;
    _ensureInitialised();
    _attachCallback();

    // Android 13+ needs POST_NOTIFICATIONS for the service notification; the service still runs
    // without it, so this is best-effort and never blocks the start.
    try {
      final perm = await FlutterForegroundTask.checkNotificationPermission();
      if (perm != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    } catch (e) {
      debugPrint('BackgroundSyncService: notification permission check failed: $e');
    }

    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
      } else {
        await FlutterForegroundTask.startService(
          serviceId: 4720,
          serviceTypes: const [ForegroundServiceTypes.connectedDevice],
          notificationTitle: 'WHOOP sync',
          notificationText: 'Keeping your strap connected…',
          callback: backgroundSyncCallback,
        );
      }
    } catch (e) {
      debugPrint('BackgroundSyncService.start failed: $e');
    }

    _watchForCompletion();
  }

  /// Subscribe to the live offload so the service dismisses itself when the sync
  /// finishes. Fires only on the transition INTO `complete` after a real
  /// `offloading` run this session, so a stale replayed `complete` can't stop us
  /// before syncing. Idempotent — re-subscribes cleanly on a restart.
  void _watchForCompletion() {
    final WhoopBleClient client;
    try {
      client = _ref.read(whoopBleClientProvider);
    } catch (e) {
      debugPrint('BackgroundSyncService: client unavailable to watch sync: $e');
      return;
    }
    _sawOffloading = false;
    unawaited(_syncSub?.cancel());
    _syncSub = client.syncProgress.listen((p) {
      if (p.phase == 'offloading') {
        _sawOffloading = true;
      } else if (p.phase == 'complete' && _sawOffloading) {
        _sawOffloading = false;
        // Sync done → let the notification go away. WorkManager keeps syncing
        // periodically; the lifecycle observer restarts us on the next background.
        _updateNotification('WHOOP synced', 'Up to date');
        unawaited(stop());
      }
    });
  }

  /// Stop the foreground service and drop the main-isolate nudge listener.
  Future<void> stop() async {
    if (!isSupported) return;
    _detachCallback();
    unawaited(_syncSub?.cancel());
    _syncSub = null;
    _sawOffloading = false;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e) {
      debugPrint('BackgroundSyncService.stop failed: $e');
    }
  }

  void _ensureInitialised() {
    if (_initialized) return;
    // Port between the service isolate and this (main) isolate.
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'noop_whoop_sync',
        channelName: 'WHOOP background sync',
        channelDescription:
            'Keeps your WHOOP strap connected while NOOP is in the background.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(_kNudgeIntervalMs),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    _initialized = true;
  }

  void _attachCallback() {
    if (_callbackAttached) return;
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    _callbackAttached = true;
  }

  void _detachCallback() {
    if (!_callbackAttached) return;
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _callbackAttached = false;
  }

  /// Fired on the MAIN isolate whenever the service isolate sends a tick.
  void _onTaskData(Object data) {
    if (data != kBgSyncNudgeKey) return;
    _nudge();
  }

  /// The heart of it: on each tick, ask the ONE main-isolate client to reconnect a dropped link
  /// (which runs its offload on connect). When already connected/syncing there is nothing to do —
  /// the live client is already streaming/offloading; we just refresh the notification text.
  void _nudge() {
    final WhoopBleClient client;
    try {
      client = _ref.read(whoopBleClientProvider);
    } catch (e) {
      debugPrint('BackgroundSyncService: client unavailable for nudge: $e');
      return;
    }
    switch (client.state) {
      case BleConnectionState.idle:
        unawaited(client.connectRemembered());
        _updateNotification('WHOOP sync', 'Reconnecting to your strap…');
      case BleConnectionState.connected:
      case BleConnectionState.syncing:
        _updateNotification('WHOOP connected', 'Syncing in the background');
      case BleConnectionState.scanning:
      case BleConnectionState.connecting:
        // In-flight — let it finish; no new action.
        break;
    }
  }

  void _updateNotification(String title, String text) {
    try {
      FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    } catch (_) {
      // Notification refresh is cosmetic; never let it break the sync loop.
    }
  }
}
