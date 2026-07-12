/// Faithful Dart port of `ReconnectBackoff.kt`.
///
/// Capped exponential reconnect backoff — the twin of the iOS BLEManager schedule
/// (`min(60, 3 * 2^(n-1))`, BLEManager.swift didFailToConnect, #414). A strap that's genuinely out of
/// range must not hammer BLE with a fixed-3s rescan loop; the delay grows 3 → 6 → 12 → 24 → 48 → 60s
/// and then holds at the 60s ceiling. Pure + side-effect-free so it's unit-testable in isolation from
/// the GATT machinery; the BLE client owns the attempt counter and resets it on a real connect.
library;

class ReconnectBackoff {
  ReconnectBackoff._();

  /// First (and minimum) delay, matching the iOS base and the previous fixed RECONNECT_DELAY_MS.
  static const int baseDelayMs = 3000;

  /// Ceiling — the schedule never waits longer than this between attempts.
  static const int maxDelayMs = 60000;

  /// Delay before the [attempt]-th reconnect (1-based: attempt 1 → 3s, 2 → 6s, 3 → 12s, 4 → 24s,
  /// 5 → 48s, 6+ → 60s). [attempt] values ≤ 1 (including 0 / negatives, e.g. an uninitialised or
  /// underflowed counter) coerce to the base delay rather than producing a sub-base or negative wait.
  ///
  /// Overflow guard: `3000 << n` would overflow well before n is large, and even before that it sails
  /// past the 60s cap — so for attempt ≥ 6 we short-circuit to [maxDelayMs]. That keeps the largest
  /// shift at `3000 << 4` (attempt 5 = 48s), the last value below the ceiling.
  static int nextDelayMs(int attempt) {
    final n = attempt < 1 ? 1 : attempt;
    if (n >= 6) return maxDelayMs;
    final delay = baseDelayMs << (n - 1); // 3000, 6000, 12000, 24000, 48000
    return delay < maxDelayMs ? delay : maxDelayMs;
  }
}
