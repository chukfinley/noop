/// Faithful Dart port of `ImuFeatureExtractor.kt` / `ImuFeatureExtractor.swift` (upstream #423).
///
/// Activity features from decoded WHOOP 5/MG raw 6-axis IMU. The offload buffer decodes
/// ([Whoop5RawImu]) to 100 Hz 3-axis accel (g) + 3-axis gyro; at 100 Hz the accelerometer resolves
/// gait cadence, impact/jerk and rotational energy that the 1 Hz gravity vector physically cannot (a
/// 1.8 Hz step rate is above the 1 Hz stream's Nyquist limit). This turns a window of raw samples into
/// a compact activity-feature vector.
///
/// Per the repo's derived-signal rule, cadence here is an autocorrelation peak on the accel-magnitude
/// AC over a genuinely high-rate stream — NOT over a fixed-N-per-record buffer, which is what makes it
/// legitimate where [WorkoutTypeClassifier] correctly refuses to do the same on ~1 Hz gravity (a peak
/// at the record period looks physiological but isn't; cf. the withdrawn PPG→HR estimate #194). It is
/// reported with its own strength so a caller can ignore a weak/absent peak, and it is a FEATURE —
/// never fed to a physiological gate.
///
/// ─────────────────────────────────────────────────────────────────────────────
/// DORMANT — no call site, and its intended consumer does not exist.
/// ─────────────────────────────────────────────────────────────────────────────
/// Nothing in this app calls this yet, mirroring upstream (whose only caller is a research JSONL
/// log). It is NOT the missing input to [WorkoutTypeClassifier]: that classifier scores a
/// [WorkoutClassFeatures] vector of HR / step-tick / gravity / duration, deliberately contains no IMU
/// term on any platform, and its own header states that fine-grained sport discrimination from raw
/// IMU is out of scope. What it actually waits on is a workout DETECTOR (there is none — see its
/// `gravityActivitySeries`/`deriveRestingHR` port notes) plus real labeled workouts to validate
/// against. Wiring these features into it would be a new classifier, not a completed chain.
///
/// The upstream feed is likewise absent: [Whoop5RawImu] is not wired into [extractHistoricalStreams]
/// (see its header for why — the raw bytes are already archived, and the emission rate is unmeasured
/// so no storage design is justified). So this extractor's honest status is: proven pure function,
/// no producer, no consumer.
///
/// UNITS CAVEAT: [ImuActivityFeatures.gyroEnergyDps] inherits [Whoop5RawImu.gyroScale], whose ±2000
/// dps full scale is INFERENCE and not established by any frame we hold (the one real capture is at
/// rest, where every candidate scale is consistent). Treat gyro energy as relative, not as dps.
/// The accel-derived features ([accelEnergyG], [jerkRms]) rest on the gravity-shell-proven 1/4096
/// scale and are calibrated; [cadenceHz] depends only on the sample RATE, not on either scale.
library;

import 'dart:math' as math;

import 'package:noop/core/ble/protocol/whoop5_raw_imu.dart';

/// Compact activity features over a window of raw IMU samples.
class ImuActivityFeatures {
  const ImuActivityFeatures({
    required this.accelEnergyG,
    required this.gyroEnergyDps,
    required this.jerkRms,
    required this.cadenceHz,
    required this.cadenceStrength,
    required this.sampleCount,
  });

  /// RMS of the accel-magnitude AC (gravity removed), in g — overall movement intensity.
  final double accelEnergyG;

  /// Mean gyroscope magnitude over the window, nominal deg/s. UNCALIBRATED — see the library header.
  final double gyroEnergyDps;

  /// RMS of the accel first-difference (jerk), in g/sample — impact / explosiveness.
  final double jerkRms;

  /// Dominant cadence in the gait band, Hz — null when no rhythmic peak clears
  /// [ImuFeatureExtractor.minCadenceStrength]. Multiply by 60 for steps/min.
  final double? cadenceHz;

  /// Normalized strength (0..1) of that cadence peak — high = rhythmic, low = bursty or still.
  final double cadenceStrength;

  final int sampleCount;

  @override
  String toString() =>
      'ImuActivityFeatures(accelEnergyG: $accelEnergyG, gyroEnergyDps: $gyroEnergyDps, '
      'jerkRms: $jerkRms, cadenceHz: $cadenceHz, cadenceStrength: $cadenceStrength, '
      'sampleCount: $sampleCount)';
}

/// Extractor for [ImuActivityFeatures] over decoded raw IMU.
class ImuFeatureExtractor {
  ImuFeatureExtractor._();

  /// Cadence search band, Hz — human gait/pedal foot rate (~72-210 steps/min). Below the IMU Nyquist.
  static const double cadenceBandLowHz = 1.2;
  static const double cadenceBandHighHz = 3.5;

  /// A cadence peak below this normalized autocorrelation strength is treated as "no rhythm" (→ null).
  static const double minCadenceStrength = 0.20;

  /// Extract features from [samples] (from one or more [Whoop5ImuFrame]s, in order) at [sampleRateHz].
  static ImuActivityFeatures extract(
    List<RawImuSample> samples,
    int sampleRateHz,
  ) {
    final n = samples.length;
    if (n < 8 || sampleRateHz <= 0) {
      return ImuActivityFeatures(
        accelEnergyG: 0.0,
        gyroEnergyDps: 0.0,
        jerkRms: 0.0,
        cadenceHz: null,
        cadenceStrength: 0.0,
        sampleCount: n,
      );
    }

    final amag = <double>[
      for (final s in samples)
        math.sqrt(s.ax * s.ax + s.ay * s.ay + s.az * s.az)
    ];
    final gmag = <double>[
      for (final s in samples)
        math.sqrt(s.gx * s.gx + s.gy * s.gy + s.gz * s.gz)
    ];

    final gyroEnergy = _sum(gmag) / n;

    // Accel AC: remove the DC (~gravity) then RMS.
    final mean = _sum(amag) / n;
    final ac = <double>[for (final v in amag) v - mean];
    var acSq = 0.0;
    for (final v in ac) {
      acSq += v * v;
    }
    final accelEnergy = math.sqrt(acSq / n);

    // Jerk: RMS of |accel| first difference.
    var jerkSq = 0.0;
    for (var i = 1; i < n; i++) {
      final d = amag[i] - amag[i - 1];
      jerkSq += d * d;
    }
    final jerk = math.sqrt(jerkSq / (n - 1));

    // Cadence: normalized autocorrelation of the AC series over the gait-band lags; the strongest
    // peak's frequency + strength. Strength = peak ACF / zero-lag ACF (0..1), so it's amplitude-scale
    // free (a faint but rhythmic walk and a hard one both read as rhythmic).
    final ac0 = acSq;
    double? bestFreq;
    var bestStrength = 0.0;
    if (ac0 > 0) {
      final loLag = math.max(1, (sampleRateHz / cadenceBandHighHz).round());
      final hiLag = math.min(n - 1, (sampleRateHz / cadenceBandLowHz).round());
      if (loLag < hiLag) {
        for (var lag = loLag; lag <= hiLag; lag++) {
          var s = 0.0;
          for (var i = 0; i < n - lag; i++) {
            s += ac[i] * ac[i + lag];
          }
          final strength = s / ac0;
          if (strength > bestStrength) {
            bestStrength = strength;
            bestFreq = sampleRateHz.toDouble() / lag.toDouble();
          }
        }
      }
    }
    final cadence = bestStrength >= minCadenceStrength ? bestFreq : null;

    return ImuActivityFeatures(
      accelEnergyG: accelEnergy,
      gyroEnergyDps: gyroEnergy,
      jerkRms: jerk,
      cadenceHz: cadence,
      cadenceStrength: math.max(0.0, bestStrength),
      sampleCount: n,
    );
  }

  /// Convenience: extract over the concatenated samples of decoded IMU frames.
  static ImuActivityFeatures extractFrames(List<Whoop5ImuFrame> frames) {
    final rate = frames.isEmpty ? 100 : frames.first.sampleRateHz;
    return extract(
      <RawImuSample>[for (final f in frames) ...f.samples],
      rate,
    );
  }

  static double _sum(List<double> xs) {
    var t = 0.0;
    for (final x in xs) {
      t += x;
    }
    return t;
  }
}
