/// WHOOP BLE transport (Wave D2a) — the device-facing half of the strap sync.
///
/// A `flutter_blue_plus` engine that mirrors the happy path of the Android Kotlin
/// `WhoopBleClient.kt` (5299 LOC) reference, wiring the already-ported, already-tested
/// decode layer (`../protocol/`) and sync layer (`../sync/`) into a working strap SYNC.
///
/// This half CANNOT be unit-tested without hardware (the project rule forbids launching the
/// app), so its correctness comes from faithfully mirroring the Kotlin connection sequence.
/// Everything degrades safely OFF device: every `flutter_blue_plus` call is guarded behind
/// [_blePlatform] (`Platform.isAndroid || Platform.isIOS`), and the client is inert until an
/// explicit [connect] — construction touches no radio, so a plain `flutter test` never scans.
///
/// The connect sequence (mirrors the Kotlin 6-step flow):
///   1. [connect] — `ensureBlePermissions()`, then a service-filtered scan for the chosen
///      family's service UUID, with a [fallbackScanModel] rotation after [scanFallbackDelay].
///   2. take the first matching [ScanResult], stop the scan, and `connect()` to the device.
///   3. on `BluetoothConnectionState.connected` → `discoverServices()`.
///   4. locate the custom WHOOP4/WHOOP5 service → capture the cmd-write char + enable
///      notifications (write the CCCD via `setNotifyValue`) on the family's notify chars, plus
///      the standard HR (0x2A37) and battery (0x2A19) chars. For WHOOP5: write CLIENT_HELLO,
///      subscribe the puffin notify chars, then send the [Whoop5Config.enableR22Sequence].
///   5. the connect-time command sequence, in Kotlin order: SET_CLOCK → GET_DATA_RANGE →
///      (deferred by [initialBackfillDelay]) trigger the historical offload.
///   6. inbound routing (mirrors `onCharacteristicChanged`): DATA/CMD/EVENT notify bytes →
///      [Reassembler] → [Framing.parseFrame]; live REALTIME_DATA → [extractStreams] → persist
///      via [StreamPersistence] + publish live HR; HISTORICAL_DATA offload frames →
///      [Backfiller.ingest] (persist to drift); COMMAND_RESPONSE GET_DATA_RANGE → session gates.
///   • reconnect on an involuntary drop using [ReconnectBackoff.nextDelayMs].
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../bond/bond_refusal_give_up.dart';
import '../bond/bond_watchdog_backoff.dart';
import '../bond/post_bond_timeout_loop_detector.dart';
import '../permissions.dart';
import '../protocol/alarm_payload.dart';
import '../protocol/device_family.dart';
import '../protocol/enums.dart';
import '../protocol/framing.dart';
import '../protocol/haptic_clock.dart';
import '../protocol/historical_streams.dart';
import '../protocol/parsed_frame.dart';
import '../protocol/streams.dart';
import '../protocol/whoop5_config.dart';
import '../sync/backfiller.dart';
import '../sync/raw_archive.dart';
import '../sync/reconnect_backoff.dart';
import '../sync/stream_persistence.dart';

/// High-level link state surfaced to the UI (mirrors the Kotlin `LiveState` phases we expose).
enum BleConnectionState { idle, scanning, connecting, connected, syncing }

/// A snapshot of historical-offload progress: how many packets have landed, how far through the
/// strap's banked-record span the offload has advanced, and which day is being decoded right now —
/// enough for the UI to show "syncing &lt;date&gt;", a percent bar, and a packet counter.
class SyncProgress {
  const SyncProgress({
    required this.recordsPersisted,
    required this.phase,
    this.percent,
    this.currentTsMs,
    this.oldestTsMs,
    this.newestTsMs,
  });

  /// Total biometric rows (packets) persisted this offload session (from
  /// [Backfiller.sessionRowsPersisted]) — the "how many packets" number.
  final int recordsPersisted;

  /// Coarse phase: "idle", "offloading", "complete".
  final String phase;

  /// 0..1 offload progress through the strap's `[oldest, newest]` banked-record span, derived from
  /// how far [currentTsMs] has advanced past [oldestTsMs]. Null when the range isn't known yet
  /// (pre-GET_DATA_RANGE) or we aren't offloading.
  final double? percent;

  /// Unix milliseconds of the most-recent record decoded/persisted in the offload, so the UI can
  /// render "syncing &lt;date&gt;". Null before any offload record has landed.
  final int? currentTsMs;

  /// GET_DATA_RANGE lower bound (unix ms) — the oldest banked record on the strap. Null pre-range.
  final int? oldestTsMs;

  /// GET_DATA_RANGE upper bound (unix ms) — the newest banked record on the strap. Null pre-range.
  final int? newestTsMs;

  @override
  String toString() =>
      'SyncProgress(recordsPersisted: $recordsPersisted, phase: $phase, '
      'percent: $percent, currentTsMs: $currentTsMs, oldestTsMs: $oldestTsMs, '
      'newestTsMs: $newestTsMs)';
}

/// A WHOOP strap surfaced by [WhoopBleClient.discoverStraps] so the UI can show a picker instead of
/// auto-connecting to the first advertiser. [id] is the platform remote-id (feed it back to
/// [WhoopBleClient.connectToStrap] via the same [DiscoveredStrap]).
class DiscoveredStrap {
  const DiscoveredStrap({
    required this.id,
    required this.name,
    required this.rssi,
    required this.family,
  });

  /// Stable platform remote-id (BLE MAC on Android, a system UUID on iOS).
  final String id;

  /// Advertised device name, or a family-derived fallback when the advert carries none.
  final String name;

  /// Last-seen signal strength (dBm; closer to 0 is stronger).
  final int rssi;

  /// Which WHOOP family advertised this service UUID (drives the bring-up branch on connect).
  final DeviceFamily family;

  @override
  String toString() =>
      'DiscoveredStrap(id: $id, name: $name, rssi: $rssi, family: ${family.name})';
}

/// An immutable handle to a paired WHOOP strap — the real platform remote-id, the resolved
/// [DeviceFamily], and the advertised name (may be null). Emitted by [WhoopBleClient.connectedStrap]
/// on a successful connect so the provider layer can persist it, and reconstructed from [Prefs] to
/// drive [WhoopBleClient.connectRemembered]. [familyToken]/[familyFromToken] convert the family to and
/// from the `"whoop4"`/`"whoop5"` string persisted in secure storage.
class PairedStrap {
  const PairedStrap({required this.id, required this.family, this.name});

  /// Stable platform remote-id (BLE MAC on Android, a system UUID on iOS) — feed back to
  /// [BluetoothDevice.fromId] to reconnect directly, no scan.
  final String id;

  /// Which WHOOP family this strap belongs to (drives the bring-up branch on reconnect).
  final DeviceFamily family;

  /// Advertised device name, or null when the advert carried none.
  final String? name;

  /// The persisted family token (`"whoop4"`/`"whoop5"`).
  String get familyToken => familyToToken(family);

  /// Parse the persisted family token back to a [DeviceFamily]; unknown/null → WHOOP 4.0.
  static DeviceFamily familyFromToken(String? token) =>
      token == 'whoop5' ? DeviceFamily.whoop5 : DeviceFamily.whoop4;

  /// The persisted token for a [DeviceFamily] (`"whoop4"`/`"whoop5"`).
  static String familyToToken(DeviceFamily f) =>
      f == DeviceFamily.whoop5 ? 'whoop5' : 'whoop4';

  @override
  String toString() => 'PairedStrap(id: $id, family: ${family.name}, name: $name)';
}

/// One timestamped line of the connection log — the rolling in-memory trace the device screen
/// renders so the user can watch, on real hardware, whether the link drops / reconnects / actually
/// syncs. [ts] is captured at log time (device runtime only — never on a pure/test path, since the
/// client is inert until an explicit connect).
class ConnLogEntry {
  const ConnLogEntry(this.ts, this.message);

  /// Wall-clock time the line was logged.
  final DateTime ts;

  /// The human-readable log line (the same text that goes to `debugPrint`).
  final String message;

  @override
  String toString() => 'ConnLogEntry($ts, $message)';
}

/// A strap-reported firmware wake-alarm, decoded defensively from a GET_ALARM_TIME (cmd 67) response
/// (smart-alarm spec §3). [wakeEpochMs] is the next wake time the strap says it will fire. The
/// response layout is UNDOCUMENTED, so this is best-effort telemetry only — never gate behaviour on it
/// (a null [StrapAlarm] just means "nothing plausible decoded", not "no alarm").
class StrapAlarm {
  const StrapAlarm({required this.wakeEpochMs});

  /// The strap's next wake time as unix milliseconds (already passed the plausibility gate).
  final int wakeEpochMs;

  /// The decoded wake time as a local [DateTime].
  DateTime get wake => DateTime.fromMillisecondsSinceEpoch(wakeEpochMs);

  @override
  String toString() => 'StrapAlarm(wake: ${wake.toIso8601String()})';
}

/// The default device id every persisted row is stamped with (matches the Kotlin `DEFAULT_DEVICE_ID`).
const String kDefaultWhoopDeviceId = 'my-whoop';

/// Whether the current platform has a BLE stack `flutter_blue_plus` can drive. On desktop/web/tests
/// every radio call is a no-op so the app (which also runs on Linux) never crashes. Mirrors the
/// `permissions._blePlatform` guard so the whole transport is inert off-device.
bool get _blePlatform {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// `flutter_blue_plus`-backed WHOOP transport. Construct once (pure — no radio access) and drive it
/// with [connect] / [disconnect]. All state is published on broadcast streams so Riverpod providers
/// can surface it without the client depending on Riverpod.
class WhoopBleClient {
  WhoopBleClient({
    required BackfillRepository streamRepository,
    required TrimCursorStore cursorStore,
    RejectedFrameArchive? rejectedArchive,
    this.deviceId = kDefaultWhoopDeviceId,
  }) : _streamRepository = streamRepository {
    // Wire the rejected-frame archive so CRC-ok-but-undecodable HISTORICAL frames are
    // persisted DURABLY before the trim is acked (#77 / #91) — otherwise the strap
    // trims them and the bytes are lost forever. Prefer an explicit archive (tests);
    // else derive one from the drift-backed repository so the production provider wiring
    // needs no change. When neither is available (a non-drift repo) the sink allows the
    // ack (legacy behaviour) rather than stalling the offload.
    final archive = rejectedArchive ??
        (streamRepository is DriftStreamRepository
            ? streamRepository.rejectedArchive
            : null);
    final RejectedSink rejectedSink = archive != null
        ? (frames, trim, family) => archive.append(frames, trim, family)
        : (frames, trim, family) async => true;
    _backfiller = Backfiller(
      repository: streamRepository,
      deviceId: deviceId,
      cursorStore: cursorStore,
      ackTrim: _ackTrim,
      onChunkCommitted: _onChunkCommitted,
      log: _log,
      rejectedSink: rejectedSink,
    );
  }

  // ── tunables (mirror the Kotlin companion constants) ──────────────────────────────────────
  /// No matching strap this long → rotate the scan to the other WHOOP family (Kotlin SCAN_FALLBACK).
  static const Duration scanFallbackDelay = Duration(seconds: 6);

  /// Overall scan give-up window per family before we surface "not found".
  static const Duration scanTimeout = Duration(seconds: 15);

  /// Deferral before the first connect-time offload, so SET_CLOCK/GET_DATA_RANGE round-trip first
  /// on a settled link (Kotlin INITIAL_BACKFILL_DELAY_MS).
  static const Duration initialBackfillDelay = Duration(milliseconds: 1500);

  /// Offload inactivity watchdog. The official app applies a 5 s inter-packet timeout to the
  /// historical stream (`straphistorysync` `g13.k.o0(flow, 5s)`); if the strap goes silent between
  /// METADATA/data packets mid-offload (a stall WITHOUT a BLE disconnect) the app sends
  /// ABORT_HISTORICAL_TRANSMITS and ends the transfer. Without this, a silent stall wedges `syncing`
  /// forever and suppresses the live path. Re-armed on every inbound offload frame.
  static const Duration offloadInactivityTimeout = Duration(seconds: 5);

  /// While connected, re-poll the strap battery on this cadence (proprietary GET_BATTERY_LEVEL 0x1A —
  /// the strap does NOT use the standard 0x2A19 service, so this is the only live battery source on
  /// WHOOP4). Mirrors the official app's periodic battery query.
  static const Duration batteryPollInterval = Duration(seconds: 60);

  /// Spacing between the 15 SET_CONFIG R22 enable writes (Kotlin uses ~80ms).
  static const Duration r22FlagSpacing = Duration(milliseconds: 80);

  /// Flush the live-frame buffer at least this often (Kotlin FLUSH_MAX_INTERVAL_MS ≈ 5s).
  static const Duration liveFlushInterval = Duration(seconds: 5);

  /// Flush the live-frame buffer once it holds this many frames (Kotlin FLUSH_MAX_FRAMES).
  static const int liveFlushMaxFrames = 40;

  /// Plausible unix-seconds window for a banked-record timestamp (Kotlin GET_DATA_RANGE scan window).
  static const int _unixFloor = 1700000000;
  static const int _unixCeil = 1900000000;

  final String deviceId;
  final BackfillRepository _streamRepository;
  late final Backfiller _backfiller;

  // ── published broadcast streams ───────────────────────────────────────────────────────────
  final _connController = StreamController<BleConnectionState>.broadcast();
  final _hrController = StreamController<int?>.broadcast();
  final _batteryController = StreamController<double?>.broadcast();
  final _chargingController = StreamController<bool?>.broadcast();
  final _syncController = StreamController<SyncProgress>.broadcast();
  final _pairedController = StreamController<PairedStrap?>.broadcast();
  final _logController = StreamController<List<ConnLogEntry>>.broadcast();
  // ── strap smart-alarm signals (smart-alarm spec §5) ─────────────────────────────────────────
  /// Emits when the strap ACKs a SET_ALARM_TIME (cmd 66) — for WHOOP4 a completed write-with-response,
  /// for 5/MG a COMMAND_RESPONSE with result=SUCCESS. The write-side flips queued→armed ONLY on this
  /// real ACK (never optimistically).
  final _alarmArmedController = StreamController<void>.broadcast();
  /// Emits on a LIVE STRAP_DRIVEN_ALARM_EXECUTED (event 57) — the strap ran its own wake haptic.
  final _alarmFiredController = StreamController<void>.broadcast();
  /// Emits the defensively-decoded GET_ALARM_TIME readback epoch (ms), or null — log/telemetry only.
  final _alarmReadbackController = StreamController<int?>.broadcast();

  // ── connection log (rolling in-memory trace of every _log line) ─────────────────────────────
  /// Newest-last rolling buffer, capped at [_maxLogEntries]. Stays empty until the first [_log]
  /// (i.e. until an explicit connect), so a fresh client — and a plain `flutter test` — logs nothing.
  final List<ConnLogEntry> _logBuffer = [];
  static const int _maxLogEntries = 100;

  /// Optional lookup for the last-paired strap, injected by the provider layer (which reads [Prefs]).
  /// Consulted by [connect] (to resolve a null family from the remembered family) and by
  /// [connectRemembered] (to reconnect directly to the remembered device). Kept as a callback so the
  /// transport stays Prefs/Riverpod-free; null (the default) means "nothing remembered".
  PairedStrap? Function()? rememberedStrapLookup;

  /// EXPERIMENTAL opt-in gate for the UNCONFIRMED WHOOP 5.0/MG rev4 strap alarm (smart-alarm spec
  /// §2.3/§7). Consulted by [setStrapAlarm] on a 5/MG strap: when this returns false (the default —
  /// null callback ⇒ closed gate), arming is SKIPPED because we have never captured a
  /// STRAP_DRIVEN_ALARM_EXECUTED on our own 5/MG, so a user must not rely on it. WHOOP4's hardware-
  /// confirmed 9-byte form is never gated. Disable is always allowed. The provider layer wires this to
  /// the experimental-features opt-in; kept as a callback so the transport stays Prefs/Riverpod-free.
  bool Function()? experimentalWhoop5AlarmOptIn;

  /// Injected by the write-side ([AlarmService]): returns the next wake [DateTime] to arm on the strap
  /// when a link comes up (the earliest enabled alarm's next occurrence), or null when no alarm is
  /// enabled. Consulted by the connect lifecycle (after SET_CLOCK) so a reconnect re-pushes the alarm.
  /// Kept as a callback so the transport stays Prefs/Riverpod-free (twin of [rememberedStrapLookup]);
  /// null (the default) means "nothing to reconcile".
  DateTime? Function()? strapAlarmReconcileLookup;

  /// Live link state (idle/scanning/connecting/connected/syncing).
  Stream<BleConnectionState> get connectionState => _connController.stream;

  /// Fires when the strap confirms it armed a SET_ALARM_TIME (the queued→armed transition source).
  Stream<void> get alarmArmed => _alarmArmedController.stream;

  /// Fires when the strap ran its own wake haptic (live event 57) — the source of the "fired" state.
  Stream<void> get alarmFired => _alarmFiredController.stream;

  /// The last defensively-decoded GET_ALARM_TIME readback (epoch ms, or null). Telemetry only.
  Stream<int?> get alarmReadback => _alarmReadbackController.stream;

  /// Live heart rate (bpm) or null when unknown. Sourced from the standard 0x2A37 profile and from
  /// REALTIME_DATA frames on the custom channel.
  Stream<int?> get liveHr => _hrController.stream;

  /// Strap battery as a 0..1 fraction, or null when unknown.
  Stream<double?> get battery => _batteryController.stream;

  /// Whether the strap is charging: true/false when a battery frame reported it (WHOOP4
  /// GET_BATTERY_LEVEL response), null when unknown (the standard 0x2A19 profile has no charging
  /// bit). Additive to [battery] — the fraction stays a separate signal.
  Stream<bool?> get charging => _chargingController.stream;

  /// Historical-offload progress.
  Stream<SyncProgress> get syncProgress => _syncController.stream;

  /// The strap we are paired to: emits a [PairedStrap] the moment a connect succeeds (the real
  /// device id + resolved family + name are known), and null on disconnect. The provider layer
  /// persists the non-null emissions to [Prefs] so a later launch can auto-reconnect.
  Stream<PairedStrap?> get connectedStrap => _pairedController.stream;

  /// The rolling connection log — emits the full (newest-last) buffer on every new [_log] line, so
  /// the UI can render a live trace of scan/connect/offload/disconnect events. Broadcast, and inert
  /// until the first log (so subscribing off-device / in tests yields nothing).
  Stream<List<ConnLogEntry>> get connectionLog => _logController.stream;

  /// The current connection-log buffer (newest-last), for a synchronous read of what's landed so far.
  List<ConnLogEntry> get connectionLogNow => List.unmodifiable(_logBuffer);

  BleConnectionState _state = BleConnectionState.idle;
  BleConnectionState get state => _state;

  /// Last human-readable error surfaced (permissions denied, adapter off, not found, …). null = none.
  String? lastError;

  // ── test seams (radio-free state-machine exercising; never used at runtime) ──────────────────
  // These drive the client's REAL transitions from a REACHABLE state so the lifecycle fixes (#982
  // scan give-up, #HIGH-3 half-open teardown, #LOW-1 backoff reset) can be pinned by unit tests that
  // touch no radio (the project rule forbids launching). They fabricate no device data — they only
  // place the state machine where a scan / GATT callback would, then invoke the same code path.
  @visibleForTesting
  void debugSetState(BleConnectionState s) => _setState(s);

  @visibleForTesting
  void debugScanGiveUp() => _onScanGiveUp();

  @visibleForTesting
  Future<void> debugAbortBringUp(String error) => _abortBringUp(error);

  @visibleForTesting
  void debugResetForUserAction() => _resetBondStateForUserAction();

  @visibleForTesting
  int get debugReconnectAttempt => _reconnectAttempt;

  @visibleForTesting
  set debugReconnectAttempt(int v) => _reconnectAttempt = v;

  /// Whether an offload is in progress (drives the watchdog + live-path suppression).
  @visibleForTesting
  bool get debugSyncing => _syncing;

  /// Place the client in the mid-offload state a running sync would reach, so the watchdog recovery
  /// path is reachable radio-free (every GATT call is guarded behind `_blePlatform`, false in tests).
  @visibleForTesting
  void debugForceSyncing() {
    _syncing = true;
    _setState(BleConnectionState.syncing);
  }

  /// Fire the offload inactivity watchdog exactly as the real timer would.
  @visibleForTesting
  void debugFireOffloadWatchdog() => _onOffloadWatchdogFired();

  // ── bond hardening (Android bonding stack, ported from the Kotlin WhoopBleClient) ───────────
  /// Minimum time since the bond-loop pause tripped (or since the last probe) before another salvage
  /// probe may fire (#78 hole-4). 10 minutes: long enough that a still-held strap sees a handful of
  /// bounded attempts per day, short enough that a strap the user freed reconnects on the next natural
  /// app open. Twin of the Kotlin `BOND_LOOP_SALVAGE_FLOOR_MS`.
  static const int bondLoopSalvageFloorMs = 10 * 60 * 1000;

  /// Pure gate for the one-shot bond-loop salvage probe (#78 hole-4): probe ONLY while the pause is
  /// latched, with no live link, no user teardown in force, and at least [bondLoopSalvageFloorMs] since
  /// the pause tripped (or since the previous probe re-stamped it). null ms = no trip timestamp = never
  /// probe. Pure so the never-hammer contract is pinned by unit tests. Twin of the Kotlin
  /// `WhoopBleClient.shouldSalvageProbe`.
  static bool shouldSalvageProbe({
    required bool pausedForBondLoop,
    required bool connected,
    required bool intentionalDisconnect,
    required int? msSincePauseTripped,
  }) =>
      pausedForBondLoop &&
      !connected &&
      !intentionalDisconnect &&
      msSincePauseTripped != null &&
      msSincePauseTripped >= bondLoopSalvageFloorMs;

  int? _hrNow;
  double? _batteryNow;
  bool? _chargingNow;
  int? get liveHrNow => _hrNow;
  double? get batteryNow => _batteryNow;
  bool? get chargingNow => _chargingNow;

  // ── connection internals ──────────────────────────────────────────────────────────────────
  DeviceFamily _family = DeviceFamily.whoop4;
  Reassembler _reassembler = Reassembler();
  BluetoothDevice? _device;
  /// Advertised name of the strap currently being connected to, captured at scan-pick / connect time
  /// so a successful connect can emit a fully-populated [PairedStrap]. Null when unknown.
  String? _pairedName;
  BluetoothCharacteristic? _cmdChar;
  int _seq = 0;

  bool _syncing = false;
  /// Newest record timestamp (unix seconds) seen so far in the current offload, for the live
  /// SyncProgress `currentTs`/`percent`. Reset when an offload session starts.
  int? _offloadCurrentTsUnix;
  bool _intentionalDisconnect = false;
  bool _connected = false;
  int _reconnectAttempt = 0;

  // ── bond hardening state (Android only; inert off-device and in tests) ──────────────────────
  /// #971 bond-handshake watchdog pacer: escalates the createBond window per consecutive bounce and
  /// gives up after a capped number of tries.
  final BondWatchdogBackoff _bondWatchdog = BondWatchdogBackoff();
  /// #747/#750 give-up: pauses auto-reconnect + writes the epitaph after N consecutive bond refusals.
  final BondRefusalGiveUp _bondGiveUp = BondRefusalGiveUp();
  /// #617 detector: trips on consecutive bond-then-quick-timeout cycles (a WHOOP-4 bond loop).
  final PostBondTimeoutLoopDetector _postBondLoop = PostBondTimeoutLoopDetector();
  /// Whether the CURRENT connection reached a genuine bond (drives the loop detector's msSinceBond).
  bool _didBond = false;
  /// Wall-clock (epoch ms) when the current connection bonded, for the loop detector's quick-timeout test.
  int? _bondedAtMs;
  /// True while auto-reconnect is PAUSED by a bond give-up / loop trip — the reconnect path skips it.
  bool _autoReconnectPausedForBondLoop = false;
  /// When the bond-loop pause last tripped (epoch ms), feeding [shouldSalvageProbe]; null when clear.
  int? _bondLoopPausedAtMs;

  Timer? _scanFallbackTimer;
  /// #982 scan give-up: bounds every scan so a scan that never sees a matching strap can't wedge the
  /// client in `scanning` forever. On elapse (no match, not connected) [_onScanGiveUp] stops the scan,
  /// sets [lastError], and returns to a RETRYABLE idle. Twin of the Kotlin `scanTimeoutRunnable`.
  Timer? _scanGiveUpTimer;
  Timer? _liveFlushTimer;
  Timer? _offloadKickTimer;
  Timer? _reconnectTimer;
  /// Re-armed on every inbound offload frame; on elapse (still syncing) the offload is aborted so
  /// `syncing` can never wedge on a silent strap. See [offloadInactivityTimeout].
  Timer? _offloadWatchdog;
  /// Periodic proprietary battery poll while connected. See [batteryPollInterval].
  Timer? _batteryPollTimer;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  final List<StreamSubscription<List<int>>> _charSubs = [];

  // ── live-persistence buffer (port of the Kotlin Collector: custom realtime/event/battery frames) ──
  final List<Uint8List> _liveBuffer = [];
  bool _liveFlushInFlight = false;

  // ============================================================================================
  // Public control
  // ============================================================================================

  /// Begin a connection to a WHOOP strap. When [family] is null the model is auto-detected: the
  /// remembered family (from [rememberedStrapLookup]) seeds the scan filter if present, otherwise a
  /// universal scan (both WHOOP4 + WHOOP5 service filters) adopts whichever family actually advertises
  /// — so the caller never has to know the model (mirrors the Kotlin `fallbackScanModel` behaviour).
  /// Passing an explicit [family] keeps the old service-filtered scan. No-op (surfaces an error)
  /// off-device. Idempotent while a scan/connection is already active. Touches the radio.
  Future<void> connect({DeviceFamily? family}) async {
    if (!_blePlatform) {
      lastError = 'Bluetooth LE is only available on Android/iOS.';
      _log('connect ignored — no BLE on this platform');
      return;
    }
    if (_state == BleConnectionState.scanning ||
        _state == BleConnectionState.connecting) {
      _log('connect ignored — already scanning/connecting');
      return;
    }
    _intentionalDisconnect = false;
    lastError = null;
    _pairedName = null;
    _resetBondStateForUserAction(); // an explicit Connect re-arms the bond give-up / loop pause

    // Runtime permission gate first (mirrors the Kotlin caller contract).
    final granted = await ensureBlePermissions();
    if (!granted) {
      lastError = 'Bluetooth permission denied.';
      _setState(BleConnectionState.idle);
      return;
    }

    try {
      final supported = await FlutterBluePlus.isSupported;
      if (!supported) {
        lastError = 'This device has no Bluetooth LE.';
        _setState(BleConnectionState.idle);
        return;
      }
    } catch (e) {
      _log('isSupported check failed: $e');
    }

    // Adapter power gate (mirrors the Kotlin `adapter.isEnabled` check): don't scan against a
    // powered-off radio. Best-effort turn it on (Android); otherwise surface a clear error and stop.
    if (!await _ensureAdapterOn()) {
      _setState(BleConnectionState.idle);
      return;
    }

    // Family resolution: explicit arg wins; else the remembered family seeds a filtered scan (with
    // fallback rotation to the other family); else a universal scan adopts whichever advertises.
    final resolved = family ?? resolveConnectFamily(rememberedStrapLookup?.call());
    if (resolved != null) {
      _family = resolved;
      _startScan(resolved, allowFallback: true);
    } else {
      _startUniversalScan();
    }
  }

  /// Pure family-resolution rule for a null-family [connect] (unit-testable without a radio): the
  /// remembered strap's family if one is remembered, else null → the caller runs a universal scan.
  static DeviceFamily? resolveConnectFamily(PairedStrap? remembered) =>
      remembered?.family;

  /// Whether the Bluetooth adapter is powered on, best-effort turning it on first (Android only).
  /// Sets [lastError] and returns false when it stays off. Inert (returns true) off-device so tests
  /// never touch the radio. Mirrors the Kotlin `adapter.isEnabled` gate + `ACTION_REQUEST_ENABLE`.
  Future<bool> _ensureAdapterOn() async {
    if (!_blePlatform) return true;
    try {
      final state = await FlutterBluePlus.adapterState.first;
      if (state == BluetoothAdapterState.on) return true;
    } catch (e) {
      _log('adapterState read failed: $e — proceeding');
      return true; // a read failure shouldn't hard-block a connect attempt
    }
    // Best-effort power-on. `turnOn()` completes once the adapter reaches ON (Android only); iOS has
    // no programmatic toggle, so we can only surface the error there.
    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
        final state = await FlutterBluePlus.adapterState.first;
        if (state == BluetoothAdapterState.on) return true;
      } catch (e) {
        _log('turnOn() failed: $e');
      }
    }
    lastError = 'Bluetooth is off. Turn it on, then tap Connect.';
    _log('Bluetooth is off');
    return false;
  }

  /// Discover EVERY nearby WHOOP strap (both families) so the UI can show a picker instead of
  /// auto-connecting to the first advertiser. Starts a scan filtered to both WHOOP4 + WHOOP5 service
  /// UUIDs and emits the growing, de-duplicated-by-id list as advertisements arrive; the scan stops
  /// on [timeout], on stream cancel, or on [dispose]. This does NOT connect — call [connectToStrap]
  /// with the chosen entry.
  ///
  /// Guarded by platform (emits an empty list off-device), permission-gated via
  /// `ensureBlePermissions()`, and adapter-gated (Fix 1) — a denied permission or a powered-off
  /// adapter emits an empty list and sets [lastError] instead of touching the radio further.
  Stream<List<DiscoveredStrap>> discoverStraps(
      {Duration timeout = const Duration(seconds: 12)}) {
    final controller = StreamController<List<DiscoveredStrap>>();
    StreamSubscription<List<ScanResult>>? sub;
    Timer? stopTimer;
    final found = <String, DiscoveredStrap>{};

    Future<void> stop() async {
      stopTimer?.cancel();
      await sub?.cancel();
      sub = null;
      if (_blePlatform) {
        try {
          await FlutterBluePlus.stopScan();
        } catch (_) {}
      }
    }

    controller.onCancel = () async {
      await stop();
    };

    Future<void> run() async {
      if (!_blePlatform) {
        controller.add(const <DiscoveredStrap>[]);
        await controller.close();
        return;
      }
      final granted = await ensureBlePermissions();
      if (!granted) {
        lastError = 'Bluetooth permission denied.';
        controller.add(const <DiscoveredStrap>[]);
        await controller.close();
        return;
      }
      if (!await _ensureAdapterOn()) {
        controller.add(const <DiscoveredStrap>[]);
        await controller.close();
        return;
      }

      sub = FlutterBluePlus.scanResults.listen((results) {
        var changed = false;
        for (final r in results) {
          final family = _familyOfResult(r);
          if (family == null) continue;
          final id = r.device.remoteId.str;
          final name = r.advertisementData.advName.isNotEmpty
              ? r.advertisementData.advName
              : (r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : 'WHOOP ${family == DeviceFamily.whoop5 ? '5' : '4'}');
          final existing = found[id];
          if (existing == null ||
              existing.rssi != r.rssi ||
              existing.name != name) {
            found[id] = DiscoveredStrap(
                id: id, name: name, rssi: r.rssi, family: family);
            changed = true;
          }
        }
        if (changed && !controller.isClosed) {
          final list = found.values.toList()
            ..sort((a, b) => b.rssi.compareTo(a.rssi));
          controller.add(list);
        }
      }, onError: (Object e) {
        _log('discover scan error: $e');
      });

      stopTimer = Timer(timeout, () async {
        await stop();
        if (!controller.isClosed) await controller.close();
      });

      try {
        await FlutterBluePlus.startScan(
          withServices: [
            Guid(DeviceFamily.whoop4.serviceUuidString),
            Guid(DeviceFamily.whoop5.serviceUuidString),
          ],
          timeout: timeout,
        );
        _log('Discover: scanning both WHOOP families for straps');
      } catch (e) {
        lastError = 'Scan failed to start: $e';
        _log(lastError!);
        await stop();
        if (!controller.isClosed) await controller.close();
      }
    }

    unawaited(run());
    return controller.stream;
  }

  /// Connect directly to a strap the user picked from [discoverStraps], skipping the auto-first-match
  /// scan. Reuses the same connect/discover/handshake path as [connect]; the family comes from the
  /// chosen [strap]. No-op (surfaces an error) off-device or while already scanning/connecting.
  Future<void> connectToStrap(DiscoveredStrap strap) async {
    if (!_blePlatform) {
      lastError = 'Bluetooth LE is only available on Android/iOS.';
      _log('connectToStrap ignored — no BLE on this platform');
      return;
    }
    if (_state == BleConnectionState.scanning ||
        _state == BleConnectionState.connecting) {
      _log('connectToStrap ignored — already scanning/connecting');
      return;
    }
    _intentionalDisconnect = false;
    lastError = null;
    _resetBondStateForUserAction(); // an explicit pick re-arms the bond give-up / loop pause

    final granted = await ensureBlePermissions();
    if (!granted) {
      lastError = 'Bluetooth permission denied.';
      _setState(BleConnectionState.idle);
      return;
    }
    if (!await _ensureAdapterOn()) {
      _setState(BleConnectionState.idle);
      return;
    }

    // Stop any auto-pick scan already in flight, then connect straight to the chosen device+family.
    _scanFallbackTimer?.cancel();
    _scanGiveUpTimer?.cancel();
    await _scanSub?.cancel();
    _scanSub = null;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    _family = strap.family;
    _pairedName = strap.name;
    _connectToDevice(BluetoothDevice.fromId(strap.id));
  }

  /// Reconnect directly to the remembered strap ([rememberedStrapLookup]) — `BluetoothDevice.fromId`
  /// with the remembered family, NO scan (mirrors the Kotlin direct-connect-to-lastDevice path, which
  /// beats a scan for a bonded strap the OS still holds or that isn't advertising). When nothing is
  /// remembered this falls back to a universal scan-and-connect. No-op (surfaces an error) off-device
  /// or while already scanning/connecting. This is the auto-reconnect entry point.
  Future<void> connectRemembered() async {
    if (!_blePlatform) {
      lastError = 'Bluetooth LE is only available on Android/iOS.';
      _log('connectRemembered ignored — no BLE on this platform');
      return;
    }
    if (_state == BleConnectionState.scanning ||
        _state == BleConnectionState.connecting) {
      _log('connectRemembered ignored — already scanning/connecting');
      return;
    }
    final remembered = rememberedStrapLookup?.call();
    if (remembered == null) {
      _log('connectRemembered — nothing remembered, running a universal scan');
      await connect();
      return;
    }
    // Honour a latched bond-loop pause: auto-reconnect is allowed only as a bounded salvage probe.
    if (!_allowAutoReconnectWhilePaused()) {
      _setState(BleConnectionState.idle);
      return;
    }
    _intentionalDisconnect = false;
    lastError = null;
    // #LOW-1: reset the reconnect-backoff ramp so this user-initiated (re)connect starts fresh. Unlike
    // [_resetBondStateForUserAction] we do NOT lift the bond-loop pause here (this path honours it above).
    _reconnectAttempt = 0;

    final granted = await ensureBlePermissions();
    if (!granted) {
      lastError = 'Bluetooth permission denied.';
      _setState(BleConnectionState.idle);
      return;
    }
    if (!await _ensureAdapterOn()) {
      _setState(BleConnectionState.idle);
      return;
    }

    _family = remembered.family;
    _pairedName = remembered.name;
    _log('Auto-reconnect: connecting directly to remembered ${remembered.family.name} strap');
    _connectToDevice(BluetoothDevice.fromId(remembered.id));
  }

  /// Which WHOOP family (if any) a scan result advertises, by matching its advertised service UUIDs
  /// against both families' custom service GUIDs.
  static DeviceFamily? _familyOfResult(ScanResult r) {
    final uuids = r.advertisementData.serviceUuids;
    final whoop4 = Guid(DeviceFamily.whoop4.serviceUuidString);
    final whoop5 = Guid(DeviceFamily.whoop5.serviceUuidString);
    if (uuids.contains(whoop5)) return DeviceFamily.whoop5;
    if (uuids.contains(whoop4)) return DeviceFamily.whoop4;
    return null;
  }

  /// Intentional teardown: stop scanning, drop the link, and DO NOT auto-reconnect.
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _resetBondStateForUserAction(); // an explicit disconnect clears any latched bond-loop pause
    _log('Disconnect requested — dropping the link (no auto-reconnect)');
    _cancelTimers();
    await _teardownConnection();
    _setState(BleConnectionState.idle);
  }

  /// While the bond-loop pause is latched, auto-reconnect is allowed ONLY as a bounded salvage probe,
  /// at most once per [bondLoopSalvageFloorMs] (#78 hole-4): a strap the user has since freed self-heals
  /// on the next app-foreground, while a still-held strap gets at most one bounded attempt per floor
  /// window (the give-up stays latched throughout — a genuine bond on the probe is what fully clears it
  /// via [_onGenuineBond]). Returns true if the caller may proceed (re-stamping the floor so the next
  /// probe waits another window); false to stay paused. Not paused → always proceed.
  bool _allowAutoReconnectWhilePaused() {
    if (!_autoReconnectPausedForBondLoop) return true;
    final since = _bondLoopPausedAtMs == null
        ? null
        : DateTime.now().millisecondsSinceEpoch - _bondLoopPausedAtMs!;
    if (!shouldSalvageProbe(
      pausedForBondLoop: _autoReconnectPausedForBondLoop,
      connected: _connected,
      intentionalDisconnect: _intentionalDisconnect,
      msSincePauseTripped: since,
    )) {
      _log('bond-loop pause latched — skipping auto-reconnect (salvage floor not reached)');
      return false;
    }
    _bondLoopPausedAtMs = DateTime.now().millisecondsSinceEpoch; // re-stamp: next probe waits a floor
    _log('bond-loop salvage probe: one bounded reconnect attempt while paused (#78)');
    return true;
  }

  /// A user-initiated connect/disconnect re-arms the whole bond hardening stack: clears the refusal /
  /// watchdog / loop streaks, lifts any latched auto-reconnect pause, and resets the reconnect-backoff
  /// counter — so a fresh tap always retries the bond AND the reconnect ramp from a clean slate
  /// (mirrors the Kotlin `clearPairingHint` + `resetReconnectBackoff`). Without the backoff reset (#LOW-1)
  /// a manual Connect after prior involuntary drops would start the next drop's wait at the capped-max
  /// delay instead of restarting the ramp.
  void _resetBondStateForUserAction() {
    _bondWatchdog.reset();
    _bondGiveUp.reset();
    _postBondLoop.reset();
    _autoReconnectPausedForBondLoop = false;
    _bondLoopPausedAtMs = null;
    _reconnectAttempt = 0;
  }

  // ============================================================================================
  // Strap smart-alarm (program the strap's own firmware wake alarm — smart-alarm spec §2-§5)
  // ============================================================================================

  /// Program (or clear) the strap's own firmware wake alarm over BLE (spec §2/§4). It fires the wake
  /// haptic on the strap's own RTC even with the phone away.
  ///
  /// - `enabled == false` → send DISABLE_ALARM (cmd 69, `[0x02,0xFF]`) to clear the single slot. Always
  ///   allowed (a no-op on a strap with no alarm).
  /// - WHOOP 4.0 → the hardware-confirmed 9-byte form ([AlarmPayload.buildWhoop4]); a completed
  ///   write-with-response is the arm ACK.
  /// - WHOOP 5.0/MG → the 20-byte rev4 form ([AlarmPayload.build]), GATED behind
  ///   [experimentalWhoop5AlarmOptIn] (UNCONFIRMED to wake real hardware, spec §7). When not opted in,
  ///   arming is skipped (the alarm honestly stays queued); the queued→armed flip waits for a
  ///   COMMAND_RESPONSE result=SUCCESS.
  ///
  /// Safe with no device: when there is no command characteristic (disconnected) this no-ops, so the
  /// write-side status stays "queued". Also fires a log-only GET_ALARM_TIME readback (spec §3).
  Future<void> setStrapAlarm(DateTime wake, {bool enabled = true}) async {
    final ch = _cmdChar;
    if (ch == null) {
      _log('setStrapAlarm ignored — no strap link (alarm stays queued)');
      return;
    }
    if (!enabled) {
      _log('Strap alarm: DISABLE_ALARM (clearing the firmware slot)');
      unawaited(_write(ch, _frameFor(CommandNumber.disableAlarm, AlarmPayload.disableRev2())));
      return;
    }
    final Uint8List payload;
    if (_family == DeviceFamily.whoop5) {
      if (!(experimentalWhoop5AlarmOptIn?.call() ?? false)) {
        _log('Strap alarm: WHOOP 5/MG rev4 alarm is experimental & not opted in — not arming (spec §7)');
        return;
      }
      payload = AlarmPayload.build(wake.millisecondsSinceEpoch);
    } else {
      payload = AlarmPayload.buildWhoop4(wake.millisecondsSinceEpoch ~/ 1000);
    }
    _log('Strap alarm: SET_ALARM_TIME ${wake.toIso8601String()} '
        '(${_family.name}, ${payload.length}-byte payload)');
    final ok = await _writeChecked(ch, _frameFor(CommandNumber.setAlarmTime, payload));
    // WHOOP4: a completed write-with-response IS the arm ACK (the strap sends no CR for cmd 66). 5/MG
    // waits for the COMMAND_RESPONSE result=SUCCESS in [_handleCommandResponse] before declaring armed.
    if (ok && _family == DeviceFamily.whoop4) _emitAlarmArmed();
    // Log-only readback — decoded defensively, never gates behaviour (spec §3).
    unawaited(_write(ch, _frameFor(CommandNumber.getAlarmTime, _alarmReadbackRequest())));
  }

  /// Read back the strap's armed alarm (GET_ALARM_TIME, cmd 67). Sends the request and awaits the next
  /// defensively-decoded [alarmReadback] emission (short timeout). Returns null on anything unexpected —
  /// the response layout is undocumented, so this NEVER crashes or gates behaviour (spec §3).
  Future<StrapAlarm?> getStrapAlarm() async {
    final ch = _cmdChar;
    if (ch == null) {
      _log('getStrapAlarm ignored — no strap link');
      return null;
    }
    // Attach the listener BEFORE sending so we can't miss the reply.
    final pending = alarmReadback.first
        .timeout(const Duration(seconds: 3), onTimeout: () => null)
        .catchError((Object _) => null);
    unawaited(_write(ch, _frameFor(CommandNumber.getAlarmTime, _alarmReadbackRequest())));
    final epochMs = await pending;
    return epochMs == null ? null : StrapAlarm(wakeEpochMs: epochMs);
  }

  /// GET_ALARM_TIME request payload per family: `[0x04,0x01]` (rev4, alarmId 1) for 5/MG, `[0x01]` for
  /// WHOOP4 (spec §3.1).
  List<int> _alarmReadbackRequest() =>
      _family == DeviceFamily.whoop5 ? const [0x04, 0x01] : const [0x01];

  void _emitAlarmArmed() {
    _log('Strap alarm armed — SET_ALARM_TIME acked by the strap');
    if (!_alarmArmedController.isClosed) _alarmArmedController.add(null);
  }

  // Plausibility window for a decoded alarm epoch (SECONDS): 2017-07 … 2100 (spec §3.2).
  static const int _alarmEpochFloor = 1500000000;
  static const int _alarmEpochCeil = 4102444800;

  /// Defensive GET_ALARM_TIME response decoder (spec §3.2) — port of the Kotlin `whoop4ArmedAlarmEpoch`
  /// + plausibility gate. Payload starts after the COMMAND_RESPONSE header (abs offset 9 on WHOOP4, 13
  /// on 5/MG). Tries two shapes, first plausible wins: (1) SET-mirror `[0x01][u32 LE epoch]`, (2) bare
  /// `u32 LE epoch`. Returns epoch MILLIS, or null when nothing plausible decodes (never throws).
  int? _decodeArmedAlarmEpochMs(Uint8List frame) {
    final payOff = _family == DeviceFamily.whoop5 ? 13 : 9;
    // Shape 1: SET-mirror — a leading 0x01 then the u32 LE epoch.
    if (payOff < frame.length && (frame[payOff] & 0xFF) == 0x01) {
      final e = _u32le(frame, payOff + 1);
      if (e != null && e >= _alarmEpochFloor && e <= _alarmEpochCeil) return e * 1000;
    }
    // Shape 2: a bare u32 LE epoch at the payload start.
    final e = _u32le(frame, payOff);
    if (e != null && e >= _alarmEpochFloor && e <= _alarmEpochCeil) return e * 1000;
    return null;
  }

  static int? _u8f(Uint8List f, int off) => off < f.length ? f[off] & 0xFF : null;

  static int? _u32le(Uint8List f, int off) {
    if (off < 0 || off + 4 > f.length) return null;
    return (f[off] & 0xFF) |
        ((f[off + 1] & 0xFF) << 8) |
        ((f[off + 2] & 0xFF) << 16) |
        ((f[off + 3] & 0xFF) << 24);
  }

  // ============================================================================================
  // Haptics + device config (device-config-and-haptics spec §4/§6) — buzz/locate + Broadcast-HR
  // ============================================================================================

  /// Buzz the strap once so the user can LOCATE it on the wrist (spec §6). Family-aware, both forms
  /// mirror the confirmed official-app buzz:
  ///  - WHOOP 5.0/MG → the one-shot "maverick" notification buzz, cmd 0x13
  ///    ([CommandNumber.runHapticPatternMaverick]) carrying the 12-byte DRV2625 notify body
  ///    ([HapticPattern.maverickNotifyBody]). A raw legacy 79 is rejected on real MG (spec §6.2), so
  ///    the correct opcode is sent per family — no un-honored write ever goes out.
  ///  - WHOOP 4.0 → the legacy `RUN_HAPTICS_PATTERN` (cmd 79) with `[patternId 2, loops, 0,0,0]`.
  ///
  /// Written with response (the char supports it, mirroring the Kotlin acked buzz). No-op (logs) when
  /// there is no command characteristic (disconnected) — safe on every non-device path, so a plain
  /// `flutter test` never buzzes. [loops] applies to the WHOOP 4.0 form only.
  Future<void> runHaptic({int loops = 3}) async {
    final ch = _cmdChar;
    if (ch == null) {
      _log('runHaptic ignored — no strap link');
      return;
    }
    final CommandNumber cmd;
    final Uint8List body;
    if (_family == DeviceFamily.whoop5) {
      cmd = CommandNumber.runHapticPatternMaverick; // 0x13
      body = HapticPattern.maverickNotifyBody();
    } else {
      cmd = CommandNumber.runHapticsPattern; // 0x4F
      body = HapticPattern.whoop4BuzzBody(loops: loops);
    }
    _log('Haptics: locate buzz (${_family.name}, cmd 0x'
        '${cmd.rawValue.toRadixString(16)})');
    await _write(ch, _frameFor(cmd, body));
  }

  /// Enable/disable Broadcast-HR on the strap (spec §4): one SET_DEVICE_CONFIG (0x77) write of the
  /// confirmed key [Whoop5Config.broadcastHrKey] = '1'/'0', which makes the strap advertise its heart
  /// rate as a standard 0x180D BLE sensor a Garmin / Zwift / gym receiver can pair to directly. This is
  /// a WHOOP 5.0/MG device-config (0x77 is a puffin command) — a no-op (logs) on WHOOP 4.0 or with no
  /// link. Confirmed on real hardware (paired on a Garmin Edge 840), so it is NOT gated behind the
  /// experimental opt-in. Reversible (write '0' to turn it back off).
  Future<void> setDeviceConfig({required bool broadcastHr}) async {
    final ch = _cmdChar;
    if (ch == null) {
      _log('setDeviceConfig ignored — no strap link');
      return;
    }
    if (_family != DeviceFamily.whoop5) {
      _log('setDeviceConfig ignored — Broadcast-HR is a WHOOP 5/MG device-config (not WHOOP 4.0)');
      return;
    }
    final value = broadcastHr ? 0x31 : 0x30; // ASCII '1' / '0'
    _log('Device config: Broadcast-HR ${broadcastHr ? 'ON' : 'OFF'} '
        '(SET_DEVICE_CONFIG ${Whoop5Config.broadcastHrKey})');
    await _write(
      ch,
      _frameFor(CommandNumber.setDeviceConfig,
          Whoop5Config.deviceConfigPayload(Whoop5Config.broadcastHrKey, value)),
    );
  }

  /// Release all resources. Safe to call multiple times.
  Future<void> dispose() async {
    _intentionalDisconnect = true;
    _cancelTimers();
    await _teardownConnection();
    await _connController.close();
    await _hrController.close();
    await _batteryController.close();
    await _chargingController.close();
    await _syncController.close();
    await _pairedController.close();
    await _logController.close();
    await _alarmArmedController.close();
    await _alarmFiredController.close();
    await _alarmReadbackController.close();
  }

  // ============================================================================================
  // Scan (Kotlin scanForWhoops + the fallback rotation)
  // ============================================================================================

  void _startScan(DeviceFamily family, {required bool allowFallback}) {
    if (!_blePlatform) return;
    _family = family;
    _setState(BleConnectionState.scanning);
    _scanFallbackTimer?.cancel();
    _scanGiveUpTimer?.cancel();
    _scanSub?.cancel();

    final serviceGuid = Guid(family.serviceUuidString);

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      if (results.isEmpty) return;
      // First advertiser wins (the scan is already service-filtered to this family).
      final ScanResult r = results.first;
      _scanSub?.cancel();
      _scanSub = null;
      _scanFallbackTimer?.cancel();
      _scanGiveUpTimer?.cancel();
      _pairedName = _nameOfResult(r, family);
      _log('Strap found: ${_pairedName!} (${family.name}) — connecting');
      unawaited(FlutterBluePlus.stopScan());
      _connectToDevice(r.device);
    }, onError: (Object e) {
      _log('scan error: $e');
    });

    // Fallback rotation: nothing on this family after [scanFallbackDelay] → try the other family
    // (a stale/missing persisted preference can point the scan at the wrong service). (Kotlin PR#195)
    if (allowFallback) {
      _scanFallbackTimer = Timer(scanFallbackDelay, () {
        if (_connected) return;
        final fallback = _fallbackFamily(family);
        _log('Scan: no ${family.name} found — rotating to ${fallback.name}');
        unawaited(FlutterBluePlus.stopScan());
        _startScan(fallback, allowFallback: false);
      });
    }

    try {
      unawaited(FlutterBluePlus.startScan(
        withServices: [serviceGuid],
        timeout: scanTimeout,
      ));
      _log('Scan: looking for a ${family.name} strap (${family.serviceUuidString})');
      // Bound this scan so a no-match never wedges us in `scanning` (#982). Re-armed per family, so a
      // fallback rotation resets the window; a match/connect cancels it above.
      _scanGiveUpTimer?.cancel();
      _scanGiveUpTimer = Timer(scanTimeout, _onScanGiveUp);
    } catch (e) {
      lastError = 'Scan failed to start: $e';
      _log(lastError!);
      _setState(BleConnectionState.idle);
    }
  }

  static DeviceFamily _fallbackFamily(DeviceFamily f) =>
      f == DeviceFamily.whoop4 ? DeviceFamily.whoop5 : DeviceFamily.whoop4;

  /// The scan give-up (#982 / MASTER-BACKLOG HIGH-2): a scan that never sees a matching strap (strap on
  /// its charger, held by the official app, or out of range) used to leave the client stuck in
  /// `scanning` forever — `connect()`/`connectRemembered()` then early-return on the scanning guard, so
  /// Connect was permanently dead until an app restart. Every [_startScan]/[_startUniversalScan] arms
  /// [_scanGiveUpTimer] for [scanTimeout]; on elapse (still scanning, nothing found) we stop the scan,
  /// set a clear [lastError], and drop back to a RETRYABLE idle. Twin of the Kotlin `scanTimeoutRunnable`.
  /// Guarded so a match/connect/teardown that already left `scanning` makes this a no-op.
  void _onScanGiveUp() {
    if (_connected || _state != BleConnectionState.scanning) return;
    _scanFallbackTimer?.cancel();
    _scanGiveUpTimer?.cancel();
    _scanSub?.cancel();
    _scanSub = null;
    if (_blePlatform) {
      try {
        unawaited(FlutterBluePlus.stopScan());
      } catch (_) {}
    }
    lastError = 'No WHOOP strap found';
    _log('Scan timed out — no WHOOP strap found; giving up (state → idle, retryable)');
    _setState(BleConnectionState.idle);
  }

  /// Universal auto-detect scan: filter on BOTH families' service UUIDs at once and connect to the
  /// first WHOOP that advertises, adopting its family from the advertised service UUID (Kotlin
  /// `fallbackScanModel`). Used by [connect] when the caller passes no family and nothing is
  /// remembered — the user never has to pick the model.
  void _startUniversalScan() {
    if (!_blePlatform) return;
    _setState(BleConnectionState.scanning);
    _scanFallbackTimer?.cancel();
    _scanGiveUpTimer?.cancel();
    _scanSub?.cancel();

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final fam = _familyOfResult(r);
        if (fam == null) continue;
        _scanSub?.cancel();
        _scanSub = null;
        _scanGiveUpTimer?.cancel();
        _family = fam;
        _pairedName = _nameOfResult(r, fam);
        _log('Strap found: ${_pairedName!} (${fam.name}) — connecting');
        unawaited(FlutterBluePlus.stopScan());
        _connectToDevice(r.device);
        return;
      }
    }, onError: (Object e) {
      _log('universal scan error: $e');
    });

    try {
      unawaited(FlutterBluePlus.startScan(
        withServices: [
          Guid(DeviceFamily.whoop4.serviceUuidString),
          Guid(DeviceFamily.whoop5.serviceUuidString),
        ],
        timeout: scanTimeout,
      ));
      _log('Scan: universal (both WHOOP families) — auto-detecting the model');
      // Bound the universal scan too (#982): no WHOOP of either family → give up to a retryable idle.
      _scanGiveUpTimer?.cancel();
      _scanGiveUpTimer = Timer(scanTimeout, _onScanGiveUp);
    } catch (e) {
      lastError = 'Scan failed to start: $e';
      _log(lastError!);
      _setState(BleConnectionState.idle);
    }
  }

  /// The advertised name for a scan result, or a family-derived fallback when the advert carries none
  /// (mirrors the [discoverStraps] naming).
  static String _nameOfResult(ScanResult r, DeviceFamily family) =>
      r.advertisementData.advName.isNotEmpty
          ? r.advertisementData.advName
          : (r.device.platformName.isNotEmpty
              ? r.device.platformName
              : 'WHOOP ${family == DeviceFamily.whoop5 ? '5' : '4'}');

  // ============================================================================================
  // Connect + discover (Kotlin connectToDevice + onConnectionStateChange + onServicesDiscovered)
  // ============================================================================================

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _device = device;
    _setState(BleConnectionState.connecting);
    _log('Connecting to ${device.remoteId.str} (${_family.name})');
    _reassembler = Reassembler(_family);

    _connSub?.cancel();
    _connSub = device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.connected) {
        _onConnected(device);
      } else if (s == BluetoothConnectionState.disconnected) {
        _onDisconnected();
      }
    });

    try {
      // License.nonprofit: NOOP is an open-source app with no Pro tier (see the flutter_blue_plus 2.x
      // source-available license). A commercial release would need the paid license instead.
      await device.connect(
          license: License.nonprofit, timeout: const Duration(seconds: 35));
    } catch (e) {
      _log('connect() failed: $e');
      _onDisconnected();
    }
  }

  Future<void> _onConnected(BluetoothDevice device) async {
    if (_connected) return; // guard against duplicate connected events
    _connected = true;
    _didBond = false; // each fresh connection starts unbonded until proven (drives the loop detector)
    _bondedAtMs = null;
    _reconnectAttempt = 0; // a real connect clears the backoff (Kotlin resetReconnectBackoff)
    _reassembler.reset();
    _log('Connected — discovering services');

    List<BluetoothService> services;
    try {
      services = await device.discoverServices();
    } catch (e) {
      // #HIGH-3: discovery threw → we hold a live-but-useless GATT link with _state stuck at
      // `connecting`. Tear the link down and drop to a retryable idle (mirrors the _ensureBonded==false
      // path) instead of wedging so Connect can be retried.
      await _abortBringUp('Service discovery failed: $e');
      return;
    }
    _log('Services discovered (${services.length})');

    // Locate the custom WHOOP service for the family we scanned for; if the OTHER family answered
    // (fallback rotation raced), adopt it. Mirrors the Kotlin whoop4/whoop5 branch.
    BluetoothService? custom = _serviceByUuid(services, _family.serviceUuidString);
    if (custom == null) {
      final other = _fallbackFamily(_family);
      final maybe = _serviceByUuid(services, other.serviceUuidString);
      if (maybe != null) {
        _family = other;
        _reassembler = Reassembler(_family)..reset();
        custom = maybe;
      }
    }
    if (custom == null) {
      // #HIGH-3: the custom WHOOP service isn't present → same half-open-link wedge as a discovery
      // throw. Tear down and go retryable-idle rather than sitting in `connecting` forever.
      _log('Custom WHOOP service not found on this peripheral');
      await _abortBringUp('Not a WHOOP strap (service not found).');
      return;
    }

    _cmdChar = _charByUuid(custom, _family.commandCharacteristicUuidString);

    // Standard profiles first (they work unbonded — the reliable HR + battery source).
    final hrChar = _standardChar(services, _hrServiceUuid, _hrCharUuid);
    final battChar = _standardChar(services, _batteryServiceUuid, _batteryCharUuid);
    if (hrChar != null) {
      await _subscribe(hrChar, (v) => _onStandardHr(v));
    }
    if (battChar != null) {
      await _subscribe(battChar, (v) => _onStandardBattery(v));
    }

    // Ensure the strap is BONDED before enabling the WHOOP custom notify CCCDs. The encrypted custom
    // characteristics only stream on a bonded link; a fresh (never-paired) WHOOP otherwise wedges in
    // "finishing the secure handshake" and loops. Android-only (iOS/CoreBluetooth owns pairing) and
    // inert off-device; on a give-up / bond loop this returns false and we stop the bring-up.
    final bonded = await _ensureBonded(device);
    if (!bonded) {
      // Drop the wedged link. If the bond give-up / loop detector latched the pause, [_onDisconnected]
      // skips the reconnect; otherwise it backoff-reconnects and retries with a wider bond window.
      // No lastError/idle here on purpose: the bond stack owns the paused hint + state on a give-up.
      await _disconnectDevice(device);
      return;
    }

    if (_family == DeviceFamily.whoop5) {
      await _bringUpWhoop5(custom);
    } else {
      await _bringUpWhoop4(custom);
    }

    _setState(BleConnectionState.connected);
    // We have the real device id + the resolved family now — publish the pairing so the provider layer
    // can remember it for auto-reconnect on a later launch.
    _publishPaired(PairedStrap(
      id: device.remoteId.str,
      family: _family,
      name: _pairedName,
    ));
    _startLiveFlushTimer();
    _runConnectHandshake();
    _reconcileStrapAlarmOnConnect();
  }

  /// After the connect handshake (so SET_CLOCK has latched the strap RTC — the alarm fires on the
  /// strap's own clock, spec §6.1) push the write-side's currently-enabled alarm to the strap. No-op
  /// when nothing is enabled or no lookup is wired. The SET ack flips the write-side queued→armed via
  /// [alarmArmed]; on 5/MG without the experimental opt-in [setStrapAlarm] skips arming (stays queued).
  void _reconcileStrapAlarmOnConnect() {
    final wake = strapAlarmReconcileLookup?.call();
    if (wake == null) {
      _log('Strap alarm: nothing enabled to reconcile on connect');
      return;
    }
    _log('Strap alarm: reconciling the enabled alarm on connect');
    unawaited(setStrapAlarm(wake, enabled: true));
  }

  /// Best-effort GATT teardown of a single device (Android/iOS only; a no-op off-device and in tests).
  /// The subsequent `disconnected` state event fires [_onDisconnected], which owns the state reset and
  /// the backoff reconnect. Swallows any disconnect error — we're already on a failure path.
  Future<void> _disconnectDevice(BluetoothDevice device) async {
    if (!_blePlatform) return;
    try {
      await device.disconnect();
    } catch (_) {}
  }

  /// Abort a post-connect bring-up that can't proceed (discovery threw or the custom WHOOP service is
  /// missing — MASTER-BACKLOG HIGH-3). Surfaces [error], tears down the half-open GATT link, and — so
  /// the client never stays wedged in `connecting` with a live-but-useless link — drops immediately to
  /// a RETRYABLE idle. On-device the disconnect also drives [_onDisconnected] (backoff reconnect);
  /// off-device (tests) the explicit idle transition is the observable recovery. Uses the current
  /// [_device] so it needs no argument and stays trivially exercisable without a radio.
  Future<void> _abortBringUp(String error) async {
    lastError = error;
    _log('Bring-up aborted ($error) — tearing down the half-open link (state → idle, retryable)');
    final device = _device;
    if (device != null) await _disconnectDevice(device);
    if (_state == BleConnectionState.connecting) _setState(BleConnectionState.idle);
  }

  // ============================================================================================
  // Bond handshake (Android bonding stack, ported from the Kotlin WhoopBleClient)
  // ============================================================================================

  /// Make sure [device] is BONDED before we enable the WHOOP custom notify CCCDs.
  ///
  /// Bonding is an Android concept: `flutter_blue_plus` exposes `bondState` / `createBond()` only on
  /// Android, while iOS/CoreBluetooth performs (just-works) pairing implicitly when the first encrypted
  /// characteristic is touched — so off Android this is a no-op that proceeds straight to the bring-up.
  ///
  /// The Kotlin transport forces the WHOOP-4 just-works bond with a confirmed GET_BATTERY_LEVEL write
  /// once notifications are on; `flutter_blue_plus` gives us an explicit `createBond()` that performs
  /// the same OS pairing without the write trick, so we gate the custom-CCCD enable behind it. The
  /// createBond timeout uses the escalating [BondWatchdogBackoff] window so a slow-but-healthy bond gets
  /// progressively more time, and repeated failures feed [BondRefusalGiveUp] so we stop hammering a
  /// strap that keeps refusing (surfacing the re-pair guide instead of an infinite loop).
  ///
  /// Returns true when the link is bonded (or bonding doesn't apply); false when the bond failed — the
  /// caller drops the link, and a give-up will already have latched the auto-reconnect pause.
  Future<bool> _ensureBonded(BluetoothDevice device) async {
    if (!_blePlatform || !Platform.isAndroid) return true;

    BluetoothBondState current;
    try {
      current = await device.bondState.first;
    } catch (e) {
      _log('bondState read failed: $e — proceeding without an explicit bond');
      return true; // a bond-state read failure shouldn't hard-block the bring-up
    }
    if (current == BluetoothBondState.bonded) {
      _log('bondState bonded (already paired)');
      _onGenuineBond();
      return true;
    }

    // Not bonded: force the OS pairing BEFORE enabling the encrypted custom notify CCCDs.
    final windowMs = _bondWatchdog.currentWindowMs();
    _log('bondState bonding — requesting createBond (window ${windowMs ~/ 1000}s)');
    try {
      await device.createBond(timeout: (windowMs / 1000).ceil());
      _log('bondState bonded');
      _onGenuineBond();
      return true;
    } catch (e) {
      return _onBondFailed(device, e);
    }
  }

  /// A genuine bond landed: mark the connection bonded (for the loop detector) and re-arm the whole
  /// stack — clear the refusal + watchdog streaks and lift any latched pause (mirrors Kotlin
  /// `clearPairingHint`). The bond-loop detector is deliberately NOT reset here: it must survive across
  /// bond→drop→bond→drop cycles and is cleared only by a healthy session or a user teardown.
  void _onGenuineBond() {
    _didBond = true;
    _bondedAtMs = DateTime.now().millisecondsSinceEpoch;
    _bondWatchdog.reset();
    _bondGiveUp.reset();
    _autoReconnectPausedForBondLoop = false;
    _bondLoopPausedAtMs = null;
  }

  /// createBond failed (refusal or handshake-never-landed). Feed BOTH give-up trackers: the refusal
  /// counter (#747/#750) stops the hammering after N refusals, and the watchdog (#971) escalates the
  /// window and independently gives up after a capped number of stuck handshakes. If EITHER gives up we
  /// latch the auto-reconnect pause and surface the re-pair guide; otherwise we return false so the
  /// caller drops the link and the backoff reconnect retries with a wider bond window. Always false.
  bool _onBondFailed(BluetoothDevice device, Object error) {
    final refusalGaveUp = _bondGiveUp.recordRefusal();
    final watchdogGaveUp = _bondWatchdog.recordBounce();
    _log('bond refused (attempt ${_bondGiveUp.refusals}): $error');
    if (refusalGaveUp || watchdogGaveUp) {
      _enterBondLoopPause(device.remoteId.str,
          refusalGaveUp ? 'bond refused' : 'bond handshake never completed');
    } else {
      _log('bond not established; dropping link to retry '
          '(bond attempt ${_bondWatchdog.consecutiveBounces})');
    }
    return false;
  }

  /// Latch the auto-reconnect pause + surface the re-pair guide once. Stamps [_bondLoopPausedAtMs] so a
  /// paused strap the user later frees can be re-probed past [bondLoopSalvageFloorMs] (see
  /// [shouldSalvageProbe]), writes the one-line PII-free epitaph, and sets [lastError] to the honest
  /// paused hint so the device screen shows why NOOP stopped retrying.
  void _enterBondLoopPause(String address, String cause) {
    _autoReconnectPausedForBondLoop = true;
    _bondLoopPausedAtMs = DateTime.now().millisecondsSinceEpoch;
    final opaque = BondRefusalGiveUp.opaqueId(address);
    _log(BondRefusalGiveUp.epitaphLine(_bondGiveUp.refusals, opaque));
    _log('bond loop detected ($cause) — pausing auto-reconnect and surfacing the re-pair guide');
    lastError = BondRefusalGiveUp.pausedHint();
  }

  /// WHOOP 4.0 bring-up: subscribe the three custom notify chars (CMD/EVENT/DATA). Kotlin fires a
  /// confirmed GET_BATTERY_LEVEL "bond" write once notifications are on — we do the same in the
  /// handshake, so the bond write never races the CCCD subscribes (Kotlin issue #12).
  Future<void> _bringUpWhoop4(BluetoothService custom) async {
    for (final uuid in _notifyUuids(DeviceFamily.whoop4)) {
      final ch = _charByUuid(custom, uuid);
      if (ch != null) await _subscribe(ch, _onCustomFrameBytes);
    }
  }

  /// WHOOP 5.0/MG bring-up (experimental, mirrors the Kotlin 5/MG path): write CLIENT_HELLO to the
  /// command char (just-works bond), subscribe the puffin notify chars, then send the R22 enable
  /// sequence to unlock the deep biometric streams the strap withholds from a fresh client.
  Future<void> _bringUpWhoop5(BluetoothService custom) async {
    final hello = DeviceFamily.whoop5.clientHello;
    final cmd = _cmdChar;
    if (hello != null && cmd != null) {
      await _write(cmd, hello);
      _log('WHOOP 5/MG: CLIENT_HELLO sent');
    }
    for (final uuid in _notifyUuids(DeviceFamily.whoop5)) {
      final ch = _charByUuid(custom, uuid);
      if (ch != null) await _subscribe(ch, _onCustomFrameBytes);
    }
    await _sendR22EnableSequence();
  }

  /// Send the 15-flag [Whoop5Config.enableR22Sequence], each as one SET_CONFIG puffin write, spaced
  /// ~80ms apart (mirrors the Kotlin enableWhoop5DeepData cadence). Reversible; only changes which
  /// data the strap emits.
  Future<void> _sendR22EnableSequence() async {
    final cmd = _cmdChar;
    if (cmd == null) return;
    _log('Deep-data: sending the ${Whoop5Config.enableR22Sequence.length}-flag enable_r22 sequence');
    for (final flag in Whoop5Config.enableR22Sequence) {
      if (!_connected) return;
      _seq = (_seq + 1) & 0xFF;
      final frame = Whoop5Config.frame(flag, _seq);
      await _write(cmd, frame);
      await Future<void>.delayed(r22FlagSpacing);
    }
  }

  // ============================================================================================
  // Connect handshake + command sequence (Kotlin runConnectHandshake)
  // ============================================================================================

  /// The connect-time command sequence, in the Kotlin order: SET_CLOCK (so the strap latches its RTC
  /// and resumes banking to flash) → GET_DATA_RANGE (refresh the stored range) → then, deferred by
  /// [initialBackfillDelay] so the first two round-trip on a settled link, kick the historical offload.
  void _runConnectHandshake() {
    // ABORT_HISTORICAL_TRANSMITS FIRST — exactly as the official app's init sequence (Kotlin
    // runInitSequence: ABORT → HELLO → BATTERY). A strap left mid-dump by a previously-crashed
    // session keeps streaming stale history and never answers a fresh SEND_HISTORICAL_DATA cleanly;
    // aborting first puts it back to a known-idle state so our own offload starts reliably.
    _send(CommandNumber.abortHistoricalTransmits, payload: const []);

    // SET_CLOCK: WHOOP4 gets both firmware forms (8-byte + legacy 9-byte); 5/MG the single 8-byte form.
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _send(CommandNumber.setClock, payload: _setClockPayload(now));
    if (_family == DeviceFamily.whoop4) {
      _send(CommandNumber.setClock, payload: _setClockPayloadLegacy(now));
      // Stop the unprompted type-43 realtime raw flood (it eats BLE airtime). Kotlin sends this too.
      _send(CommandNumber.sendR10R11Realtime, payload: const [0]);
    }
    _send(CommandNumber.getDataRange, payload: const []);
    // Device-screen info the official app pulls on connect: firmware/serial (HELLO) + battery %/charging
    // (GET_BATTERY_LEVEL 0x1A — proprietary, NOT the standard 0x2A19 service). Then keep battery fresh.
    _queryDeviceInfo();
    _startBatteryPollTimer();
    _log('Connect handshake sent (abort/set-clock/get-range/hello/battery)');

    // Historical offload: the type-47 store is the PRIMARY metric source. Kick it once on connect,
    // deferred so SET_CLOCK/GET_DATA_RANGE round-trip first (Kotlin asyncAfter(1.5s) { requestSync }).
    _offloadKickTimer?.cancel();
    _offloadKickTimer = Timer(initialBackfillDelay, _beginBackfill);
  }

  /// One-shot device-state query: HELLO (firmware/serial + battery+charging on 5/MG) and the
  /// proprietary battery level. Port of the official app's runInitSequence HELLO + GET_BATTERY_LEVEL.
  void _queryDeviceInfo() {
    // GET_HELLO_HARVARD(35) on WHOOP4, GET_HELLO(145) on 5/MG — the response carries firmware/serial,
    // and on 5/MG the battery + charging bytes (parser `ni0/s`). Payload `[0x01]` mirrors Kotlin.
    _send(
      _family == DeviceFamily.whoop4
          ? CommandNumber.getHelloHarvard
          : CommandNumber.getHello,
      payload: const [0x01],
    );
    // GET_BATTERY_LEVEL(26 / 0x1A) — empty payload, response is a raw-byte percentage (+ charging).
    _send(CommandNumber.getBatteryLevel, payload: const []);
  }

  /// Keep the battery reading fresh while connected (the strap only reports battery on request; there
  /// is no notify). Cancelled on disconnect/teardown. Mirrors the official app's periodic query.
  void _startBatteryPollTimer() {
    _batteryPollTimer?.cancel();
    _batteryPollTimer = Timer.periodic(batteryPollInterval, (_) {
      if (_connected) _send(CommandNumber.getBatteryLevel, payload: const []);
    });
  }

  /// SET_CLOCK(10) 8-byte form: [seconds u32 LE][subseconds u32 LE]. Port of Kotlin setClockPayload.
  List<int> _setClockPayload(int now) => [
        now & 0xFF,
        (now >> 8) & 0xFF,
        (now >> 16) & 0xFF,
        (now >> 24) & 0xFF,
        0, 0, 0, 0,
      ];

  /// SET_CLOCK(10) legacy 9-byte form for WHOOP 4 fw 41.17.x. Port of Kotlin setClockPayloadLegacy.
  List<int> _setClockPayloadLegacy(int now) => [
        now & 0xFF,
        (now >> 8) & 0xFF,
        (now >> 16) & 0xFF,
        (now >> 24) & 0xFF,
        0, 0, 0, 0, 0,
      ];

  // ============================================================================================
  // Historical offload (Kotlin beginBackfill)
  // ============================================================================================

  /// Start a historical-offload session: tell the state machine to begin, flip the routing flag,
  /// and kick the strap with SEND_HISTORICAL_DATA. Port of the Kotlin beginBackfill happy path.
  void _beginBackfill() {
    if (!_connected || _syncing) return;
    _backfiller.begin(_family); // family drives the +4 puffin offset for 5/MG
    _syncing = true;
    _offloadCurrentTsUnix = null;
    _setState(BleConnectionState.syncing);
    _emitSyncProgress('offloading');
    // Payload MUST be [0x00], not empty: verified on-device that the strap serves type-47 only with
    // [0x00] (Kotlin sendHistoricalKick).
    _send(CommandNumber.sendHistoricalData, payload: const [0], withResponse: true);
    // Arm the inactivity watchdog: if the strap never streams the first burst (or stalls mid-stream),
    // this fires in [offloadInactivityTimeout] and aborts instead of wedging `syncing` forever.
    _armOffloadWatchdog();
    _log('Backfill: session started — historical offload requested');
  }

  /// (Re)arm the offload inactivity watchdog. Called on begin and on every inbound offload frame, so
  /// the timer only elapses after a genuine [offloadInactivityTimeout] of strap silence mid-offload.
  void _armOffloadWatchdog() {
    _offloadWatchdog?.cancel();
    _offloadWatchdog = Timer(offloadInactivityTimeout, _onOffloadWatchdogFired);
  }

  /// The strap went silent mid-offload without a BLE disconnect. Do exactly what the official app does:
  /// send ABORT_HISTORICAL_TRANSMITS, drop the uncommitted open chunk (never ack un-persisted data),
  /// and end the session so the live path resumes. Already-acked chunks stay durably saved; the strap
  /// resumes from its own trim pointer on the next connect.
  void _onOffloadWatchdogFired() {
    if (!_syncing) return;
    _log('Offload watchdog: ${offloadInactivityTimeout.inSeconds}s strap silence — '
        'STALLED at ${_fmtDataTs(_offloadCurrentTsUnix)} '
        '(${_backfiller.sessionRowsPersisted} rows in); sending ABORT + restarting');
    _send(CommandNumber.abortHistoricalTransmits, payload: const []);
    _backfiller.timeoutFired();
    _finishOffload();
  }

  /// A committed offload chunk: advance the "which day is syncing" cursor to the newest record ts in
  /// the chunk, then emit a fresh SyncProgress so the UI's percent/current-day tick live.
  void _onChunkCommitted(StreamBatch batch) {
    final newest = _newestBatchTsUnix(batch);
    if (newest != null &&
        (_offloadCurrentTsUnix == null || newest > _offloadCurrentTsUnix!)) {
      _offloadCurrentTsUnix = newest;
    }
    _log('Offload chunk — ${_backfiller.sessionRowsPersisted} rows · '
        'at ${_fmtDataTs(_offloadCurrentTsUnix)} (data time)');
    _emitSyncProgress('offloading');
  }

  /// Human, local formatting of a DATA-record unix-seconds timestamp for the
  /// connection log — so a line shows WHICH second of the wearer's own history the
  /// sync had reached (the packet's time), not just when the log line was written.
  /// "—" when unknown.
  static String _fmtDataTs(int? unixSec) {
    if (unixSec == null) return '—';
    final t = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    const mon = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    String p2(int n) => n.toString().padLeft(2, '0');
    return '${p2(t.day)} ${mon[t.month - 1]} '
        '${p2(t.hour)}:${p2(t.minute)}:${p2(t.second)}';
  }

  /// The newest wall-clock unix-seconds timestamp across every row list in a committed chunk, or null
  /// if the chunk carries no timestamped rows.
  static int? _newestBatchTsUnix(StreamBatch b) {
    int? best;
    void consider(int ts) {
      if (best == null || ts > best!) best = ts;
    }

    for (final r in b.hr) {
      consider(r.ts);
    }
    for (final r in b.rr) {
      consider(r.ts);
    }
    for (final r in b.events) {
      consider(r.ts);
    }
    for (final r in b.battery) {
      consider(r.ts);
    }
    for (final r in b.spo2) {
      consider(r.ts);
    }
    for (final r in b.skinTemp) {
      consider(r.ts);
    }
    for (final r in b.resp) {
      consider(r.ts);
    }
    for (final r in b.gravity) {
      consider(r.ts);
    }
    for (final r in b.steps) {
      consider(r.ts);
    }
    for (final r in b.sleepState) {
      consider(r.ts);
    }
    for (final r in b.ppgHr) {
      consider(r.ts);
    }
    return best;
  }

  /// The Backfiller's safe-trim ack: confirm one HISTORY_END chunk so the strap may trim it. Payload
  /// = [0x01] + the verbatim 8-byte HISTORY_END end_data (Kotlin HISTORICAL_DATA_RESULT).
  void _ackTrim(int trim, Uint8List endData) {
    _send(CommandNumber.historicalDataResult,
        payload: [0x01, ...endData], withResponse: true);
  }

  void _finishOffload() {
    _offloadWatchdog?.cancel();
    if (!_syncing) return;
    _syncing = false;
    _emitSyncProgress('complete');
    _setState(_connected ? BleConnectionState.connected : BleConnectionState.idle);
    _log('Backfill: offload complete — ${_backfiller.sessionRowsPersisted} rows this '
        'session, up to ${_fmtDataTs(_offloadCurrentTsUnix)} (data time)');
  }

  // ============================================================================================
  // Inbound routing (Kotlin onInbound / onCharacteristicChanged)
  // ============================================================================================

  /// Standard 0x2A37 HR profile — the reliable, always-on live-HR + R-R source.
  void _onStandardHr(List<int> data) {
    final parsed = _parseStandardHr(data);
    if (parsed == null) return;
    final hr = parsed.$1;
    final rr = parsed.$2;
    if (hr >= 30 && hr <= 220) _publishHr(hr);
    // Persist the reliable standard stream directly (carries a wall-clock ts).
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final batch = StreamBatch(
      hr: [HrRow(ts, hr)],
      rr: [for (final r in rr) if (r >= 250 && r <= 3000) RrRow(ts, r)],
    );
    if (!batch.isEmpty) {
      unawaited(_streamRepository.insert(batch, deviceId).catchError((Object e) {
        _log('standard-HR persist failed: $e');
        return const InsertCounts();
      }));
    }
  }

  /// Parse a standard HR characteristic value → (hr, rrIntervalsMs). Port of Kotlin parseStandardHr.
  (int, List<int>)? _parseStandardHr(List<int> data) {
    if (data.isEmpty) return null;
    final flags = data[0] & 0xFF;
    final hr16 = (flags & 0x01) != 0;
    final rrPresent = (flags & 0x10) != 0;
    var idx = 1;
    final int hr;
    if (hr16) {
      if (data.length < idx + 2) return null;
      hr = (data[idx] & 0xFF) | ((data[idx + 1] & 0xFF) << 8);
      idx += 2;
    } else {
      if (data.length < idx + 1) return null;
      hr = data[idx] & 0xFF;
      idx += 1;
    }
    // Energy-expended field (bit3) precedes R-R if present — skip its 2 bytes.
    if ((flags & 0x08) != 0) idx += 2;
    final rr = <int>[];
    if (rrPresent) {
      while (idx + 1 < data.length) {
        final raw = (data[idx] & 0xFF) | ((data[idx + 1] & 0xFF) << 8);
        idx += 2;
        rr.add((raw * 1000) ~/ 1024); // 1/1024 s units → ms
      }
    }
    return (hr, rr);
  }

  /// Standard 0x2A19 battery — first byte is the percent. 5/MG only (on WHOOP4 this char is a stub
  /// constant; the real value is the GET_BATTERY_LEVEL command response). Mirrors Kotlin.
  void _onStandardBattery(List<int> data) {
    if (_family == DeviceFamily.whoop4) return;
    if (data.isEmpty) return;
    _publishBattery((data[0] & 0xFF) / 100.0);
  }

  /// Custom-channel bytes → reassemble → route each complete frame. Port of the Kotlin reassembler
  /// feed loop, wrapped so one bad frame drops that frame and the link stays up.
  void _onCustomFrameBytes(List<int> bytes) {
    for (final frame in _reassembler.feed(Uint8List.fromList(bytes))) {
      try {
        _handleFrame(frame);
      } catch (e) {
        _log('inbound frame handling threw $e — dropping this frame, link stays up');
      }
    }
  }

  void _handleFrame(Uint8List frame) {
    final parsed = Framing.parseFrame(frame, _family);
    if (parsed.crcOk == false) return;

    // Command responses feed the session gates + WHOOP4 battery, whether or not we're mid-offload.
    if (parsed.typeName == 'COMMAND_RESPONSE') {
      _handleCommandResponse(frame, parsed);
    }

    if (_syncing) {
      // Route ONLY genuine offload frames through the serial backfill drain (preserves chunk order).
      // The live type-40/43 flood is dropped here — extractHistoricalStreams ignores it and feeding
      // it only stalls the strap. Live HR still flows over the standard 0x2A37 profile. (Kotlin.)
      if (_isOffloadFrame(frame, _family)) {
        _armOffloadWatchdog(); // strap made progress — reset the inactivity timer
        _ingestBackfill(frame);
      }
    } else {
      // Live path: publish HR immediately + buffer for a batched decode+insert (Kotlin Collector).
      _publishLiveHrFromRealtime(parsed);
      _maybeSignalAlarmFired(frame, parsed);
      _bufferLiveFrame(frame);
    }
  }

  /// A LIVE EVENT 57 (STRAP_DRIVEN_ALARM_EXECUTED) means the strap ran its own wake haptic — surface it
  /// so the write-side can flip the alarm to "fired" (spec §5). Only on the live path: a historical
  /// replay of the same event drains through the offload branch while syncing and is never surfaced
  /// here (twin of the Kotlin `smartAlarmFiredForEvent` LIVE-only rule).
  void _maybeSignalAlarmFired(Uint8List frame, ParsedFrame parsed) {
    if (parsed.typeName != 'EVENT') return;
    final evOff = _family == DeviceFamily.whoop5 ? 10 : 6;
    if (_u8f(frame, evOff) == EventNumber.strapDrivenAlarmExecuted.rawValue) {
      _log('Strap-driven alarm fired (event 57) — surfacing to the write-side');
      if (!_alarmFiredController.isClosed) _alarmFiredController.add(null);
    }
  }

  void _handleCommandResponse(Uint8List frame, ParsedFrame parsed) {
    // WHOOP4 battery arrives as a GET_BATTERY_LEVEL command response (u16/10 → percent). This path
    // also carries the charging bit when present, so surface it alongside the fraction.
    final pct = parsed.parsed.doubleOrNull('battery_pct');
    if (pct != null) {
      final chargingRaw = parsed.parsed.intOrNull('battery_charging');
      _publishBattery(pct / 100.0,
          charging: chargingRaw == null ? null : chargingRaw != 0);
    }

    final cmdOff = _family == DeviceFamily.whoop5 ? 10 : 6;
    final respCmd = frame.length > cmdOff ? frame[cmdOff] & 0xFF : null;

    // GET_BATTERY_LEVEL (0x1A) response: the strap answers our proprietary poll with a raw-byte
    // percentage (+ optional charging byte). This is the ONLY live battery source on WHOOP4 (the
    // standard 0x2A19 char is a stub there). Decode + publish. (RE: response data at inner offset 5 =
    // cmdOff+3; charging byte follows — matches official `ni0/k`/`vi0/c` + Kotlin battery heuristic.)
    if (respCmd == CommandNumber.getBatteryLevel.rawValue) {
      final b = decodeBatteryResponse(frame, cmdOff);
      if (b != null) _publishBattery(b.$1, charging: b.$2);
    }

    // SET_ALARM_TIME ack: on 5/MG require result=SUCCESS; a WHOOP4 CR for cmd 66 is itself the ack.
    // This flips the write-side queued→armed (spec §5).
    if (respCmd == CommandNumber.setAlarmTime.rawValue) {
      final result = parsed.parsed['result'];
      final ok = _family == DeviceFamily.whoop4 ||
          (result is String && result.startsWith('SUCCESS'));
      if (ok) _emitAlarmArmed();
    }

    // GET_ALARM_TIME readback: decode defensively and surface it (telemetry only — never gates, §3).
    if (respCmd == CommandNumber.getAlarmTime.rawValue) {
      final epochMs = _decodeArmedAlarmEpochMs(frame);
      _log('Strap alarm readback: '
          '${epochMs == null ? 'none/implausible' : DateTime.fromMillisecondsSinceEpoch(epochMs).toIso8601String()}');
      if (!_alarmReadbackController.isClosed) _alarmReadbackController.add(epochMs);
    }

    // GET_DATA_RANGE: publish the strap's banked-record window to the Backfiller so the historical
    // ingest gate can reject records dated outside THIS strap's own [oldest, newest] (Kotlin #547).
    if (frame.length > cmdOff &&
        (frame[cmdOff] & 0xFF) == CommandNumber.getDataRange.rawValue) {
      final newest = _dataRangeNewestUnix(frame);
      if (newest != null) {
        _backfiller.sessionNewestUnix = newest;
        final oldest = _dataRangeOldestUnix(frame);
        if (oldest != null && oldest < newest) {
          _backfiller.sessionOldestUnix = oldest;
        }
      }
    }
  }

  /// Serial backfill drain: [Backfiller.ingest] already serialises internally, so chaining its
  /// futures preserves chunk order; when the state machine consumes HISTORY_COMPLETE we exit cleanly.
  void _ingestBackfill(Uint8List frame) {
    unawaited(_backfiller.ingest(frame).then((_) {
      _emitSyncProgress('offloading');
      if (_syncing && !_backfiller.isBackfilling) _finishOffload();
    }).catchError((Object e) {
      _log('Backfill: drain error ($e) — skipping frame, offload continues');
    }));
  }

  void _publishLiveHrFromRealtime(ParsedFrame parsed) {
    if (parsed.typeName != 'REALTIME_DATA') return;
    final bpm = parsed.parsed.intOrNull('heart_rate');
    if (bpm != null && bpm >= 30 && bpm <= 220) _publishHr(bpm);
  }

  // ── live-frame buffering + flush (Kotlin Collector.ingest / flush) ─────────────────────────
  void _bufferLiveFrame(Uint8List frame) {
    _liveBuffer.add(frame);
    if (_liveBuffer.length >= liveFlushMaxFrames) unawaited(_flushLive());
  }

  void _startLiveFlushTimer() {
    _liveFlushTimer?.cancel();
    _liveFlushTimer = Timer.periodic(liveFlushInterval, (_) => unawaited(_flushLive()));
  }

  /// Decode the buffered live frames and persist them. Anchors the batch's NEWEST realtime timestamp
  /// to wall-clock `now` so live HR lands on today's timeline whatever the strap's (possibly invalid)
  /// RTC says — a no-op when the clock is already valid. Port of Kotlin flushLive.
  Future<void> _flushLive() async {
    if (_liveFlushInFlight || _liveBuffer.isEmpty) return;
    _liveFlushInFlight = true;
    final frames = List<Uint8List>.from(_liveBuffer);
    _liveBuffer.clear();
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final parsed = [for (final f in frames) Framing.parseFrame(f, _family)];
      var newestRealtime = now;
      for (final p in parsed) {
        if (p.ok && p.crcOk != false && p.typeName == 'REALTIME_DATA') {
          final ts = p.parsed.intOrNull('timestamp');
          if (ts != null && ts > newestRealtime) newestRealtime = ts;
        }
      }
      final streams = extractStreams(parsed, newestRealtime, now);
      final batch = StreamPersistence.toBatch(streams);
      if (!batch.isEmpty) {
        await _streamRepository.insert(batch, deviceId);
      }
    } catch (e) {
      // Re-buffer at the front so these frames retry on the next cadence (Kotlin Collector).
      _liveBuffer.insertAll(0, frames);
      _log('live flush failed: $e');
    } finally {
      _liveFlushInFlight = false;
    }
  }

  // ============================================================================================
  // Disconnect + reconnect (Kotlin handleDisconnect + ReconnectBackoff)
  // ============================================================================================

  void _onDisconnected() {
    final wasConnected = _connected;
    _connected = false;
    _syncing = false;
    _cmdChar = null;
    for (final s in _charSubs) {
      s.cancel();
    }
    _charSubs.clear();
    _liveFlushTimer?.cancel();
    _offloadKickTimer?.cancel();
    _offloadWatchdog?.cancel();
    _batteryPollTimer?.cancel();
    _reassembler.reset();
    _publishHr(null);
    if (wasConnected) _publishPaired(null);

    // Feed the #617 bond-loop detector: a bond followed by a quick involuntary drop is the loop's
    // signature. An intentional/user teardown is not a timeout, so it clears suspicion. A freshly
    // tripped loop latches the auto-reconnect pause (checked just below). Inert off-device — _didBond
    // never becomes true without a real Android bond.
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final msSinceBond =
        (_didBond && _bondedAtMs != null) ? nowMs - _bondedAtMs! : null;
    if (_postBondLoop.connectionEnded(
      wasBonded: _didBond,
      msSinceBond: msSinceBond,
      timedOut: !_intentionalDisconnect,
    )) {
      _enterBondLoopPause(_device?.remoteId.str ?? 'device', 'bond-then-quick-timeout loop');
    }
    _didBond = false; // the connection is gone; the next one re-proves the bond

    if (_intentionalDisconnect) {
      _setState(BleConnectionState.idle);
      return;
    }
    // A latched bond give-up / loop pause stops the auto-reconnect hammer: hold idle until the user
    // taps Connect (which re-arms via [_resetBondStateForUserAction]) or a salvage probe fires.
    if (_autoReconnectPausedForBondLoop) {
      _log('auto-reconnect paused (bond give-up latched) — not scheduling a reconnect');
      _setState(BleConnectionState.idle);
      return;
    }
    // Involuntary drop → capped-exponential reconnect (Kotlin ReconnectBackoff).
    _reconnectAttempt += 1;
    final delayMs = ReconnectBackoff.nextDelayMs(_reconnectAttempt);
    _log('Disconnected${wasConnected ? '' : ' (never connected)'}; '
        'reconnecting in ${delayMs ~/ 1000}s (attempt $_reconnectAttempt)');
    _setState(BleConnectionState.idle);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      if (_intentionalDisconnect) return;
      final device = _device;
      if (device != null) {
        // Reconnect straight to the strap we last connected to (no scan).
        _connectToDevice(device);
      } else {
        _startScan(_family, allowFallback: true);
      }
    });
  }

  Future<void> _teardownConnection() async {
    await _scanSub?.cancel();
    _scanSub = null;
    if (_blePlatform) {
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
    }
    for (final s in _charSubs) {
      await s.cancel();
    }
    _charSubs.clear();
    await _connSub?.cancel();
    _connSub = null;
    final device = _device;
    if (device != null && _blePlatform) {
      try {
        await device.disconnect();
      } catch (_) {}
    }
    _connected = false;
    _syncing = false;
    _offloadWatchdog?.cancel();
    _batteryPollTimer?.cancel();
    _cmdChar = null;
    _liveBuffer.clear();
  }

  void _cancelTimers() {
    _scanFallbackTimer?.cancel();
    _scanGiveUpTimer?.cancel();
    _liveFlushTimer?.cancel();
    _offloadKickTimer?.cancel();
    _offloadWatchdog?.cancel();
    _batteryPollTimer?.cancel();
    _reconnectTimer?.cancel();
  }

  // ============================================================================================
  // Command send (Kotlin send) — family-aware framing
  // ============================================================================================

  void _send(CommandNumber cmd, {List<int>? payload, bool withResponse = false}) {
    final ch = _cmdChar;
    if (ch == null) {
      _log('send(${cmd.name}) ignored — no command characteristic');
      return;
    }
    // The WHOOP command characteristic supports write-with-response; use it for every command
    // (a dropped without-response write silently breaks SET_CLOCK / the offload ack). withResponse
    // is retained for call-site intent parity with the Kotlin send().
    unawaited(_write(ch, _frameFor(cmd, payload)));
  }

  /// Frame [cmd]+[payload] for the connected family (WHOOP4 [Framing.buildCommand] / 5MG puffin),
  /// advancing the rolling command seq. Shared by [_send] and the strap-alarm writes.
  Uint8List _frameFor(CommandNumber cmd, List<int>? payload) {
    _seq = (_seq + 1) & 0xFF;
    final pay = payload == null ? null : Uint8List.fromList(payload);
    return _family == DeviceFamily.whoop5
        ? Framing.puffinCommandFrame(cmd: cmd.rawValue, seq: _seq, payload: pay)
        : Framing.buildCommand(cmd, payload: pay, seq: _seq);
  }

  Future<void> _write(BluetoothCharacteristic ch, Uint8List value,
      {bool withoutResponse = false}) async {
    if (!_blePlatform) return;
    try {
      await ch.write(value, withoutResponse: withoutResponse);
    } catch (e) {
      _log('write to ${ch.uuid} failed: $e');
    }
  }

  /// Like [_write] but reports whether the GATT write actually completed. Used by [setStrapAlarm] so a
  /// WHOOP4 completed write-with-response can be treated as the arm ACK. Off-device it returns false
  /// (nothing was written), so no false "armed" is ever emitted in tests.
  Future<bool> _writeChecked(BluetoothCharacteristic ch, Uint8List value) async {
    if (!_blePlatform) return false;
    try {
      await ch.write(value);
      return true;
    } catch (e) {
      _log('write to ${ch.uuid} failed: $e');
      return false;
    }
  }

  // ============================================================================================
  // GATT helpers
  // ============================================================================================

  /// Enable notifications (writes the CCCD) then wire the value listener. Cancels with the device.
  Future<void> _subscribe(
      BluetoothCharacteristic ch, void Function(List<int>) onValue) async {
    if (!_blePlatform) return;
    final sub = ch.onValueReceived.listen(onValue);
    _device?.cancelWhenDisconnected(sub);
    _charSubs.add(sub);
    try {
      await ch.setNotifyValue(true);
    } catch (e) {
      _log('setNotifyValue failed for ${ch.uuid}: $e');
    }
  }

  static BluetoothService? _serviceByUuid(
      List<BluetoothService> services, String uuid) {
    final want = Guid(uuid);
    for (final s in services) {
      if (s.uuid == want) return s;
    }
    return null;
  }

  static BluetoothCharacteristic? _charByUuid(
      BluetoothService service, String uuid) {
    final want = Guid(uuid);
    for (final c in service.characteristics) {
      if (c.uuid == want) return c;
    }
    return null;
  }

  static BluetoothCharacteristic? _standardChar(
      List<BluetoothService> services, String serviceUuid, String charUuid) {
    final svc = _serviceByUuid(services, serviceUuid);
    if (svc == null) return null;
    return _charByUuid(svc, charUuid);
  }

  /// Notify characteristic UUIDs for a family = every custom characteristic except the …0002 command
  /// write char (WHOOP4 → 0003/0004/0005; WHOOP5 → 0003/0004/0005/0007).
  static List<String> _notifyUuids(DeviceFamily family) {
    final cmd = family.commandCharacteristicUuidString;
    return [
      for (final u in family.characteristicUuidStrings)
        if (u != cmd) u
    ];
  }

  // Standard GATT profiles (full 128-bit forms so Guid equality is unambiguous).
  static const String _hrServiceUuid = '0000180d-0000-1000-8000-00805f9b34fb';
  static const String _hrCharUuid = '00002a37-0000-1000-8000-00805f9b34fb';
  static const String _batteryServiceUuid = '0000180f-0000-1000-8000-00805f9b34fb';
  static const String _batteryCharUuid = '00002a19-0000-1000-8000-00805f9b34fb';

  // ── GET_DATA_RANGE scan (Kotlin dataRangeNewestUnix / dataRangeOldestUnix) ──────────────────
  int? _dataRangeNewestUnix(Uint8List frame) {
    if (frame.length <= 7) return null;
    int? newest;
    for (var i = 7; i + 4 <= frame.length; i += 4) {
      final w = (frame[i] & 0xFF) |
          ((frame[i + 1] & 0xFF) << 8) |
          ((frame[i + 2] & 0xFF) << 16) |
          ((frame[i + 3] & 0xFF) << 24);
      if (w >= _unixFloor && w <= _unixCeil) {
        newest = newest == null ? w : (w > newest ? w : newest);
      }
    }
    return newest;
  }

  int? _dataRangeOldestUnix(Uint8List frame) {
    if (frame.length <= 7) return null;
    int? oldest;
    for (var i = 7; i + 4 <= frame.length; i += 4) {
      final w = (frame[i] & 0xFF) |
          ((frame[i + 1] & 0xFF) << 8) |
          ((frame[i + 2] & 0xFF) << 16) |
          ((frame[i + 3] & 0xFF) << 24);
      if (w >= _unixFloor && w <= _unixCeil) {
        oldest = oldest == null ? w : (w < oldest ? w : oldest);
      }
    }
    return oldest;
  }

  /// Whether a complete frame is a historical-offload frame (HISTORICAL_DATA/EVENT/METADATA/
  /// CONSOLE_LOGS, incl. the 5/MG puffin metadata type) vs the live REALTIME flood. The type byte
  /// sits at offset 4 (WHOOP4) or 8 (WHOOP5 puffin +4). The Backfiller re-validates every frame.
  /// Decode a GET_BATTERY_LEVEL (0x1A) COMMAND_RESPONSE into `(fraction 0..1, charging?)`, or null if
  /// no plausible percentage byte is present. [cmdOff] is the offset of the response command byte
  /// (frame[cmdOff] == 0x1A); the response's data region begins just after it.
  ///
  /// The strap reports battery as a single raw byte = percent (RE `vi0/c`: `toString "BatteryLevel="+
  /// byte`, low < 20%). The official parser slices the data at inner offset 5 (== [cmdOff]+3); we try
  /// that exact byte first, then fall back to the proven Kotlin heuristic (first byte in 1..100) so an
  /// off-by-a-firmware-revision layout still surfaces a value. A following 0/1 byte is the charge flag.
  @visibleForTesting
  static (double, bool?)? decodeBatteryResponse(Uint8List frame, int cmdOff) {
    bool plausible(int v) => v >= 1 && v <= 100;
    int at(int i) => (i >= 0 && i < frame.length) ? frame[i] & 0xFF : -1;

    // Primary: the RE-precise data offset (inner+5 == cmdOff+3).
    var pctIdx = cmdOff + 3;
    if (!plausible(at(pctIdx))) {
      // Fallback: first plausible byte anywhere in the data region after the command byte.
      pctIdx = -1;
      for (var i = cmdOff + 1; i < frame.length; i++) {
        if (plausible(at(i))) {
          pctIdx = i;
          break;
        }
      }
      if (pctIdx < 0) return null;
    }
    final pct = at(pctIdx);
    final next = at(pctIdx + 1);
    final bool? charging = (next == 0 || next == 1) ? next == 1 : null;
    return (pct / 100.0, charging);
  }

  static bool _isOffloadFrame(Uint8List frame, DeviceFamily family) {
    final off = family == DeviceFamily.whoop5 ? 8 : 4;
    if (frame.length <= off) return false;
    final t = frame[off] & 0xFF;
    return t == PacketType.historicalData.rawValue || // 47
        t == PacketType.event.rawValue || // 48
        t == PacketType.metadata.rawValue || // 49
        t == PacketType.consoleLogs.rawValue || // 50
        t == PuffinPacketType.puffinMetadata; // 56
  }

  // ============================================================================================
  // Publish helpers
  // ============================================================================================

  void _setState(BleConnectionState s) {
    _state = s;
    if (!_connController.isClosed) _connController.add(s);
  }

  void _publishHr(int? hr) {
    _hrNow = hr;
    if (!_hrController.isClosed) _hrController.add(hr);
  }

  /// Publish the battery fraction and, additively, the charging flag. [charging] is null when the
  /// source carries no charging bit (standard 0x2A19) — the fraction and charging are independent
  /// signals so the UI can keep the last-known fraction while charging goes null.
  void _publishBattery(double frac, {bool? charging}) {
    final v = frac.clamp(0.0, 1.0);
    _batteryNow = v;
    if (!_batteryController.isClosed) _batteryController.add(v);
    _publishCharging(charging);
  }

  void _publishCharging(bool? charging) {
    _chargingNow = charging;
    if (!_chargingController.isClosed) _chargingController.add(charging);
  }

  void _publishPaired(PairedStrap? strap) {
    if (!_pairedController.isClosed) _pairedController.add(strap);
  }

  void _emitSyncProgress(String phase) {
    if (_syncController.isClosed) return;
    final oldest = _backfiller.sessionOldestUnix;
    final newest = _backfiller.sessionNewestUnix;
    final current = _offloadCurrentTsUnix;

    // Percent = how far the newest-decoded record has advanced through the strap's [oldest, newest]
    // banked span. Only meaningful while offloading with a known range and a landed record.
    double? percent;
    if (phase == 'offloading' &&
        oldest != null &&
        newest != null &&
        newest > oldest &&
        current != null) {
      percent = ((current - oldest) / (newest - oldest)).clamp(0.0, 1.0);
    } else if (phase == 'complete' && oldest != null && newest != null) {
      percent = 1.0;
    }

    _syncController.add(SyncProgress(
      recordsPersisted: _backfiller.sessionRowsPersisted,
      phase: phase,
      percent: percent,
      currentTsMs: current == null ? null : current * 1000,
      oldestTsMs: oldest == null ? null : oldest * 1000,
      newestTsMs: newest == null ? null : newest * 1000,
    ));
  }

  void _log(String line) {
    if (kDebugMode) debugPrint('[WhoopBleClient] $line');
    // Append to the rolling buffer (device-runtime timestamp) and republish the whole trace. This
    // only ever runs once the client is used (connect/scan) — construction touches no _log.
    _logBuffer.add(ConnLogEntry(DateTime.now(), line));
    if (_logBuffer.length > _maxLogEntries) {
      _logBuffer.removeRange(0, _logBuffer.length - _maxLogEntries);
    }
    if (!_logController.isClosed) {
      _logController.add(List.unmodifiable(_logBuffer));
    }
  }
}
