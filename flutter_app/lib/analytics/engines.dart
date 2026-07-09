import 'dart:math' as math;
import 'baselines.dart';

/// Faithful Dart ports of the NOOP scoring engines. Each function mirrors the
/// Kotlin algorithm named in its doc comment — same constants, same shape.
/// (Heavy raw-sample pipelines / sync stay native; these are the pure scorers.)

/// Max HR — Tanaka `208 - 0.7*age`, or a manual override.
double hrMax(int age, {int? override}) =>
    override?.toDouble() ?? (208 - 0.7 * age);

// ── Recovery / "Charge" (0..100) — RecoveryScorer.recovery ────────────────
class RecoveryInput {
  final double hrv; // RMSSD ms
  final double rhr; // bpm
  final double? resp; // rpm
  final double? sleepPerf01; // Rest/100 or efficiency 0..1
  final double? skinTempDevC; // ±°C
  const RecoveryInput({
    required this.hrv,
    required this.rhr,
    this.resp,
    this.sleepPerf01,
    this.skinTempDevC,
  });
}

const _wHRV = 0.55, _wRHR = 0.20, _wResp = 0.05, _wSleep = 0.15, _wSkin = 0.05;
const recoveryPopulationMean = 58.0;

/// Returns null on cold-start (HRV baseline not usable).
double? recoveryScore(
  RecoveryInput i,
  BaselineState hrvBase,
  BaselineState rhrBase,
  BaselineState respBase,
) {
  if (!hrvBase.usable) return null;

  double zSum = 0, wSum = 0;

  final zHrv = Baselines.zScore(i.hrv, hrvBase);
  zSum += zHrv * _wHRV;
  wSum += _wHRV;

  // Lower RHR better → args swapped.
  final zRhr = Baselines.zScoreRaw(rhrBase.baseline, i.rhr, rhrBase.spread);
  zSum += zRhr * _wRHR;
  wSum += _wRHR;

  if (i.resp != null && respBase.usable) {
    final zResp = Baselines.zScoreRaw(respBase.baseline, i.resp!, respBase.spread);
    zSum += zResp * _wResp;
    wSum += _wResp;
  }
  if (i.sleepPerf01 != null) {
    final zSleep = (i.sleepPerf01! - 0.85) / 0.12;
    zSum += zSleep * _wSleep;
    wSum += _wSleep;
  }
  if (i.skinTempDevC != null) {
    final zSkin = -(i.skinTempDevC!.abs()) / 1.0;
    zSum += zSkin * _wSkin;
    wSum += _wSkin;
  }

  if (wSum <= 0) return null;
  final z = zSum / wSum;
  final score = 100 / (1 + math.exp(-1.6 * (z - (-0.20))));
  return score.clamp(0, 100);
}

// ── Strain / "Effort" (0..100) — StrainScorer.strain (Edwards TRIMP) ───────
const strainDenominator = 7201.0;

/// Edwards zone weight by %HRR.
int _edwardsWeight(double pctHrr) {
  if (pctHrr >= 90) return 5;
  if (pctHrr >= 80) return 4;
  if (pctHrr >= 70) return 3;
  if (pctHrr >= 60) return 2;
  if (pctHrr >= 50) return 1;
  return 0;
}

/// Compute Effort (0..100) from HR samples. [times] in unix seconds.
/// Returns null if the sample gate fails.
double? strainScore({
  required List<double> bpm,
  required List<double> times,
  required int age,
  required double restingHr,
  int? hrMaxOverride,
}) {
  final n = bpm.length;
  if (n < 2) return null;
  final span = times.last - times.first;
  final gateOk = n >= 600 || (n >= 20 && span >= 600);
  if (!gateOk) return null;

  final maxHr = hrMax(age, override: hrMaxOverride);
  final hrr = maxHr - restingHr;
  if (hrr <= 0) return null;

  double trimp = 0;
  for (var i = 0; i < n; i++) {
    final durMin = i < n - 1 ? (times[i + 1] - times[i]) / 60.0 : 1 / 60.0;
    final pctHrr = (((bpm[i] - restingHr) / hrr) * 100).clamp(0, 100).toDouble();
    trimp += _edwardsWeight(pctHrr) * durMin;
  }
  if (trimp <= 0) return 0;
  final effort = 100 * math.log(trimp + 1) / math.log(strainDenominator);
  return double.parse(effort.toStringAsFixed(2));
}

// ── Rest / Sleep performance (0..100) — RestScorer.rest ────────────────────
double? restScore({
  required double asleepSec,
  required double needSec,
  required double efficiency01,
  required double deepSec,
  required double remSec,
  double? consistency01,
}) {
  if (asleepSec <= 0) return null;
  final duration = math.min(100, asleepSec / needSec * 100);
  final efficiency = (efficiency01 * 100).clamp(0, 100).toDouble();

  final restorativeShare = (deepSec + remSec) / asleepSec;
  final deepAdequacy = ((deepSec / asleepSec) / 0.13).clamp(0, 1).toDouble();
  final deepFactor = 0.5 + 0.5 * deepAdequacy;
  final restorative = math.min(100, restorativeShare / 0.50 * 100) * deepFactor;

  final consistency = ((consistency01 ?? 0.5) * 100).clamp(0, 100).toDouble();

  final rest =
      0.50 * duration + 0.20 * efficiency + 0.20 * restorative + 0.10 * consistency;
  return double.parse(rest.toStringAsFixed(2));
}

// ── Stress (0..3) — StressModel.build ──────────────────────────────────────
/// baseline means/SDs from a trailing window ending the day before.
double stressScore({
  required double todayRhr,
  required double meanRhr,
  required double sdRhr,
  required double todayHrv,
  required double meanHrv,
  required double sdHrv,
}) {
  double raw = 0;
  if (sdRhr > 1e-6) raw += (todayRhr - meanRhr) / sdRhr;
  if (sdHrv > 1e-6) raw += (meanHrv - todayHrv) / sdHrv;
  return (3 / (1 + math.exp(-raw))).clamp(0, 3);
}

/// Stress band label. <1 LOW, <2 MEDIUM, else HIGH.
String stressBand(double s) => s < 1.0 ? 'LOW' : (s < 2.0 ? 'MEDIUM' : 'HIGH');

// ── HR zones — HrZones ─────────────────────────────────────────────────────
const zoneEdges = [0.50, 0.60, 0.70, 0.80, 0.90, 1.00];

/// Zone index 1..5 for a bpm (0 = below zone 1).
int hrZoneFor(double bpm, double maxHr) {
  final pct = bpm / maxHr;
  if (pct < zoneEdges[0]) return 0;
  for (var z = 1; z <= 5; z++) {
    if (pct <= zoneEdges[z] || z == 5) return z;
  }
  return 5;
}

// ── Sleep need + debt ──────────────────────────────────────────────────────
/// Sleep need (minutes): imported value if >0, else max(450, mean history).
double sleepNeedMin(double? imported, List<double> historyMin) {
  if (imported != null && imported > 0) return imported;
  if (historyMin.isEmpty) return 480;
  final mean = historyMin.reduce((a, b) => a + b) / historyMin.length;
  return math.max(450, mean);
}

/// Sleep debt balance over trailing 14 counted nights (min); ±30 min deadband.
double sleepDebtMin(List<double> sleptMin, List<double> needMin) {
  double bal = 0;
  final n = math.min(math.min(sleptMin.length, needMin.length), 14);
  for (var i = sleptMin.length - n; i < sleptMin.length; i++) {
    if (sleptMin[i] <= 0) continue;
    bal += sleptMin[i] - needMin[i];
  }
  return bal.abs() <= 30 ? 0 : bal;
}

// ── Caffeine decay — CaffeineDecay ─────────────────────────────────────────
const caffeineHalfLifeH = 5.5;
double caffeineRemaining(double hoursElapsed) =>
    math.pow(0.5, hoursElapsed / caffeineHalfLifeH).toDouble();
bool caffeineActive(double hoursElapsed) => caffeineRemaining(hoursElapsed) > 0.25;

// ── Recovery colour band (WHOOP) — red<34, yellow<67, green≥67 ──────────────
String recoveryBand(double score) =>
    score < 34 ? 'LOW' : (score < 67 ? 'MODERATE' : 'HIGH');
