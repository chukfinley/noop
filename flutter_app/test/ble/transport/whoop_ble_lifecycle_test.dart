import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';
import 'package:noop/core/ble/sync/backfiller.dart';
import 'package:noop/core/ble/transport/whoop_ble_client.dart';

/// Radio-free state-machine tests for the three transport-lifecycle fixes in
/// `whoop_ble_client.dart` (MASTER-BACKLOG §4). The project rule forbids launching the app, so these
/// drive the client's REAL transitions from a REACHABLE state via the `@visibleForTesting` seams —
/// no `flutter_blue_plus` call is ever made (every radio path is guarded behind `_blePlatform`, which
/// is false under `flutter test`). They fabricate no device data; they only place the state machine
/// where a scan / GATT callback would and then invoke the same code path.
///
///   • HIGH-2 (#982) scan give-up: a scan with no match must LEAVE `scanning` for a retryable idle
///     with a clear `lastError`, instead of wedging Connect forever.
///   • HIGH-3 half-open link: a discovery failure / service-not-found must LEAVE `connecting` for a
///     retryable idle (the disconnect that tears the GATT link is radio-gated, so off-device we pin
///     the observable state recovery).
///   • LOW-1 reconnect backoff: a user-initiated connect must reset the reconnect-attempt counter so a
///     later involuntary drop restarts the ramp instead of waiting the capped-max delay.
class _FakeRepo implements BackfillRepository {
  @override
  Future<InsertCounts> insert(StreamBatch batch, String deviceId) async =>
      const InsertCounts();
}

void main() {
  late WhoopBleClient client;

  setUp(() {
    client = WhoopBleClient(
      streamRepository: _FakeRepo(),
      cursorStore: InMemoryTrimCursorStore(),
    );
  });

  tearDown(() async {
    await client.dispose();
  });

  group('HIGH-2 — scan give-up (#982)', () {
    test('a scan that finds nothing leaves `scanning` for a retryable idle + sets lastError', () {
      // A live scan puts the client here (see _startScan / _startUniversalScan).
      client.debugSetState(BleConnectionState.scanning);
      expect(client.state, BleConnectionState.scanning);
      expect(client.lastError, isNull);

      // The give-up timer elapses with no match.
      client.debugScanGiveUp();

      expect(client.state, BleConnectionState.idle,
          reason: 'must leave `scanning` so connect() is no longer blocked by the scanning guard');
      expect(client.lastError, 'No WHOOP strap found');
    });

    test('give-up is a no-op once the scan already left `scanning` (match/connect won the race)', () {
      // Simulate a strap having been found → we moved on to connecting.
      client.debugSetState(BleConnectionState.connecting);
      client.debugScanGiveUp();
      expect(client.state, BleConnectionState.connecting,
          reason: 'a late give-up must not clobber an in-flight connect');
      expect(client.lastError, isNull);
    });

    test('after give-up the state is idle, so a retry is reachable (guard no longer trips)', () {
      client.debugSetState(BleConnectionState.scanning);
      client.debugScanGiveUp();
      // The scanning/connecting guard in connect()/connectRemembered() only early-returns while
      // scanning or connecting; idle means a fresh Connect can proceed.
      expect(client.state, isNot(BleConnectionState.scanning));
      expect(client.state, isNot(BleConnectionState.connecting));
    });
  });

  group('HIGH-3 — half-open link on discovery failure', () {
    test('a discovery failure leaves `connecting` for a retryable idle + sets lastError', () async {
      // _onConnected reaches this state right before discoverServices().
      client.debugSetState(BleConnectionState.connecting);
      await client.debugAbortBringUp('Service discovery failed: boom');
      expect(client.state, BleConnectionState.idle,
          reason: 'must not wedge in `connecting` with a live-but-useless GATT link');
      expect(client.lastError, 'Service discovery failed: boom');
    });

    test('service-not-found aborts the bring-up to a retryable idle', () async {
      client.debugSetState(BleConnectionState.connecting);
      await client.debugAbortBringUp('Not a WHOOP strap (service not found).');
      expect(client.state, BleConnectionState.idle);
      expect(client.lastError, 'Not a WHOOP strap (service not found).');
    });

    test('abort only forces idle from `connecting` (does not stomp an already-recovered state)', () async {
      // If _onDisconnected already ran (state back to idle/other), the explicit idle-force is skipped.
      client.debugSetState(BleConnectionState.connected);
      await client.debugAbortBringUp('late abort');
      expect(client.state, BleConnectionState.connected,
          reason: 'abort must only clear the `connecting` wedge, not override a live state');
      expect(client.lastError, 'late abort');
    });
  });

  group('LOW-1 — reconnect backoff reset on user-initiated connect', () {
    test('a user-action reset zeroes the inflated reconnect-attempt counter', () {
      // Several involuntary drops inflated the ramp.
      client.debugReconnectAttempt = 7;
      expect(client.debugReconnectAttempt, 7);

      // A user tap (connect/connectToStrap/disconnect all route through this).
      client.debugResetForUserAction();

      expect(client.debugReconnectAttempt, 0,
          reason: 'a manual reconnect must restart the backoff ramp, not resume at the capped-max delay');
    });
  });
}
