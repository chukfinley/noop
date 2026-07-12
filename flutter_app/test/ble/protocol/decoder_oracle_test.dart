import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';

/// Faithful Dart port of `DecoderOracleTest.kt`.
///
/// GOLDEN DECODER ORACLE (lane-4 A8) — the Dart half of a shared Swift<->Kotlin<->Dart drift guard.
///
/// `test/fixtures/decoder_oracle.json` is a fixture of REAL captured WHOOP type-47 HISTORICAL_DATA
/// frames plus their expected decode. The IDENTICAL file is committed alongside the Kotlin/Swift
/// suites, which run the same assertions through their own decoders. Decoding the same fixture and
/// asserting the same output is what catches a one-sided edit (a moved offset / changed scaling on one
/// platform only).
///
/// NOTE: the Kotlin `oracleCopiesAreIdentical` cross-repo byte-for-byte check against the Swift tree is
/// deliberately NOT ported (it is a Kotlin<->Swift-only lockstep check); only the decode-vs-oracle
/// assertions are ported here.
void main() {
  Uint8List hexToBytes(String s) {
    final out = Uint8List(s.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  Map<String, dynamic> loadOracle() {
    final file = File('test/fixtures/decoder_oracle.json');
    expect(file.existsSync(), isTrue,
        reason: 'decoder_oracle.json missing from test/fixtures');
    return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('oracleFramesDecodeToExpectedOutput', () {
    final oracle = loadOracle();
    final tolerance = (oracle['tolerance'] as num).toDouble();
    final frames = oracle['frames'] as List<dynamic>;
    expect(frames.isNotEmpty, isTrue, reason: 'no oracle frames loaded');

    for (final frameAny in frames) {
      final frame = frameAny as Map<String, dynamic>;
      final name = frame['name'] as String;
      final family = frame['family'] == 'whoop5'
          ? DeviceFamily.whoop5
          : DeviceFamily.whoop4;
      final parsed = decodeHistorical(hexToBytes(frame['hex'] as String), family);
      expect(parsed, isNotNull, reason: '$name: decodeHistorical returned null');

      final expected = frame['expect'] as Map<String, dynamic>;
      for (final key in expected.keys) {
        if (key == 'gravity_mag') {
          final wantMag = (expected[key] as num).toDouble();
          final gx = parsed!['gravity_x'] as double?;
          final gy = (parsed['gravity_y'] as double?) ?? 0.0;
          final gz = (parsed['gravity_z'] as double?) ?? 0.0;
          expect(gx, isNotNull, reason: '$name: gravity did not decode');
          final mag = sqrt(gx! * gx + gy * gy + gz * gz);
          expect((mag - wantMag).abs() <= 0.1, isTrue,
              reason: '$name: |gravity| $mag != ~$wantMag');
        } else {
          final want = expected[key];
          if (want is List) {
            final got = (parsed![key] as List?)?.cast<int>() ?? <int>[];
            final wantList = want.map((e) => (e as num).toInt()).toList();
            expect(got, wantList, reason: '$name.$key');
          } else if (want is num) {
            final got = parsed![key];
            if (got is int) {
              expect(got, want.toInt(), reason: '$name.$key');
            } else if (got is double) {
              expect((got - want.toDouble()).abs() <= tolerance, isTrue,
                  reason: '$name.$key: $got != ~$want');
            } else if (got == null) {
              fail('$name.$key missing in decoded output');
            } else {
              expect(got.toString(), want.toString(), reason: '$name.$key');
            }
          } else {
            fail('$name.$key: unhandled expect type ${want.runtimeType}');
          }
        }
      }
    }
  });
}
