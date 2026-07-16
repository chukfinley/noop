import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/permission_gate.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';
import 'package:noop/core/ble/sync/backfiller.dart';
import 'package:noop/core/ble/transport/whoop_ble_client.dart';

/// Radio-free tests for the transient-vs-wedged permission WIRING in `whoop_ble_client.dart` — the
/// half the pure `BlePermissionGate` suite cannot cover: does the client feed the gate the right
/// signals, surface the string that matches the verdict, and keep its hands off the backoff?
///
/// These drive the real `_applyPermissionResult` through its `@visibleForTesting` seam with the
/// outcomes `requestBlePermissions()` would have returned, so no platform channel is touched (the
/// plugin needs a real Android/iOS host; the policy does not).
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

  group('the gate lets a granted request through silently', () {
    test('granted returns true and surfaces nothing', () {
      final ok = client.debugApplyPermissionResult(
          granted: true, permanentlyDenied: false, userInitiated: true);

      expect(ok, isTrue);
      expect(client.lastError, isNull);
    });
  });

  group('transient — the caller is told to retry, not to go to Settings', () {
    test('a re-promptable denial surfaces the retry hint', () {
      final ok = client.debugApplyPermissionResult(
          granted: false, permanentlyDenied: false, userInitiated: true);

      expect(ok, isFalse);
      expect(client.lastError, BlePermissionGate.transientHint);
    });

    test('the old dead string is gone — it was the same for both states', () {
      // The whole bug in one line: `'Bluetooth permission denied.'` was surfaced identically for a
      // never-asked user and a permanently-blocked one, so it could not be right for either.
      client.debugApplyPermissionResult(
          granted: false, permanentlyDenied: false, userInitiated: true);
      final transient = client.lastError;
      client.debugApplyPermissionResult(
          granted: false, permanentlyDenied: true, userInitiated: true);
      final wedged = client.lastError;

      expect(transient, isNot('Bluetooth permission denied.'));
      expect(wedged, isNot('Bluetooth permission denied.'));
      expect(transient, isNot(wedged),
          reason: 'two states needing opposite advice must not share one string');
    });
  });

  group('wedged — only reachable from a request that could actually prompt', () {
    test('a user-initiated latched denial surfaces the Settings guidance', () {
      final ok = client.debugApplyPermissionResult(
          granted: false, permanentlyDenied: true, userInitiated: true);

      expect(ok, isFalse);
      expect(client.lastError, BlePermissionGate.wedgedHintAndroid);
    });

    test('an AUTOMATIC path must never surface the Settings guidance', () {
      // The false-wedge our architecture actually invites: the launch kick, the Bluetooth-on
      // listener, the foreground-service nudge and the headless worker all call the same permission
      // request with no Activity behind them, and Android can report a latched denial off nothing
      // more than that missing Activity. A background tick must not be able to park a permanent
      // "your permission is blocked" banner on a healthy install.
      final ok = client.debugApplyPermissionResult(
          granted: false, permanentlyDenied: true, userInitiated: false);

      expect(ok, isFalse);
      expect(client.lastError, BlePermissionGate.transientHint,
          reason: 'no dialog could have run, so the report is not evidence of a real refusal');
      expect(client.lastError, isNot(BlePermissionGate.wedgedHintAndroid));
    });

    test('apple selects the iOS wording for the same verdict', () {
      client.debugApplyPermissionResult(
          granted: false, permanentlyDenied: true, userInitiated: true, apple: true);

      expect(client.lastError, BlePermissionGate.wedgedHintApple);
    });
  });

  group('the permission gate INFORMS only — it never pauses a retry', () {
    test('a wedged verdict leaves the reconnect-backoff ramp untouched', () {
      // Same rule as #147: the user can grant the permission from Settings at any moment, and a
      // transport that paused itself would then sit dead until they found a button to press.
      client.debugReconnectAttempt = 3;

      client.debugApplyPermissionResult(
          granted: false, permanentlyDenied: true, userInitiated: true);

      expect(client.lastError, BlePermissionGate.wedgedHintAndroid);
      expect(client.debugReconnectAttempt, 3);
    });

    test('a later grant clears the note without any reset ceremony', () {
      // The gate is stateless, so recovery needs no explicit unwedge: one granted request and the
      // guidance is simply no longer produced.
      client.debugApplyPermissionResult(
          granted: false, permanentlyDenied: true, userInitiated: true);
      expect(client.lastError, isNotNull);

      client.lastError = null;
      final ok = client.debugApplyPermissionResult(
          granted: true, permanentlyDenied: false, userInitiated: true);

      expect(ok, isTrue);
      expect(client.lastError, isNull);
    });
  });
}
