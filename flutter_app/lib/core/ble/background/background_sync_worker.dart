/// WorkManager headless WHOOP sync — the ONLY sync path that survives an app KILL.
///
/// ## Why WorkManager (and why its own DB + BLE client)
/// The sibling [BackgroundSyncService] (flutter_foreground_task) only keeps the app PROCESS
/// alive while it is *backgrounded*; the moment the OS kills the app (swipe-away, low-memory
/// reap) the main isolate — and with it the single [WhoopBleClient] that owns the drift DB and
/// the live GATT link — is gone, and sync stops.
///
/// Android's WorkManager is the standard mechanism for periodic work that runs *after the app
/// is terminated*: it wakes a fresh, HEADLESS Flutter isolate (no widgets, no main isolate) on
/// a periodic schedule (15-min Android minimum) and runs [callbackDispatcher]. Because the app
/// is dead when this runs, the headless isolate is the SOLE owner of the strap + the DB file for
/// the duration of the run, so it can safely open its OWN [AppDatabase] (same sqlite file) and
/// construct its OWN slim [WhoopBleClient] over a [DriftStreamRepository] without racing the main
/// isolate — there is no main isolate. Drift/sqlite tolerates a second connection to the same
/// file; the [appIsAlive] heartbeat guard below guarantees we never open it for a heavy sync
/// while the app process is actually running.
///
/// ## Concurrency guard (single-owner across isolates/processes)
/// A foregrounded (or foreground-service-kept-alive) app and this headless task must never drive
/// BLE at the same time. The main isolate writes a heartbeat — a unix-seconds timestamp in the
/// shared drift `syncCursor` KV under [kAppAliveHeartbeatCursor] — every ~60s for as long as its
/// process lives (see `background_sync_scheduler.startForegroundHeartbeat`). This task reads that
/// heartbeat first: if it is fresher than [kHeartbeatStale] the app process is alive and already
/// owns BLE, so the task SKIPS. Once the app is killed the heartbeat stops advancing, goes stale,
/// and the task proceeds. The KV lives in the same sqlite file both sides open, so the signal is
/// cross-process safe (sqlite file locking) with no extra plumbing.
///
/// ## Bounded runtime
/// WorkManager grants a worker ~10 minutes before it is force-stopped. We cap the whole attempt
/// at [kBgSyncMaxRuntime] (a margin under that), tear the link down cleanly, close the DB, and
/// return so WorkManager records success and keeps the periodic schedule.
///
/// ## Platform scope
///  • **Android:** the real path (this file's reason to exist).
///  • **iOS:** BGTaskScheduler is far more restrictive — no guaranteed periodic wakeups, a few
///    seconds of runtime, and the OS decides *if* it runs at all based on app-usage heuristics.
///    A reliable killed-app BLE offload is NOT possible there; if the callback is ever invoked on
///    iOS it is a best-effort no-op (returns true) rather than a fake. We do not register periodic
///    work on iOS (see the scheduler).
///  • **Desktop / web / tests:** never reached — WorkManager is Android/iOS only, tests never call
///    `main()` and never register work, and this file is imported only from `main.dart`.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/db/database.dart';
import '../../state/prefs.dart';
import '../sync/stream_persistence.dart';
import '../transport/whoop_ble_client.dart';
import '../transport/whoop_providers.dart' show readPairedStrap;

/// Unique WorkManager name for the single periodic sync job (used to register + cancel it).
const String kBgSyncUniqueName = 'noop.whoop.bgsync.periodic';

/// Task name handed back to [callbackDispatcher] so it can route (WorkManager passes it through).
const String kBgSyncTaskName = 'whoopBackgroundSync';

/// The shared drift `syncCursor` KV key the main isolate stamps with its liveness heartbeat
/// (unix seconds). Distinct from any strap-trim cursor name, so it never collides with sync data.
const String kAppAliveHeartbeatCursor = 'app_alive_heartbeat_unix';

/// How stale the app heartbeat must be before the headless task assumes the app is dead and it is
/// safe to own BLE. The main isolate refreshes every ~60s, so 3 minutes tolerates a couple of
/// missed beats without ever overlapping a live app.
const Duration kHeartbeatStale = Duration(minutes: 3);

/// Hard cap on one headless run — a margin under WorkManager's ~10-min budget.
const Duration kBgSyncMaxRuntime = Duration(minutes: 8);

/// How long to wait for the Bluetooth adapter state before giving up (off → skip this run).
const Duration _kAdapterProbeTimeout = Duration(seconds: 6);

/// The top-level WorkManager entry point. Annotated `@pragma('vm:entry-point')` so it survives
/// tree-shaking and can be invoked in the fresh headless isolate. Registered via
/// `Workmanager().initialize(callbackDispatcher)` from the scheduler.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Only Android has a meaningful killed-app periodic path. Anything else is a best-effort no-op.
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      return await runHeadlessWhoopSync();
    } catch (e, st) {
      debugPrint('WorkManager WHOOP sync failed: $e\n$st');
      // Returning true keeps the periodic schedule (a transient failure retries next tick anyway);
      // returning false would ask WorkManager to reschedule the SAME run with backoff, which we
      // don't want for a periodic job that will fire again on its own.
      return true;
    }
  });
}

/// One bounded headless sync attempt. Opens its own DB + BLE client, honours the heartbeat guard,
/// runs a single offload, persists it, tears everything down, and returns true. Always returns
/// (never throws) so WorkManager records a clean result. Exposed (non-private) for readability;
/// only [callbackDispatcher] calls it.
Future<bool> runHeadlessWhoopSync() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read persisted state in this fresh isolate (separate memory from the main isolate).
  await Prefs.instance.load();

  final remembered = readPairedStrap();
  if (remembered == null) {
    // Nothing paired — nothing to sync. (The scheduler shouldn't have registered work, but a
    // strap could have been unpaired since; bail cleanly.)
    return true;
  }
  // Respect an explicit user opt-out. `null` means "never chosen" → default ON when paired, which
  // we are, so a null value proceeds. Only an explicit `false` blocks the run.
  if (Prefs.instance.backgroundSyncEnabled == false) return true;

  // Own DB handle on the SAME on-device sqlite file the app uses. Safe here because either the app
  // is dead (sole owner) or the heartbeat guard below makes us bail before any heavy work.
  final db = AppDatabase();
  try {
    // ── Concurrency guard: skip while the app process is alive and owns BLE ──────────────────
    if (await appIsAlive(db)) {
      debugPrint('WorkManager WHOOP sync: app is alive (heartbeat fresh) — skipping');
      return true;
    }

    // Adapter gate — don't hold a wakelock spinning up a client against a powered-off radio.
    // (connectRemembered re-checks; this only avoids pointless work.) Battery-not-critical is
    // enforced at the OS scheduling layer via the WorkManager `requiresBatteryNotLow` constraint,
    // so there is no runtime battery plugin to consult here.
    if (!await _bluetoothOn()) {
      debugPrint('WorkManager WHOOP sync: Bluetooth off — skipping');
      return true;
    }

    await _runOneOffload(db, remembered);
    return true;
  } finally {
    await db.close();
  }
}

/// Whether the main app process is alive, judged by the freshness of the [kAppAliveHeartbeatCursor]
/// it stamps into the shared drift KV. A read failure is treated as "not alive" (fail open → we do
/// our job) — the worst case is a brief, sqlite-lock-serialised overlap, not corruption.
Future<bool> appIsAlive(AppDatabase db) async {
  try {
    final beatUnix = await db.getSyncCursor(kAppAliveHeartbeatCursor);
    if (beatUnix == null) return false;
    final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final ageSec = nowUnix - beatUnix;
    return ageSec >= 0 && ageSec < kHeartbeatStale.inSeconds;
  } catch (_) {
    return false;
  }
}

/// Stamp the app-alive heartbeat (unix seconds) into the shared drift KV. Called ONLY by the main
/// isolate (see the scheduler); the headless task only ever reads it via [appIsAlive].
Future<void> writeAppAliveHeartbeat(AppDatabase db) async {
  try {
    final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await db.setSyncCursor(kAppAliveHeartbeatCursor, nowUnix);
  } catch (e) {
    debugPrint('writeAppAliveHeartbeat failed: $e');
  }
}

/// Construct a slim [WhoopBleClient] over [db], reconnect to [remembered], run exactly one
/// historical offload (bounded by [kBgSyncMaxRuntime]), persist the sync-state, then tear down.
Future<void> _runOneOffload(AppDatabase db, PairedStrap remembered) async {
  final client = WhoopBleClient(
    streamRepository: DriftStreamRepository(db),
    cursorStore: DriftTrimCursorStore(db),
  );
  client.rememberedStrapLookup = () => remembered;

  final done = Completer<void>();
  String? lastPhase;
  final sub = client.syncProgress.listen((p) {
    final was = lastPhase;
    lastPhase = p.phase;
    if (p.phase == 'complete' && was != 'complete') {
      // Bank the wall-clock sync-state so the UI's "Last synced …" reflects this headless run on
      // the next foreground read (this isolate's Prefs write goes straight to secure storage).
      unawaited(Prefs.instance.recordSyncCompleted(
        atMs: DateTime.now().millisecondsSinceEpoch,
        newestRecordTsMs: p.newestTsMs ?? p.currentTsMs,
        recordCount: p.recordsPersisted,
      ));
      if (!done.isCompleted) done.complete();
    }
  });

  try {
    // Fire the direct reconnect (no scan) → SET_CLOCK/GET_DATA_RANGE → single historical offload.
    await client.connectRemembered();
    // Wait for the offload to complete, or give up at the runtime cap (connect could fail, or the
    // strap is out of range / permissions were revoked — in all cases we tear down cleanly).
    await done.future.timeout(kBgSyncMaxRuntime, onTimeout: () {});
  } finally {
    await sub.cancel();
    // Intentional teardown: drop the link (no auto-reconnect) and release every resource so the
    // isolate can exit and WorkManager can reap it.
    await client.disconnect();
    await client.dispose();
  }
}

/// Best-effort Bluetooth-adapter power check, bounded by [_kAdapterProbeTimeout]. Any failure or
/// timeout is treated as "off" so we skip rather than block.
Future<bool> _bluetoothOn() async {
  try {
    final state = await FlutterBluePlus.adapterState
        .firstWhere((s) =>
            s == BluetoothAdapterState.on || s == BluetoothAdapterState.off)
        .timeout(_kAdapterProbeTimeout);
    return state == BluetoothAdapterState.on;
  } catch (_) {
    return false;
  }
}
