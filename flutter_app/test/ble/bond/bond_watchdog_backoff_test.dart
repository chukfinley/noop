import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/bond/bond_watchdog_backoff.dart';

/// Port of `BondWatchdogBackoffTest.kt` (#971). A slow-but-healthy bond must get progressively MORE
/// time before the watchdog bounces it, and a handshake that never completes must STOP bouncing after
/// a capped number of tries. Pure value type — no BLE seam needed.
void main() {
  test('window escalates per bounce and caps', () {
    final b = BondWatchdogBackoff(baseWindowMs: 7000, stepMs: 3000, maxWindowMs: 16000);
    expect(b.windowMsForAttempt(0), 7000); // 0 bounces => historical 7s (unchanged first connect)
    expect(b.windowMsForAttempt(1), 10000);
    expect(b.windowMsForAttempt(2), 13000);
    expect(b.windowMsForAttempt(3), 16000);
    // Past the cap the window holds at the ceiling — a dead handshake can't wait minutes.
    expect(b.windowMsForAttempt(4), 16000);
    expect(b.windowMsForAttempt(99), 16000);
  });

  test('negative prior bounces coerce to base', () {
    final b = BondWatchdogBackoff(baseWindowMs: 7000, stepMs: 3000, maxWindowMs: 16000);
    expect(b.windowMsForAttempt(-5), 7000);
  });

  test('current window tracks recorded bounces', () {
    final b = BondWatchdogBackoff(
        baseWindowMs: 7000, stepMs: 3000, maxWindowMs: 16000, giveUpThreshold: 4);
    expect(b.currentWindowMs(), 7000); // no bounces yet
    b.recordBounce();
    expect(b.currentWindowMs(), 10000); // one bounce -> next window is wider
    b.recordBounce();
    expect(b.currentWindowMs(), 13000);
  });

  test('gives up once at threshold', () {
    final b = BondWatchdogBackoff(giveUpThreshold: 4);
    expect(b.recordBounce(), isFalse); // bounce 1 keeps bouncing
    expect(b.shouldGiveUp(), isFalse);
    expect(b.recordBounce(), isFalse); // bounce 2
    expect(b.recordBounce(), isFalse); // bounce 3
    expect(b.recordBounce(), isTrue); // bounce 4 crosses the cap -> give up (fresh)
    expect(b.shouldGiveUp(), isTrue);
    expect(b.consecutiveBounces, 4);
    // Already gave up -> no second "freshly gave up" signal (caller surfaces the guide once).
    expect(b.recordBounce(), isFalse);
    expect(b.shouldGiveUp(), isTrue);
  });

  test('reset clears streak and re-arms base window', () {
    final b = BondWatchdogBackoff(
        baseWindowMs: 7000, stepMs: 3000, maxWindowMs: 16000, giveUpThreshold: 4);
    for (var i = 0; i < 4; i++) {
      b.recordBounce();
    }
    expect(b.shouldGiveUp(), isTrue);
    expect(b.currentWindowMs(), 16000);

    b.reset();
    expect(b.shouldGiveUp(), isFalse);
    expect(b.consecutiveBounces, 0);
    expect(b.currentWindowMs(), 7000); // window back to the tight base after a genuine bond

    // And it can escalate + give up again, exactly like the first cycle.
    expect(b.recordBounce(), isFalse);
    expect(b.currentWindowMs(), 10000);
  });

  test('defaults match the shipped config', () {
    final b = BondWatchdogBackoff();
    expect(b.windowMsForAttempt(0), 7000);
    expect(b.windowMsForAttempt(1), 10000);
    expect(b.windowMsForAttempt(2), 13000);
    expect(b.windowMsForAttempt(3), 16000);
    expect(b.windowMsForAttempt(4), 16000);
    expect(b.recordBounce(), isFalse);
    expect(b.recordBounce(), isFalse);
    expect(b.recordBounce(), isFalse);
    expect(b.recordBounce(), isTrue); // default give-up threshold is 4
  });
}
