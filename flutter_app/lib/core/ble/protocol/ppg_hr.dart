/// Faithful Dart port of `PpgHr.kt`.
///
/// Derive heart rate from the WHOOP 5.0/MG **v26** optical PPG waveform (#156).
///
/// The strap's type-47 **layout v26** record is a 24 Hz PPG buffer — NOT a per-second biometric
/// summary like v18: **24 little-endian i16 samples at frame bytes [27:75]**, one record per second,
/// with the record's own unix u32 LE @15 (the same slot v18 uses). WHOOP does NOT store a per-second
/// HR in v26 — HR is PPG-derived on-device — so to recover HR we re-derive it here from the waveform,
/// **byte-for-byte mirroring the Swift estimator** (WhoopProtocol/PpgHr.swift) so macOS, iOS and
/// Android produce the SAME per-second HR from the same offload.
///
/// Algorithm (kept in lockstep with the Swift lane — #219 parity audit):
///   • Records are grouped into **consecutive-second runs** (PPG phase is only continuous within a
///     run); a window of the seconds present in `t-half … t+half` (half = WINDOW_SECONDS/2) is
///     autocorrelated, one estimate per second whose centred window holds ≥ 3 seconds.
///   • Per window: **linear least-squares detrend** (removes DC *and* baseline wander), then
///     normalised autocorrelation over the lag band that maps to **30…220 bpm**.
///   • **Fundamental-period preference**: pick the smallest-lag local maximum that is ≥ 0.85× the
///     global peak, so the harmonic peaks at 2×/3× the true period don't report half/third the rate.
///   • Emit only when the global peak clears **0.3**.
///   • bpm = 60·fs/lag, rounded to whole; the estimate's timestamp is the window's CENTRE second.
///
/// Pure + side-effect-free so it is unit-testable on synthetic signals (see PpgHrTest).
class PpgHr {
  PpgHr._();

  /// PPG sample rate of the v26 waveform (Hz).
  static const int sampleRateHz = 24;

  /// HR estimation window length in seconds (centred half-window = WINDOW_SECONDS/2 each side).
  static const int windowSeconds = 8;

  /// Physiological HR search bounds (bpm).
  static const double minBpm = 30.0;
  static const double maxBpm = 220.0;

  /// Minimum normalised-autocorrelation peak to emit an estimate.
  static const double minConfidence = 0.3;

  /// Per-second PPG-HR over the concatenated [samples] (mirror of Swift `derivePpgHr`).
  ///
  /// [samples] carry one [PpgSample.ts] per strap-second (all 24 samples of a record share it). They
  /// may be unsorted or contain gaps: records are grouped by second (last write wins on a duplicate
  /// ts), split into consecutive-second runs, and a centred window is autocorrelated for each second.
  /// Returns one [PpgEstimate] per second that yielded a confident estimate, ascending by ts.
  static List<PpgEstimate> estimate(List<PpgSample> samples) {
    if (samples.isEmpty) return <PpgEstimate>[];
    // One waveform per second, in first-seen sample order (last record wins on a duplicate ts).
    // A Dart map literal preserves insertion order (LinkedHashMap), matching the Kotlin.
    final secs = <int, List<int>>{};
    for (final s in samples) {
      final list = secs.putIfAbsent(s.ts, () => <int>[]);
      list.add(s.value);
    }
    final order = secs.keys.toList()..sort();

    // Split into consecutive-second runs.
    final runs = <List<int>>[];
    var cur = <int>[order[0]];
    for (var i = 1; i < order.length; i++) {
      final u = order[i];
      if (u - cur.last == 1) {
        cur.add(u);
      } else {
        runs.add(cur);
        cur = <int>[u];
      }
    }
    runs.add(cur);

    final half = windowSeconds ~/ 2;
    final out = <PpgEstimate>[];
    for (final run in runs) {
      if (run.length < 3) continue;
      final runSet = run.toSet();
      for (final t in run) {
        // Window of consecutive seconds present in this run, centred on t.
        final win = <int>[];
        var u = t - half;
        while (u <= t + half) {
          if (runSet.contains(u)) win.add(u);
          u++;
        }
        if (win.length < 3) continue;
        var total = 0;
        for (final w in win) {
          total += secs[w]!.length;
        }
        final sig = List<double>.filled(total, 0.0);
        var idx = 0;
        for (final w in win) {
          for (final v in secs[w]!) {
            sig[idx++] = v.toDouble();
          }
        }
        final est = _estimateWindow(sig, t);
        if (est != null) out.add(est);
      }
    }
    out.sort((a, b) => a.ts.compareTo(b.ts));
    return out;
  }

  /// Linear-detrend a waveform: subtract the least-squares best-fit line to remove DC + baseline
  /// wander (slow respiration/perfusion drift) before the autocorrelation, so the pulse dominates.
  /// Mirror of Swift `PpgHr.detrend`.
  static List<double> _detrend(List<double> x) {
    final n = x.length;
    if (n <= 1) return List<double>.filled(n, 0.0); // 0 for all (matches Swift's x.map { 0 })
    final nD = n.toDouble();
    final sumI = nD * (nD - 1) / 2;
    final sumI2 = (nD - 1) * nD * (2 * nD - 1) / 6;
    var sumY = 0.0;
    var sumIY = 0.0;
    for (var i = 0; i < n; i++) {
      sumY += x[i];
      sumIY += i.toDouble() * x[i];
    }
    final denom = nD * sumI2 - sumI * sumI;
    if (denom == 0.0) {
      final mean = sumY / nD;
      return List<double>.generate(n, (it) => x[it] - mean);
    }
    final slope = (nD * sumIY - sumI * sumY) / denom;
    final intercept = (sumY - slope * sumI) / nD;
    return List<double>.generate(n, (it) => x[it] - (slope * it.toDouble() + intercept));
  }

  /// Normalised autocorrelation of [x] at [lag] (0 when the signal is flat). Mirror of Swift `acf`.
  static double _acf(List<double> x, int lag) {
    final n = x.length - lag;
    if (n <= 0) return 0.0;
    var mean = 0.0;
    for (final v in x) {
      mean += v;
    }
    mean /= x.length;
    var den = 0.0;
    for (final v in x) {
      final d = v - mean;
      den += d * d;
    }
    if (den == 0.0) return 0.0;
    var num = 0.0;
    for (var i = 0; i < n; i++) {
      num += (x[i] - mean) * (x[i + lag] - mean);
    }
    return num / den;
  }

  /// Subtract the record-synchronous (period = fs) component — the artifact a per-record DC step /
  /// phase reset injects, which autocorrelates at lag = fs (60 bpm) and would SNAP a sub-60-bpm
  /// sleeper to 60 via the fundamental-period preference (#194, ryanbr). A true ~60-bpm pulse is also
  /// period-fs, so we only de-artifact when the record BOUNDARY is discontinuous (the artifact's
  /// signature) — a real pulse flows smoothly across it and is left untouched, preserving a true
  /// 60 bpm. Mirror of the Swift PpgHr.removeRecordRateComponent.
  static List<double> _removeRecordRateComponent(List<double> x, int fs) {
    final n = x.length;
    if (fs <= 1 || n < fs * 4) return x;
    var withinSum = 0.0;
    var withinCount = 0;
    var boundarySum = 0.0;
    var boundaryCount = 0;
    for (var i = 1; i < n; i++) {
      final d = (x[i] - x[i - 1]).abs();
      if (i % fs == 0) {
        boundarySum += d;
        boundaryCount++;
      } else {
        withinSum += d;
        withinCount++;
      }
    }
    if (withinCount == 0 || boundaryCount == 0) return x;
    final within = withinSum / withinCount;
    final boundary = boundarySum / boundaryCount;
    if (within <= 0.0 || boundary <= within * 3) return x; // smooth → real pulse → leave it
    final colSum = List<double>.filled(fs, 0.0);
    final colCount = List<int>.filled(fs, 0);
    for (var i = 0; i < n; i++) {
      final p = i % fs;
      colSum[p] += x[i];
      colCount[p]++;
    }
    final colMean =
        List<double>.generate(fs, (p) => colCount[p] > 0 ? colSum[p] / colCount[p] : 0.0);
    return List<double>.generate(n, (i) => x[i] - colMean[i % fs]);
  }

  /// Estimate HR for one window via linear detrend + normalised autocorrelation with
  /// fundamental-period preference. Returns null when the window is too short (< 3 s), flat, or no
  /// lag clears [minConfidence]. Mirror of Swift `PpgHr.estimate` wrapped with the centre [ts].
  ///
  /// Lag band: a faster HR is a SHORTER lag, so [maxBpm] → loLag and [minBpm] → hiLag. Bounds use
  /// round-to-nearest and clamp to [2, n-2] exactly as Swift does.
  static PpgEstimate? _estimateWindow(List<double> values, int ts) {
    if (values.length < sampleRateHz * 3) return null; // need >= 3 s to resolve a low HR
    // De-artifact (#194) THEN detrend, so the autocorrelation sees the pulse, not a record-rate comb.
    final x = _detrend(_removeRecordRateComponent(values, sampleRateHz));
    final fsD = sampleRateHz.toDouble();
    final loLag = _max2(2, (fsD * 60 / maxBpm).round());
    final hiLag = _min2(x.length - 2, (fsD * 60 / minBpm).round());
    if (hiLag <= loLag) return null;

    final vals = <int, double>{};
    var peak = double.negativeInfinity;
    for (var lag = loLag; lag <= hiLag; lag++) {
      final v = _acf(x, lag);
      vals[lag] = v;
      if (v > peak) peak = v;
    }
    if (peak < minConfidence) return null;

    // Prefer the FUNDAMENTAL period: the smallest-lag local maximum that is nearly as strong as
    // the global peak. Autocorrelation also peaks at 2×/3× the true period (half/third HR); the
    // global max there would report half the real rate, so prefer the shortest prominent period.
    var bestLag = -1;
    if (loLag + 1 <= hiLag - 1) {
      for (var lag = loLag + 1; lag <= hiLag - 1; lag++) {
        final v = vals[lag]!;
        if (v >= 0.85 * peak && v >= vals[lag - 1]! && v >= vals[lag + 1]!) {
          bestLag = lag;
          break;
        }
      }
    }
    if (bestLag < 0) {
      // Fallback: global argmax, smallest lag wins a tie (deterministic).
      var argmax = loLag;
      var best = vals[loLag]!;
      for (var lag = loLag + 1; lag <= hiLag; lag++) {
        final v = vals[lag]!;
        if (v > best) {
          best = v;
          argmax = lag;
        }
      }
      bestLag = argmax;
    }

    // Round to whole bpm (the lag is integer, so sub-bpm precision isn't real signal) and round
    // conf to 3 dp — both matching the Swift estimator and the measured-HR Int domain (#219).
    final bpm = (fsD * 60 / bestLag).round();
    final conf = (vals[bestLag]! * 1000).round() / 1000.0;
    return PpgEstimate(ts: ts, bpm: bpm, conf: conf);
  }

  static int _max2(int a, int b) => a >= b ? a : b;
  static int _min2(int a, int b) => a <= b ? a : b;
}

/// One concatenated, time-ordered PPG sample: its wall-clock second [ts] and raw ADC [value].
/// Built from contiguous v26 records (each record contributes 24 samples spanning one second).
/// Dart port of the Kotlin nested `PpgHr.Sample`.
class PpgSample {
  final int ts;
  final int value;

  const PpgSample({required this.ts, required this.value});

  @override
  bool operator ==(Object other) =>
      other is PpgSample && other.ts == ts && other.value == value;

  @override
  int get hashCode => Object.hash(ts, value);

  @override
  String toString() => 'PpgSample(ts: $ts, value: $value)';
}

/// A derived HR estimate: [ts] = window-centre second, [bpm], [conf] in 0…1.
/// Dart port of the Kotlin nested `PpgHr.Estimate`.
class PpgEstimate {
  final int ts;
  final int bpm;
  final double conf;

  const PpgEstimate({required this.ts, required this.bpm, required this.conf});

  @override
  bool operator ==(Object other) =>
      other is PpgEstimate && other.ts == ts && other.bpm == bpm && other.conf == conf;

  @override
  int get hashCode => Object.hash(ts, bpm, conf);

  @override
  String toString() => 'PpgEstimate(ts: $ts, bpm: $bpm, conf: $conf)';
}
