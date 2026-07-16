import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';
import 'package:noop/core/ble/protocol/whoop5_raw_imu.dart';

/// Guards the load-bearing consequence of leaving [Whoop5RawImu] UNWIRED from
/// [extractHistoricalStreams] (upstream #423).
///
/// A 5/MG raw-IMU buffer is type-47 **layout v21**. [decodeHistorical] maps v18 only, so v21 returns
/// null, so [rejectedHistoricalRecords] classifies the buffer as undecodable — and the Backfiller
/// durably archives its verbatim bytes into `rawSensorArchive` BEFORE acking the strap trim. That is
/// the ONLY reason it is safe to decode raw IMU without storing it: the bytes are already preserved.
///
/// This is a trap worth spelling out, because the obvious "finish the port" move breaks it. The moment
/// someone teaches the historical decoder to return non-null for v21 WITHOUT also persisting the
/// samples, these frames stop being rejected → stop being archived → and the strap frees its flash
/// copy on the next ack. The raw IMU would then be destroyed by the very change meant to decode it,
/// silently, with the UI still saying "History synced". So: decode v21 into the STREAMS path only in
/// the same change that stores it.
///
/// The v26 PPG buffer is the deliberate counter-example already in the tree — it IS decoded and IS
/// stored (`ppgRawSample`), and so is explicitly excluded from the rejected set by design.
void main() {
  final imuFrame = _hexToBytes(_realFrameHex);

  test('the real v21 IMU buffer is a genuine IMU buffer that the historical decoder does not map',
      () {
    expect(Whoop5RawImu.looksLikeImuBuffer(imuFrame), isTrue);
    expect(Whoop5RawImu.decode(imuFrame), isNotNull,
        reason: 'the standalone IMU decoder reads it');
    expect(decodeHistorical(imuFrame, DeviceFamily.whoop5), isNull,
        reason: 'the v18-only historical decoder must NOT claim it');
  });

  test('a v21 IMU buffer is still classified as rejected, so the Backfiller archives it', () {
    // If this ever fails, the raw IMU is no longer being preserved — check that whatever now decodes
    // v21 also PERSISTS it before relaxing this test.
    final rejected =
        rejectedHistoricalRecords(<Uint8List>[imuFrame], DeviceFamily.whoop5);
    expect(rejected, hasLength(1),
        reason: 'the archive is the only durable copy once the trim is acked');
    expect(rejected.single, imuFrame);
  });

  test('decoding a v21 buffer yields no stream rows (it is not silently half-stored)', () {
    final st = extractHistoricalStreams(
        <Uint8List>[imuFrame], 1784037165, 1784037165, DeviceFamily.whoop5);
    expect(st.isEmpty, isTrue,
        reason: 'nothing in the sync path consumes raw IMU today — by design');
  });

  test('the archived bytes round-trip back through the IMU decoder', () {
    // What makes "archive, do not store" honest rather than a shrug: the hex the Backfiller banks is
    // sufficient to recover the full 6-axis window offline, exactly as if it had been decoded live.
    final hex = imuFrame
        .map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0'))
        .join();
    final recovered = Whoop5RawImu.decode(_hexToBytes(hex))!;
    expect(recovered.baseTs, 1784037165);
    expect(recovered.samples, hasLength(100));
    final mags = recovered.samples
        .map((s) => math.sqrt(s.ax * s.ax + s.ay * s.ay + s.az * s.az))
        .toList()
      ..sort();
    expect(mags[mags.length ~/ 2], closeTo(1.0, 0.15),
        reason: 'the gravity shell survives the archive round-trip');
  });
}

Uint8List _hexToBytes(String hex) => Uint8List.fromList(<int>[
      for (var i = 0; i + 2 <= hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16)
    ]);

/// The same real 1244-byte type-0x2F layout-v21 buffer as `whoop5_raw_imu_test.dart` (WHOOP 5.0,
/// fw 50.40.1.0, upstream #423).
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
