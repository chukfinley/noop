/// The [TaskHandler] that runs inside `flutter_foreground_task`'s SERVICE isolate.
///
/// Design note (single-owner rule): this isolate deliberately does **almost nothing**.
/// It owns neither the drift database nor the live GATT link — those stay in the MAIN
/// isolate's [WhoopBleClient], the single owner of the DB file and the connection. Two
/// isolates writing one drift file is fragile/corruption-prone, so we never re-instantiate
/// the client here.
///
/// The foreground service's real job is **process-liveness**: while it runs, Android keeps
/// the whole app process (and therefore the main isolate + its already-connected BLE client)
/// alive when the app is backgrounded, so the main-isolate client keeps auto-reconnecting and
/// offloading on its own. On each repeat tick this handler simply pings the main isolate via
/// [FlutterForegroundTask.sendDataToMain]; the main isolate (see [BackgroundSyncService]) is
/// what actually nudges `connectRemembered()`.
library;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Message key the service isolate sends on every repeat tick; the main isolate keys off it.
const String kBgSyncNudgeKey = 'noop_bg_sync_nudge';

/// Top-level entry point handed to `FlutterForegroundTask.startService(callback: ...)`.
/// Must be a top-level or static function annotated `@pragma('vm:entry-point')` so it
/// survives tree-shaking and can be invoked in the fresh service isolate.
@pragma('vm:entry-point')
void backgroundSyncCallback() {
  FlutterForegroundTask.setTaskHandler(_BackgroundSyncTaskHandler());
}

class _BackgroundSyncTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Nudge once immediately on start so a just-backgrounded app reconnects promptly.
    FlutterForegroundTask.sendDataToMain(kBgSyncNudgeKey);
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Periodic keep-alive nudge → the MAIN isolate reconnects + offloads (see the note above).
    FlutterForegroundTask.sendDataToMain(kBgSyncNudgeKey);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    // Bring the app back to the foreground when the user taps the notification.
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {}
}
