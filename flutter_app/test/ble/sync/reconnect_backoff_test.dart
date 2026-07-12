import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/sync/reconnect_backoff.dart';

/// Port of `ReconnectBackoffTest.kt`. Pure capped-exponential reconnect schedule (#48): the iOS
/// BLEManager backoff `min(60, 3 * 2^(n-1))` — 3, 6, 12, 24, 48, 60s then held.
void main() {
  test('first six attempts match the capped exponential schedule', () {
    expect(ReconnectBackoff.nextDelayMs(1), 3000);
    expect(ReconnectBackoff.nextDelayMs(2), 6000);
    expect(ReconnectBackoff.nextDelayMs(3), 12000);
    expect(ReconnectBackoff.nextDelayMs(4), 24000);
    expect(ReconnectBackoff.nextDelayMs(5), 48000);
    expect(ReconnectBackoff.nextDelayMs(6), 60000);
  });

  test('attempt five is the last value below the ceiling', () {
    expect(ReconnectBackoff.nextDelayMs(5), 48000);
    expect(ReconnectBackoff.nextDelayMs(5) < ReconnectBackoff.maxDelayMs, isTrue);
  });

  test('delay never exceeds the ceiling for large attempts', () {
    expect(ReconnectBackoff.nextDelayMs(7), 60000);
    expect(ReconnectBackoff.nextDelayMs(20), 60000);
    expect(ReconnectBackoff.nextDelayMs(64), 60000);
    expect(ReconnectBackoff.nextDelayMs(0x7FFFFFFFFFFFFFFF), 60000);
  });

  test('zero and negative attempts coerce to the base delay', () {
    expect(ReconnectBackoff.nextDelayMs(0), ReconnectBackoff.baseDelayMs);
    expect(ReconnectBackoff.nextDelayMs(-1), ReconnectBackoff.baseDelayMs);
    expect(ReconnectBackoff.nextDelayMs(-0x8000000000000000), ReconnectBackoff.baseDelayMs);
  });

  test('every delay is at least one and within bounds', () {
    for (var n = -5; n <= 70; n++) {
      final d = ReconnectBackoff.nextDelayMs(n);
      expect(d >= 1, isTrue, reason: 'attempt $n gave $d (< 1)');
      expect(d <= ReconnectBackoff.maxDelayMs, isTrue, reason: 'attempt $n gave $d (> cap)');
    }
  });

  test('schedule matches the closed form min(60, 3 * 2^(n-1))', () {
    for (var n = 1; n <= 12; n++) {
      final closedFormSeconds = math.min(60.0, 3.0 * math.pow(2.0, (n - 1).toDouble()));
      final expectedMs = (closedFormSeconds * 1000.0).toInt();
      expect(ReconnectBackoff.nextDelayMs(n), expectedMs, reason: 'attempt $n');
    }
  });
}
