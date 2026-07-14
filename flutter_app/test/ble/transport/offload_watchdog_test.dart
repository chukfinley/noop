import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';
import 'package:noop/core/ble/sync/backfiller.dart';
import 'package:noop/core/ble/transport/whoop_ble_client.dart';

/// Radio-free tests for the offload sync fixes that bring the transport in line with the official
/// WHOOP app (reverse-engineered from `com.whoop.straphistorysync.sync` + the working Kotlin client):
///
///   • Offload inactivity watchdog — a strap that goes silent mid-offload (no BLE disconnect) must
///     NOT wedge `syncing` forever. The official app applies a 5 s inter-packet timeout and then
///     sends ABORT_HISTORICAL_TRANSMITS; our watchdog must end the session so the live path resumes.
///   • GET_BATTERY_LEVEL (0x1A) response decode — the strap reports battery over a proprietary
///     command, not the standard 0x2A19 service; the raw-byte percentage (+ charging) must decode.
///
/// Every radio path is guarded behind `_blePlatform` (false under `flutter test`), so these drive the
/// REAL transitions through the `@visibleForTesting` seams without touching `flutter_blue_plus`.
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

  group('offload inactivity watchdog', () {
    test('a mid-offload stall leaves `syncing` for a reachable idle instead of wedging', () {
      client.debugForceSyncing();
      expect(client.debugSyncing, isTrue);
      expect(client.state, BleConnectionState.syncing);

      // The strap goes silent; the watchdog elapses.
      client.debugFireOffloadWatchdog();

      expect(client.debugSyncing, isFalse,
          reason: 'the session must end so the live path is no longer suppressed');
      expect(client.state, BleConnectionState.idle,
          reason: 'off-device (_connected false) the ended offload returns to a retryable idle');
    });

    test('firing the watchdog when not syncing is a no-op', () {
      expect(client.debugSyncing, isFalse);
      client.debugSetState(BleConnectionState.connected);
      client.debugFireOffloadWatchdog();
      expect(client.state, BleConnectionState.connected,
          reason: 'a late watchdog must not clobber a settled connected state');
    });
  });

  group('GET_BATTERY_LEVEL (0x1A) response decode', () {
    // WHOOP4 COMMAND_RESPONSE: response command byte sits at offset 6; data at inner offset 5 == 9.
    Uint8List w4Frame(List<int> tail) => Uint8List.fromList(
          <int>[0xAA, 0x00, 0x00, 0x00, 36, 0x01, 26, ...tail],
        );

    test('decodes the raw-byte percentage at the RE-precise offset (cmdOff+3) + charging', () {
      // tail: [7]=status, [8]=pad, [9]=pct 85, [10]=charging 1
      final r = WhoopBleClient.decodeBatteryResponse(w4Frame([0x00, 0x00, 85, 1]), 6);
      expect(r, isNotNull);
      expect(r!.$1, closeTo(0.85, 1e-9));
      expect(r.$2, isTrue);
    });

    test('reports not-charging when the flag byte is 0', () {
      final r = WhoopBleClient.decodeBatteryResponse(w4Frame([0x00, 0x00, 42, 0]), 6);
      expect(r!.$1, closeTo(0.42, 1e-9));
      expect(r.$2, isFalse);
    });

    test('leaves charging null when no 0/1 flag byte follows', () {
      final r = WhoopBleClient.decodeBatteryResponse(w4Frame([0x00, 0x00, 60]), 6);
      expect(r!.$1, closeTo(0.60, 1e-9));
      expect(r.$2, isNull);
    });

    test('falls back to the first plausible byte when cmdOff+3 is not a percentage', () {
      // cmdOff+3 (index 9) is 0 (implausible); the real value 73 is one byte later.
      final r = WhoopBleClient.decodeBatteryResponse(w4Frame([0x00, 0x00, 0, 73, 0]), 6);
      expect(r!.$1, closeTo(0.73, 1e-9));
    });

    test('returns null when the response carries no plausible percentage', () {
      final r = WhoopBleClient.decodeBatteryResponse(w4Frame([0x00, 0x00, 0, 0]), 6);
      expect(r, isNull);
    });
  });
}
