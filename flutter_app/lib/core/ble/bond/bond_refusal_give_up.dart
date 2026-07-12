/// Faithful Dart port of `BondRefusalGiveUp.kt` (#747 / #750).
///
/// Decides when a strap that keeps REFUSING the encrypted bond (INSUFFICIENT_AUTHENTICATION /
/// _ENCRYPTION, no genuine bond in between) has refused enough times that hammering it further is
/// pointless. Two responsibilities, both pure so they're unit-testable without a BLE seam (no
/// flutter_blue_plus import):
///
///  - #747 PAUSE: after [giveUpThreshold] consecutive refusals the auto-reconnect should STOP
///    re-kicking (it can't bond without the user freeing the strap / re-pairing), so the caller pauses
///    the rescan and surfaces an honest hint instead of looping forever and draining the battery.
///  - #750 EPITAPH: at the same moment, emit ONE summary "epitaph" line recording how the bond attempt
///    died (the streak + an opaque, install-local id), so a shared strap log carries the cause without
///    any PII (no MAC, no serial, just the count and a short opaque token).
///
/// The streak accumulates across the reconnect loop (a disconnect does NOT reset it) and is cleared
/// only by a genuine bond or an explicit user reconnect.
library;

import 'dart:convert';
import 'dart:typed_data';

class BondRefusalGiveUp {
  BondRefusalGiveUp({this.giveUpThreshold = 5});

  /// Consecutive bond refusals before we pause auto-reconnect + write the epitaph. 5 (not 2, where the
  /// pairing HINT already shows): the hint asks the user to act; we give them several reconnect cycles
  /// to do it before we stop hammering.
  final int giveUpThreshold;

  int _refusals = 0;
  bool _gaveUp = false;

  int get refusals => _refusals;

  /// True once [giveUpThreshold] is reached: auto-reconnect should pause and the epitaph has been (or
  /// should be) written. Stays true until [reset] so the pause holds across the loop.
  bool get gaveUp => _gaveUp;

  /// Record one bond refusal. Returns true if THIS refusal freshly crossed the give-up threshold (so
  /// the caller pauses the reconnect + writes the epitaph exactly once).
  bool recordRefusal() {
    _refusals += 1;
    if (!_gaveUp && _refusals >= giveUpThreshold) {
      _gaveUp = true;
      return true;
    }
    return false;
  }

  /// Clear the streak: a genuine bond landed, or the user explicitly reconnected. Re-arms auto-reconnect.
  void reset() {
    _refusals = 0;
    _gaveUp = false;
  }

  /// #750: the one-line bond-refusal EPITAPH. Records the streak + an OPAQUE install-local id only,
  /// never a MAC or serial. [opaqueId] should be a short token derived from the per-install local
  /// device id, which carries no PII. Pure so a fixture pins it. No em-dash (project rule).
  /// Byte-identical to the Kotlin `BondRefusalGiveUp.epitaphLine`.
  static String epitaphLine(int refusals, String opaqueId) =>
      'Bond epitaph: the strap [$opaqueId] refused the encrypted bond ${refusals}x in a row with no '
      'successful bond - giving up auto-reconnect to stop hammering it. It is almost certainly '
      'held by the official WHOOP app or a stale phone pairing. Free it (close the WHOOP app, put '
      'the strap in pairing mode, forget it in Bluetooth settings) then reconnect in NOOP.';

  /// #747: the honest user-facing hint shown when auto-reconnect pauses. Tells them WHY it stopped and
  /// how to get going again. Pure; no em-dash. Byte-identical to the Kotlin `BondRefusalGiveUp.pausedHint`.
  static String pausedHint() =>
      'NOOP stopped retrying because your strap keeps refusing to pair. It is likely still held by the '
      'official WHOOP app, or your phone is holding an old pairing. Close the WHOOP app, put the '
      'strap in pairing mode (tap until the LEDs flash blue), and if it is listed in your Bluetooth '
      'settings choose Forget This Device. Then tap Connect to try again.';

  /// #750: a short OPAQUE token for the epitaph, derived from the strap's device id.
  ///
  /// On Android the strap id IS a MAC address (PII), so we must NEVER expose its bytes. We therefore
  /// HASH it (SHA-256, first 8 hex of the digest) so the token is stable within a log, lets us tell two
  /// straps apart, but is irreversible and carries no device-identifying PII. Pure + deterministic.
  /// Falls back to a safe constant token if hashing ever throws, so id-formatting can never crash the
  /// bond path (and the MAC still never reaches the log).
  static String opaqueId(String localId) {
    try {
      final digest = _sha256(utf8.encode(localId.toLowerCase()));
      final sb = StringBuffer();
      for (var i = 0; i < 4; i++) {
        sb.write(digest[i].toRadixString(16).padLeft(2, '0'));
      }
      return sb.toString();
    } catch (_) {
      return 'device';
    }
  }
}

// ── Pure SHA-256 (FIPS 180-4) ──────────────────────────────────────────────────────────────────
// Self-contained so the bond epitaph needs no extra package dependency. Returns the 32-byte digest.

final Uint32List _sha256K = Uint32List.fromList(const [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
]);

int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xffffffff;

Uint8List _sha256(List<int> message) {
  var h0 = 0x6a09e667,
      h1 = 0xbb67ae85,
      h2 = 0x3c6ef372,
      h3 = 0xa54ff53a,
      h4 = 0x510e527f,
      h5 = 0x9b05688c,
      h6 = 0x1f83d9ab,
      h7 = 0x5be0cd19;

  // Pad: append 0x80, then zeros, then the 64-bit big-endian bit length.
  final bitLen = message.length * 8;
  final padded = <int>[...message, 0x80];
  while (padded.length % 64 != 56) {
    padded.add(0);
  }
  for (var i = 7; i >= 0; i--) {
    padded.add((bitLen >> (i * 8)) & 0xff);
  }

  final w = Uint32List(64);
  for (var chunk = 0; chunk < padded.length; chunk += 64) {
    for (var i = 0; i < 16; i++) {
      final j = chunk + i * 4;
      w[i] = (padded[j] << 24) |
          (padded[j + 1] << 16) |
          (padded[j + 2] << 8) |
          padded[j + 3];
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr(w[i - 15], 7) ^ _rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final s1 = _rotr(w[i - 2], 17) ^ _rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
    }

    var a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ (~e & g);
      final temp1 = (h + s1 + ch + _sha256K[i] + w[i]) & 0xffffffff;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (s0 + maj) & 0xffffffff;
      h = g;
      g = f;
      f = e;
      e = (d + temp1) & 0xffffffff;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & 0xffffffff;
    }

    h0 = (h0 + a) & 0xffffffff;
    h1 = (h1 + b) & 0xffffffff;
    h2 = (h2 + c) & 0xffffffff;
    h3 = (h3 + d) & 0xffffffff;
    h4 = (h4 + e) & 0xffffffff;
    h5 = (h5 + f) & 0xffffffff;
    h6 = (h6 + g) & 0xffffffff;
    h7 = (h7 + h) & 0xffffffff;
  }

  final out = Uint8List(32);
  final hs = [h0, h1, h2, h3, h4, h5, h6, h7];
  for (var i = 0; i < 8; i++) {
    out[i * 4] = (hs[i] >> 24) & 0xff;
    out[i * 4 + 1] = (hs[i] >> 16) & 0xff;
    out[i * 4 + 2] = (hs[i] >> 8) & 0xff;
    out[i * 4 + 3] = hs[i] & 0xff;
  }
  return out;
}
