import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/crc.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';

/// Faithful Dart port of `HistoricalFallbackTest.kt`.
///
/// The unmapped-firmware-version fallback for WHOOP 4.0 type-47 records (#30/#77). An unmapped version
/// now falls back to the canonical v24 layout, accepted ONLY when it decodes to physically-real data
/// (|gravity| ≈ 1 g + plausible HR), so it can never store garbage.
void main() {
  // Real on-wrist WHOOP 4.0 v24 record (HR 109, two R-R, gravity ~1 g). version byte frame[5] = 0x18.
  const realV24Hex =
      'aa6400a12f18054c1c0a023ed0266a5037805418016d022b0234020000000000006b07ff00'
      '85593c1f65cebed7b3e63eb85a5f3f000080401f65cebed7b3e63eb85a5f3f500264025d03'
      '640229014009010c020c00000000000f0001c4020000000000008fdeb278';

  Uint8List bytes(String s) {
    final out = Uint8List(s.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  /// Recompute the body CRC32 (over inner bytes frame[4 until length]) and write it LE into the
  /// trailer at frame[length..length+4], so a frame mutated in the test still validates.
  void repairCrc32(Uint8List frame) {
    final length = (frame[1] & 0xFF) | ((frame[2] & 0xFF) << 8);
    final crc = Crc.crc32(frame, from: 4, to: length);
    frame[length] = crc & 0xFF;
    frame[length + 1] = (crc >> 8) & 0xFF;
    frame[length + 2] = (crc >> 16) & 0xFF;
    frame[length + 3] = (crc >> 24) & 0xFF;
  }

  test('mappedV24RecordStillDecodes', () {
    final p = decodeHistorical(bytes(realV24Hex), DeviceFamily.whoop4);
    expect(p, isNotNull);
    expect(p!['hist_version'], 24);
    expect(p['heart_rate'], 109);
  });

  test('unmappedVersionFallsBackToV24WhenPhysicallyReal', () {
    final frame = bytes(realV24Hex);
    frame[5] = 99; // unmapped version (not in {5,7,9,12,24})
    repairCrc32(frame);
    final p = decodeHistorical(frame, DeviceFamily.whoop4);
    expect(p, isNotNull,
        reason: 'unmapped-but-v24-compatible record must decode via fallback, not drop');
    expect(p!['hist_version'], 99);
    expect(p['heart_rate'], 109);
    expect((p['rr_intervals'] as List).length, 2,
        reason: 'R-R intervals must survive the fallback');
  });

  test('unmappedVersionWithNonPhysicalDataIsStillDropped', () {
    final frame = bytes(realV24Hex);
    frame[5] = 99;
    for (var i = 40; i < 52; i++) {
      frame[i] = 0; // zero gravity x/y/z (offsets 40/44/48) → |g| = 0
    }
    repairCrc32(frame);
    expect(decodeHistorical(frame, DeviceFamily.whoop4), isNull);
  });
}
