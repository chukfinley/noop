import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/whoop5_raw_imu.dart';

/// Pins [Whoop5RawImu.decode] — the WHOOP 5/MG raw 6-axis IMU offload buffer (upstream #423), the
/// Dart twin of the Kotlin `Whoop5RawImuTest` / Swift `Whoop5RawImuTests`.
///
/// Two kinds of pin, and the difference matters:
///   * a SYNTHETIC frame checks the exact columnar offsets + scales (upstream's vector, byte-for-byte);
///   * a REAL captured buffer (fw 50.40.1.0, the same fixture as the Kotlin twin — the Swift lane has
///     no real-frame test) checks the decode against hardware.
///
/// The real frame proves the ACCEL decode outright: gravity is an absolute 1 g reference, so all 100
/// samples landing in a ~1.006 g shell could not happen at a wrong offset or a wrong scale. It proves
/// NOTHING about the gyro SCALE — the capture is at rest, where every candidate full-scale range is
/// consistent. [gyroScaleIsNotPinnedByARestingFrame] pins that honest boundary as a test, so the
/// inference documented in the decoder's header cannot quietly become fact later.
void main() {
  /// Build a minimal valid frame: counts = 100, and one known accel + gyro sample at index [i].
  /// Mirrors upstream's `syntheticFrame`.
  Uint8List syntheticFrame({required int i, required int axLsb, required int gxLsb}) {
    final f = Uint8List(Whoop5RawImu.bufferLength);
    void putU16(int o, int v) {
      f[o] = v & 0xFF;
      f[o + 1] = (v >> 8) & 0xFF;
    }

    void putI16(int o, int v) => putU16(o, v < 0 ? v + 65536 : v);

    f[8] = 0x2F;
    putU16(24, 100); // countA
    putU16(630, 100); // countB
    putU16(15, 100); // baseTs = 100 (f[17..18] stay 0 -> u32 = 100)
    putI16(28 + 2 * i, axLsb); // ax[i]
    putI16(640 + 2 * i, gxLsb); // gx[i]
    return f;
  }

  test('decodes a known sample with the correct columnar offsets and scales', () {
    // ax = 4096 LSB -> 1.0 g; gx = 328 LSB -> 328 * 2000/32768 = 20.02 dps.
    final frame =
        Whoop5RawImu.decode(syntheticFrame(i: 3, axLsb: 4096, gxLsb: 328));
    expect(frame, isNotNull);
    expect(frame!.samples.length, 100);
    expect(frame.sampleRateHz, 100);
    expect(frame.samples[3].ax, closeTo(1.0, 1e-9));
    expect(frame.samples[3].ay, closeTo(0.0, 1e-9));
    expect(frame.samples[3].gx, closeTo(328.0 * 2000.0 / 32768.0, 1e-6));
    expect(frame.samples[0].ax, closeTo(0.0, 1e-9)); // other indices untouched
  });

  test('rejects a wrong length or wrong in-packet counts', () {
    expect(Whoop5RawImu.decode(Uint8List(500)), isNull); // too short
    final f = syntheticFrame(i: 0, axLsb: 0, gxLsb: 0);
    f[24] = 0;
    f[25] = 0; // countA != 100
    expect(Whoop5RawImu.decode(f), isNull);
  });

  group('real captured WHOOP 5.0 buffer (fw 50.40.1.0)', () {
    late Uint8List frameBytes;

    setUp(() => frameBytes = _hexToBytes(_realFrameHex));

    test('decodes the envelope tags and the strap timestamp', () {
      expect(frameBytes.length, Whoop5RawImu.bufferLength);
      expect(Whoop5RawImu.looksLikeImuBuffer(frameBytes), isTrue,
          reason: 'type-47 layout v21 at the puffin envelope offsets');
      final frame = Whoop5RawImu.decode(frameBytes);
      expect(frame, isNotNull, reason: 'real buffer did not decode');
      expect(frame!.samples.length, 100);
      expect(frame.baseTs, 1784037165); // strap ts @15
    });

    test('the accel block decodes as a ~1 g gravity shell', () {
      // The defining accel signature, and the whole proof of the accel offsets + 1/4096 scale:
      // gravity is an absolute physical reference, so a wrong offset or scale cannot land here.
      final frame = Whoop5RawImu.decode(frameBytes)!;
      final mags = frame.samples
          .map((s) => math.sqrt(s.ax * s.ax + s.ay * s.ay + s.az * s.az))
          .toList()
        ..sort();
      final median = mags[mags.length ~/ 2];
      expect(median, closeTo(1.0, 0.15), reason: 'median |accel| should be ~1 g');
      final inShell =
          mags.where((m) => m > 0.7 * median && m < 1.3 * median).length;
      expect(inShell, greaterThanOrEqualTo(95),
          reason: '>=95/100 accel samples should sit in the gravity shell');
    });

    test('the gyro block reads near zero on a resting capture', () {
      final frame = Whoop5RawImu.decode(frameBytes)!;
      final mean = frame.samples
              .map((s) => math.sqrt(s.gx * s.gx + s.gy * s.gy + s.gz * s.gz))
              .reduce((a, b) => a + b) /
          100.0;
      // Far below the +/-2000 dps full scale. This establishes the block IS rotational data at rest;
      // see the next test for what it deliberately does NOT establish.
      expect(mean, lessThan(200.0));
    });

    test('gyro scale is NOT pinned by a resting frame — documented as inference, pinned as a test',
        () {
      // The decoder's header calls gyroScale an INFERENCE. This is why, mechanically: at rest the
      // gyro block reads ~13.9 LSB mean magnitude, so EVERY candidate full-scale range satisfies the
      // "near zero" assertion above. Upstream's own test asserts only `mean < 200 dps`, which all of
      // them pass — so that assertion cannot distinguish them and must not be read as calibration.
      // Pinning the scale needs a capture under a KNOWN rotation. If someone later promotes the
      // constant to fact, they must confront this test.
      final frame = Whoop5RawImu.decode(frameBytes)!;
      final meanLsb = frame.samples
              .map((s) => math.sqrt(
                  math.pow(s.gx / Whoop5RawImu.gyroScale, 2) +
                      math.pow(s.gy / Whoop5RawImu.gyroScale, 2) +
                      math.pow(s.gz / Whoop5RawImu.gyroScale, 2)))
              .reduce((a, b) => a + b) /
          100.0;
      expect(meanLsb, closeTo(13.9, 0.5), reason: 'raw LSB magnitude at rest');

      for (final fullScaleDps in <double>[250, 500, 1000, 2000]) {
        final meanDps = meanLsb * (fullScaleDps / 32768.0);
        expect(meanDps, lessThan(200.0),
            reason: 'a +/-$fullScaleDps dps scale is EQUALLY consistent with this '
                'resting frame — which is exactly why the scale is unproven');
      }
    });
  });
}

Uint8List _hexToBytes(String hex) => Uint8List.fromList(<int>[
      for (var i = 0; i + 2 <= hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16)
    ]);

/// One real 1244-byte type-0x2F layout-v21 IMU buffer captured off a WHOOP 5.0 (fw 50.40.1.0),
/// upstream #423 — the identical fixture the Kotlin `Whoop5RawImuTest` uses, so the decode is
/// cross-platform ground truth rather than a Dart-local assumption.
const String _realFrameHex =
    'aa01d40401005c702f1580e520af002d3f566a002004640064000300d308cc08c408c908c208cd08b708c208cc08c908'
    'cc08e108d608e408d208c508bd08d708c508d208cc08c908bc08b508a908c008cc08cb08d308e108dc08d408d108c108'
    'c208c208b708ce08c608e008c308d208bd08c908bb08b708be08c208cc08ce08c608cf08c408c808ca08cb08cf08cb08'
    'd508c708c908cc08bf08c308c408cc08cc08cc08c508c708d108c108c608c808c108c408c308c608cf08c808c608cf08'
    'ce08c808d008c008d008c608bb08cb08d208c008cb08c708c008c508c208c608cf08d008d3ffcaffc1ffc8ffcaffc5ff'
    'ccffd4ffd3ffdeffddffd8ffdbffd6ffc7ffc7ffd0ffd5ffd6ffe2ffd4ffceffd6ffd2ffe2ffdbffdbffc7ffc6ffc9ff'
    'c1ffb1ffb7ffb7ffc9ffceffe4ffe7ffe4ffeaffe7ffdbffd7ffe0ffd7ffc4ffccffcdffbbffc2ffbeffb9ffccffd4ff'
    'd4ffc6ffcaffd3ffc8ffd6ffceffd7ffdaffdfffddffdaffd6ffddffdaffd3ffe1ffd0ffc9ffcdffd1ffcaffd3ffcfff'
    'd3ffd6ffcfffcaffc9ffc7ffcaffd7ffd5ffd0ffdaffd4ffddffd6ffd8ffdcffd8ffd4ffcaffe5ffceffccff690d840d'
    '810d760d7f0d7a0d730d7a0d800d8a0d820d8c0d800d750d740d740d620d690d800d7a0d7d0d6e0d710d780d790d890d'
    '770d810d7d0d760d7d0d7b0d7a0d890d810d830d7a0d6d0d6c0d6f0d690d6d0d790d6d0d730d760d770d850d790d810d'
    '760d7d0d750d720d760d740d720d820d750d890d840d830d7d0d7b0d770d7b0d820d6f0d830d6f0d770d6e0d7b0d820d'
    '700d760d7f0d6a0d780d790d7c0d830d780d7a0d840d780d6f0d7f0d740d800d7b0d860d7f0d7a0d840d7d0d820d770d'
    '810d7c0d6400640005020000000000000900090004000500060007000a000c000b000d000e000c000d000d000c000b00'
    '090008000c000d000d0011000e000c000c000b000b000e000f00130011001100100010000e000e000e000e000c000b00'
    '0c000c000b000e000d0010000e000e000d000d000c000b000c000a000b000c000c000e000b000b000c000c000d000a00'
    '0b000b000a000b000c000c000c000d000e000f000b000d000b000b000e000d000c000c000b000b000c000c000c000b00'
    '0b000a000a000b000b000d000f000d000d000b000b000a00fcfffbfffbfffdfff9fffbfffcfffdfffdfffdfffcfffcff'
    'fffffcfffcfffdfffffffdfffcffffff01000000fefffdfffdfffefffeffffff0000ffff0200feffffffffff00000000'
    '0100fefffffffdfffdfffefffdfffefffbfffdffffff0100fefffefffdfffdfffdfffefffdfffffffefffeff0000feff'
    'fdfffffffefffdff0000fefffefffefffdfffefffefffefffefffffffffffffffffffdff00000000fefffdfffffffeff'
    'fdfffefffdfffdfffffffffffdfffefffffffcfffdfffefffdfffdfffefffdfffbfff9fff9fff8fffcfff9fff8fff9ff'
    'f7fff7fffafffcfffbfffdfffbfffafffcfffcfffbfff9fff8fffcfff9fff8fffbfff9fff9fffcfffcfffcfffffffbff'
    'fcfffafff8fff7fff8fff7fff6fff9fff9fffafffcfffbfffdfffdfffcfffcfffcfffcfffbfffbfffafff9fffcfffaff'
    'f7fffafffbfff9fffbfffafff8fff7fff8fffafff8fff8fffafffafffafffbfffcfffcfffafffafffbfffcfffafffaff'
    'f9fffafffafff9fff8fff8fff9fff9fffbfff8fffafffafffafffbfffbfff9fffafffafffafff9ff7ae96eb8';
