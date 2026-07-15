/// Faithful Dart port of `EstablishTimeoutTracker.kt` (#147-guidance, rntcruz23/noop @ b9680a9).
///
/// Detects a strap that ADVERTISES but never ANSWERS connection requests: the scan finds it
/// immediately (often at strong RSSI), the connect goes out, and the stack gives up ~30s later with
/// GATT status 147 (0x93, the Android 14+ fine-grained code for a connection-establishment timeout)
/// without the link ever reaching STATE_CONNECTED. Seen in the field on a WHOOP 5/MG whose BLE
/// firmware wedged after a spontaneous reboot: the band kept advertising while refusing every
/// connection, and the app retried silently forever — the user saw an endless "Searching…" with no
/// explanation and no way to know the fix is on the strap/phone side (charge-kick the strap, toggle
/// Bluetooth, restart the phone), NOT a pairing problem.
///
/// Distinct from every bond detector in `../bond/`: status 147 means the link never came up at all,
/// so no pairing/bond logic ever ran and none of the re-pair guides apply — surfacing them here would
/// cost the user a needless unpair that cannot fix a wedged radio. Distinct too from
/// `GATT_CONN_TIMEOUT` (0x08), which is an ESTABLISHED link's supervision timing out (that is #617's
/// [PostBondTimeoutLoopDetector] territory).
///
/// A SINGLE establishment timeout is normal at the edge of range (the connect request can simply be
/// lost), so warning on one would false-alarm healthy setups. We require CONSECUTIVE establishment
/// timeouts with nothing in between: any failed connect with a DIFFERENT status breaks the streak (a
/// different failure means the strap is at least answering), and the caller [reset]s on a real
/// connect, a user teardown, and a strap release. At [warnThreshold] the caller surfaces the recovery
/// guidance; unlike the one-shot re-pair guides, the signal REPEATS on every over-threshold timeout so
/// the caller can re-assert the (idempotent) hint after the UI cleared it — a user-initiated Connect
/// overwrites the status note with "Searching…".
///
/// The caller must NOT pause its reconnect backoff on this: 147 can self-heal (the strap's radio may
/// come back on its own), so we inform, never pause.
///
/// ANDROID-ONLY by necessity: 147 is an Android (14+) GATT stack code with no CoreBluetooth analogue —
/// iOS surfaces establishment failures through `didFailToConnect`, which already has its own backoff +
/// guidance (#414), so there is no Swift twin to keep in parity.
///
/// Pure value type → unit-testable without a BLE seam (no flutter_blue_plus import). The concrete
/// Dart-side signal that feeds it: `flutter_blue_plus`'s `device.connect()` throws a
/// `FlutterBluePlusException` whose `.code` is the raw Android GATT `status` (the Android plugin puts
/// `onConnectionStateChange`'s `status` straight into `disconnect_reason_code`, which
/// `BluetoothDevice.connect` rethrows as the exception code) — so `e.platform == ErrorPlatform.android
/// && e.code == 147` is the establishment-timeout tell.
library;

class EstablishTimeoutTracker {
  EstablishTimeoutTracker({this.warnThreshold = 2});

  /// The raw Android GATT `status` for "connection was never established": the connect request went
  /// out, the strap never answered, and the stack gave up ~30s later. 147 / 0x93 — the Android 14+
  /// fine-grained establishment-timeout code (older stacks folded this into the generic 133). Exposed
  /// so the wiring layer compares against one named constant instead of a bare literal.
  static const int gattConnEstablishTimeout = 0x93; // 147

  /// Consecutive establishment timeouts before the guidance shows. 2 (not 1): one lost connect request
  /// is edge-of-range noise; two ~30s timeouts in a row (≈ a minute of silence, with the strap
  /// advertising the whole time) is the wedged-radio signature.
  final int warnThreshold;

  int _consecutiveTimeouts = 0;

  /// Consecutive failed connects that were establishment timeouts (status 147).
  int get consecutiveTimeouts => _consecutiveTimeouts;

  /// Record a FAILED connect attempt (the link never reached a connected state and the drop was
  /// involuntary). [establishTimedOut] = the stack reported a connection-establishment timeout (status
  /// [gattConnEstablishTimeout]). Returns true once the streak is SUSTAINED (>= [warnThreshold]) — the
  /// caller surfaces/re-asserts the recovery guidance then. Any other failure status breaks the streak.
  bool recordFailedConnect({required bool establishTimedOut}) {
    if (!establishTimedOut) {
      _consecutiveTimeouts = 0;
      return false;
    }
    _consecutiveTimeouts += 1;
    return _consecutiveTimeouts >= warnThreshold;
  }

  /// Clear the streak: the link established (the strap answered), or the user tore down / released the
  /// strap. The next suspicion must accumulate afresh.
  void reset() {
    _consecutiveTimeouts = 0;
  }
}
