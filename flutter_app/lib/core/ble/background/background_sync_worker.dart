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

/// How often the in-flight offload re-checks the app-alive heartbeat. The pre-flight check at the
/// top of [runHeadlessWhoopSync] is one-shot; an offload runs for up to [kBgSyncMaxRuntime], so the
/// guard MUST be re-evaluated continuously — otherwise a foreground launch (or a foreground-service
/// revive) part-way through spins up a second BLE/DB owner. On the main isolate stamping a fresh
/// beat immediately at launch (see the scheduler), this bounds the two-owner window to one interval.
const Duration kHeartbeatRecheckInterval = Duration(seconds: 30);

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

/// Pure single-owner decision: given the app-alive heartbeat value just read from the shared drift
/// KV ([beatUnix] in unix seconds, or `null` when the key is unset) and the current unix time
/// [nowUnix], should the headless worker YIELD to the foreground — i.e. treat the app process as the
/// live owner of BLE + the DB and NOT run its own offload?
///
/// This is the guard's whole truth table, kept side-effect-free so it can be unit-tested without a
/// DB, a radio, or a clock. It is deliberately **fail-CLOSED**: on any ambiguity the worker yields,
/// because two concurrent owners of one strap + one sqlite file is the outcome we must never risk,
/// whereas a skipped run is harmless (WorkManager fires again next tick).
///   • [readFailed] (the KV read threw / lock contention) → yield. A lost heartbeat lock is NOT
///     evidence the app is dead; the previous "fail open → run anyway" was the bug (HIGH-4).
///   • [beatUnix] == null (app has never stamped liveness) → do NOT yield: the app is genuinely dead
///     / has never run, so the worker is the sole owner and should proceed.
///   • a FUTURE beat (ageSec < 0: clock skew, DST, a beat from the future) → yield. We cannot prove
///     staleness, so we assume the app is live.
///   • a fresh beat (age < [kHeartbeatStale]) → yield; a stale beat → proceed.
bool workerShouldYield({
  required int? beatUnix,
  required int nowUnix,
  bool readFailed = false,
}) {
  if (readFailed) return true; // ambiguity → never risk a second owner
  if (beatUnix == null) return false; // no heartbeat ever → app dead → safe to own BLE
  final ageSec = nowUnix - beatUnix;
  if (ageSec < 0) return true; // future/skewed beat → cannot prove stale → assume alive
  return ageSec < kHeartbeatStale.inSeconds; // fresh → app owns BLE; stale → app dead
}

/// Whether the main app process is alive (owns BLE + the DB), judged by the freshness of the
/// [kAppAliveHeartbeatCursor] it stamps into the shared drift KV. Thin DB wrapper around the pure
/// [workerShouldYield] predicate. **Fail-CLOSED**: a read failure is treated as "alive/owned" so the
/// worker yields rather than racing the foreground — the previous fail-open behaviour was HIGH-4.
Future<bool> appIsAlive(AppDatabase db) async {
  final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  try {
    final beatUnix = await db.getSyncCursor(kAppAliveHeartbeatCursor);
    return workerShouldYield(beatUnix: beatUnix, nowUnix: nowUnix);
  } catch (_) {
    return workerShouldYield(beatUnix: null, nowUnix: nowUnix, readFailed: true);
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
  // Completes if the foreground process reclaims BLE part-way through (heartbeat goes fresh). This
  // is the continuous, symmetric half of the single-owner guard: the foreground always wins, so the
  // instant it is alive the worker abandons the offload and tears the link down.
  final yielded = Completer<void>();
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

  // Continuous single-owner guard. The pre-flight [appIsAlive] check is one-shot; without this a
  // foreground launch mid-offload would leave two BLE/DB owners for up to [kBgSyncMaxRuntime]. We
  // re-poll the heartbeat every [kHeartbeatRecheckInterval] and, the moment the app is alive, fire
  // [yielded] so the run unwinds into the clean teardown below. Crucially we only STOP WAITING — we
  // never force-kill a write; the awaited disconnect/dispose (and the caller's db.close) drain any
  // in-flight chunk, so the abort lands BETWEEN chunks and can never corrupt the trim/ack invariant
  // (the strap is only told to trim after a chunk is durably persisted, so a mid-run abort at worst
  // re-fetches the last chunk next tick — it never leaves a half-acked cursor).
  final guard = Timer.periodic(kHeartbeatRecheckInterval, (_) async {
    if (yielded.isCompleted || done.isCompleted) return;
    if (await appIsAlive(db)) {
      debugPrint('WorkManager WHOOP sync: app became alive mid-offload — yielding BLE to foreground');
      if (!yielded.isCompleted) yielded.complete();
    }
  });

  try {
    // Fire the direct reconnect (no scan) → SET_CLOCK/GET_DATA_RANGE → single historical offload.
    await client.connectRemembered();
    // Unwind on the FIRST of: offload complete, foreground reclaimed BLE, or the runtime cap
    // (connect could fail, or the strap is out of range / permissions were revoked). Every path
    // lands in the clean teardown below.
    await Future.any([done.future, yielded.future])
        .timeout(kBgSyncMaxRuntime, onTimeout: () {});
  } finally {
    guard.cancel();
    await sub.cancel();
    // Intentional teardown: drop the link (no auto-reconnect) and release every resource so the
    // isolate can exit and WorkManager can reap it. Awaited so any in-flight chunk drains before
    // the caller closes the DB — the abort is between chunks, never mid-ack.
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
