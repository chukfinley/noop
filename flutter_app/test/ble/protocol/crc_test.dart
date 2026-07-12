import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/crc.dart';
import 'package:noop/core/ble/protocol/device_family.dart';

/// Faithful Dart port of `CrcTest.kt`.
///
/// Concrete-vector tests for the three frame checksums. The "123456789" check values are the
/// canonical reference constants for each algorithm:
///  - CRC-8 (poly 0x07) check  = 0xF4
///  - CRC-32 (zlib)     check  = 0xCBF43926
///  - CRC16-Modbus      check  = 0x4B37
void main() {
  final check = Uint8List.fromList(ascii.encode('123456789'));

  test('crc8_referenceCheckValue', () {
    expect(Crc.crc8(check), 0xF4);
  });

  test('crc8_emptyIsZero', () {
    expect(Crc.crc8(Uint8List(0)), 0x00);
  });

  test('crc8_resultIsByteWide', () {
    // A length header of 0x0008 must yield the same crc8 the device verifies.
    expect(Crc.crc8(Uint8List.fromList(<int>[0x08, 0x00])), 0xA8);
  });

  test('crc32_referenceCheckValue', () {
    expect(Crc.crc32(check), 0xCBF43926);
  });

  test('crc32_emptyIsZero', () {
    expect(Crc.crc32(Uint8List(0)), 0x00000000);
  });

  test('crc32_isUnsignedThirtyTwoBit', () {
    // Result must always be in 0..0xFFFFFFFF (never negative / sign-extended).
    final v = Crc.crc32(Uint8List.fromList(<int>[0xFF, 0xFF, 0xFF, 0xFF]));
    expect(v >= 0 && v <= 0xFFFFFFFF, isTrue, reason: 'crc32 out of range: $v');
  });

  test('crc16Modbus_referenceCheckValue', () {
    expect(Crc.crc16Modbus(check), 0x4B37);
  });

  test('crc16Modbus_whoop5HelloHeader', () {
    // CRC16-Modbus over the first 6 bytes of the Whoop 5.0 hello must equal the LE value
    // stored at bytes [6..7] of that hello (0xE6, 0x71 -> 0x71E6).
    final hello = DeviceFamily.whoop5ClientHello;
    final want = (hello[6] & 0xFF) | ((hello[7] & 0xFF) << 8);
    expect(Crc.crc16Modbus(Uint8List.sublistView(hello, 0, 6)), want);
    expect(want, 0x71E6);
  });
}
