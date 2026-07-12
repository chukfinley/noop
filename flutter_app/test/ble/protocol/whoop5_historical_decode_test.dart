import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/crc.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';

/// Faithful Dart port of `Whoop5HistoricalDecodeTest.kt`.
///
/// WHOOP 5.0/MG type-47 "v18" historical decode, against the SAME real captured frames the macOS/Kotlin
/// suites use — so every platform decodes byte-for-byte identical data. Offsets are WHOOP5-absolute
/// (record @8), NOT the WHOOP4 V24 layout. Each per-second biometric field is gated to a physical range;
/// this test pins the real decoded values.
void main() {
  Uint8List bytes(String s) {
    final out = Uint8List(s.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  // Real worn WHOOP 5 v18 frame: hr=102, rr=[602,613] ms, |gravity|≈1, skin temp 30.57 °C.
  const wornV18 =
      'aa01740001003fb12f1280733d8401b69f266a66460066025a0265020000000000007b0a8d656463ff0012163cf6a439bf2924fd3ed763fe3e3200aa000000000000000000f7000901f10b0007010c020c00000000000000000000000000000000000000000000000100656f1e1e0000009d61a7c00000003e862817';

  // Real off-wrist v18 frame (hr=0): same thermistor reads ambient (~22.5 °C), not skin.
  const offWristV18 =
      'aa01740001003fb12f12803a3d84018889266a3d0a00000000000000000000000000000000000000000064c33b52b47d3fe1ba1dbda470ecbd000064000000000000000000e500e200c708000c010c020c0000000000000000000000000000000000000000000000010000008080000000000000000000009ffafe6c';

  // Real Android WHOOP 5.0 v18 frame from an ACK-enabled hardware offload. (#78 fork)
  const androidAckCaptureV18 =
      'aa01740001003fb12f1280aaae6f01bea0286ae11a004200000000000000000000b0000084414b38dc80b96c3c717d243dd7638f3ee182773ff6007e00000000000000000026013601a60c5004010c020c00000000000000000000000000000000000000000000010100a27c2521000000bff73ec00000002ce4150a';

  // A SECOND device (Galaxy S24 Ultra capture, 2026-06-11), HR cross-checked against live REALTIME_DATA.
  const secondDeviceHR57 =
      'aa01740001003fb12f128093c47c006dbc296a00600039000000000000000000006137020b610000e1e04c063d8fce36bf7b08233f8fea993e38a50000000000000000000019012101920b5002010c020c0100000000000000000000000000000000000000000005010085808080000000a5538ec000000016d0680d';
  const secondDeviceHR63 =
      'aa01740001003fb12f128034d67c000ece296a0a77003f01fc0300000000000000203a0302e30000ff00f8093c1f8534bcc3a5473f4819243f85a6000000000000000000001b012601e80b5003010c020c00000000000000000000000000000000000000000000050100ced7241c0000006ead8cc00000008775b70c';

  /// Mutate one absolute frame byte and re-stamp the CRC32 (over frame[8..len-4]) so it passes the gate.
  Uint8List mutateAndReCrc(int index, int value) {
    final f = bytes(wornV18);
    f[index] = value & 0xFF;
    final end = f.length - 4;
    final crc = Crc.crc32(f, from: 8, to: end);
    f[end] = crc & 0xFF;
    f[end + 1] = (crc >> 8) & 0xFF;
    f[end + 2] = (crc >> 16) & 0xFF;
    f[end + 3] = (crc >> 24) & 0xFF;
    return f;
  }

  double sqrtd(double v) => sqrt(v);

  test('decodesWhoop5V18CoreAndBiometrics', () {
    final p = decodeHistorical(bytes(wornV18), DeviceFamily.whoop5);
    expect(p, isNotNull);
    expect(p!['hist_version'], 18);
    expect(p['unix'], 1780916150);
    expect(p['heart_rate'], 102);
    expect(p['rr_count'], 2);
    expect(p['rr_intervals'], <int>[602, 613]);

    final gx = p['gravity_x'] as double;
    final gy = p['gravity_y'] as double;
    final gz = p['gravity_z'] as double;
    expect((sqrtd(gx * gx + gy * gy + gz * gz) - 1.0).abs() <= 0.05, isTrue);

    // Per-second biometric fields (verified vs the real frame).
    expect(p['skin_temp_raw'], 3057); // 30.57 °C
    expect(p['step_motion_counter'], 50);
    expect(p['motion_wear_quality'], 0);
    expect(p['activity_class'], 0);
    expect((p['dynamic_acceleration'] as double) >= 0.0 &&
        (p['dynamic_acceleration'] as double) <= 8.0, isTrue);
  });

  test('decodesV18ActivityClassEnum', () {
    expect(decodeHistorical(mutateAndReCrc(63, 0), DeviceFamily.whoop5)!['activity_class'], 0);
    expect(decodeHistorical(mutateAndReCrc(63, 1), DeviceFamily.whoop5)!['activity_class'], 1);
    expect(decodeHistorical(mutateAndReCrc(63, 2), DeviceFamily.whoop5)!['activity_class'], 2);
    expect(decodeHistorical(mutateAndReCrc(63, 0xFF), DeviceFamily.whoop5)!['activity_class'], isNull);
    expect(decodeHistorical(mutateAndReCrc(63, 7), DeviceFamily.whoop5)!['activity_class'], isNull);
  });

  test('stepCounterIsFullU16NotLowByte', () {
    expect(decodeHistorical(mutateAndReCrc(58, 0x01), DeviceFamily.whoop5)!['step_motion_counter'],
        0x0132);
  });

  test('decodesV18ObservedFields', () {
    final p = decodeHistorical(bytes(wornV18), DeviceFamily.whoop5)!;
    expect(p['record_index'], 25443699);
    expect(p['hr_fixed_8_8'], 25997);
    expect((p['hr_fixed_8_8'] as int) ~/ 256, 101);
    expect(p['step_cadence'], 170);
    expect(p['status_word'], 1792);
    expect(p['sleep_state'], 0);
    expect(p['rr_packed'], 25444);
    expect(p['cardiac_flags'], 0);
    expect(p['cardiac_status'], 255);
    expect(((p['unknown_f32_113'] as double) - -5.2307).abs() <= 0.001, isTrue);

    expect(p['temp_aux_1_raw'], 247);
    expect(p['temp_aux_2_raw'], 265);
    expect(p['skin_temp_raw'], 3057);
    expect(p['status_word_1'], 3073);
    expect(p['status_word_2'], 3074);
    expect(p['wake_quality'], 0);
    expect(p['onwrist'], 0);
    expect(p['aux_byte_82'], 0);
  });

  test('decodesV18AuxFieldsAcrossDevices', () {
    final ack = decodeHistorical(bytes(androidAckCaptureV18), DeviceFamily.whoop5)!;
    expect(ack['temp_aux_1_raw'], 294);
    expect(ack['temp_aux_2_raw'], 310);
    expect(ack['status_word_1'], 3073);
    expect(ack['status_word_2'], 3074);
    expect(ack['skin_temp_raw'], 3238);

    final dev57 = decodeHistorical(bytes(secondDeviceHR57), DeviceFamily.whoop5)!;
    expect(dev57['onwrist'], 1);
    expect(dev57['wake_quality'], 0);
    expect(dev57['sleep_state'], 0);
    expect(dev57['skin_temp_raw'], 2962);
  });

  test('band81NibblesSplitIndependently', () {
    final cases = <List<int>>[
      // [raw, sleep, wakeQ, onwrist]
      [0x00, 0, 0, 0],
      [0x39, 3, 2, 1],
      [0x16, 1, 1, 2],
      [0x2B, 2, 2, 3],
    ];
    for (final e in cases) {
      final f = bytes(wornV18);
      f[81] = e[0];
      final end = f.length - 4;
      final crc = Crc.crc32(f, from: 8, to: end);
      f[end] = crc & 0xFF;
      f[end + 1] = (crc >> 8) & 0xFF;
      f[end + 2] = (crc >> 16) & 0xFF;
      f[end + 3] = (crc >> 24) & 0xFF;
      final p = decodeHistorical(f, DeviceFamily.whoop5)!;
      expect(p['sleep_state'], e[1]);
      expect(p['wake_quality'], e[2]);
      expect(p['onwrist'], e[3]);
    }
  });

  test('sleepStateReadsHighNibbleOnly', () {
    final cases = <List<int>>[
      [0x00, 0],
      [0x10, 1],
      [0x20, 2],
      [0x30, 3],
      [0x25, 2],
    ];
    for (final e in cases) {
      final f = bytes(wornV18);
      f[81] = e[0];
      final end = f.length - 4;
      final crc = Crc.crc32(f, from: 8, to: end);
      f[end] = crc & 0xFF;
      f[end + 1] = (crc >> 8) & 0xFF;
      f[end + 2] = (crc >> 16) & 0xFF;
      f[end + 3] = (crc >> 24) & 0xFF;
      expect(decodeHistorical(f, DeviceFamily.whoop5)!['sleep_state'], e[1]);
    }
  });

  test('sleepStateReachesStreamOnRealFixture', () {
    final st = extractHistoricalStreams(
        [bytes(wornV18)], 1780916150, 1780916150, DeviceFamily.whoop5);
    expect(st.sleepState, <SleepStateRow>[const SleepStateRow(1780916150, 0)]);
  });

  test('sleepStateStreamCarriesEachNibble', () {
    for (final e in <List<int>>[
      [0x10, 1],
      [0x20, 2],
      [0x30, 3],
    ]) {
      final frame = mutateAndReCrc(81, e[0]);
      final st = extractHistoricalStreams(
          [frame], 1780916150, 1780916150, DeviceFamily.whoop5);
      expect(st.sleepState, <SleepStateRow>[SleepStateRow(1780916150, e[1])]);
    }
  });

  test('skinTempTracksWristContact', () {
    final worn = decodeHistorical(bytes(wornV18), DeviceFamily.whoop5)!;
    final off = decodeHistorical(bytes(offWristV18), DeviceFamily.whoop5)!;
    expect(worn['skin_temp_raw'], 3057);
    expect(off['skin_temp_raw'], 2247);
  });

  test('whoop4FamilyDoesNotMisreadAWhoop5Frame', () {
    expect(decodeHistorical(bytes(wornV18), DeviceFamily.whoop4), isNull);
  });

  test('decodesAndroidAckCaptureV18', () {
    final p = decodeHistorical(bytes(androidAckCaptureV18), DeviceFamily.whoop5);
    expect(p, isNotNull);
    expect(p!['hist_version'], 18);
    expect(p['unix'], 1781047486);
    expect(p['heart_rate'], 66);
    expect(p['skin_temp_raw'], 3238);
    final gx = p['gravity_x'] as double;
    final gy = p['gravity_y'] as double;
    final gz = p['gravity_z'] as double;
    expect((sqrtd(gx * gx + gy * gy + gz * gz) - 1.0).abs() <= 0.05, isTrue);
  });

  test('decodesV18FromASecondDevice', () {
    final cases = <List<Object>>[
      [secondDeviceHR57, 57, 1781120109],
      [secondDeviceHR63, 63, 1781124622],
    ];
    for (final c in cases) {
      final p = decodeHistorical(bytes(c[0] as String), DeviceFamily.whoop5);
      expect(p, isNotNull);
      expect(p!['hist_version'], 18);
      expect(p['unix'], c[2]);
      expect(p['heart_rate'], c[1]);
      final gx = p['gravity_x'] as double;
      final gy = p['gravity_y'] as double;
      final gz = p['gravity_z'] as double;
      expect((sqrtd(gx * gx + gy * gy + gz * gz) - 1.0).abs() <= 0.2, isTrue);
    }
  });
}
