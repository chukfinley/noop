# python/ — local algorithm test suite

A Python port of the noop Flutter analytics (`flutter_app/lib/core/analytics/`)
for testing the algorithms **locally on a raw strap DB** — independent of the app,
so you can see exactly what each metric computes on real data and why.

- `noop_algos.py` — the ported algorithms (HRV RMSSD with Malik/range cleaning,
  robust resting HR, strap-`sleep_state` sleep window, Edwards-TRIMP strain, EWMA
  personal baselines + calibration status, the recovery model + its cold-start
  gate) plus a raw-`.sqlite` loader and a per-day report.
- `test_algos.py` — pytest suite: synthetic sanity tests (always) + an optional
  assertion pass over a real DB.

No personal data lives in the repo — you pass a DB path at runtime.

## Run

```bash
# Per-day report on a raw strap DB (hrSample / rrInterval / gravitySample /
# sleepStateSample tables — e.g. one pulled off the phone or an exported .noopbak
# unzipped to .sqlite):
python3 noop_algos.py /path/to/noop.sqlite [age]

# Test suite:
pytest -q                                     # synthetic sanity
NOOP_DB=/path/to/noop.sqlite pytest -q        # + assert real data is sane
```

## Why Recovery can read 58

Recovery (Charge) is HRV-dominant and refuses to score until the personal HRV
baseline has **≥4 valid nights** (WHOOP-style calibration). Below that it returns
the population mean, **58**. A "night" needs a real sleep window (≥2 h of strap
`sleep_state`), so partial capture days (sync started/stopped mid-day) don't count.
The report's `hrvBase` column and the `←58` flag show when this gate is active —
the HRV / RHR / sleep / strain columns are real regardless.
