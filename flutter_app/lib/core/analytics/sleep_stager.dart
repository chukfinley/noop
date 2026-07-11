// Simplified heuristic sleep-staging module.
//
// A deliberately small, self-contained Dart port of the intent behind the
// Kotlin `SleepStager` / `SleepStagerV2` recipes (per-night HR + movement →
// wake/light/deep/rem). This is a clean heuristic, NOT the full z-scored,
// DFT-per-epoch, Viterbi implementation — it trades accuracy for ~250 lines.
//
// Pure Dart, only `dart:math`. Deterministic: no randomness, no clock reads.

import 'dart:math' as math;

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
  final double? respRate; // breaths/min estimate, or null
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
  static const double _moveWake = 0.12; // above this ≈ awake movement
  static const int _maxGapEpochs = 20; // ~10 min interruption tolerated
  static const double _hrSleepMargin = 13.0; // bpm above floor still "asleep"
  static const double _hrWakeMargin = 12.0; // bpm above baseline ≈ awake

  /// epochTs/epochHr/epochMovement are parallel & time-ordered over ~24h of
  /// ONE day. epochHr entries may be null (no HR that epoch). epochMovement is
  /// |accel| in g. Returns null if no plausible sleep window (>= ~2h) is found.
  static SleepResult? detect({
    required List<int> epochTs,
    required List<double?> epochHr,
    required List<double> epochMovement,
    double? dayHrMin,
  }) {
    final n = epochTs.length;
    if (n < _minWindowEpochs) return null;
    if (epochHr.length != n || epochMovement.length != n) return null;

    // Day's low HR: caller hint, else the min observed HR (fallback 50 bpm).
    double hrFloor = dayHrMin ?? double.infinity;
    if (!hrFloor.isFinite) {
      for (final h in epochHr) {
        if (h != null && h < hrFloor) hrFloor = h;
      }
    }
    if (!hrFloor.isFinite) hrFloor = 50.0;

    // ── 1. Find the longest low-HR run, tolerating short gaps.
    // HR is the trustworthy sleep signal on this strap (the accel scalar is too
    // noisy to threshold absolutely), so the window is HR-driven: an epoch is
    // "sleepy" when it HAS a heart rate and that rate sits near the day's floor.
    // Movement is used only for within-window awake/deep/REM staging below.
    final sleepy = List<bool>.generate(n, (i) {
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

    // Sleeping baseline HR = mean HR of sleepy epochs inside the window.
    double hrSum = 0;
    int hrCnt = 0;
    for (var i = lo; i <= hi; i++) {
      final h = epochHr[i];
      if (h != null && sleepy[i]) {
        hrSum += h;
        hrCnt++;
      }
    }
    final baseline = hrCnt > 0 ? hrSum / hrCnt : hrFloor;
    final winLen = hi - lo + 1;
    final deepBand = hrFloor + _hrSleepMargin * 0.5; // lowest HR band
    final remBand = baseline + 3.0; // elevated above deep, movement tiny

    // ── 2. Stage each epoch in the window.
    final stages = List<SleepStageK>.filled(winLen, SleepStageK.light);
    for (var i = lo; i <= hi; i++) {
      final k = i - lo;
      final h = epochHr[i];
      final mv = epochMovement[i];
      final nightFrac = winLen > 1 ? k / (winLen - 1) : 0.0;

      // HR-driven staging (the accel scalar is too noisy to gate on here; it is
      // used only as a strong corroborating signal for awakenings).
      if (h == null || h > baseline + _hrWakeMargin) {
        // A missing HR inside the window is a dropout, not a real awakening —
        // keep it light rather than fragmenting the night.
        stages[k] = h == null ? SleepStageK.light : SleepStageK.awake;
      } else if (mv >= _moveWake * 4 && h > baseline) {
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

    final respRate = _estimateRespRate(epochHr, epochMovement, lo, hi);

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

  /// Crude respiratory-rate proxy: count up/down cycles of the smoothed
  /// in-sleep HR (a respiratory-sinus-arrhythmia stand-in) per minute, then
  /// clamp to a healthy-adult band. Returns null if HR is too sparse.
  static double? _estimateRespRate(
    List<double?> epochHr,
    List<double> epochMovement,
    int lo,
    int hi,
  ) {
    // Gather in-sleep HR (skip high-movement epochs), require dense coverage.
    final hr = <double>[];
    for (var i = lo; i <= hi; i++) {
      final h = epochHr[i];
      if (h != null && epochMovement[i] <= _moveWake) hr.add(h);
    }
    final span = hi - lo + 1;
    if (hr.length < 20 || hr.length < span * 0.4) return null;

    // 3-tap moving-average smooth to suppress single-epoch noise.
    final sm = List<double>.filled(hr.length, 0);
    for (var i = 0; i < hr.length; i++) {
      final a = hr[i == 0 ? 0 : i - 1];
      final b = hr[i];
      final c = hr[i == hr.length - 1 ? i : i + 1];
      sm[i] = (a + b + c) / 3.0;
    }

    // Count local maxima (one per oscillation cycle) with a small hysteresis.
    var peaks = 0;
    var rising = false;
    final amp = _std(sm);
    final minDelta = math.max(0.3, amp * 0.25); // ignore flat wiggle
    for (var i = 1; i < sm.length; i++) {
      final d = sm[i] - sm[i - 1];
      if (d > minDelta) {
        rising = true;
      } else if (d < -minDelta && rising) {
        peaks++;
        rising = false;
      }
    }
    if (peaks < 3) return null;

    final minutes = (hr.length * epochSec) / 60.0;
    if (minutes <= 0) return null;
    final rate = peaks / minutes;
    return rate.clamp(8.0, 22.0).toDouble();
  }

  static double _std(List<double> xs) {
    if (xs.length < 2) return 0;
    var mean = 0.0;
    for (final x in xs) {
      mean += x;
    }
    mean /= xs.length;
    var v = 0.0;
    for (final x in xs) {
      final d = x - mean;
      v += d * d;
    }
    v /= xs.length;
    return math.sqrt(v);
  }
}
