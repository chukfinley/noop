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
  /// verbatim. `null` when the source has no such channel — a WHOOP 4.0 emits none
  /// at all (it is decoded only from 5.0/MG v18 records), as does the bundled
  /// asset; the pipeline then falls back to its HR-derived sleep detection.
  ///
  /// NOT a proven ground-truth signal, and deliberately not documented as one. It
  /// is a 2-BIT field — `(frame[81] >> 4) & 3` — so it cannot carry light/deep/REM
  /// under any reading. The `0 wake / 1 still / 2 asleep / 3 up` gloss is
  /// STRUCTURAL INFERENCE: upstream's ad4cc1f4 states the boundary outright ("the
  /// meaning of the non-zero codes is structural inference; every frame we hold
  /// reads 0"), and a sweep of the RE repo found no grounding for byte 81 — the
  /// official app never decodes it, because its staging is server-side.
  ///
  /// We nonetheless let it drive the sleep WINDOW (e412e0ed), on the strength of a
  /// phone-DB check that matched the band's bouts to ~1 min. That corroborates the
  /// bounds; it does not decode the codes. Two consequences follow, both real:
  /// `_buildEpochs`'s `st != 0` counts code 3 — inferred as "up" — as asleep; and
  /// the channel co-emits with gravity in the same per-second record, so it is
  /// silent exactly where motion is (see [SleepStager.detect] and c35c7bd9).
  /// Widening its role beyond the window needs frames that actually carry non-zero
  /// codes, not a re-reading of the gloss.
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
