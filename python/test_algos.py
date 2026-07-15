"""Python test suite for the noop analytics port (noop_algos.py).

Run:  pytest -q            # synthetic sanity tests (always)
      NOOP_DB=/path/to/noop.sqlite pytest -q   # + assertions on a real strap DB

The synthetic tests pin the algorithms to hand-checked numbers; the optional
real-DB test asserts the per-day metrics come out physiologically sane (and
documents WHY recovery may read 58 — the HRV baseline calibration gate).
"""
import math
import os

import noop_algos as A


# ─────────────────────────── HRV / RMSSD ───────────────────────────
def test_rmssd_constant_rr_is_zero():
    # No beat-to-beat variation → RMSSD 0.
    assert A.rmssd([800.0] * 40) == 0.0


def test_rmssd_known_alternating():
    # Alternating 800/840 → successive diffs ±40 → RMSSD = 40.
    rr = [800.0 if i % 2 == 0 else 840.0 for i in range(60)]
    assert abs(A.rmssd(rr) - 40.0) < 1e-9


def test_rmssd_rejects_out_of_range_beats():
    # 100 ms (too short) and 3000 ms (too long) are dropped; the gap is bridged
    # so it can't inflate RMSSD.
    rr = [800.0] * 30 + [100.0] + [800.0] * 30
    assert A.rmssd(rr) == 0.0


def test_rmssd_too_few_beats_is_none():
    assert A.rmssd([800.0] * 10) is None


# ─────────────────────────── robust resting HR ───────────────────────────
def test_rhr_small_sample_is_median():
    ts = list(range(10))
    bpm = [50, 51, 52, 53, 54, 55, 56, 57, 58, 59]
    # <30 samples → plain median.
    assert A.resting_hr_robust(ts, bpm, 0, 9) == round(A._percentile_sorted(sorted(bpm), 50))


def test_rhr_large_sample_blends_p25_and_median():
    ts = list(range(40))
    bpm = [50 + (i % 10) for i in range(40)]  # 40 samples ≥ 30 → (p25+median)/2
    s = sorted(bpm)
    expect = round((A._percentile_sorted(s, 25) + A._percentile_sorted(s, 50)) / 2)
    assert A.resting_hr_robust(ts, bpm, 0, 39) == expect


# ─────────────────────────── EWMA baseline status ───────────────────────────
def test_baseline_status_transitions():
    b = A.Baseline()
    assert b.status == A.CALIBRATING and not b.usable
    for _ in range(3):                      # 3 valid nights → still calibrating
        A.baseline_update(b, "hrv", 80.0)
    assert b.status == A.CALIBRATING and not b.usable
    A.baseline_update(b, "hrv", 80.0)       # 4th → provisional (usable)
    assert b.status == A.PROVISIONAL and b.usable
    for _ in range(10):                      # ≥14 → trusted
        A.baseline_update(b, "hrv", 80.0)
    assert b.status == A.TRUSTED


def test_baseline_ignores_out_of_range():
    b = A.Baseline()
    A.baseline_update(b, "hrv", 4.0)   # < min 5 → not folded
    assert b.n_valid == 0


# ─────────────────────────── recovery gate ───────────────────────────
def test_recovery_none_while_calibrating():
    b = A.Baseline(baseline=80, spread=8, n_valid=2, status=A.CALIBRATING)
    assert A.recovery(80, 55, b, None, 0.9, hrv_usable=False) is None


def test_recovery_scores_once_usable():
    b = A.Baseline(baseline=80, spread=8, n_valid=6, status=A.PROVISIONAL)
    score = A.recovery(80, 55, b, None, 0.9, hrv_usable=True)
    assert score is not None and 0 <= score <= 100
    # HRV exactly at baseline + decent sleep → mid/upper score, not the 58 floor.
    assert score != A.RECOVERY_POPULATION_MEAN


def test_higher_hrv_gives_higher_recovery():
    b = A.Baseline(baseline=80, spread=8, n_valid=6, status=A.PROVISIONAL)
    lo = A.recovery(70, 55, b, None, 0.9, True)
    hi = A.recovery(95, 55, b, None, 0.9, True)
    assert hi > lo


# ─────────────────────────── sleep window ───────────────────────────
def test_sleep_window_needs_two_hours():
    # 200 epochs of "asleep" (<240 = 2 h) → no window.
    ts = [i * A.EPOCH_SEC for i in range(200)]
    assert A.detect_sleep(ts, [True] * 200) is None


def test_sleep_window_detects_long_bout():
    ts = [i * A.EPOCH_SEC for i in range(400)]
    asleep = [False] * 20 + [True] * 360 + [False] * 20
    win = A.detect_sleep(ts, asleep)
    assert win is not None
    assert win.asleep_sec == 360 * A.EPOCH_SEC
    assert win.efficiency == 1.0


# ─────────────────────────── optional: real strap DB ───────────────────────────
def test_real_db_is_physiologically_sane():
    db = os.environ.get("NOOP_DB")
    if not db or not os.path.exists(db):
        import pytest
        pytest.skip("set NOOP_DB=/path/to/noop.sqlite to run on real data")
    results = A.run_pipeline(A.load_raw_days(db))
    assert results, "no scoreable days in the DB"
    nights = [r for r in results if r.hrv is not None]
    assert nights, "no night with a sleep window + HRV"
    for r in nights:
        assert 5 <= r.hrv <= 250, f"{r.date}: implausible HRV {r.hrv}"
        assert 30 <= r.rhr <= 120, f"{r.date}: implausible RHR {r.rhr}"
        # Recovery is either a real 0..100 score or a calibration state (N/4).
        if r.recovery_raw is not None:
            assert 0 <= r.recovery_raw <= 100
        else:
            assert 0 <= r.calibration_nights <= A.BASELINE_MIN_NIGHTS
    A.print_report(results)
