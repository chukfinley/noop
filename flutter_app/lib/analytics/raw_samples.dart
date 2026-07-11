import 'dart:typed_data';

/// Raw per-sample decode of the bundled Whoop capture (`assets/data/real_raw.bin.gz`).
///
/// This is the seam between the real reverse-engineered strap capture and the
/// ported NOOP analytics: the binary holds ~2.7M genuine per-second sensor rows
/// (88 days, 2026-01-28 → 2026-05-26) exactly as offloaded from a WHOOP 4.0/5.0
/// band, and the Dart pipeline runs the SAME scoring the Kotlin app runs.
///
/// Wire format (little-endian), payload gzipped as a whole:
///   header : 'NOOPRAW1' (8 bytes ASCII) + recordCount : u32
///   record : ts:u32  hr:u8  spo2:u8  rrCount:u8  pad:u8
///            rr1:u16  rr2:u16  rr3:u16  mv:u16          (16 bytes)
/// `mv` = |accel| × 1000 (a movement scalar, ~1000 ≈ 1 g at rest); `rrN` are the
/// strap's beat-to-beat RR intervals in ms (0 = absent). `ts` is unix seconds.
class RawSample {
  final int ts; // unix seconds
  final int hr; // bpm (0 = no reading)
  final int spo2; // % (raw strap value; 0 = absent)
  final int rrCount; // valid RR intervals in this row (0..3)
  final int rr1, rr2, rr3; // RR intervals, ms
  final double movement; // |accel| in g

  const RawSample({
    required this.ts,
    required this.hr,
    required this.spo2,
    required this.rrCount,
    required this.rr1,
    required this.rr2,
    required this.rr3,
    required this.movement,
  });

  /// The valid RR intervals (ms) carried by this row, in order.
  List<double> get rrIntervals {
    final out = <double>[];
    if (rrCount >= 1 && rr1 > 0) out.add(rr1.toDouble());
    if (rrCount >= 2 && rr2 > 0) out.add(rr2.toDouble());
    if (rrCount >= 3 && rr3 > 0) out.add(rr3.toDouble());
    return out;
  }
}

/// Timezone the capture is anchored to (CET, +1h). The strap timestamps are
/// absolute unix seconds; we bucket them into local calendar days / nights with
/// this fixed offset so the demo dates match how the wearer lived them.
const int captureTzOffsetSec = 3600;

/// A single local calendar day of raw samples, oldest → newest.
class RawDay {
  /// Local midnight (CET) of this day, expressed as a UTC DateTime whose Y/M/D
  /// is the local date — used purely as the record's logical date.
  final DateTime date;
  final List<RawSample> samples;
  const RawDay(this.date, this.samples);
}

/// Decoded capture: all samples plus a per-local-day grouping.
class RawCapture {
  final List<RawSample> samples;
  final List<RawDay> days;
  const RawCapture(this.samples, this.days);

  static const _magic = 'NOOPRAW1';

  /// Decode the gzip-inflated payload bytes (header + records). Throws on a bad
  /// magic. Groups into local calendar days ([captureTzOffsetSec]).
  factory RawCapture.decode(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    for (var i = 0; i < 8; i++) {
      if (bytes[i] != _magic.codeUnitAt(i)) {
        throw const FormatException('real_raw.bin: bad magic');
      }
    }
    final count = bd.getUint32(8, Endian.little);
    const base = 12, stride = 16;
    final samples = List<RawSample>.generate(count, (i) {
      final o = base + i * stride;
      return RawSample(
        ts: bd.getUint32(o, Endian.little),
        hr: bd.getUint8(o + 4),
        spo2: bd.getUint8(o + 5),
        rrCount: bd.getUint8(o + 6),
        // o+7 pad
        rr1: bd.getUint16(o + 8, Endian.little),
        rr2: bd.getUint16(o + 10, Endian.little),
        rr3: bd.getUint16(o + 12, Endian.little),
        movement: bd.getUint16(o + 14, Endian.little) / 1000.0,
      );
    }, growable: false);

    return RawCapture(samples, _groupDays(samples));
  }

  static List<RawDay> _groupDays(List<RawSample> samples) {
    final buckets = <int, List<RawSample>>{};
    for (final s in samples) {
      final localDayIdx = (s.ts + captureTzOffsetSec) ~/ 86400;
      (buckets[localDayIdx] ??= <RawSample>[]).add(s);
    }
    final keys = buckets.keys.toList()..sort();
    return keys.map((k) {
      final localMidnightSec = k * 86400 - captureTzOffsetSec;
      // Logical date: the local Y/M/D, held in a UTC DateTime.
      final d = DateTime.fromMillisecondsSinceEpoch(
        (localMidnightSec + captureTzOffsetSec) * 1000,
        isUtc: true,
      );
      return RawDay(DateTime(d.year, d.month, d.day), buckets[k]!);
    }).toList(growable: false);
  }
}
