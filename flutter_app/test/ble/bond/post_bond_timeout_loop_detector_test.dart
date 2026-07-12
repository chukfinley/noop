import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/bond/post_bond_timeout_loop_detector.dart';

/// Port of `PostBondTimeoutLoopDetectorTest.kt` (#617). A WHOOP 4 strap bonds, then the encrypted link
/// drops ~1s later with a connection timeout, the auto-rescan reconnects, it bonds again, and dies
/// again — an endless bond→timeout loop. The detector watches for CONSECUTIVE bond-then-quick-timeout
/// cycles and, after the threshold, surfaces the re-pair guide. Pure value type → no BLE seam needed.
void main() {
  test('trips after two consecutive bond timeouts', () {
    final d = PostBondTimeoutLoopDetector(); // default tripThreshold=2, window=8s
    expect(
      d.connectionEnded(wasBonded: true, msSinceBond: 1000, timedOut: true),
      isFalse, // one bond-then-timeout is noise, not yet a trip
    );
    expect(d.tripped, isFalse);
    expect(
      d.connectionEnded(wasBonded: true, msSinceBond: 1200, timedOut: true),
      isTrue, // second consecutive bond-then-timeout trips the loop
    );
    expect(d.tripped, isTrue);
    // Already tripped → no second "freshly tripped" signal (caller surfaces the guide only once).
    expect(d.connectionEnded(wasBonded: true, msSinceBond: 900, timedOut: true), isFalse);
    expect(d.tripped, isTrue);
  });

  test('single drop does not trip', () {
    final d = PostBondTimeoutLoopDetector();
    expect(d.connectionEnded(wasBonded: true, msSinceBond: 1000, timedOut: true), isFalse);
    expect(d.tripped, isFalse);
    expect(d.consecutiveBondTimeouts, 1);
  });

  test('timeout outside window breaks the streak', () {
    final d = PostBondTimeoutLoopDetector(tripThreshold: 2, quickTimeoutWindowMs: 8000);
    expect(d.connectionEnded(wasBonded: true, msSinceBond: 2000, timedOut: true), isFalse);
    expect(d.consecutiveBondTimeouts, 1);
    // 90s after bonding: the link clearly survived the bond — this drop is unrelated to the loop.
    expect(d.connectionEnded(wasBonded: true, msSinceBond: 90000, timedOut: true), isFalse);
    expect(d.consecutiveBondTimeouts, 0); // a late drop resets the bond-timeout streak
    expect(d.tripped, isFalse);
  });

  test('non-timeout close does not count', () {
    final d = PostBondTimeoutLoopDetector();
    expect(d.connectionEnded(wasBonded: true, msSinceBond: 1000, timedOut: true), isFalse);
    expect(d.connectionEnded(wasBonded: true, msSinceBond: 1000, timedOut: false), isFalse);
    expect(d.consecutiveBondTimeouts, 0); // a clean (non-timeout) close resets suspicion
    // ...and now it takes two fresh bond-timeouts again to trip.
    expect(d.connectionEnded(wasBonded: true, msSinceBond: 1000, timedOut: true), isFalse);
    expect(d.connectionEnded(wasBonded: true, msSinceBond: 1000, timedOut: true), isTrue);
    expect(d.tripped, isTrue);
  });

  test('unbonded drop resets the streak', () {
    final d = PostBondTimeoutLoopDetector();
    expect(d.connectionEnded(wasBonded: true, msSinceBond: 1000, timedOut: true), isFalse);
    expect(d.consecutiveBondTimeouts, 1);
    expect(d.connectionEnded(wasBonded: false, msSinceBond: null, timedOut: true), isFalse);
    expect(d.consecutiveBondTimeouts, 0);
  });

  test('null sinceBond does not count', () {
    final d = PostBondTimeoutLoopDetector();
    expect(d.connectionEnded(wasBonded: true, msSinceBond: null, timedOut: true), isFalse);
    expect(d.consecutiveBondTimeouts, 0);
    expect(d.tripped, isFalse);
  });

  test('timeout at the window boundary counts', () {
    final d = PostBondTimeoutLoopDetector(tripThreshold: 2, quickTimeoutWindowMs: 8000);
    expect(d.connectionEnded(wasBonded: true, msSinceBond: 8000, timedOut: true), isFalse);
    expect(d.consecutiveBondTimeouts, 1); // exactly at the window boundary still counts
  });

  test('reset clears state', () {
    final d = PostBondTimeoutLoopDetector();
    d.connectionEnded(wasBonded: true, msSinceBond: 1000, timedOut: true);
    d.connectionEnded(wasBonded: true, msSinceBond: 1000, timedOut: true);
    expect(d.tripped, isTrue);
    d.reset();
    expect(d.tripped, isFalse);
    expect(d.consecutiveBondTimeouts, 0);
    // After reset it takes the full threshold again to re-trip.
    expect(d.connectionEnded(wasBonded: true, msSinceBond: 1000, timedOut: true), isFalse);
    expect(d.tripped, isFalse);
  });

  test('custom higher threshold', () {
    final d = PostBondTimeoutLoopDetector(tripThreshold: 3, quickTimeoutWindowMs: 8000);
    expect(d.connectionEnded(wasBonded: true, msSinceBond: 1000, timedOut: true), isFalse);
    expect(d.connectionEnded(wasBonded: true, msSinceBond: 1000, timedOut: true), isFalse);
    expect(d.tripped, isFalse);
    expect(d.connectionEnded(wasBonded: true, msSinceBond: 1000, timedOut: true), isTrue);
    expect(d.tripped, isTrue);
  });
}
