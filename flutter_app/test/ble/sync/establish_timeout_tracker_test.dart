import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/sync/establish_timeout_tracker.dart';

/// Port of `EstablishTimeoutTrackerTest.kt` (rntcruz23/noop @ b9680a9). Pins the status-147
/// establishment-timeout detector: a strap that advertises but never answers a connect request (two
/// consecutive ~30s establishment timeouts) must surface the charge-kick/radio recovery guidance,
/// while a single edge-of-range timeout — or a mixed streak broken by a different failure — must stay
/// quiet. Pure value type → no BLE seam needed.
void main() {
  test('single timeout stays quiet', () {
    final t = EstablishTimeoutTracker(); // default warnThreshold = 2
    // One lost connect request is edge-of-range noise, not a wedged radio.
    expect(t.recordFailedConnect(establishTimedOut: true), isFalse);
    expect(t.consecutiveTimeouts, 1);
  });

  test('warns on the second consecutive timeout and keeps re-asserting', () {
    final t = EstablishTimeoutTracker();
    expect(t.recordFailedConnect(establishTimedOut: true), isFalse);
    // Two in a row is the wedged-radio signature.
    expect(t.recordFailedConnect(establishTimedOut: true), isTrue);
    // Unlike the one-shot re-pair guides, the signal REPEATS on every further over-threshold timeout
    // so the caller can re-assert the hint after a user Connect overwrote it with "Searching…".
    expect(t.recordFailedConnect(establishTimedOut: true), isTrue);
    expect(t.consecutiveTimeouts, 3);
  });

  test('a different failure breaks the streak', () {
    final t = EstablishTimeoutTracker();
    expect(t.recordFailedConnect(establishTimedOut: true), isFalse);
    // A failed connect with a DIFFERENT status means the strap is at least answering.
    expect(t.recordFailedConnect(establishTimedOut: false), isFalse);
    expect(t.consecutiveTimeouts, 0);
    // Suspicion never accumulates across unrelated failures — the streak restarts from scratch.
    expect(t.recordFailedConnect(establishTimedOut: true), isFalse);
    expect(t.recordFailedConnect(establishTimedOut: true), isTrue);
  });

  test('a non-timeout failure while over threshold silences the guidance', () {
    final t = EstablishTimeoutTracker();
    t.recordFailedConnect(establishTimedOut: true);
    expect(t.recordFailedConnect(establishTimedOut: true), isTrue);
    // The strap started answering again (different status) → stop asserting the wedged-radio hint.
    expect(t.recordFailedConnect(establishTimedOut: false), isFalse);
    expect(t.consecutiveTimeouts, 0);
  });

  test('reset clears the streak', () {
    final t = EstablishTimeoutTracker();
    t.recordFailedConnect(establishTimedOut: true);
    t.recordFailedConnect(establishTimedOut: true);
    // reset() = a real connect (the strap answered), a user teardown, or a strap release.
    t.reset();
    expect(t.consecutiveTimeouts, 0);
    // Post-reset the next suspicion must accumulate afresh: the first 147 is noise again.
    expect(t.recordFailedConnect(establishTimedOut: true), isFalse);
  });

  test('reset is idempotent and safe on a fresh tracker', () {
    final t = EstablishTimeoutTracker();
    t.reset();
    t.reset();
    expect(t.consecutiveTimeouts, 0);
    expect(t.recordFailedConnect(establishTimedOut: true), isFalse);
  });

  test('custom threshold is honoured', () {
    // Defensive: the default is 2, but the knob must work.
    final t = EstablishTimeoutTracker(warnThreshold: 3);
    expect(t.recordFailedConnect(establishTimedOut: true), isFalse);
    expect(t.recordFailedConnect(establishTimedOut: true), isFalse);
    expect(t.recordFailedConnect(establishTimedOut: true), isTrue);
  });

  test('threshold of 1 warns on the first timeout', () {
    final t = EstablishTimeoutTracker(warnThreshold: 1);
    expect(t.recordFailedConnect(establishTimedOut: true), isTrue);
    expect(t.consecutiveTimeouts, 1);
  });

  test('the establishment-timeout status constant is 147 (0x93)', () {
    // Pinned: the wiring layer compares the raw flutter_blue_plus exception code against this.
    expect(EstablishTimeoutTracker.gattConnEstablishTimeout, 147);
    expect(EstablishTimeoutTracker.gattConnEstablishTimeout, 0x93);
  });

  test('a fresh tracker starts clean', () {
    expect(EstablishTimeoutTracker().consecutiveTimeouts, 0);
  });
}
