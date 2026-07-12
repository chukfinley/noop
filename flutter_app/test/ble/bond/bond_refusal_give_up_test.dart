import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/bond/bond_refusal_give_up.dart';

/// Port of `BondRefusalGiveUpTest.kt` (#747 / #750). A strap that keeps REFUSING the encrypted bond
/// eventually trips a give-up that (a) pauses auto-reconnect so NOOP stops hammering it and (b) writes
/// a one-line epitaph carrying only an opaque, HASHED id (no MAC, no serial). Pure value type, no BLE
/// seam.
void main() {
  test('gives up after threshold refusals', () {
    final g = BondRefusalGiveUp(); // default giveUpThreshold = 5
    for (var i = 1; i <= 4; i++) {
      expect(g.recordRefusal(), isFalse, reason: 'refusal $i is below the give-up threshold');
      expect(g.gaveUp, isFalse);
    }
    expect(g.recordRefusal(), isTrue); // the 5th refusal freshly trips the give-up
    expect(g.gaveUp, isTrue);
    expect(g.refusals, 5);
    // Already gave up → no second "freshly tripped" signal (caller pauses + writes the epitaph once).
    expect(g.recordRefusal(), isFalse);
    expect(g.gaveUp, isTrue);
  });

  test('reset re-arms', () {
    final g = BondRefusalGiveUp();
    for (var i = 0; i < 5; i++) {
      g.recordRefusal();
    }
    expect(g.gaveUp, isTrue);
    g.reset();
    expect(g.gaveUp, isFalse);
    expect(g.refusals, 0);
    for (var i = 1; i <= 4; i++) {
      expect(g.recordRefusal(), isFalse);
    }
    expect(g.recordRefusal(), isTrue);
  });

  test('custom threshold trips sooner', () {
    final g = BondRefusalGiveUp(giveUpThreshold: 2);
    expect(g.recordRefusal(), isFalse);
    expect(g.recordRefusal(), isTrue);
    expect(g.gaveUp, isTrue);
  });

  test('epitaph line has no PII', () {
    final line = BondRefusalGiveUp.epitaphLine(5, 'a1b2c3d4');
    expect(line.contains('refused the encrypted bond 5x'), isTrue);
    expect(line.contains('a1b2c3d4'), isTrue);
    // No raw MAC (colon-separated hex octets) and no em-dash.
    expect(RegExp(r'[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:').hasMatch(line), isFalse);
    expect(line.contains('—'), isFalse);
  });

  test('opaque id hashes the MAC deterministically', () {
    const mac = 'A1:B2:C3:D4:E5:F6';
    final id = BondRefusalGiveUp.opaqueId(mac);
    // 8 hex chars, lower-case, and it does NOT contain the raw MAC bytes.
    expect(id.length, 8);
    expect(RegExp(r'^[0-9a-f]{8}$').hasMatch(id), isTrue);
    expect(id.contains('a1b2'), isFalse);
    // Deterministic: the same MAC always hashes to the same token.
    expect(BondRefusalGiveUp.opaqueId(mac), id);
    // Distinct MACs give distinct tokens (so a log can tell two straps apart).
    expect(id == BondRefusalGiveUp.opaqueId('11:22:33:44:55:66'), isFalse);
  });

  test('opaque id uses real SHA-256 (known vector)', () {
    // sha256("abc") = ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad → first 4 bytes.
    expect(BondRefusalGiveUp.opaqueId('abc'), 'ba7816bf');
  });

  test('paused hint wording', () {
    final hint = BondRefusalGiveUp.pausedHint();
    expect(hint.contains('stopped retrying'), isTrue);
    expect(hint.contains('Forget This Device'), isTrue);
    expect(hint.contains('—'), isFalse);
  });
}
