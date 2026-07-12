import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';

/// Faithful Dart port of `Whoop4HistoricalV25Test.kt`.
///
/// WHOOP 4.0 **v25** historical layout (issue #30) — three REAL v25 records (faklei, App 1.92,
/// 2026-06-11), 84 bytes each. Layout RE'd from 45 such records: `unix` @11 (u32 LE) and the DSP
/// gravity vector @73/75/77 as 3×i16 LE / 16384 (|gravity| ≈ 1 g).
void main() {
  Uint8List bytes(String s) {
    final out = Uint8List(s.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  final records = <Uint8List>[
    bytes(
        'aa50000c2f1900006800007dff2a6a20430900433103007e026502ba026c022eff70f996f879fad6fd8300d6017e0267027201be00290258030e05c507f00c030ead11cb15791500d2553c9003000000d6393716'),
    bytes(
        'aa50000c2f1900016800007eff2a6a283e0900a0ad03007a0e880698018bfff5fb61eee9f2a7fa2bfe1af5fdf618fdf0f9c2fb0804510a14046a004dffd0ff6dfdddfd670183014e071a3f9003000000587bbabf'),
    bytes(
        'aa50000c2f1900026800007fff2a6a38390900729103003608a2fd0104850d4f1bd21aa60f080d850edb116b0f160b7d063f06ab04d5041704a4045f04f003f5ffd7ff7efe73ffa8b2333e9003010000fa54e5e9'),
  ];

  test('v25DecodesUnixAndGravity', () {
    for (final rec in records) {
      final p = decodeHistorical(rec, DeviceFamily.whoop4);
      expect(p, isNotNull, reason: 'v25 record must decode (not rejected)');
      expect(p!['hist_version'], 25);
      final unix = p['unix'] as int?;
      expect(unix, isNotNull);
      expect(unix! > 1781000000, isTrue);
      final gx = p['gravity_x'] as double?;
      expect(gx, isNotNull, reason: 'v25 must decode gravity (the sleep-staging input)');
      final gy = (p['gravity_y'] as double?) ?? 0.0;
      final gz = (p['gravity_z'] as double?) ?? 0.0;
      final mag = sqrt(gx! * gx + gy * gy + gz * gz);
      expect(mag >= 0.8 && mag <= 1.2, isTrue, reason: '|gravity| ~1 g, got $mag');
    }
    // unix increments 1 Hz across the three.
    final ts = records
        .map((r) => decodeHistorical(r, DeviceFamily.whoop4)!['unix'] as int)
        .toList();
    expect(ts, <int>[ts[0], ts[0] + 1, ts[0] + 2]);
  });

  test('v25NotRejected', () {
    expect(rejectedHistoricalRecords(records, DeviceFamily.whoop4).isEmpty, isTrue,
        reason: 'v25 records carry gravity and must not be treated as undecodable');
  });

  test('v25ProducesGravityStream', () {
    final ref = decodeHistorical(records[0], DeviceFamily.whoop4)!['unix'] as int;
    final streams = extractHistoricalStreams(records, ref, ref);
    expect(streams.gravity.length, records.length);
  });
}
