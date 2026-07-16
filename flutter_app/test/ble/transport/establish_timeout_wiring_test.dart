import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';
import 'package:noop/core/ble/sync/backfiller.dart';
import 'package:noop/core/ble/sync/establish_timeout_tracker.dart';
import 'package:noop/core/ble/transport/whoop_ble_client.dart';

/// Radio-free tests for the #147 establishment-timeout WIRING in `whoop_ble_client.dart` — the half
/// the pure `EstablishTimeoutTracker` (already pinned by its own suite) cannot cover: does the client
/// CLASSIFY the exception correctly, surface the right guidance, and leave the reconnect ramp alone?
///
/// These drive the real `_recordConnectFailure` through its `@visibleForTesting` seam with the exact
/// exception objects `flutter_blue_plus` throws, so no radio is touched (the project rule forbids
/// launching the app). The exception shapes are taken from fbp's own `bluetooth_device.dart`:
///   • a native GATT failure  → `FlutterBluePlusException(_nativeError, "connect", <raw GATT status>, …)`
///     — on Android `_nativeError` is [ErrorPlatform.android] and the code is the raw status, so 147
///     is the establishment timeout we count.
///   • fbp's OWN connect timeout → `FlutterBluePlusException(ErrorPlatform.fbp, …, FbpErrorCode.timeout.index, …)`
///     — same TYPE, but the code is an enum INDEX, not a GATT status. That collision is exactly why
///     the `platform` check in the predicate is load-bearing.
class _FakeRepo implements BackfillRepository {
  @override
  Future<InsertCounts> insert(StreamBatch batch, String deviceId) async =>
      const InsertCounts();
}

/// The real thing an Android GATT establishment timeout arrives as.
FlutterBluePlusException _androidStatus(int code) =>
    FlutterBluePlusException(ErrorPlatform.android, 'connect', code, 'status $code');

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

  group('#147 classification — the load-bearing platform check', () {
    test('a SINGLE Android status-147 failure is NOT enough to warn (edge-of-range noise)', () {
      client.debugRecordConnectFailure(_androidStatus(147));

      expect(client.debugEstablishTimeoutStreak, 1);
      expect(client.lastError, isNull,
          reason: 'one lost connect request is normal at the edge of range; warning on it '
              'would false-alarm healthy setups');
    });

    test('TWO consecutive Android status-147 failures surface the recovery guidance', () {
      client.debugRecordConnectFailure(_androidStatus(147));
      client.debugRecordConnectFailure(_androidStatus(147));

      expect(client.debugEstablishTimeoutStreak, 2);
      expect(client.lastError, WhoopBleClient.establishTimeoutHint);
    });

    test('the hint is the honest strap/phone recovery — never re-pair steps', () {
      client.debugRecordConnectFailure(_androidStatus(147));
      client.debugRecordConnectFailure(_androidStatus(147));

      final hint = client.lastError!.toLowerCase();
      // A 147 link never reached a connected state, so no bond ever ran: telling the user to
      // unpair would cost them a re-pair that cannot fix a wedged radio.
      expect(hint, isNot(contains('pair')),
          reason: 'no pairing logic ever ran on a 147, so re-pair guidance would be a lie');
      expect(hint, isNot(contains('forget')));
      // The three that actually do fix it.
      expect(hint, contains('charger'));
      expect(hint, contains('bluetooth'));
      expect(hint, contains('restart'));
    });

    test('an fbp-ORIGIN code 147 must NOT count — only Android status 147 is a GATT status', () {
      // fbp reuses the same exception type for its own errors, where `code` is an FbpErrorCode
      // index. Without the platform check this would be misread as a GATT status the stack
      // never sent.
      client.debugRecordConnectFailure(
          FlutterBluePlusException(ErrorPlatform.fbp, 'connect', 147, 'fbp-origin'));
      client.debugRecordConnectFailure(
          FlutterBluePlusException(ErrorPlatform.fbp, 'connect', 147, 'fbp-origin'));

      expect(client.debugEstablishTimeoutStreak, 0);
      expect(client.lastError, isNull);
    });

    test("fbp's OWN connect timeout (platform fbp, code = FbpErrorCode.timeout) never counts", () {
      client.debugRecordConnectFailure(FlutterBluePlusException(
          ErrorPlatform.fbp, 'connect', FbpErrorCode.timeout.index, 'Timed out'));

      expect(client.debugEstablishTimeoutStreak, 0);
      expect(client.lastError, isNull);
    });

    test('an apple-platform code 147 must NOT count (147 is an Android GATT status)', () {
      client.debugRecordConnectFailure(_androidStatus(147));
      client.debugRecordConnectFailure(
          FlutterBluePlusException(ErrorPlatform.apple, 'connect', 147, 'apple-origin'));

      expect(client.debugEstablishTimeoutStreak, 0,
          reason: 'a non-Android failure is a DIFFERENT failure, so it breaks the streak');
      expect(client.lastError, isNull);
    });
  });

  group('#147 streak breaking — a different failure means the strap is answering', () {
    test('a non-147 Android status (133) breaks the streak', () {
      client.debugRecordConnectFailure(_androidStatus(147));
      expect(client.debugEstablishTimeoutStreak, 1);

      client.debugRecordConnectFailure(_androidStatus(133));

      expect(client.debugEstablishTimeoutStreak, 0);
      expect(client.lastError, isNull);
    });

    test('GATT_CONN_TIMEOUT (8) is a DIFFERENT failure and breaks the streak', () {
      // 0x08 is an ESTABLISHED link's supervision timing out — the bond stack's territory, not ours.
      client.debugRecordConnectFailure(_androidStatus(147));
      client.debugRecordConnectFailure(_androidStatus(8));

      expect(client.debugEstablishTimeoutStreak, 0);
      expect(client.lastError, isNull);
    });

    test('a plain non-fbp exception breaks the streak', () {
      client.debugRecordConnectFailure(_androidStatus(147));
      client.debugRecordConnectFailure(Exception('something else entirely'));

      expect(client.debugEstablishTimeoutStreak, 0);
    });

    test('a broken streak must re-accumulate from scratch before warning again', () {
      client.debugRecordConnectFailure(_androidStatus(147));
      client.debugRecordConnectFailure(_androidStatus(133)); // breaks it
      client.debugRecordConnectFailure(_androidStatus(147)); // streak = 1, not 2

      expect(client.debugEstablishTimeoutStreak, 1);
      expect(client.lastError, isNull);
    });
  });

  group('#147 guidance re-assertion', () {
    test('every over-threshold timeout RE-asserts the hint (not one-shot like the bond guides)', () {
      client.debugRecordConnectFailure(_androidStatus(147));
      client.debugRecordConnectFailure(_androidStatus(147));
      expect(client.lastError, WhoopBleClient.establishTimeoutHint);

      // A user-initiated Connect overwrites lastError with its own progress text; the UI having
      // cleared the note must not silence a strap that is still wedged.
      client.lastError = null;
      client.debugRecordConnectFailure(_androidStatus(147));

      expect(client.debugEstablishTimeoutStreak, 3);
      expect(client.lastError, WhoopBleClient.establishTimeoutHint,
          reason: 'the signal repeats so the caller can re-assert the idempotent hint');
    });
  });

  group('#147 must INFORM, never pause — 147 can self-heal', () {
    test('recording a sustained streak leaves the reconnect-backoff ramp untouched', () {
      // The backoff counter is what drives the capped-exponential reconnect in _onDisconnected.
      // A 147 streak must not touch it: the strap's radio may come back on its own, and pausing
      // would strand a strap that recovered.
      client.debugReconnectAttempt = 3;

      client.debugRecordConnectFailure(_androidStatus(147));
      client.debugRecordConnectFailure(_androidStatus(147));
      client.debugRecordConnectFailure(_androidStatus(147));

      expect(client.lastError, WhoopBleClient.establishTimeoutHint);
      expect(client.debugReconnectAttempt, 3,
          reason: 'the tracker informs only — the backoff reconnect keeps running unchanged');
    });
  });

  group('#147 streak resets', () {
    test('a user teardown / fresh Connect re-arms the streak', () {
      client.debugRecordConnectFailure(_androidStatus(147));
      client.debugRecordConnectFailure(_androidStatus(147));
      expect(client.debugEstablishTimeoutStreak, 2);

      client.debugResetForUserAction();

      expect(client.debugEstablishTimeoutStreak, 0,
          reason: 'the guidance the user just acted on must not re-assert off a stale streak');
    });

    test('a real connect (the strap answered) clears the streak', () {
      client.debugRecordConnectFailure(_androidStatus(147));
      client.debugResetEstablishTimeout(); // what _onConnected does

      expect(client.debugEstablishTimeoutStreak, 0);
    });

    test('after a reset the next warning needs a full fresh streak', () {
      client.debugRecordConnectFailure(_androidStatus(147));
      client.debugRecordConnectFailure(_androidStatus(147));
      client.debugResetForUserAction();
      client.lastError = null;

      client.debugRecordConnectFailure(_androidStatus(147));

      expect(client.lastError, isNull,
          reason: 'one timeout after a reset is edge-of-range noise again');
    });
  });

  group('connect-timeout headroom (the feature depends on it)', () {
    test("fbp's own timeout leaves real margin over Android's ~30s status-147", () {
      // If fbp's timer fired first we would get FbpErrorCode.timeout (platform fbp) and the 147
      // would NEVER reach the tracker — the whole feature would be dead. The old 35s left ~5s,
      // which the stack's own jitter can eat.
      expect(WhoopBleClient.connectTimeout.inSeconds, greaterThanOrEqualTo(50),
          reason: "fbp's timer must be a backstop, not a race against the Android stack");
    });
  });

  group('the tracker constant is the one the client compares against', () {
    test('the client counts exactly EstablishTimeoutTracker.gattConnEstablishTimeout', () {
      expect(EstablishTimeoutTracker.gattConnEstablishTimeout, 147);

      client.debugRecordConnectFailure(
          _androidStatus(EstablishTimeoutTracker.gattConnEstablishTimeout));

      expect(client.debugEstablishTimeoutStreak, 1);
    });
  });
}
