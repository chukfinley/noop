import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/whoop5_config.dart';

/// Faithful Dart port of `Whoop5ConfigTest.kt`.
///
/// Byte-parity tests for the WHOOP 5/MG R22 deep-data enable sequence. The golden frame is shared
/// verbatim with the macOS/iOS `Whoop5ConfigTests` and is the exact output of judes.club's documented
/// frame-builder for `enable_r22_packets` at seq=1 — so a mismatch here means Android and Apple would
/// write different bytes to the strap. (#174)
void main() {
  String hex(Uint8List bytes) =>
      bytes.map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0')).join();

  test('enableR22PacketsGoldenFrame', () {
    final frame = Whoop5Config.frame(Whoop5Config.enableR22Sequence[0], 1);
    // Identical to the macOS/iOS golden frame: header aa 01 30 00 00 01, CRC16 eb11, inner
    // [0x23,0x01,0x78,0x01] + "enable_r22_packets" NUL-padded to 32 + value '2' (0x32) + 7 zeros,
    // then CRC32 d2eeb0b7.
    const expected =
        'aa0130000001eb1123017801656e61626c655f7232325f7061636b65747300000000000000000000000000003200000000000000d2eeb0b7';
    expect(hex(frame), expected);
  });

  test('sequenceIsFifteenFlagsWithExpectedValues', () {
    final seq = Whoop5Config.enableR22Sequence;
    expect(seq.length, 15);
    expect(seq[0].name, 'enable_r22_packets');
    expect(seq[0].value, 0x32);
    // v4 and the passive-strap-fit flag are the only '1' (0x31) values in the documented set.
    expect(seq.firstWhere((f) => f.name == 'enable_r22_v4_packets').value, 0x31);
    expect(
        seq.firstWhere((f) => f.name == 'enable_passive_strap_fit_gen5').value,
        0x31);
  });

  test('payloadBodyIsAsciiNameNulPaddedWithValueAt32', () {
    final body = Whoop5Config.payloadBody('enable_r22_packets', 0x32);
    expect(body.length, 40);
    expect(String.fromCharCodes(body.sublist(0, 18)), 'enable_r22_packets');
    for (var i = 18; i < 32; i++) {
      expect(body[i], 0);
    }
    expect(body[32] & 0xFF, 0x32);
    for (var i = 33; i < 40; i++) {
      expect(body[i], 0);
    }
  });
}
