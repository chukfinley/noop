/// Faithful Dart port of `BondWatchdogBackoff.kt` (#971).
///
/// Paces the WHOOP 4.0 bond-handshake watchdog so a genuinely SLOW bond gets progressively more time
/// before the link is bounced, and a strap whose handshake never completes stops bouncing after a
/// capped number of tries instead of looping forever. Pure + side-effect-free (no flutter_blue_plus
/// import) so it's unit-testable in isolation from the GATT machinery — the same shape as
/// [PostBondTimeoutLoopDetector] / [BondRefusalGiveUp].
///
/// Three parts, all decided here:
///  1. ESCALATE the watchdog window per consecutive bounce ([windowMsForAttempt]) so a slow-but-healthy
///     handshake that just needs 9-10s gets it on the second/third try instead of being bounced forever
///     at a too-tight 7s. Capped so a truly dead handshake can't wait minutes.
///  2. COUNT consecutive bounces ([recordBounce]); the streak survives the intermediate connected state
///     (unlike the reconnect backoff) and is cleared only by a genuine bond ([reset]) or an explicit
///     user reconnect.
///  3. GIVE UP after [giveUpThreshold] bounces ([shouldGiveUp]): stop bouncing, surface the re-pair
///     guide and pause auto-reconnect, so a strap that genuinely can't finish the handshake stops
///     draining the battery.
///
/// ANDROID-ONLY concern: the bond watchdog only exists on Android (iOS's CoreBluetooth owns bonding),
/// so there is no iOS twin to keep in parity.
library;

class BondWatchdogBackoff {
  BondWatchdogBackoff({
    this.baseWindowMs = 7000,
    this.stepMs = 3000,
    this.maxWindowMs = 16000,
    this.giveUpThreshold = 4,
  });

  /// The first (tightest) watchdog window, matching the historical fixed 7s timeout.
  final int baseWindowMs;

  /// Extra time added to the window per prior bounce (attempt 1 → base, 2 → base+step, ...).
  final int stepMs;

  /// Ceiling — a slow handshake gets at most this long before a bounce, so a dead one can't hang.
  final int maxWindowMs;

  /// Consecutive bounces before we STOP bouncing and hand off to the re-pair guide + auto-reconnect
  /// pause. 4: each bounce here also costs a full reconnect + rediscover, so a slow-but-recoverable
  /// handshake gets several escalating windows (7s, 10s, 13s, 16s) before we declare it stuck.
  final int giveUpThreshold;

  int _consecutiveBounces = 0;
  bool _gaveUp = false;

  /// Consecutive bond-watchdog bounces with no genuine bond in between.
  int get consecutiveBounces => _consecutiveBounces;

  /// True once [giveUpThreshold] bounces have accrued — the caller must stop bouncing and hand off.
  bool get gaveUp => _gaveUp;

  /// The watchdog window to arm for the NEXT handshake, given the bounces seen so far. Escalates from
  /// [baseWindowMs] by [stepMs] per prior bounce, capped at [maxWindowMs]. With 0 bounces this is the
  /// historical 7s, so the first, common healthy connect is UNCHANGED.
  int currentWindowMs() => windowMsForAttempt(_consecutiveBounces);

  /// Pure window schedule: [priorBounces] = how many bounces have already happened (0-based). A
  /// negative / uninitialised count coerces to the base window, never a sub-base value.
  int windowMsForAttempt(int priorBounces) {
    final n = priorBounces < 0 ? 0 : priorBounces;
    final window = baseWindowMs + stepMs * n;
    return window < maxWindowMs ? window : maxWindowMs;
  }

  /// Record one bond-watchdog bounce (the handshake didn't land inside its window). Returns true if
  /// THIS bounce freshly crossed [giveUpThreshold] — the caller then stops bouncing and surfaces the
  /// re-pair guide + pauses auto-reconnect exactly once.
  bool recordBounce() {
    _consecutiveBounces += 1;
    if (!_gaveUp && _consecutiveBounces >= giveUpThreshold) {
      _gaveUp = true;
      return true;
    }
    return false;
  }

  /// Whether the caller should give up bouncing now (already at/over the threshold).
  bool shouldGiveUp() => _gaveUp;

  /// Clear the streak: a genuine bond landed, or the user explicitly reconnected. Re-arms the tight
  /// base window and lets a later slow handshake escalate afresh.
  void reset() {
    _consecutiveBounces = 0;
    _gaveUp = false;
  }
}
