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

  static const configs = <String, MetricConfig>{
    'hrv': MetricConfig(5, 250, 5),
    'resting_hr': MetricConfig(30, 120, 2),
    'resp': MetricConfig(4, 40, 0.5),
    'skin_temp': MetricConfig(20, 42, 0.3),
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
}
