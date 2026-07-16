// Simplified heuristic sleep-staging module.
//
// A deliberately small, self-contained Dart port of the intent behind the
// Kotlin `SleepStager` / `SleepStagerV2` recipes (per-night HR + movement →
// wake/light/deep/rem). This is a clean heuristic, NOT the full z-scored,
// DFT-per-epoch, Viterbi implementation — it trades accuracy for ~250 lines.
//
// Pure Dart. Deterministic: no randomness, no clock reads.

enum SleepStageK { awake, light, deep, rem }

class SleepSegmentK {
  final int startTs; // unix seconds
  final int durationSec;
  final SleepStageK stage;
  const SleepSegmentK(this.startTs, this.durationSec, this.stage);
}

class SleepResult {
  final int startTs, endTs; // main sleep window (unix seconds)
  final int inBedSec, asleepSec, awakeSec, lightSec, deepSec, remSec;
  final double efficiency; // asleepSec / inBedSec, 0..1

  /// Breaths/min — ALWAYS null out of [SleepStager.detect]. Kept as the seam an
  /// engine that can genuinely measure respiration fills in: `OpenStrapEngine`
  /// does, with a Lomb-Scargle RSA estimator over the RAW RR intervals.
  ///
  /// This stager cannot, and no threshold here can change that. It only ever
  /// sees HR already AVERAGED INTO 30-SECOND EPOCHS. Adult respiration is 12–20
  /// breaths/min = 0.2–0.33 Hz, but a 30 s grid samples at 0.033 Hz — Nyquist
  /// 0.0167 Hz, some 15–20× BELOW the respiratory band. The modulation is
  /// aliased away by [epochSec] binning before staging ever runs.
  ///
  /// The estimator removed from here counted local maxima of that epoch series
  /// and divided by minutes: at most one peak per 2 epochs = 1.0 breaths/min,
  /// which its own `.clamp(8.0, 22.0)` then pinned to EXACTLY 8.0. It could only
  /// ever return null or a fabricated constant 8.0 — reachable on ordinary
  /// sleeping-HR wander, and pinned by test — and that 8.0 fed both the Recovery
  /// `resp` term and the resp baseline. Null is the honest answer; NoopEngine
  /// renders respiratory rate as "coming soon".
  final double? respRate;

  final int disturbances; // count of awakenings within the window
  final List<SleepSegmentK> hypnogram; // ordered, covers [startTs,endTs]
  const SleepResult({
    required this.startTs,
    required this.endTs,
    required this.inBedSec,
    required this.asleepSec,
    required this.awakeSec,
    required this.lightSec,
    required this.deepSec,
    required this.remSec,
    required this.efficiency,
    required this.respRate,
    required this.disturbances,
    required this.hypnogram,
  });
}

class SleepStager {
  SleepStager._();

  static const int epochSec = 30;

  // ── Tunables (fixed a-priori from adult sleep physiology) ────────────────
  static const int _minWindowEpochs = 240; // ~2h of epochs
  static const int _maxGapEpochs = 20; // ~10 min interruption tolerated
  static const double _hrSleepMargin = 13.0; // bpm above floor still "asleep"
  static const double _hrWakeMargin = 12.0; // bpm above baseline ≈ awake

  // ── Motion-corroborated wake (#462) ──────────────────────────────────────
  //
  // The rule upstream settled on: elevated HR ALONE is insufficient to call
  // WAKE. On a night that holds resting HR up WITHOUT the wearer getting up — a
  // supplement protocol, a fever, a hot room, alcohol — HR-led wake logic reads
  // hot-but-motionless sleep as wake: it over-calls WASO, mis-places onset, and
  // tanks efficiency. `SleepStagerV2` implements this by clamping the AWAKE
  // emission's cardiac term to <= 0 on a motion-quiescent epoch — the
  // wake-SUPPRESSING (low, flat HR) half is kept, the wake-PROMOTING half
  // dropped. BOTH of this heuristic's wake branches are cardiac-driven, so the
  // same policy here reads: a motion-quiescent epoch cannot be scored awake on
  // cardiac evidence at all. It falls through to the normal deep/REM/light
  // banding, where an elevated HR still reads REM exactly as it does upstream.
  // Wake is never invented and no pro-sleep evidence is removed, so a night
  // that actually moved stages identically.
  //
  // The floor is NIGHT-RELATIVE, mirroring V2's `jerkScale` (the night's own
  // median per-second jerk), NOT an absolute bar. [epochMovement] carries no
  // guaranteed absolute scale — it is whatever the producer's accel decode and
  // gravity removal leave behind — so a fixed threshold cannot separate
  // stillness from motion across straps, decode scales or wear positions. The
  // night's own median + MAD can.
  //
  // TWO tiers, both off that same median + MAD, so they cannot drift apart:
  //   * quiescent — "the wrist did not move": the gate for #462's rule that
  //     cardiac evidence alone may not vote wake.
  //   * excursion — "the wrist CLEARLY moved": the stronger corroboration the
  //     weak-cardiac wake branch demands (see the staging loop).
  // The dead-band between them is deliberate: an epoch that is neither plainly
  // still nor plainly moving corroborates nothing either way.
  //
  // These replace a single absolute `_moveWake = 0.12` "g" bar that was anchored
  // to nothing and was wrong in BOTH directions on the real producer's data
  // (gravity-removed, quiet-subtracted motion — ~0 at rest, ~0.3 peak across a
  // whole day): the wake branch's `mv >= _moveWake * 4` (0.48) bar NEVER fired,
  // so that branch was dead code, while the resp-rate gate's `mv <= _moveWake`
  // admitted the entire night. Night-relative tiers cannot rot like that.
  static const double _quiescentMadMult = 4.0; // within floor ± this × MAD ≈ still
  static const double _excursionMadMult = 8.0; // beyond floor + this × MAD ≈ clearly moved

  /// epochTs/epochHr/epochMovement are parallel & time-ordered over ~24h of
  /// ONE day. epochHr entries may be null (no HR that epoch).
  ///
  /// [epochMovement] is a per-epoch MOTION MAGNITUDE — NOT raw |accel|. Its only
  /// contract is "bigger = moved more"; its absolute scale is deliberately
  /// unspecified, because every consumer in here measures it night-relatively
  /// (median + MAD — see [motionQuiescent] / [motionExcursion]). That makes the
  /// stager invariant to the strap's accel decode scale, to wear position, and
  /// to whether the producer removed gravity at all. The real producer,
  /// `DailyPipeline._buildEpochs`, hands over the mean deviation from the 1 g
  /// resting magnitude with the day's quiet level subtracted, so a still wrist
  /// reads ~0 there — but nothing here may assume that.
  ///
  /// Returns null if no plausible sleep window (>= ~2h) is found.
  static SleepResult? detect({
    required List<int> epochTs,
    required List<double?> epochHr,
    required List<double> epochMovement,
    double? dayHrMin,
    List<bool>? epochAsleep,
  }) {
    final n = epochTs.length;
    if (n < _minWindowEpochs) return null;
    if (epochHr.length != n || epochMovement.length != n) return null;
    if (epochAsleep != null && epochAsleep.length != n) return null;

    // Day's low HR: caller hint, else the min observed HR (fallback 50 bpm).
    double hrFloor = dayHrMin ?? double.infinity;
    if (!hrFloor.isFinite) {
      for (final h in epochHr) {
        if (h != null && h < hrFloor) hrFloor = h;
      }
    }
    if (!hrFloor.isFinite) hrFloor = 50.0;

    // ── 1. Find the longest sleep run, tolerating short gaps.
    // GROUND-TRUTH FIRST: when the strap's own per-second sleep_state is available
    // ([epochAsleep] non-null, #175), an epoch is "sleepy" exactly when the band
    // says so — this matches WHOOP's official app and, crucially, reports NO sleep
    // window on a day the wearer never slept (an awake-but-resting stretch in bed
    // no longer gets mis-detected as a night). Only when the band gives us nothing
    // (e.g. the bundled asset) do we fall back to the HR-driven heuristic: an epoch
    // is sleepy when it HAS a heart rate that sits near the day's floor. Movement is
    // used only for within-window awake/deep/REM staging below.
    final sleepy = List<bool>.generate(n, (i) {
      if (epochAsleep != null) return epochAsleep[i];
      final h = epochHr[i];
      return h != null && h <= hrFloor + _hrSleepMargin;
    });

    final win = _longestBout(sleepy, n);
    if (win == null) return null;
    var lo = win[0], hi = win[1]; // inclusive epoch indices
    if (hi - lo + 1 < _minWindowEpochs) return null;

    // Trim leading/trailing non-sleepy epochs so the window is tightly bounded.
    while (lo < hi && !sleepy[lo]) {
      lo++;
    }
    while (hi > lo && !sleepy[hi]) {
      hi--;
    }
    if (hi - lo + 1 < _minWindowEpochs) return null;

    final startTs = epochTs[lo];
    final endTs = epochTs[hi] + epochSec;

    // Sleeping baseline HR = MEDIAN HR of sleepy epochs inside the window
    // (ryanbr #268). A handful of brief arousal/wake spikes (up to ~190 bpm)
    // pull a mean over the sleep threshold and skew the deep/REM banding — or,
    // in the strap's own detector, get a whole normal night rejected as "no
    // sleep." The spike-robust median recovers exactly those nights; on a clean
    // night the median and mean coincide, so nothing changes.
    final sleepyHr = <double>[];
    for (var i = lo; i <= hi; i++) {
      final h = epochHr[i];
      if (h != null && sleepy[i]) sleepyHr.add(h);
    }
    final baseline = sleepyHr.isNotEmpty ? _median(sleepyHr) : hrFloor;
    final winLen = hi - lo + 1;
    final deepBand = hrFloor + _hrSleepMargin * 0.5; // lowest HR band
    final remBand = baseline + 3.0; // elevated above deep, movement tiny

    // ── 2. Stage each epoch in the window.
    // Motion corroboration for the wake calls below (#462), measured against
    // THIS window's own movement so both tiers are this night's own levels.
    final windowMv = epochMovement.sublist(lo, hi + 1);
    final quiescent = motionQuiescent(windowMv);
    final excursion = motionExcursion(windowMv);
    final stages = List<SleepStageK>.filled(winLen, SleepStageK.light);
    for (var i = lo; i <= hi; i++) {
      final k = i - lo;
      final h = epochHr[i];
      final nightFrac = winLen > 1 ? k / (winLen - 1) : 0.0;
      // The wrist did not move this epoch → no cardiac evidence, however
      // elevated, may vote it awake (#462); it falls through to the bands below.
      final still = quiescent[k];
      // The wrist plainly moved this epoch. Strictly stronger than `!still`
      // (a wider gate off the same median + MAD), so `moved` implies `!still`.
      final moved = excursion[k];

      // HR-driven staging, motion-corroborated: HR picks the stage, but a wake
      // call additionally requires that the wrist actually moved. The two wake
      // branches trade the two kinds of evidence off against each other —
      // strong cardiac + any motion, or weak cardiac + unmistakable motion.
      if (h == null) {
        // A missing HR inside the window is a dropout, not a real awakening —
        // keep it light rather than fragmenting the night.
        stages[k] = SleepStageK.light;
      } else if (!still && h > baseline + _hrWakeMargin) {
        stages[k] = SleepStageK.awake;
      } else if (moved && h > baseline) {
        stages[k] = SleepStageK.awake;
      } else if (h <= deepBand && nightFrac < 0.65) {
        // Deep: lowest HR band, weighted to the first half of the night.
        stages[k] = SleepStageK.deep;
      } else if (h >= remBand && nightFrac > 0.35) {
        // REM: HR elevated over deep, later in the night.
        stages[k] = SleepStageK.rem;
      } else {
        stages[k] = SleepStageK.light;
      }
    }

    // ── 3. Merge consecutive same-stage epochs into segments (relative idx).
    final hypnogram = <SleepSegmentK>[];
    var segStartRel = 0;
    for (var k = 1; k <= winLen; k++) {
      final atEnd = k == winLen;
      if (atEnd || stages[k] != stages[k - 1]) {
        final segTs = epochTs[lo + segStartRel];
        final segEnd = atEnd ? endTs : epochTs[lo + k];
        hypnogram.add(
          SleepSegmentK(segTs, segEnd - segTs, stages[segStartRel]),
        );
        segStartRel = k;
      }
    }

    // ── 4. Totals.
    int lightSec = 0, deepSec = 0, remSec = 0, awakeSec = 0, disturbances = 0;
    for (final seg in hypnogram) {
      switch (seg.stage) {
        case SleepStageK.light:
          lightSec += seg.durationSec;
          break;
        case SleepStageK.deep:
          deepSec += seg.durationSec;
          break;
        case SleepStageK.rem:
          remSec += seg.durationSec;
          break;
        case SleepStageK.awake:
          awakeSec += seg.durationSec;
          disturbances++;
          break;
      }
    }
    final inBedSec = endTs - startTs;
    final asleepSec = lightSec + deepSec + remSec;
    final efficiency = inBedSec > 0 ? asleepSec / inBedSec : 0.0;

    // Respiratory rate is NOT emitted here, and deliberately so — the epoch grid
    // has already aliased respiration away before this line runs. See the note
    // on [SleepResult.respRate]; NoopEngine renders it "coming soon" and
    // OpenStrapEngine measures it properly off the raw RR intervals.
    const double? respRate = null;

    return SleepResult(
      startTs: startTs,
      endTs: endTs,
      inBedSec: inBedSec,
      asleepSec: asleepSec,
      awakeSec: awakeSec,
      lightSec: lightSec,
      deepSec: deepSec,
      remSec: remSec,
      efficiency: efficiency,
      respRate: respRate,
      disturbances: disturbances,
      hypnogram: hypnogram,
    );
  }

  /// Longest run of `true` in [flags], allowing runs of up to [_maxGapEpochs]
  /// consecutive `false` to be bridged. Prefers the earliest longest bout
  /// (the overnight bout in a time-ordered day). Returns [loIdx, hiInclusive].
  static List<int>? _longestBout(List<bool> flags, int n) {
    int? bestLo, bestHi;
    var i = 0;
    while (i < n) {
      if (!flags[i]) {
        i++;
        continue;
      }
      // Extend a bout, bridging short false gaps.
      var lastTrue = i;
      var j = i + 1;
      while (j < n) {
        if (flags[j]) {
          lastTrue = j;
          j++;
        } else {
          // Count the gap; abandon the bout if it exceeds tolerance.
          var gap = 0;
          while (j < n && !flags[j]) {
            gap++;
            j++;
          }
          if (gap > _maxGapEpochs || j >= n) break;
        }
      }
      final len = lastTrue - i + 1;
      if (bestLo == null || len > (bestHi! - bestLo + 1)) {
        bestLo = i;
        bestHi = lastTrue;
      }
      i = lastTrue + 1;
    }
    if (bestLo == null) return null;
    return [bestLo, bestHi!];
  }

  /// The night's OWN motion scale: each epoch's absolute deviation from the
  /// window's median movement, paired with the median of those deviations (the
  /// MAD). The median is the night's quiescent level — whatever the producer's
  /// units make that — and the MAD is the night's motion scale, so everything
  /// built on this self-calibrates to the strap and the fit instead of pinning a
  /// value that means different things on different nights.
  static (List<double>, double) _motionScale(List<double> windowMovement) {
    final floor = _median(windowMovement);
    final dev = <double>[for (final m in windowMovement) (m - floor).abs()];
    return (dev, _median(dev));
  }

  /// Per-epoch "the wrist did not move this epoch" verdicts over ONE night's
  /// movement trace (motion-corroborated wake, #462). [windowMovement] is the
  /// sleep window's per-epoch motion magnitude, in order (see [detect] for the
  /// contract — the absolute scale is irrelevant here by construction).
  ///
  /// An epoch is quiescent when its movement sits within [_quiescentMadMult]
  /// median-absolute-deviations of the window's OWN median movement — the
  /// night-relative analogue of V2's `jerkMax <= jerkScale * jerkFloorGateMult`.
  /// The multiplier sits well above 1 because the MAD is by construction the
  /// deviation half the epochs already exceed; at 4 MADs a still night's sensor
  /// noise stays quiescent while a real excursion does not.
  ///
  /// A trace with a zero MAD (every epoch at the same coarsely-quantised value)
  /// admits only epochs exactly at the floor, so the verdict degrades toward the
  /// strict pre-corroboration behaviour rather than waving wake through.
  /// Pure + deterministic.
  static List<bool> motionQuiescent(List<double> windowMovement) {
    if (windowMovement.isEmpty) return const <bool>[];
    final (dev, mad) = _motionScale(windowMovement);
    final gate = mad * _quiescentMadMult;
    return <bool>[for (final d in dev) d <= gate];
  }

  /// Per-epoch "the wrist CLEARLY moved this epoch" verdicts over ONE night's
  /// movement trace — the strong-motion tier the weak-cardiac wake branch needs
  /// (#462). Same night-relative median + MAD as [motionQuiescent], just a wider
  /// gate ([_excursionMadMult]), so the two tiers can never contradict: an
  /// excursion is always non-quiescent.
  ///
  /// A zero-MAD trace has NO motion scale to measure an excursion against, so
  /// nothing qualifies. That is the fail-safe direction here: this tier can only
  /// ever ADD wake, so a degenerate trace must promote nothing rather than
  /// promote every off-floor epoch. (Note this is the opposite branch of the
  /// same coin as [motionQuiescent]'s zero-MAD case, which stays strict — both
  /// degrade AWAY from inventing sleep-state changes.)
  /// Pure + deterministic.
  static List<bool> motionExcursion(List<double> windowMovement) {
    if (windowMovement.isEmpty) return const <bool>[];
    final (dev, mad) = _motionScale(windowMovement);
    if (mad <= 0) return List<bool>.filled(windowMovement.length, false);
    final gate = mad * _excursionMadMult;
    return <bool>[for (final d in dev) d > gate];
  }

  /// Median of a non-empty list (spike-robust central tendency).
  static double _median(List<double> xs) {
    final s = List<double>.from(xs)..sort();
    final n = s.length;
    if (n == 0) return 0;
    return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2.0;
  }
}
