/// Riverpod wiring for the WHOOP BLE transport (Wave D2a).
///
/// Every provider here is INERT until an explicit `connect()` action: [whoopBleClientProvider]
/// only constructs the client (which touches no radio in its constructor), and the stream providers
/// merely subscribe to its broadcast streams. Nothing scans at construction, so the existing
/// widget/smoke tests (MockRepository, no device) stay green.
library;

import 'dart:async' show unawaited;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/prefs.dart';
import '../../state/providers.dart' show databaseProvider;
import '../sync/stream_persistence.dart';
import 'whoop_ble_client.dart';

/// The singleton WHOOP BLE transport, wired to the drift database:
/// `databaseProvider` → [DriftStreamRepository] (live + offload persistence) + [DriftTrimCursorStore]
/// (the safe-trim watermark). Disposed with the scope. Construction is pure — it does NOT scan or
/// connect; a caller must invoke [WhoopBleClient.connect].
final whoopBleClientProvider = Provider<WhoopBleClient>((ref) {
  final db = ref.watch(databaseProvider);
  final client = WhoopBleClient(
    streamRepository: DriftStreamRepository(db),
    cursorStore: DriftTrimCursorStore(db),
  );
  // Remember/auto-reconnect seam (no radio here — a pure Prefs read + a broadcast-stream listen that
  // only fires once a connect actually succeeds, so tests with no device stay inert):
  //  • lookup: reconstruct the last-paired strap from Prefs for connect()/connectRemembered().
  //  • listen: persist each successful pairing back to Prefs (non-null only — a disconnect emits null
  //    but must NOT forget the strap; only an explicit unpair clears it).
  client.rememberedStrapLookup = () => readPairedStrap();
  final sub = client.connectedStrap.listen((strap) {
    if (strap != null) {
      unawaited(Prefs.instance
          .setPairedStrap(strap.id, strap.familyToken, strap.name));
    }
  });
  ref.onDispose(sub.cancel);
  // Sync-state persistence: on the transition INTO the 'complete' phase (one offload
  // finishing), bank the WALLCLOCK sync-state to Prefs, then invalidate
  // [syncStateProvider] so the device screen re-reads "Last synced …". Wall-clock now
  // is fine here — this only ever fires on real device runtime, never on a test path
  // (nothing drives the client to 'complete' without hardware).
  String? lastSyncPhase;
  final syncSub = client.syncProgress.listen((p) {
    final was = lastSyncPhase;
    lastSyncPhase = p.phase;
    if (p.phase == 'complete' && was != 'complete') {
      unawaited(Prefs.instance
          .recordSyncCompleted(
            atMs: DateTime.now().millisecondsSinceEpoch,
            newestRecordTsMs: p.newestTsMs ?? p.currentTsMs,
            recordCount: p.recordsPersisted,
          )
          .then((_) => ref.invalidate(syncStateProvider)));
    }
  });
  ref.onDispose(syncSub.cancel);
  ref.onDispose(client.dispose);
  return client;
});

/// The persisted [SyncState] — WHEN the strap last finished an offload, the newest
/// record we banked, and that sync's record count. Reads [Prefs] synchronously, so it
/// is inert in tests (no device → nothing ever completes → an honest "Never synced").
/// [whoopBleClientProvider] invalidates this on each complete-transition, so a fresh
/// watch reflects the just-finished sync.
final syncStateProvider = Provider<SyncState>((ref) => Prefs.instance.syncState);

/// Reconstruct the remembered [PairedStrap] from [Prefs], or null when nothing is paired. Pure — a
/// synchronous read of the already-loaded Prefs fields, safe to call from a provider or the client seam.
PairedStrap? readPairedStrap() {
  final id = Prefs.instance.pairedStrapId;
  if (id == null || id.isEmpty) return null;
  return PairedStrap(
    id: id,
    family: PairedStrap.familyFromToken(Prefs.instance.pairedStrapFamily),
    name: Prefs.instance.pairedStrapName,
  );
}

/// The remembered strap from [Prefs] (null if none). Read by the auto-reconnect kick + the UI to show
/// "paired with …". Note this reads Prefs at watch time; it does not reactively rebuild on a new
/// pairing (a fresh read after a connect reflects the update).
final pairedStrapProvider = Provider<PairedStrap?>((ref) => readPairedStrap());

/// Forget the remembered strap: clear it from [Prefs] and invalidate [pairedStrapProvider] so a
/// re-watch reads null and the device screen falls back to the un-paired "Scan for straps" state.
/// Additive — leaves any live link untouched (call [WhoopBleClient.disconnect] separately to drop it).
Future<void> forgetPairedStrap(WidgetRef ref) async {
  await Prefs.instance.clearPairedStrap();
  ref.invalidate(pairedStrapProvider);
}

/// Live link state (idle/scanning/connecting/connected/syncing). Read `.value` for the current
/// phase; `.hasError` / the client's [WhoopBleClient.lastError] for the last surfaced error string.
final bleConnectionProvider = StreamProvider<BleConnectionState>((ref) {
  return ref.watch(whoopBleClientProvider).connectionState;
});

/// Live heart rate (bpm), or null when unknown/disconnected.
final liveHrProvider = StreamProvider<int?>((ref) {
  return ref.watch(whoopBleClientProvider).liveHr;
});

/// Strap battery as a 0..1 fraction, or null when unknown/disconnected.
final liveBatteryProvider = StreamProvider<double?>((ref) {
  return ref.watch(whoopBleClientProvider).battery;
});

/// Whether the strap is charging (true/false), or null when unknown. Additive to
/// [liveBatteryProvider] — the fraction and the charging flag are independent signals.
final liveChargingProvider = StreamProvider<bool?>((ref) {
  return ref.watch(whoopBleClientProvider).charging;
});

/// Historical-offload progress (packets persisted this session + percent + which day is syncing).
final syncProgressProvider = StreamProvider<SyncProgress>((ref) {
  return ref.watch(whoopBleClientProvider).syncProgress;
});

/// The rolling connection log (newest-last [ConnLogEntry] list) — the live scan/connect/offload/
/// disconnect trace the device screen renders so the user can watch drops/reconnects on real hardware.
/// Inert until the client logs its first line (so `flutter test` with no device stays empty).
final connectionLogProvider = StreamProvider<List<ConnLogEntry>>((ref) {
  return ref.watch(whoopBleClientProvider).connectionLog;
});

/// Whether the Bluetooth adapter is powered ON. Fed by `FlutterBluePlus.adapterState`, guarded by
/// platform: off Android/iOS (desktop/web/tests) it emits a single `true` and never touches the
/// radio, so the UI can show a "Bluetooth is off" banner on-device without the transport churning
/// elsewhere.
final bleAdapterOnProvider = StreamProvider<bool>((ref) {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
    return Stream<bool>.value(true);
  }
  return FlutterBluePlus.adapterState
      .map((s) => s == BluetoothAdapterState.on);
});

/// Drives the device-picker scan: watching it starts a discovery scan (both WHOOP families) and
/// pushes the growing, de-duplicated [DiscoveredStrap] list; `autoDispose` stops the scan the moment
/// the UI stops watching (e.g. leaves the picker). INERT until watched, so tests never scan — nothing
/// subscribes at construction. The UI then calls `whoopBleClientProvider.connectToStrap(pick)`.
final strapScanProvider =
    StreamProvider.autoDispose<List<DiscoveredStrap>>((ref) {
  return ref.watch(whoopBleClientProvider).discoverStraps();
});

/// One-shot auto-reconnect kick, read once from `main()` at app launch. Fires [connectRemembered] so a
/// remembered strap reconnects (and runs its offload) with no user action. Guarded to a strict no-op
/// off-device / in tests / when nothing is remembered:
///  • bails on web/desktop (no `Platform.isAndroid || Platform.isIOS`),
///  • bails when no strap is remembered ([pairedStrapProvider] null),
///  • the client's own permission + adapter-power gates inside [connectRemembered] finish the job
///    (it no-ops with a clear error if Bluetooth is off).
///
/// Deliberately NOT watched by any widget the smoke test builds — `main()` reads it explicitly, so a
/// plain `flutter test` (which builds its own scope, never `main()`) never triggers it.
final whoopAutoConnectProvider = Provider<void>((ref) {
  if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
  final remembered = ref.read(pairedStrapProvider);
  if (remembered == null) return;
  // Only bother when the adapter reports ON (best-effort; connectRemembered re-checks and no-ops if
  // it is off, so a not-yet-loaded stream value never blocks the reconnect).
  final adapterOn = ref.read(bleAdapterOnProvider).valueOrNull;
  if (adapterOn == false) return;
  unawaited(ref.read(whoopBleClientProvider).connectRemembered());
});

/// Kick the guarded [whoopAutoConnectProvider] once, from `main()` at startup. A helper (not a widget)
/// so the startup wiring is explicit and stays out of the widget tree the tests build.
void kickWhoopAutoConnect(ProviderContainer container) {
  container.read(whoopAutoConnectProvider);
}
