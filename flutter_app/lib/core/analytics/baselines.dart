import 'dart:math' as math;

/// Personal-baseline calibration status. Mirrors BaselineState.status.
enum BaselineStatus { calibrating, provisional, trusted, stale }

/// Valid nights a baseline needs before it is `usable` (leaves `calibrating`).
/// The recovery model is HRV-baseline-dominant, so until the HRV baseline clears
/// this the app reports a "calibrating N/needed nights" state instead of a score.
const int baselineProvisionalMinNights = 4;

/// A per-metric rolling baseline: an EWMA centre + EWMA absolute-deviation spread.
/// Faithful port of `Baselines` (winsorized EWMA path).
class BaselineState {
  double baseline;
  double spread; // EWMA abs-dev; ×1.253 ≈ σ
  int nValid;
  int nightsSinceUpdate;
  BaselineStatus status;

  BaselineState({
    this.baseline = 0,
    this.spread = 0,
    this.nValid = 0,
    this.nightsSinceUpdate = 0,
    this.status = BaselineStatus.calibrating,
  });

  bool get usable =>
      status == BaselineStatus.provisional || status == BaselineStatus.trusted;
}

/// Per-metric winsorizing config.
class MetricConfig {
  final double minVal, maxVal, floorSpread;
  const MetricConfig(this.minVal, this.maxVal, this.floorSpread);
}

class Baselines {
  Baselines._();

  /// Default per-metric configurations (HRV, resting HR, respiration, skin temp, daily
  /// Effort/strain).
  ///
  /// `'strain'` backs the [ChargeTerms] Activity-Balance / previous-day-Effort Charge term
  /// (#436): bounds match [StrainScorer.maxStrain]'s 0–100 output scale, and `floorSpread` is
  /// deliberately WIDER than the physiological metrics (5.0 vs ~1–2% of range elsewhere) because
  /// day-to-day training load is EXPECTED to swing hard — a rest day vs a hard day is a normal,
  /// large delta — and a tight floor would make the z-score hypersensitive to routine training
  /// variation. It shares the other metrics' half-lives, which in this port are the file-level
  /// `_centerHalfLife`/`_spreadHalfLife` constants rather than per-metric fields (upstream carries
  /// `halfLifeB`/`halfLifeS` on every `MetricCfg` and sets them to the same 14/21 for all five, so
  /// the two shapes agree).
  ///
  /// Registering `'strain'` is INERT for the existing metrics: every consumer of this map is a
  /// lookup-by-key ([update] takes the metric name), never an enumeration, so no other metric's
  /// fold changes. Nothing scores against it until a caller supplies a previous-day Effort — see
  /// [ChargeTerms.activityBalanceTerm].
  static const configs = <String, MetricConfig>{
    'hrv': MetricConfig(5, 250, 5),
    'resting_hr': MetricConfig(30, 120, 2),
    'resp': MetricConfig(4, 40, 0.5),
    'skin_temp': MetricConfig(20, 42, 0.3),
    'strain': MetricConfig(0, 100, 5),
  };

  static const _centerHalfLife = 14.0;
  static const _spreadHalfLife = 21.0;
  static const _earlyAdaptNights = 8;
  static const _youngCenterHalfLife = 3.0;

  static double _lambda(double halfLife) => 1 - math.pow(0.5, 1 / halfLife).toDouble();

  /// Fold one nightly value into the state (in place).
  static void update(BaselineState s, String metric, double? value) {
    final cfg = configs[metric] ?? const MetricConfig(0, 1e9, 0.1);
    if (value == null || value < cfg.minVal || value > cfg.maxVal) {
      s.nightsSinceUpdate++;
      if (s.nValid >= 14 && s.nightsSinceUpdate > 14) s.status = BaselineStatus.stale;
      return;
    }
    if (s.nValid == 0) {
      s.baseline = value;
      s.spread = cfg.floorSpread;
      s.nValid = 1;
      s.nightsSinceUpdate = 0;
      s.status = BaselineStatus.calibrating;
      return;
    }

    final young = s.nValid < _earlyAdaptNights;
    final centerHl = young ? _youngCenterHalfLife : _centerHalfLife;
    final lambda = _lambda(centerHl);
    final lambdaS = _lambda(_spreadHalfLife);
    final band = young ? 2.5 : 1.0;

    // Outlier gate (suspended in young phase).
    if (!young && (value - s.baseline).abs() > 5 * s.spread) {
      s.nValid++; // seen, not folded
      s.nightsSinceUpdate = 0;
      return;
    }

    final lo = s.baseline - 3 * s.spread * band;
    final hi = s.baseline + 3 * s.spread * band;
    final clamped = value.clamp(lo, hi);
    s.baseline = lambda * clamped + (1 - lambda) * s.baseline;
    s.spread = math.max(
        cfg.floorSpread, lambdaS * (value - s.baseline).abs() + (1 - lambdaS) * s.spread);
    s.nValid++;
    s.nightsSinceUpdate = 0;

    if (s.nValid < baselineProvisionalMinNights) {
      s.status = BaselineStatus.calibrating;
    } else if (s.nValid < 14) {
      s.status = BaselineStatus.provisional;
    } else {
      s.status = BaselineStatus.trusted;
    }
  }

  /// z = (value - baseline) / max(1.253×spread, 1e-9). Mirrors the deviation helper.
  static double zScore(double value, BaselineState s) =>
      (value - s.baseline) / math.max(1.253 * s.spread, 1e-9);

  static double zScoreRaw(double value, double mean, double spread) =>
      (value - mean) / math.max(1.253 * spread, 1e-9);

  // ── Device-era boundary (upstream #459 / #470) ─────────────────────────────

  /// Coarse HRV-scale brand for a source id (#459). Every WHOOP-origin id shares ONE scale; each
  /// wearable-export brand is its own. Unknown ids bucket to `'whoop'` (the strap source and its
  /// Apple/Health-Connect riders), so only a positively-identified wearable export changes the era.
  /// Faithful twin of the Kotlin/Swift `brandBucket`.
  ///
  /// Deliberately NOT a per-strap identity: WHOOP 4 vs 5, the canonical import id, the active strap
  /// and the `-noop` computed sibling all report RMSSD on the SAME scale, so a strap-to-strap swap
  /// must NOT open an era boundary — only a genuine brand change does. `startsWith` catches both the
  /// export id (`oura-import`) and a cloud id (`oura-api`), so an Oura-cloud era and an Oura-export
  /// era read as one brand.
  static String brandBucket(String sourceId) {
    if (sourceId.startsWith('oura')) return 'oura';
    if (sourceId.startsWith('fitbit')) return 'fitbit';
    if (sourceId.startsWith('garmin')) return 'garmin';
    // 'apple-health' / 'health-connect' fall through to 'whoop' ON PURPOSE: their daily rows ride the
    // strap source's scale, and Health Connect is a pass-through whose true origin is unknowable, so
    // they must NOT open a false era boundary against WHOOP nights.
    return 'whoop';
  }

  /// The recalibration epoch (unix SECONDS, UTC start-of-day) at the LATEST device-era boundary in a
  /// source-tagged nightly history, so a baseline can't mix two brands' incompatible HRV scales
  /// (#459: an Oura→WHOOP switch has Oura RMSSD ~120–155 ms vs WHOOP ~72–112 ms with no overlap
  /// nights, so a straddling window reads the first WHOOP nights as "suppressed" against an
  /// Oura-inflated mean — a device artifact, not physiology).
  ///
  /// DORMANT BY DESIGN, exactly as upstream #470 landed it: this is the vetted primitive, with no
  /// consumer wired. Upstream's own re-review found the obvious wiring is WRONG — the import-scoring
  /// fold re-homes a wearable day's HRV under the WHOOP computed id, destroying the brand before the
  /// merged series any consumer reads, so the epoch must be computed in the engine from the ORIGINAL
  /// per-source reads and threaded to each consumer. The recovery/Charge fold reads WHOOP-native
  /// sources only, so gating it here would be a no-op. See the report on #459 for the follow-up.
  ///
  /// CONTRACT: [sourceDays] is exactly ONE [SourceDay] per night — the day's WINNING source (the same
  /// per-day merge winner whose value the fold uses), NOT one row per source. The current era is read
  /// off the NEWEST day's brand, so an overlap day carrying two brands would, under the deterministic
  /// (day, sourceId) sort, let the lexically-later source (`oura-import` > `my-whoop`) masquerade as
  /// the current brand. Passing one-per-day-winner makes that impossible; the same-day tie handling is
  /// a determinism backstop, not a licence to pass raw multi-source rows. Any order is fine (sorted
  /// here).
  ///
  /// The epoch is the start of the first day of the LATEST contiguous single-brand era: walk
  /// newest→oldest while the brand matches the newest night's brand, and return that run's first day's
  /// start. A lone off-brand day inside the current era truncates it — fail-safe: it drops MORE
  /// history, never mixes scales. Returns 0 (no recalibration → an identical fold) when the whole
  /// history is ONE brand, so a single-device user — i.e. every user of this app today, which has no
  /// non-WHOOP importer — is completely unaffected.
  static int deviceEraEpoch(List<SourceDay> sourceDays) {
    if (sourceDays.isEmpty) return 0;
    // Total order by (day, sourceId) — a same-day mixed-brand row (an overlap night) must break the
    // tie IDENTICALLY to the Kotlin/Swift twins, so the computed epoch can never diverge by platform.
    final sorted = List<SourceDay>.of(sourceDays)
      ..sort((a, b) =>
          a.day != b.day ? a.day.compareTo(b.day) : a.sourceId.compareTo(b.sourceId));
    final currentBrand = brandBucket(sorted.last.sourceId);
    // No brand change anywhere → no epoch (an identical fold for every single-brand user).
    if (!sorted.any((e) => brandBucket(e.sourceId) != currentBrand)) return 0;
    // Walk back over the contiguous current-brand suffix; its first day opens the current era.
    var eraStartDay = sorted.last.day;
    for (final e in sorted.reversed) {
      if (brandBucket(e.sourceId) != currentBrand) break;
      eraStartDay = e.day;
    }
    return dayStartEpochUtc(eraStartDay);
  }

  /// Unix seconds at the UTC start of a `"yyyy-MM-dd"` [dayKey], or 0 when it is not exactly that.
  ///
  /// STRICT on purpose: `DateTime.tryParse` silently rolls a nonsense key over (`2026-13-45` →
  /// 2027-02-14) where the Kotlin/Swift twins' strict formatters return null → 0. The round-trip
  /// check below rejects any key the parser had to normalise, keeping all three platforms in step.
  static int dayStartEpochUtc(String dayKey) {
    if (!_dayKeyPattern.hasMatch(dayKey)) return 0;
    final parsed = DateTime.tryParse('${dayKey}T00:00:00Z');
    if (parsed == null) return 0;
    final y = parsed.year.toString().padLeft(4, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    if ('$y-$m-$d' != dayKey) return 0; // parser normalised it → not a real date
    return parsed.millisecondsSinceEpoch ~/ 1000;
  }

  static final RegExp _dayKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
}

/// One night's WINNING source — the input row of [Baselines.deviceEraEpoch] (#459).
class SourceDay {
  /// Local day key, `"yyyy-MM-dd"` (fixed-width, so it sorts lexically in date order).
  final String day;

  /// The id of the source that produced this night, e.g. `'my-whoop'`, `'oura-import'`.
  final String sourceId;

  const SourceDay(this.day, this.sourceId);
}
