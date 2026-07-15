"""noop_algos — a faithful Python port of the noop Flutter analytics, for testing
the algorithms locally on a raw strap DB.

Mirrors lib/core/analytics/{hrv_analyzer,recovery_scorer,baselines,sleep_stager,
strain_scorer}.dart closely enough to reproduce the per-day scores and, crucially,
to SHOW why a metric reads the way it does on real data (e.g. Recovery sitting at
the population mean of 58 while the personal HRV baseline is still calibrating).

Pure stdlib (sqlite3 + math). No personal data lives here — pass a DB path.
"""
from __future__ import annotations

import math
import sqlite3
from dataclasses import dataclass, field
from datetime import datetime

# ─────────────────────────── constants (ported 1:1) ───────────────────────────
EPOCH_SEC = 30
MIN_WINDOW_EPOCHS = 240          # ~2 h minimum sleep window
MAX_GAP_EPOCHS = 20              # ~10 min interruption tolerated inside a bout
HR_SLEEP_MARGIN = 13.0

RR_MIN_MS, RR_MAX_MS = 300.0, 2000.0
ECTOPIC_THRESHOLD = 0.20         # Malik: >20% off local median → ectopic
ECTOPIC_HALF_WINDOW = 2
HRV_MIN_BEATS = 20

ROBUST_RHR_MIN_SAMPLES = 30

# recovery_scorer.dart
W_HRV, W_RHR, W_RESP, W_SLEEP, W_SKIN = 0.55, 0.20, 0.05, 0.15, 0.05
SLEEP_PERF_CENTER, SLEEP_PERF_SCALE = 0.85, 0.12
SKIN_TEMP_DEV_SCALE = 1.0
LOGISTIC_K, LOGISTIC_Z0 = 1.6, -0.20
RECOVERY_POPULATION_MEAN = 58.0

# baselines.dart
BASE_CONFIGS = {  # metric -> (minVal, maxVal, floorSpread)
    "hrv": (5, 250, 5),
    "resting_hr": (30, 120, 2),
    "resp": (4, 40, 0.5),
}
CENTER_HALFLIFE, SPREAD_HALFLIFE = 14.0, 21.0
EARLY_ADAPT_NIGHTS, YOUNG_CENTER_HALFLIFE = 8, 3.0
# Valid HRV nights the baseline needs before recovery is a real score. Below this
# the app shows a "calibrating N/needed nights" state instead of a number.
BASELINE_MIN_NIGHTS = 4


def _lambda(halflife: float) -> float:
    return 1 - math.pow(0.5, 1 / halflife)


# ─────────────────────────── HRV (hrv_analyzer.dart) ───────────────────────────
def _median(xs):
    s = sorted(xs)
    n = len(s)
    if n == 0:
        return 0.0
    return s[n // 2] if n % 2 else (s[n // 2 - 1] + s[n // 2]) / 2


def _is_ectopic_at(ranged, i):
    lo = max(0, i - ECTOPIC_HALF_WINDOW)
    hi = min(len(ranged) - 1, i + ECTOPIC_HALF_WINDOW)
    neigh = [ranged[j] for j in range(lo, hi + 1) if j != i]
    if len(neigh) < 2:
        return False
    med = _median(neigh)
    if med <= 0:
        return False
    return abs(ranged[i] - med) / med > ECTOPIC_THRESHOLD


def clean_rr_with_breaks(rr):
    """Range filter + Malik ectopic rejection, tracking where a beat was dropped."""
    ranged, ranged_break, pending = [], [], False
    for v in rr:
        if RR_MIN_MS <= v <= RR_MAX_MS:
            ranged_break.append(pending)
            ranged.append(v)
            pending = False
        else:
            pending = True
    nn, broken, pending = [], [], False
    for i in range(len(ranged)):
        if _is_ectopic_at(ranged, i):
            pending = True
            continue
        nn.append(ranged[i])
        broken.append(ranged_break[i] or pending)
        pending = False
    return nn, broken


def rmssd(raw_rr):
    """Task-Force RMSSD (ms) over cleaned NN, gap-aware. None if too few beats."""
    nn, broken = clean_rr_with_breaks(raw_rr)
    if len(nn) < HRV_MIN_BEATS:
        return None
    sumsq, ndiff = 0.0, 0
    for i in range(1, len(nn)):
        if broken[i]:
            continue
        d = nn[i] - nn[i - 1]
        sumsq += d * d
        ndiff += 1
    return math.sqrt(sumsq / ndiff) if ndiff >= 1 else None


# ─────────────────────── robust resting HR (recovery_scorer.dart) ──────────────
def _percentile_sorted(s, pct):
    if not s:
        return 0.0
    if len(s) == 1:
        return s[0]
    rank = (pct / 100) * (len(s) - 1)
    lo = int(math.floor(rank))
    hi = min(lo + 1, len(s) - 1)
    frac = rank - lo
    return s[lo] + (s[hi] - s[lo]) * frac


def resting_hr_robust(ts, bpm, start, end):
    vals = sorted(b for t, b in zip(ts, bpm) if start <= t <= end and b > 30)
    if not vals:
        return None
    med = _percentile_sorted(vals, 50.0)
    if len(vals) < ROBUST_RHR_MIN_SAMPLES:
        return round(med)
    p25 = _percentile_sorted(vals, 25.0)
    return round((p25 + med) / 2.0)


# ─────────────────────────── EWMA baselines (baselines.dart) ───────────────────
CALIBRATING, PROVISIONAL, TRUSTED, STALE = "calibrating", "provisional", "trusted", "stale"


@dataclass
class Baseline:
    baseline: float = 0.0
    spread: float = 0.0
    n_valid: int = 0
    nights_since: int = 0
    status: str = CALIBRATING

    @property
    def usable(self):
        return self.status in (PROVISIONAL, TRUSTED)


def baseline_update(s: Baseline, metric: str, value):
    cfg = BASE_CONFIGS.get(metric, (0, 1e9, 0.1))
    lo_v, hi_v, floor_spread = cfg
    if value is None or value < lo_v or value > hi_v:
        s.nights_since += 1
        if s.n_valid >= 14 and s.nights_since > 14:
            s.status = STALE
        return
    if s.n_valid == 0:
        s.baseline, s.spread, s.n_valid, s.nights_since, s.status = value, floor_spread, 1, 0, CALIBRATING
        return
    young = s.n_valid < EARLY_ADAPT_NIGHTS
    center_hl = YOUNG_CENTER_HALFLIFE if young else CENTER_HALFLIFE
    lam, lam_s = _lambda(center_hl), _lambda(SPREAD_HALFLIFE)
    band = 2.5 if young else 1.0
    if (not young) and abs(value - s.baseline) > 5 * s.spread:
        s.n_valid += 1
        s.nights_since = 0
        return
    lo = s.baseline - 3 * s.spread * band
    hi = s.baseline + 3 * s.spread * band
    clamped = min(max(value, lo), hi)
    s.baseline = lam * clamped + (1 - lam) * s.baseline
    s.spread = max(floor_spread, lam_s * abs(value - s.baseline) + (1 - lam_s) * s.spread)
    s.n_valid += 1
    s.nights_since = 0
    if s.n_valid < BASELINE_MIN_NIGHTS:
        s.status = CALIBRATING
    elif s.n_valid < 14:
        s.status = PROVISIONAL
    else:
        s.status = TRUSTED


# ─────────────────────────── recovery (recovery_scorer.dart) ───────────────────
def _z(value, mean, spread):
    return (value - mean) / max(1.253 * spread, 1e-9)


def recovery(hrv, rhr, hrv_base: Baseline, rhr_base: Baseline | None,
             sleep_perf, hrv_usable):
    """Returns (score, is_real). is_real=False → None inside → caller uses 58."""
    if not hrv_usable:
        return None
    terms = [(_z(hrv, hrv_base.baseline, hrv_base.spread), W_HRV)]
    if rhr_base is not None:
        terms.append((_z(rhr_base.baseline, rhr, rhr_base.spread), W_RHR))
    if sleep_perf is not None:
        terms.append(((sleep_perf - SLEEP_PERF_CENTER) / SLEEP_PERF_SCALE, W_SLEEP))
    tw = sum(w for _, w in terms)
    if tw <= 0:
        return None
    z = sum(v * w for v, w in terms) / tw
    score = 100.0 / (1.0 + math.exp(-LOGISTIC_K * (z - LOGISTIC_Z0)))
    return max(0.0, min(100.0, score))


# ─────────────────────────── strain (Edwards TRIMP) ────────────────────────────
def edwards_strain(ts, bpm, max_hr):
    """Edwards TRIMP: minutes in 5 %HRmax zones × zone weight (1..5)."""
    if not bpm or max_hr <= 0:
        return 0.0
    zbounds = [0.5, 0.6, 0.7, 0.8, 0.9]
    minutes = [0.0] * 5
    # approximate per-sample dwell as the gap to the next sample (cap 60 s)
    for i in range(len(ts)):
        dwell = min(60, ts[i + 1] - ts[i]) if i + 1 < len(ts) else 1
        frac = bpm[i] / max_hr
        z = sum(1 for b in zbounds if frac >= b)  # 0..5
        if z >= 1:
            minutes[z - 1] += dwell / 60.0
    return sum(minutes[i] * (i + 1) for i in range(5))


def tanaka_hrmax(age):
    return 208 - 0.7 * age


# ─────────────────────────── sleep window (sleep_stager.dart) ──────────────────
def _longest_bout(sleepy):
    """Longest run of True tolerating gaps up to MAX_GAP_EPOCHS. Returns (lo,hi)."""
    best = None
    i, n = 0, len(sleepy)
    while i < n:
        if not sleepy[i]:
            i += 1
            continue
        lo = i
        hi = i
        gap = 0
        j = i
        while j < n:
            if sleepy[j]:
                hi = j
                gap = 0
            else:
                gap += 1
                if gap > MAX_GAP_EPOCHS:
                    break
            j += 1
        if best is None or (hi - lo) > (best[1] - best[0]):
            best = (lo, hi)
        i = j
    return best


@dataclass
class SleepWin:
    start_ts: int
    end_ts: int
    asleep_sec: int
    efficiency: float


def detect_sleep(epoch_ts, epoch_asleep):
    n = len(epoch_ts)
    if n < MIN_WINDOW_EPOCHS:
        return None
    win = _longest_bout(epoch_asleep)
    if win is None:
        return None
    lo, hi = win
    while lo < hi and not epoch_asleep[lo]:
        lo += 1
    while hi > lo and not epoch_asleep[hi]:
        hi -= 1
    if hi - lo + 1 < MIN_WINDOW_EPOCHS:
        return None
    start_ts = epoch_ts[lo]
    end_ts = epoch_ts[hi] + EPOCH_SEC
    asleep_epochs = sum(1 for k in range(lo, hi + 1) if epoch_asleep[k])
    in_bed = hi - lo + 1
    return SleepWin(start_ts, end_ts, asleep_epochs * EPOCH_SEC,
                    asleep_epochs / in_bed if in_bed else 0.0)


# ─────────────────────────── per-day pipeline + DB loader ──────────────────────
@dataclass
class DayResult:
    date: str
    n_hr: int
    sleep_min: int
    efficiency: float
    hrv: float | None
    rhr: int | None
    strain: float
    hrv_status: str
    recovery_raw: float | None
    calibration_nights: int | None   # None → real score; else N/BASELINE_MIN_NIGHTS


@dataclass
class Sample:
    ts: int
    hr: int = 0
    rr: list = field(default_factory=list)
    mv: float = 1.0
    state: int | None = None


def load_raw_days(db_path):
    con = sqlite3.connect(db_path)
    cur = con.cursor()

    def rows(sql):
        try:
            return cur.execute(sql).fetchall()
        except sqlite3.Error:
            return []

    by_ts = {}

    def at(ts):
        s = by_ts.get(ts)
        if s is None:
            s = Sample(ts)
            by_ts[ts] = s
        return s

    for ts, bpm in rows("SELECT ts,bpm FROM hrSample WHERE bpm>0"):
        at(ts).hr = bpm
    for ts, rr in rows("SELECT ts,rr_ms FROM rrInterval WHERE rr_ms>0"):
        at(ts).rr.append(float(rr))
    for ts, x, y, z in rows("SELECT ts,x,y,z FROM gravitySample"):
        at(ts).mv = math.sqrt(x * x + y * y + z * z)
    for ts, state in rows("SELECT ts,state FROM sleepStateSample"):
        at(ts).state = state
    con.close()

    buckets = {}
    for ts in sorted(by_ts):
        d = datetime.fromtimestamp(ts).date()  # local calendar day
        buckets.setdefault(d, []).append(by_ts[ts])
    return [(str(d), buckets[d]) for d in sorted(buckets)]


def _epochs(samples):
    """Bin samples into 30 s epochs → (epoch_ts, asleep_mask)."""
    if not samples:
        return [], []
    start = samples[0].ts - (samples[0].ts % EPOCH_SEC)
    end = samples[-1].ts
    n = (end - start) // EPOCH_SEC + 1
    asleep_cnt = [0] * n
    state_cnt = [0] * n
    ts = [start + b * EPOCH_SEC for b in range(n)]
    for s in samples:
        b = (s.ts - start) // EPOCH_SEC
        if 0 <= b < n and s.state is not None:
            state_cnt[b] += 1
            if s.state != 0:
                asleep_cnt[b] += 1
    asleep = [state_cnt[b] > 0 and asleep_cnt[b] * 2 >= state_cnt[b] for b in range(n)]
    return ts, asleep


def run_pipeline(days, age=30):
    """Score each day oldest→newest, folding baselines exactly like DailyPipeline."""
    hrv_base, rhr_base = Baseline(), Baseline()
    out = []
    for date, samples in days:
        ts_hr = [s.ts for s in samples if s.hr > 0]
        bpm = [float(s.hr) for s in samples if s.hr > 0]
        if len(bpm) < 60:
            continue
        e_ts, e_asleep = _epochs(samples)
        sleep = detect_sleep(e_ts, e_asleep)

        hrv = rhr = None
        sleep_perf = None
        sleep_min = 0
        eff = 0.0
        if sleep is not None:
            sleep_min = sleep.asleep_sec // 60
            eff = sleep.efficiency
            sleep_perf = eff
            rr = []
            for s in samples:
                if sleep.start_ts <= s.ts <= sleep.end_ts:
                    rr.extend(s.rr)
            hrv = rmssd(rr)
            rhr = resting_hr_robust(ts_hr, bpm, sleep.start_ts, sleep.end_ts)

        hrv_usable = hrv_base.usable
        rec_raw = None
        if hrv is not None and rhr is not None:
            rec_raw = recovery(hrv, float(rhr), hrv_base,
                               rhr_base if rhr_base.usable else None,
                               sleep_perf, hrv_usable)
        # None → real score; else nights collected so far (incl. tonight), so the
        # UI shows "calibrating N/BASELINE_MIN_NIGHTS" instead of a number.
        cal_nights = None if rec_raw is not None else min(
            BASELINE_MIN_NIGHTS, hrv_base.n_valid + (1 if hrv is not None else 0))

        status_before = hrv_base.status
        if hrv is not None:
            baseline_update(hrv_base, "hrv", hrv)
        if rhr is not None:
            baseline_update(rhr_base, "resting_hr", float(rhr))

        strain = edwards_strain(ts_hr, bpm, tanaka_hrmax(age))
        out.append(DayResult(date, len(bpm), sleep_min, eff, hrv, rhr,
                             strain, status_before, rec_raw, cal_nights))
    return out


def print_report(results):
    print(f"\n{'date':12} {'nHR':>7} {'sleep':>6} {'eff':>5} {'HRV':>6} "
          f"{'RHR':>4} {'strain':>7} {'hrvBase':>12} {'recov':>6}")
    print("-" * 78)
    for r in results:
        hrv = f"{r.hrv:.1f}" if r.hrv is not None else "—"
        rhr = str(r.rhr) if r.rhr is not None else "—"
        if r.recovery_raw is not None:
            rec = f"{r.recovery_raw:.0f}"
            flag = ""
        else:
            rec = f"{r.calibration_nights}/{BASELINE_MIN_NIGHTS}"
            flag = "  (calibrating — shows this, not a number)"
        print(f"{r.date:12} {r.n_hr:>7} {r.sleep_min:>5}m {r.efficiency*100:>4.0f}% "
              f"{hrv:>6} {rhr:>4} {r.strain:>7.1f} {r.hrv_status:>12} {rec:>6}{flag}")
    real = [r for r in results if r.recovery_raw is not None]
    print(f"\n{len(results)} days · {len(real)} with a REAL recovery "
          f"(the rest are calibrating until the HRV baseline reaches "
          f"{BASELINE_MIN_NIGHTS} valid nights — the app shows 'N/{BASELINE_MIN_NIGHTS}').")


if __name__ == "__main__":
    import sys
    db = sys.argv[1] if len(sys.argv) > 1 else "noop.sqlite"
    age = int(sys.argv[2]) if len(sys.argv) > 2 else 30
    print(f"Running noop analytics on: {db}  (age={age})")
    print_report(run_pipeline(load_raw_days(db), age))
