/// One second of decoded WHOOP sensor data — the unit the [DailyPipeline]
/// consumes. Built live from the drift store by [LiveRepository]: each row merges
/// the second's heart rate, its beat-to-beat RR intervals and an accel-magnitude
/// movement scalar (`~1.0` g at rest), plus the strap's own `sleepState`.
class RawSample {
  final int ts; // unix seconds
  final int hr; // bpm (0 = no reading)
  final int spo2; // % (raw strap value; 0 = absent)
  final int rrCount; // valid RR intervals in this row (0..3)
  final int rr1, rr2, rr3; // RR intervals, ms
  final double movement; // |accel| in g

  /// The strap's OWN per-second sleep state (WHOOP `sleep_state`, #175), carried
  /// verbatim: 0 = awake, non-zero = a sleep stage. `null` when the source has no
  /// such channel (e.g. the bundled asset) — the pipeline then falls back to its
  /// HR-derived sleep detection. This is the band's ground-truth sleep signal, so
  /// when present it drives the sleep window instead of re-deriving it from HR.
  final int? sleepState;

  const RawSample({
    required this.ts,
    required this.hr,
    required this.spo2,
    required this.rrCount,
    required this.rr1,
    required this.rr2,
    required this.rr3,
    required this.movement,
    this.sleepState,
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

/// A single local calendar day of raw samples, oldest → newest — the shape the
/// [DailyPipeline] consumes, built live from the drift store by [LiveRepository].
class RawDay {
  /// Local midnight of this day (a DateTime whose Y/M/D is the local date).
  final DateTime date;
  final List<RawSample> samples;
  const RawDay(this.date, this.samples);
}
