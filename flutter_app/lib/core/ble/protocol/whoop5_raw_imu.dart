/// Faithful Dart port of `Whoop5RawImu.kt` / `Whoop5RawImu.swift` (upstream #423).
///
/// Decoder for the WHOOP 5.0/MG raw 6-axis IMU offload buffer: a 1244-byte type-47 **layout v21**
/// record carrying 100 accelerometer + 100 gyroscope samples, stored COLUMNAR (all ax, then all ay,
/// then all az; likewise the gyro) as little-endian i16.
///
/// The 5/MG banks high-rate motion and ships it inside big type-0x2F buffers during the connect-time
/// offload burst, alongside the ~124 B 1 Hz rollup [decodeHistorical] already reads. Its *live* raw-IMU
/// stream is firmware-refused (TOGGLE_IMU_MODE acks but never streams), so the offload buffer is the
/// only path to 100 Hz 6-axis on this generation.
///
/// ─────────────────────────────────────────────────────────────────────────────
/// NOT WIRED INTO [extractHistoricalStreams] — deliberately. Read this before changing that.
/// ─────────────────────────────────────────────────────────────────────────────
/// This decoder is a pure, standalone reader with no call site in the sync path, matching upstream
/// (whose own only caller is a research JSONL log, not persistence). Three reasons, in order:
///
///  1. **Nothing is lost by not storing it.** A v21 buffer fails [decodeHistorical] (which maps v18
///     only), so [rejectedHistoricalRecords] already classifies it as undecodable and the Backfiller
///     archives the verbatim bytes into `rawSensorArchive` BEFORE acking the strap trim. The raw IMU
///     is therefore already durable on-device; this decoder can read those archived rows offline. A
///     new table would duplicate bytes we already hold.
///  2. **No consumer exists.** Workouts/activities are "coming soon" (`LiveRepository.workouts =>
///     const []`), and [WorkoutTypeClassifier] does NOT consume IMU features — its vector is HR /
///     step-tick / gravity / duration, and its own header states fine-grained sport discrimination
///     from raw IMU is explicitly out of scope. Its missing input is a workout DETECTOR, not this.
///  3. **The cost is unbounded because the emission RATE is unmeasured.** One buffer is 1200 B of
///     samples. If the strap banks one per worn second that is ~104 MB/day of blobs (~3.2 GB at 30
///     days) — against a 1 Hz HR stream that already drove peak RSS to 1.6 GB at 30 days before it
///     was fixed. Nobody has measured how often these actually arrive, so no storage design can be
///     justified yet. (Note the corollary: if the rate IS high, `rawSensorArchive` is already banking
///     them as ~2.5 KB of hex TEXT each — worse than a blob. That is a pre-existing exposure, called
///     out in the report, not something this decoder introduces.)
///
/// If a consumer and a measured emission rate ever exist, persist the DERIVED per-second
/// [ImuActivityFeatures] (~5 doubles), not the raw 100 Hz — and only then bump the schema.
///
/// ─────────────────────────────────────────────────────────────────────────────
/// WHAT IS PROVEN vs WHAT IS INFERENCE (the layout is decoded from ONE real captured frame)
/// ─────────────────────────────────────────────────────────────────────────────
/// PROVEN on the real 1244-byte buffer captured off a WHOOP 5.0 (fw 50.40.1.0), re-verified here:
///   * type@8 = 0x2F, layout@9 = 21, length 1244, `baseTs` u32 LE @15 = 1784037165.
///   * The accel block offsets AND the 1/4096 g scale: all 100 samples land in a gravity shell of
///     median 1.0058 g (min 0.999, max 1.012 — a ±1.3 % spread). Gravity is an absolute 1 g physical
///     reference, so a wrong offset or a wrong scale could not produce this. This is hard ground truth.
///
/// INFERENCE — believed, but NOT established by any frame we hold. Do not promote these to fact:
///   * **[gyroScale] (±2000 dps full scale).** The captured frame is AT REST: the gyro block reads a
///     mean magnitude of ~13.9 LSB. At rest EVERY candidate full-scale range is consistent (±2000 →
///     0.85 dps, ±250 → 0.11 dps); upstream's own test asserts only `mean < 200 dps`, which every
///     candidate passes. Upstream's quoted validation ("near zero at rest, spikes in motion,
///     correlates 0.79 with accel motion") establishes that the block IS rotational data — it does
///     NOT pin its scale. Pinning it needs a frame captured under a KNOWN rotation. Until then
///     [RawImuSample.gx]/[gy]/[gz] and [ImuActivityFeatures.gyroEnergyDps] are proportional to
///     angular rate but UNCALIBRATED: treat them as relative, never as a dps measurement.
///   * **[Whoop5ImuFrame.sampleRateHz] = 100 Hz.** This is derived from the sample COUNT, not decoded
///     — it holds only if a buffer spans exactly one second. One frame cannot show that; consecutive
///     `baseTs` deltas would. The 100 Hz figure (and so [ts], and every cadence in Hz) rests on it.
///   * The `countA`/`countB` field names. Both @22 and @24 read 100 (as do @628 and @630), so which
///     is a count, a rate, or an axis stride is unresolved. The gate below uses @24/@630 for parity
///     with upstream; it works as a length+magic check regardless of what the fields mean.
///
/// This file exists because the branch has been burned by exactly this: an unproven gloss ported as
/// fact and then relied on across the codebase (see commit c35c7bd9). The honest boundary is recorded
/// at the owning site, in the shape upstream's own ad4cc1f4 used.
///
/// Pure/deterministic; no I/O, no strap.
library;

import 'dart:typed_data';

import 'enums.dart';

/// One raw IMU sample: 3-axis accelerometer (g) + 3-axis gyroscope.
///
/// [ax]/[ay]/[az] are g and are CALIBRATED (the 1/4096 scale is pinned by the gravity shell).
/// [gx]/[gy]/[gz] are nominally deg/s but are **uncalibrated** — see the [gyroScale] note in the
/// library header. They are proportional to angular rate; the constant is unproven.
class RawImuSample {
  const RawImuSample({
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
  });

  /// Accelerometer, g (calibrated).
  final double ax;
  final double ay;
  final double az;

  /// Gyroscope, nominal deg/s (scale UNPROVEN — relative only).
  final double gx;
  final double gy;
  final double gz;

  @override
  bool operator ==(Object other) =>
      other is RawImuSample &&
      other.ax == ax &&
      other.ay == ay &&
      other.az == az &&
      other.gx == gx &&
      other.gy == gy &&
      other.gz == gz;

  @override
  int get hashCode => Object.hash(ax, ay, az, gx, gy, gz);

  @override
  String toString() =>
      'RawImuSample(a: ($ax, $ay, $az) g, g: ($gx, $gy, $gz) dps*)';
}

/// One decoded 5/MG raw-IMU buffer: a second of 6-axis samples with the strap's base timestamp.
class Whoop5ImuFrame {
  const Whoop5ImuFrame({
    required this.baseTs,
    required this.sampleRateHz,
    required this.samples,
  });

  /// Strap unix seconds for the frame (full u32 @15).
  final int baseTs;

  /// Samples per second. NOT decoded — assumed equal to the sample count (see the library header).
  final int sampleRateHz;

  final List<RawImuSample> samples;

  /// Wall-clock unix seconds for sample [i], assuming the samples are evenly spaced across one
  /// second. Inherits the [sampleRateHz] assumption above.
  double ts(int i) =>
      baseTs.toDouble() + i.toDouble() / (sampleRateHz < 1 ? 1 : sampleRateHz);
}

/// Decoder for the 5/MG raw 6-axis IMU offload buffer (type-47 layout v21).
class Whoop5RawImu {
  Whoop5RawImu._();

  /// Exact byte length of the buffer (8-byte puffin envelope + payload + 4-byte CRC tail).
  static const int bufferLength = 1244;

  /// Samples per axis per buffer.
  static const int sampleCount = 100;

  /// Accelerometer g per LSB. PROVEN by the gravity shell on the real frame.
  static const double accelScale = 1.0 / 4096.0;

  /// Gyroscope deg/s per LSB, assuming a ±2000 dps full scale (~16.4 LSB/dps).
  ///
  /// UNPROVEN — see the library header. The at-rest capture cannot distinguish this from ±250/±500/
  /// ±1000 dps. Kept at upstream's value for cross-platform parity (the Kotlin and Swift twins use
  /// the same constant), so a future calibration changes ONE number in three places, not a decode.
  static const double gyroScale = 2000.0 / 32768.0;

  /// The type-47 layout version this decoder reads (frame[9]).
  static const int layoutVersion = 21;

  // FRAME-absolute offsets (8-byte puffin envelope + payload).
  static const int _tsOff = 15;
  static const int _countAOff = 24;
  static const int _axOff = 28;
  static const int _ayOff = 228;
  static const int _azOff = 428;
  static const int _countBOff = 630;
  static const int _gxOff = 640;
  static const int _gyOff = 840;
  static const int _gzOff = 1040;

  /// Decode a raw-IMU buffer, or null if [f] isn't one.
  ///
  /// Gates on the exact length + the two in-packet sample counts (= 100) rather than the type byte,
  /// mirroring upstream — type 47 is shared with the v18 rollup and the v26 PPG buffer, so a
  /// type-only gate would misfire on a same-type non-IMU frame. The counts act as a magic number.
  static Whoop5ImuFrame? decode(Uint8List f) {
    if (f.length < bufferLength) return null;
    if (_u16(f, _countAOff) != sampleCount) return null;
    if (_u16(f, _countBOff) != sampleCount) return null;
    if (_gzOff + 2 * sampleCount > f.length) return null;

    final baseTs = _u32(f, _tsOff);
    final samples = <RawImuSample>[];
    for (var i = 0; i < sampleCount; i++) {
      final o = 2 * i;
      samples.add(RawImuSample(
        ax: _i16(f, _axOff + o) * accelScale,
        ay: _i16(f, _ayOff + o) * accelScale,
        az: _i16(f, _azOff + o) * accelScale,
        gx: _i16(f, _gxOff + o) * gyroScale,
        gy: _i16(f, _gyOff + o) * gyroScale,
        gz: _i16(f, _gzOff + o) * gyroScale,
      ));
    }
    // sampleRateHz := sampleCount is upstream's assumption that a buffer spans exactly one second.
    return Whoop5ImuFrame(
        baseTs: baseTs, sampleRateHz: sampleCount, samples: samples);
  }

  /// Whether [f] looks like a 5/MG raw-IMU buffer by its envelope tags (type-47, layout v21, exact
  /// length). Offered alongside [decode]'s count-based gate so a caller classifying an archived frame
  /// can ask the question by layout version rather than by magic number.
  static bool looksLikeImuBuffer(Uint8List f) =>
      f.length == bufferLength &&
      f[8] == PacketType.historicalData.rawValue &&
      f[9] == layoutVersion;

  // Little-endian readers (frame-absolute). Callers gate on length first.
  static int _u16(Uint8List f, int o) => f[o] | (f[o + 1] << 8);

  static int _u32(Uint8List f, int o) =>
      f[o] | (f[o + 1] << 8) | (f[o + 2] << 16) | (f[o + 3] << 24);

  static int _i16(Uint8List f, int o) {
    final v = _u16(f, o);
    return v >= 32768 ? v - 65536 : v;
  }
}
