import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/imu_feature_extractor.dart';
import 'package:noop/core/ble/protocol/whoop5_raw_imu.dart';

/// Pins [ImuFeatureExtractor] — activity features from decoded 5/MG raw IMU (upstream #423). Dart twin
/// of the Kotlin `ImuFeatureExtractorTest` / Swift `ImuFeatureExtractorTests`, same vectors.
///
/// Per the repo's derived-signal rule, cadence is validated to recover MULTIPLE distinct injected
/// rates — the point being that the extractor must TRACK a varying input rather than manufacture one
/// rate (the failure mode that withdrew the PPG→HR estimate, #194). Still/energy/gyro are checked
/// independently so a single lucky match can't carry the file.
void main() {
  /// 100 Hz samples: gravity on Z + a sinusoidal wobble of amplitude [amp] g at [cadence] Hz on Z,
  /// and an optional constant gyro rotation [gyroDps] on gx. Mirrors upstream's `gaitSamples`.
  List<RawImuSample> gaitSamples({
    required double cadence,
    double amp = 0.2,
    double seconds = 6.0,
    double gyroDps = 0.0,
  }) {
    const rate = 100.0;
    final n = (seconds * rate).toInt();
    return <RawImuSample>[
      for (var i = 0; i < n; i++)
        RawImuSample(
          ax: 0.0,
          ay: 0.0,
          az: 1.0 + amp * math.sin(2 * math.pi * cadence * i / rate),
          gx: gyroDps,
          gy: 0.0,
          gz: 0.0,
        )
    ];
  }

  test('recovers multiple distinct injected cadences', () {
    // The load-bearing test: the extractor must track a VARYING input, not manufacture one rate.
    for (final target in <double>[1.4, 1.8, 2.4, 3.0]) {
      final f =
          ImuFeatureExtractor.extract(gaitSamples(cadence: target), 100);
      expect(f.cadenceHz, isNotNull,
          reason: 'cadence $target Hz should be detected');
      expect(f.cadenceHz!, closeTo(target, 0.15),
          reason: 'recovered cadence should match the injected $target Hz');
      expect(f.cadenceStrength, greaterThan(0.4),
          reason: 'a clean sinusoid should read as strongly rhythmic');
    }
  });

  test('a still wrist has no cadence and low energy', () {
    final still = <RawImuSample>[
      for (var i = 0; i < 600; i++)
        const RawImuSample(ax: 0.0, ay: 0.0, az: 1.0, gx: 0.0, gy: 0.0, gz: 0.0)
    ];
    final f = ImuFeatureExtractor.extract(still, 100);
    expect(f.cadenceHz, isNull, reason: 'a still wrist has no gait cadence');
    expect(f.accelEnergyG, lessThan(0.01));
    expect(f.gyroEnergyDps, lessThan(0.01));
  });

  test('energy and jerk rise with motion', () {
    final still =
        ImuFeatureExtractor.extract(gaitSamples(cadence: 2.0, amp: 0.0), 100);
    final moving =
        ImuFeatureExtractor.extract(gaitSamples(cadence: 2.0, amp: 0.3), 100);
    expect(moving.accelEnergyG, greaterThan(still.accelEnergyG + 0.05));
    expect(moving.jerkRms, greaterThan(still.jerkRms));
  });

  test('gyro energy reflects rotation', () {
    final f = ImuFeatureExtractor.extract(
        gaitSamples(cadence: 2.0, gyroDps: 45.0), 100);
    // NOTE: this reads back a value the TEST injected in dps — it pins the extractor's arithmetic,
    // NOT the decoder's gyro scale. Real strap LSBs reach dps via [Whoop5RawImu.gyroScale], which is
    // inference (see whoop5_raw_imu_test.dart); no test here can calibrate it.
    expect(f.gyroEnergyDps, closeTo(45.0, 1.0),
        reason: 'constant 45 dps rotation should read back');
  });

  test('extracts across decoded frames (two frames concatenate into one window)', () {
    final frame = Whoop5ImuFrame(
        baseTs: 0, sampleRateHz: 100, samples: gaitSamples(cadence: 2.2));
    final f = ImuFeatureExtractor.extractFrames(<Whoop5ImuFrame>[frame, frame]);
    expect(f.sampleCount, frame.samples.length * 2);
    expect(f.cadenceHz, isNotNull);
    expect(f.cadenceHz!, closeTo(2.2, 0.15));
  });

  test('a too-short window yields zeroed features rather than a manufactured peak', () {
    final f = ImuFeatureExtractor.extract(gaitSamples(cadence: 2.0).take(4).toList(), 100);
    expect(f.sampleCount, 4);
    expect(f.cadenceHz, isNull);
    expect(f.accelEnergyG, 0.0);
    expect(f.cadenceStrength, 0.0);
  });
}
