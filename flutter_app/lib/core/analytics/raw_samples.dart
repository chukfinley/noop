/// One second of decoded WHOOP sensor data — the unit the [DailyPipeline]
/// consumes. Built live from the drift store by [LiveRepository]: each row merges
/// the second's heart rate, its beat-to-beat RR intervals and an accel-magnitude
/// movement scalar (`~1.0` g at rest), plus the strap's own `sleepState`.
///
/// The channels are merged onto one per-second row but are NOT sampled together:
/// a WHOOP 4.0 offload banks heart rate densely and gravity coarsely, so most
/// rows of a real night carry an HR and no accel at all. Every field that a
/// second may simply not have is therefore nullable or has an explicit absent
/// encoding — none of them is ever filled with a plausible stand-in.
class RawSample {
  final int ts; // unix seconds
  final int hr; // bpm (0 = no reading)
  final int spo2; // % (raw strap value; 0 = absent)
  final int rrCount; // valid RR intervals in this row (0..3)
  final int rr1, rr2, rr3; // RR intervals, ms

  /// |accel| in g (~1.0 at rest, gravity) — NULL when this second carried no
  /// accel sample. Null means UNKNOWN, never "still".
  ///
  /// This was a non-nullable `double` that [LiveRepository] defaulted to exactly
  /// `1.0` — the resting magnitude — for every second with a heart rate but no
  /// accel. That default did not merely mislabel its own second. Motion reaches
  /// the stager as a NIGHT-RELATIVE scale (median + MAD, see [SleepStager]), and
  /// `1.0` is the one value that deviates from the resting magnitude by exactly
  /// zero, so a fabricated second read as MORE still than a genuinely still wrist
  /// ever measures. Three things followed, all measured through the real producer
  /// (`test/analytics/motion_fabrication_test.dart`):
  ///
  ///   * the classic 4.0 offload (dense HR, coarse gravity) reported FULL motion
  ///     coverage, so the sparse-motion confidence guard (#345) could never trip
  ///     for the exact case it was written for — a 90 s and a 120 s gravity night
  ///     scored identically to a 30 s one, byte for byte;
  ///   * an epoch's real motion was averaged together with the fabricated zeros
  ///     that outnumbered it, diluting a genuine excursion toward the floor;
  ///   * worst, #462's motion-corroborated wake ("elevated HR on a still wrist is
  ///     not an awakening") was corroborating against invented stillness, so it
  ///     SUPPRESSED real awakenings: a 15-minute waking at 78 bpm that landed in a
  ///     gravity hole scored 0 disturbances and 1.000 efficiency.
  ///
  /// There is no magnitude that can honestly stand in for a missing sample — the
  /// same conclusion the epoch-level channel reached when its own "no sample"
  /// sentinel had to be removed (see [SleepStager.detect]'s contract).
  final double? movement;

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
