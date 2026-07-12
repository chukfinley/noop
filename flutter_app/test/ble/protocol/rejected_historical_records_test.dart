import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/crc.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';

/// Faithful Dart port of `RejectedHistoricalRecordsTest.kt`.
///
/// [rejectedHistoricalRecords] — the genuinely-undecodable type-47 record frames the Backfiller must
/// archive BEFORE acking the trim (#77 / #91). A CONSOLE (type-50) frame decodes to zero rows BY DESIGN
/// and must NOT be flagged, while a real record frame that fails to decode MUST be flagged.
void main() {
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

  void repairCrc32(Uint8List frame) {
    final length = (frame[1] & 0xFF) | ((frame[2] & 0xFF) << 8);
    final crc = Crc.crc32(frame, from: 4, to: length);
    frame[length] = crc & 0xFF;
    frame[length + 1] = (crc >> 8) & 0xFF;
    frame[length + 2] = (crc >> 16) & 0xFF;
    frame[length + 3] = (crc >> 24) & 0xFF;
  }

  test('goodRecordIsNotRejected', () {
    final good = bytes(realV24Hex);
    expect(rejectedHistoricalRecords([good], DeviceFamily.whoop4), <Uint8List>[]);
  });

  test('consoleTypeFrameIsExcluded', () {
    final console = bytes(realV24Hex);
    console[4] = 0x32; // packet type byte → CONSOLE_LOGS (50)
    repairCrc32(console); // keep the envelope valid so only the type guard excludes it
    expect(rejectedHistoricalRecords([console], DeviceFamily.whoop4), <Uint8List>[],
        reason: 'type-50 console frame must not be counted as a lost record');
  });

  test('crcFailedRecordIsRejected', () {
    final bad = bytes(realV24Hex);
    bad[21] = bad[21] ^ 0xFF; // flip HR byte, leave the CRC trailer stale → CRC mismatch
    final rejected = rejectedHistoricalRecords([bad], DeviceFamily.whoop4);
    expect(rejected.length, 1);
    expect(_bytesEqual(rejected[0], bad), isTrue);
  });

  test('unmappedNonPhysicalRecordIsRejected', () {
    final bad = bytes(realV24Hex);
    bad[5] = 99; // unmapped version
    for (var i = 40; i < 52; i++) {
      bad[i] = 0; // zero gravity x/y/z → |g| = 0, fails the gate
    }
    repairCrc32(bad);
    final rejected = rejectedHistoricalRecords([bad], DeviceFamily.whoop4);
    expect(rejected.length, 1);
    expect(_bytesEqual(rejected[0], bad), isTrue);
  });

  test('mixedChunkFlagsOnlyTheUndecodableRecord', () {
    final good = bytes(realV24Hex);
    final console = bytes(realV24Hex)..[4] = 0x32;
    repairCrc32(console);
    final bad = bytes(realV24Hex);
    bad[21] = bad[21] ^ 0xFF; // CRC now stale → fails
    final rejected = rejectedHistoricalRecords([good, console, bad], DeviceFamily.whoop4);
    expect(rejected.length, 1);
    expect(_bytesEqual(rejected[0], bad), isTrue);
  });
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
