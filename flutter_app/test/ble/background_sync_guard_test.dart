import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/background/background_sync_worker.dart';

/// Unit-pins the single-owner concurrency guard's decision logic — the pure
/// [workerShouldYield] predicate that decides whether the headless WorkManager
/// worker must YIELD the strap + DB to a live foreground app.
///
/// This is the heart of HIGH-4: the old guard was asymmetric (checked once,
/// failed OPEN on error) so a foreground launch mid-offload produced two BLE/DB
/// owners. The fix makes the predicate fail-CLOSED and the worker re-evaluate it
/// continuously; these cases pin the truth table so a regression trips here first.
/// No DB, no radio, no real clock — project rule: never launch the app.
void main() {
  // A fixed "now" so every case is deterministic; heartbeat ages are expressed
  // relative to it in seconds.
  const nowUnix = 1_800_000_000;
  final staleSec = kHeartbeatStale.inSeconds;

  group('workerShouldYield — single-owner guard', () {
    test('no heartbeat ever stamped → app is dead → worker proceeds (no yield)', () {
      expect(
        workerShouldYield(beatUnix: null, nowUnix: nowUnix),
        isFalse,
        reason: 'A never-stamped heartbeat means the app has never claimed BLE; '
            'the worker is the sole owner and must run.',
      );
    });

    test('fresh heartbeat (just now) → app is alive → worker YIELDS', () {
      expect(
        workerShouldYield(beatUnix: nowUnix, nowUnix: nowUnix),
        isTrue,
      );
    });

    test('heartbeat 1s inside the stale window → still alive → worker YIELDS', () {
      expect(
        workerShouldYield(beatUnix: nowUnix - (staleSec - 1), nowUnix: nowUnix),
        isTrue,
        reason: 'Just under the stale threshold still counts as a live app.',
      );
    });

    test('heartbeat exactly at the stale threshold → app dead → worker proceeds', () {
      expect(
        workerShouldYield(beatUnix: nowUnix - staleSec, nowUnix: nowUnix),
        isFalse,
        reason: 'age >= kHeartbeatStale is the boundary at which the app is '
            'presumed killed and the worker may own BLE.',
      );
    });

    test('long-stale heartbeat (app killed hours ago) → worker proceeds', () {
      expect(
        workerShouldYield(beatUnix: nowUnix - (staleSec + 3600), nowUnix: nowUnix),
        isFalse,
      );
    });

    test('FUTURE / clock-skewed heartbeat → cannot prove stale → worker YIELDS (fail-closed)', () {
      expect(
        workerShouldYield(beatUnix: nowUnix + 120, nowUnix: nowUnix),
        isTrue,
        reason: 'A beat in the future (skew/DST) is ambiguous; the worker must '
            'not assume the app is dead — it yields.',
      );
    });

    test('KV read failure (lock contention / exception) → worker YIELDS (fail-closed)', () {
      // This is the exact HIGH-4 regression: the old guard returned false here
      // ("fail open → run anyway"), producing two concurrent owners.
      expect(
        workerShouldYield(beatUnix: null, nowUnix: nowUnix, readFailed: true),
        isTrue,
        reason: 'A lost heartbeat lock is NOT evidence the app is dead; on '
            'ambiguity the worker yields, never the foreground.',
      );
    });

    test('read failure overrides an otherwise-stale beat → still YIELDS', () {
      // Even if the (unreliable) value read looked stale, a failed/ambiguous read
      // must fail closed regardless of the value.
      expect(
        workerShouldYield(
          beatUnix: nowUnix - (staleSec + 3600),
          nowUnix: nowUnix,
          readFailed: true,
        ),
        isTrue,
      );
    });
  });
}
