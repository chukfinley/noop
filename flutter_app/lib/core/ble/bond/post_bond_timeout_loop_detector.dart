/// Faithful Dart port of `PostBondTimeoutLoopDetector.kt` (#617).
///
/// Detects a WHOOP 4 "bond-loop": the strap bonds successfully, then the encrypted link drops ~1s later
/// with a CONNECTION TIMEOUT (Android `GATT_CONN_TIMEOUT` / `0x08`), the auto-rescan reconnects, it
/// bonds again, and dies again — an endless bond→timeout cycle that never settles and never tells the
/// user why.
///
/// The tell is a TIMEOUT drop that lands shortly after a GENUINE bond: bond → die-soon → rescan → bond
/// → die-soon. A bond that survives well past the window is healthy and breaks the streak — links flap
/// for benign reasons minutes in, and a late drop must NOT be blamed on the bond. We don't trip on a
/// single cycle (one quick drop is noise); we trip on >= [tripThreshold] CONSECUTIVE
/// bond-then-quick-timeout cycles. Once tripped, the caller surfaces the re-pair guide.
///
/// Pure value type → unit-testable without a BLE seam (no flutter_blue_plus import).
library;

class PostBondTimeoutLoopDetector {
  PostBondTimeoutLoopDetector({
    this.tripThreshold = 2,
    this.quickTimeoutWindowMs = 8000,
  });

  /// How many consecutive bond-then-quick-timeout cycles before we surface the re-pair guide.
  /// 2 (not 1): one quick post-bond drop is noise; two in a row is the loop, not a fluke.
  final int tripThreshold;

  /// A timeout only counts as "right after bonding" if it lands within this many milliseconds of the
  /// bond. A drop well into a healthy session is unrelated to bonding and must NOT count. 8s.
  final int quickTimeoutWindowMs;

  int _consecutiveBondTimeouts = 0;
  bool _tripped = false;

  int get consecutiveBondTimeouts => _consecutiveBondTimeouts;

  /// True once we've tripped: the caller has surfaced (or should surface) the re-pair guide.
  bool get tripped => _tripped;

  /// A connection ended. [wasBonded] = the link reached a genuine encrypted bond this connection;
  /// [msSinceBond] = how long after bonding the link ended in milliseconds (null if we never bonded);
  /// [timedOut] = the drop looks like a connection timeout (vs an intentional disconnect, a bond reset,
  /// a clean close). Returns true if THIS event tripped the loop (a freshly-crossed threshold), so the
  /// caller can log/surface the guide exactly once.
  bool connectionEnded({
    required bool wasBonded,
    required int? msSinceBond,
    required bool timedOut,
  }) {
    // Only a timeout that lands within the window after we actually bonded is evidence of the loop.
    // Anything else (never bonded, non-timeout close, a drop long after a healthy bond) breaks the
    // streak — a single healthy spell should clear prior suspicion.
    final bondThenQuickTimeout = wasBonded &&
        timedOut &&
        (msSinceBond != null && msSinceBond <= quickTimeoutWindowMs);
    if (!bondThenQuickTimeout) {
      _consecutiveBondTimeouts = 0;
      return false;
    }
    _consecutiveBondTimeouts += 1;
    if (!_tripped && _consecutiveBondTimeouts >= tripThreshold) {
      _tripped = true;
      return true; // freshly tripped — caller surfaces the re-pair guide once
    }
    return false;
  }

  /// Clear all suspicion: a clean session is flowing, or the user explicitly disconnected. Lets a
  /// transient bond hiccup recover instead of permanently flagging the link as bond-looping.
  void reset() {
    _consecutiveBondTimeouts = 0;
    _tripped = false;
  }
}
