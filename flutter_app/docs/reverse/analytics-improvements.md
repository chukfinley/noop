# Analytics engine improvements — RE survey → portable wins

**Status:** recon spec, implementation-ready. Author: hub-recon agent. Date: 2026-07-12.
**Scope:** concrete, portable improvements to the ported scoring engines in
`lib/core/analytics/` (`hrv_analyzer.dart`, `recovery_scorer.dart`, `strain_scorer.dart`,
`sleep_stager.dart`, `engines.dart`, `baselines.dart`, `daily_pipeline.dart`), sourced from the
reverse-engineering / algorithm-research tree at `/home/user/git/whoop/algorithms/`.

---

## 0. Honest verdict up front: this is post-decode DSP, NOT a wire-protocol change

The task template asks for "byte layouts / opcodes" and points at the BLE stack
(`Framing.buildCommand`, `CommandNumber`, `WhoopBleClient`, drift tables). **None of the wins below
touch the BLE wire.** They all operate on samples that the transport has *already* decoded — the
per-second HR / beat-to-beat RR / accel-magnitude / SpO2 rows that
`lib/core/analytics/raw_samples.dart` unpacks and `DailyPipeline` scores. The strap already streams
everything these algorithms need; the improvement is entirely in the Dart math that turns those
samples into Charge / Effort / Rest / Stress / HRV / RHR / resp.

So:
- **No new `CommandNumber`, no `Framing.buildCommand` change, no new characteristic, no drift-table
  schema change is required** for §2–§7. The existing sync path that fills `RawSample` is sufficient.
- The **one** place in this document with genuinely byte-decoded constants is the **Bevel/Superset
  recovery formula** (§4, Option B), reverse-engineered from a decrypted arm64 Mach-O by
  disassembling instruction immediates — cited with vaddrs. That is a *formula* we can port, not a
  protocol.
- Where a win would need a channel the capture does not carry reliably (skin-temp), that is called
  out as blocked.

Everything is a pure-Dart change verifiable with `flutter test` (per `CLAUDE.md`: never launch the
app; the gate is `test/analytics/engines_unit_test.dart` + `test/pipeline_real_data_test.dart`).

---

## 1. What we ship today vs. the reference (baseline)

| Engine | Our current impl | Reference file(s) | Gap |
|---|---|---|---|
| HRV RMSSD | `HrvAnalyzer.analyzeRaw`: range[300,2000]ms + Malik-20% ectopic, gap-aware Δ. Window selectable (`HrvWindow.wholeNight` **default** / `deepSleep`). | `common/preprocessing.py::rmssd_zepp`, `algo_zepp_recovery/`, CHANGELOG 2026-06-25 | Whole-night default runs **1.34× hot**; deep-locked + Zepp filter is the validated fix (r 0.54→0.70 vs WHOOP HRV). |
| Resting HR | `RecoveryScorer.restingHRRobust` = mean(P25, median) of in-window HR. | `algo11.../engine.py::compute_sleep_rhr` | **Already matches** WHOOP method — no change. |
| Recovery / Charge | z-score+logistic; weights HRV .55 / RHR .20 / resp .05 / sleep .15; `k=1.6`. | `bevel_re/recovery_strain.py` (byte-decoded), `algo11 RECOVERY_PARAMS`, `whoop_master_optimized.json` | Both validated refs weight **RHR ≥ HRV** and **resp ~0.24–0.30**, not our HRV-.55 / resp-.05 split. |
| Strain / Effort | Edwards 5-zone TRIMP on %HRR → `100·ln(trimp+1)/ln(7201)`. | `algo11 compute_strain`, `whoop_master_optimized.json`, `strain_analysis.py` | Validated model (MAE 2.4/21, r 0.88) uses tuned zone weights + `k·ln(1+load/c)` + a **coverage correction** our sparse daytime capture badly needs. |
| Sleep score / Rest | `engines.restScore`: .50 dur + .20 eff + .20 restorative + .10 consistency; consistency hardcoded 0.7. | `algo11 compute_sleep_score` (5-component, **r 0.97**), `whoop_master_optimized.json` | Best-validated model in the tree. Consistency (weight 0.39) dominates and we hardcode it. |
| Resp rate | `SleepStager._estimateRespRate`: crude HR up/down peak-count, clamp 8–22. Surfaced only inside sleep; day `respiratoryRate` mostly 0. | `algo11 compute_respiratory_rate` (Welch PSD on RSA) | Real spectral method exists; would let us promote resp rate from "coming soon" to a trustworthy number. |
| Sleep staging | HR-band-only heuristic (`sleep_stager.dart`, ~250 lines). | `whoop_engine._stage_rules`, `algo11 classify_sleep_phases`, `common/sleep_algorithm.py`, `sleep_window_fix.py` | Ignores per-epoch RMSSD + HR-variance; deep/REM separation is weak. Feature-level wins are portable; the ML/actigraphy ceilings are not (see §7). |
| Sleep need | `engines.sleepNeedMin` = `max(450, mean history)`. | `whoop_engine.compute_sleep_need` | Ignores strain + debt; WHOOP adds both. |

---

## 2. WIN 2 — Deep-lock the RMSSD window by default (highest-confidence win)

**Evidence.** `algorithms/CHANGELOG.md`, 2026-06-25 "Deep-locked RMSSD": whole-night wrist RMSSD
median ≈122 ms vs WHOOP's 91 ms (**ratio 1.34, HOT**) — it saturates the HRV curve and *inverts* the
recovery signal (sensor Pearson r=0.10 vs WHOOP recovery). Locking RMSSD to slow-wave (deep) sleep
with the Zepp artifact filter, computed on **our own stager's deep windows** (deep recall 86.8%):

| RMSSD vs WHOOP HRV | n | Pearson | MAE (ms) | median÷91 |
|---|--:|--:|--:|--:|
| whole-night baseline | 81 | 0.54 | 35.5 | 1.34 (HOT) |
| **production (our stager, deep-locked)** | 76 | **0.702** | **11.0** | **0.93** |
| ceiling (WHOOP-GT deep) | 75 | 0.724 | 10.9 | 0.92 |

End-to-end recovery correlation vs WHOOP: **0.01 → 0.48** with deep-locking (≈68% of the way to the
0.71 formula ceiling). The previously-used `×0.69` calibration scalar became obsolete and **was
removed** because deep-locking fixes the scale physiologically (median lands at 84.6 ms with no
scalar).

**What this means for us.** `DailyPipeline` already implements the deep-sleep window
(`hrvWindow == HrvWindow.deepSleep` path, `daily_pipeline.dart:94-112`, with whole-night fallback)
and `Prefs` already persists the toggle (`prefs.dart:14,97,205,272`). **The default is the wrong
one:** `prefs.dart:97 HrvWindow hrvWindow = HrvWindow.wholeNight;` and
`daily_pipeline.dart:26 {this.hrvWindow = HrvWindow.wholeNight}`.

### Step-by-step
1. `lib/core/state/prefs.dart:97` — change the default to `HrvWindow.deepSleep`. (The load path at
   `:205` already maps the stored string; only the unset-default changes.)
2. `lib/core/analytics/daily_pipeline.dart:26` — change the constructor default to
   `HrvWindow.deepSleep` so headless/test construction matches.
3. **Adopt the validated "Zepp" artifact filter** for the deep window (it beat Malik-20% in the grid;
   see CHANGELOG "Winner: deep_only | zepp"). Port `rmssd_zepp` into `HrvAnalyzer` as a new cleaning
   mode without disturbing the existing Task-Force path:
   - Compute `meanRR` over range-filtered beats.
   - Keep beat `i` iff `0.75·meanRR ≤ RR[i] ≤ 1.5·meanRR` **and** `|RR[i] − meanRR| ≤ 3·SD` (SD over
     the range-filtered series). This is a *physiological-window + 3-SD ectopic* rejection, stricter
     and cheaper than the centered-median Malik test.
   - RMSSD = √mean(ΔRR²) over **temporally adjacent kept beats only** — reuse the existing
     `cleanRRWithBreaks` / `brokenBefore` gap-machinery (`hrv_analyzer.dart:174-204,242-251`) so a
     dropped beat never spans a Δ. This is exactly the "segment-aware RMSSD" the CHANGELOG describes;
     we already have the mechanism, just feed it the Zepp keep-mask.
   - Note the CHANGELOG's own caveat: stacking Malik **on top of** deep-locking *over-corrects* (deep
     sleep has few real artifacts). So the deep path should use **Zepp-only**, not Zepp+Malik.
4. Keep the whole-night fallback (`daily_pipeline.dart:104-112`) unchanged so a sparse night is never
   dropped.

**Reuse:** `HrvAnalyzer.rangeFilter`, `cleanRRWithBreaks`, `median`; `DailyPipeline._inDeepSegment`
(`daily_pipeline.dart:212`) already selects deep beats.

**Test:** add a case to `test/analytics/engines_unit_test.dart` pinning `rmssdZepp` on a hand-built
RR series (physiological-window rejection + 3-SD drop of one ectopic). Then run
`test/pipeline_real_data_test.dart` and read its printed report: nightly HRV median should drop from
~120 ms toward ~85–95 ms, and the resting-HR-MAE-vs-WHOOP assert should stay sane.

**Open question.** Deep-lock depends on the stager's deep segments being real. On nights the stager
emits little/no deep, the fallback silently reverts to hot whole-night RMSSD. Consider a
lowest-HR-quartile *proxy* deep window (the CHANGELOG's production fallback) instead of whole-night,
so we never fall all the way back to the 1.34× scale.

---

## 3. WIN 3 — Real respiratory rate from RSA (promote from "coming soon")

**Evidence.** `algo11_whoop_optimized/engine.py::compute_respiratory_rate` (lines 311–341): resample
the cleaned RR series to a uniform 4 Hz grid, remove mean, Welch PSD (`nperseg=min(256,N)`), take the
peak frequency in the **0.15–0.5 Hz** respiratory-sinus-arrhythmia band, ×60 → breaths/min. Same band
appears in `algo11` and is the standard HRV-derived respiration method (Firstbeat family, cited in
`competitor_analysis/RESEARCH_where_to_steal.md`).

Our current `SleepStager._estimateRespRate` (`sleep_stager.dart:246-290`) counts smoothed-HR
up/down cycles and clamps to 8–22 — a coarse proxy that the `CLAUDE.md` notes is why resp rate is
"coming soon".

### Step-by-step (pure Dart, no scipy)
1. New file `lib/core/analytics/resp_rate.dart`, function
   `double? respRateFromRR(List<int> tsSec, List<double> rrMs)`:
   - Build the RR tachogram time axis: `t[k] = Σ rr[0..k]/1000` (seconds); require span ≥ 30 s and
     ≥ 60 beats (matches algo11's guards).
   - Linear-interpolate onto a uniform 4 Hz grid; subtract the mean.
   - **Welch PSD in Dart:** split into 50%-overlap Hann-windowed segments of `min(256, N)` samples;
     for each segment compute the DFT power (a direct O(N²) DFT is fine — a night's grid is a few
     thousand points, run once per night), average across segments. (No FFT dependency needed; if
     `package:fftea` is already vendored, use it, else the direct DFT is adequate at this size.)
   - Restrict to bins with `0.15 ≤ f ≤ 0.5 Hz`, take `argmax(psd)`, return `f_peak·60` rounded to
     0.1. Return `null` (not 14.0) when guards fail — never fabricate, per `CLAUDE.md`.
2. `DailyPipeline._process` (`daily_pipeline.dart:113`): replace `resp = sleep.respRate;` with a call
   that feeds the **in-window RR** (gather as at `:94-100`) into `respRateFromRR`; fall back to
   `sleep.respRate` only if the spectral method returns null. This makes `DayRecord.respiratoryRate`
   (`models.dart:120`) and `SleepRecord.respiratoryRate` (`models.dart:37`) trustworthy.
3. Feed the improved resp into the recovery resp-term (already wired,
   `recovery_scorer.dart:232-234`) and its baseline (`_respBase`, `daily_pipeline.dart:137`).

**Reuse:** `HrvAnalyzer.cleanRR` for the beat series before building the tachogram.

**Test:** synthesize an RR series modulated at exactly 0.25 Hz (15 brpm) and assert
`respRateFromRR ≈ 15 ± 0.5`. Then confirm `pipeline_real_data_test` prints non-zero resp for nights
that previously showed 0, and the value sits in 11–18 brpm.

**Product note.** Once trustworthy, remove resp rate from the "coming soon" list in the UI. Do this
only after the test above passes on real data — if median resp is implausible (e.g. clamped at the
14.0 default), leave it as coming-soon.

---

## 4. WIN 4 — Recovery weighting: two validated alternatives to our HRV-.55 split

Our `recoveryScore` / `RecoveryScorer.recovery` uses HRV 0.55 / RHR 0.20 / resp 0.05 / sleep 0.15,
logistic `k=1.6`, `z0=-0.20`. **Two independent reverse-engineered references both disagree with this
split** — they weight RHR and respiration far more heavily. Neither is a slam-dunk (recovery is the
hardest score to match: best validated MAE is still ~11.7 pts), so this is documented as a tunable
with A/B options, not a mandated swap.

### Option A — WHOOP-optimized (differential-evolution fit vs 15 nights of WHOOP GT)
`algo11_whoop_optimized/engine.py::RECOVERY_PARAMS` + `whoop_master_optimized.json`
(`mae_recovery: 11.716`):
- weights `hrv 0.2601, rhr 0.4587, sleep 0.0447, resp 0.2365`
- HRV subscore: steep sigmoid `100/(1+exp(-10.357·(hrv/baseline − 0.70)))`
- RHR subscore: linear `clamp(31.99 + (rhr_baseline − rhr)·12.777, 0, 100)`
- resp: `penalty = max(0, (resp − 16.0))·4.09`; resp subscore = `max(0, 100 − penalty)`
- combine: `Σ w·subscore`, clamp 0–100.
- calibration baselines used in the fit: `hrv 86.54 ms, rhr 53.5 bpm`.

### Option B — Bevel/Superset (byte-decoded from arm64 Mach-O — the "opcodes" the brief asked for)
`bevel_re/recovery_strain.py`, reconstructed by disassembling
`Payload/Superset.app/Superset`, `calculateRecoveryMetricsForDay` @ **vaddr 0x1010b5484**
(component subscore @ **0x1010b5cf0 / 0x1010b6370**, final combine @ **0x1010b69b8..0x1010b6b14**).
All constants below are inline immediates (movz/movk→fmov), HIGH confidence:
- component subscore: `dev = (today−base)/scale` (or `(base−today)/scale` for RHR, lower=better);
  `if dev < −1: return 0`; else `(min(dev,1)·0.5 + 0.5)·100`.
- weights `w_hrv 0.40 (0x3ecccccd), w_rhr 0.30 (0x3e99999a), w_sleep 0.30 (0x3e99999a)` — HIGH for the
  *values*; MED for *which* metric gets 0.40 (the decompile shuffles stack slots; HRV→0.40 is the
  likely assignment but not byte-certain).
- center nudge: `+ (sleep_sub − 50.0)·0.20`.
- resp term (bounded): `+ max(atan((resp_base − resp)/10.0)·30.0, −30.0)`.
- final `clamp(score, 1.0, 100.0)`.

### What to actually do
1. Keep the current formula as the default (it is transparent and documented). Add the two variants
   behind an enum so we can validate empirically against the bundled WHOOP GT:
   - `engines.dart` — introduce `enum RecoveryModel { noop, whoopOpt, bevel }` and route
     `recoveryScore` through the selected model. Keep the existing `noop` path byte-identical (the
     `engines_unit_test.dart` reference numbers must not move for `noop`).
2. **The most portable, low-risk takeaway** even if we don't swap models: **raise the resp weight and
   lower the HRV weight.** Our resp weight 0.05 is an order of magnitude below both refs (0.24 / 0.30
   equivalent). Since resp only becomes trustworthy after §3, gate any resp-weight increase on §3
   landing.
3. Validate: extend `pipeline_real_data_test.dart` to print recovery-MAE-vs-WHOOP per model over the
   bundled GT (`whoop_official.json` equivalent already drives that test's RHR-MAE assert). Pick the
   model with the lowest MAE; if `noop` wins or ties, keep it and record the numbers here.

**Reuse:** `Baselines` for per-metric mean/spread; `DriverBaseline.of`. No new data needed.

**Open question / honesty.** All three formulas top out around r≈0.48–0.71 vs WHOOP because WHOOP
also folds skin-temp, SpO2 and a proprietary model we can't port (skin-temp channel reads
uncalibrated in our capture — see §8). Don't over-promise recovery accuracy.

---

## 5. WIN 5 — Strain: tuned zone weights + coverage correction (matters most for our sparse capture)

**Evidence.** `whoop_master_optimized.json` (`mae_strain: 2.393` on the 0–21 scale, r≈0.88) and
`algo11_whoop_optimized/engine.py::compute_strain`:
- zone load `= Σ minutes_in_zone[i] · weight[i]`, weights
  `[0.276, 1.667, 2.41, 4.369, 11.0, 27.473]` for zones z0..z5.
- `strain = k·ln(1 + load/c)`, `k = 2.702`, `c = 24.84`, then `min(21, strain)`.
- **coverage correction** (the important bit for us): `coverage = validHR / totalSamples`; if
  `coverage > 0.1`, `scale = min(3.0, (1/coverage)^2.59)` and `load *= scale`. This compensates a day
  that is only partially sampled — **exactly our situation**, since the bundled capture down-samples
  daytime and the strap drops out. Without it, a day with 30% HR coverage reads ~⅓ of its true strain.
- zones there are absolute bpm from that user's WHOOP API (`WHOOP_ZONES`, MAX_HR=189). Our
  `strain_scorer.dart` correctly uses **%HRR (Karvonen)** — keep the personalized %HRR/%maxHR edges
  `[0.50,0.60,0.70,0.80,0.90,1.00]` (already in `engines.dart:161 zoneEdges` and Edwards zones in
  `strain_scorer.dart:68`); only the **weights, k/c, and coverage term** are the transferable win.

`strain_analysis.py` corroborates the log-curve family and warns our flatter curve "may underestimate
high-activity days" (lines 554–565), suggesting steeper `k`.

### Step-by-step
1. `strain_scorer.dart` — add a second accumulation method alongside Edwards TRIMP: a
   **weighted-zone-minutes** path.
   - Bucket each sample into zone 0–5 by %HRR using existing `zoneWeight`/`edwardsZones` boundaries,
     but accumulate `durationMin` per zone (not the integer Edwards weight).
   - `load = Σ zoneMinutes[i]·zoneWeightOpt[i]` with `zoneWeightOpt = [0.276,1.667,2.41,4.369,11.0,27.473]`.
     (Index 0 = z0 sub-threshold; our Edwards zone 0 currently contributes nothing — the optimized
     model gives it a small 0.276 weight, a minor accuracy gain for long low-intensity days.)
   - `strainRaw = k·ln(1 + load/c)` with `k=2.702, c=24.84`.
2. Add the **coverage correction** in `DailyPipeline._process`: pass the day's expected sample count
   (span/expected-cadence) so `strain` can compute `coverage` and apply
   `scale = min(3.0, (1/coverage)^2.59)` when `coverage > 0.1`. This needs the raw span from
   `daily_pipeline.dart:56-64` (we already build `tsHr`/`bpm`); `totalSamples` = `(tsHr.last −
   tsHr.first)` in seconds for a 1 Hz nominal cadence.
3. Rescale to our 0–100 "Effort" display consistently: either keep our `100·ln(trimp+1)/ln(7201)` map
   on the new `load`, or expose the native 0–21 and multiply by `100/21` at the UI seam — pick one and
   pin it in the test so `engines_unit_test.dart` numbers are deterministic.
4. Keep Edwards TRIMP as the default `StrainMethod`; add `StrainMethod.whoopZones` and select it in
   `DailyPipeline`. This preserves the existing pinned Edwards reference numbers.

**Reuse:** `StrainScorer.pctHRR`, `zoneWeight`, `tanakaHRmax`, `estimateHRmax`; the sample-duration
inference `sampleDurationMinutes` (`strain_scorer.dart:136`).

**Test:** `engines_unit_test.dart` — hand-compute zone minutes for a tiny HR series and assert `load`,
then `k·ln(1+load/c)`. Add a coverage case: same series at 50% coverage → `scale = min(3, 2^2.59) =
min(3, 6.02) = 3.0` → load ×3. Then read `pipeline_real_data_test`'s Effort summary: sparse days
should read higher (closer to WHOOP strain) than before.

**Caveat.** The absolute zone weights were fit to one subject's WHOOP data over 15 days; treat k/c as
starting points and confirm the strain-MAE line in the pipeline report improves before committing.

---

## 6. WIN 6 — Sleep score: 5-component model (best-validated in the whole tree, r 0.97)

**Evidence.** `algo11_whoop_optimized/engine.py::compute_sleep_score` +
`whoop_master_optimized.json` sleep block. Sleep score is the **strongest** validated reconstruction:
`mae_sleep 8.6`, correlation **0.97** with WHOOP. Five components, weights:
`hours 0.2042, consistency 0.3862, efficiency 0.1273, quality 0.0849, restorative 0.1973`.
- hours = `min(100, sleep_min/need·100)`
- consistency = `100 − variance(last-7 onset hours)·10`, clamped 0–100; **population default 57.16**
  when < 3 nights of history.
- efficiency = `min(100, asleep/inBed·100)`
- quality = `100 − max(0, min(100, −3.16 + 0.66·awake_pct))` (an awake-%→stress linear fit)
- restorative = `min(100, (deep_pct + rem_pct)·2)` (50% restorative → 100).

Our `engines.restScore` (`engines.dart:117-139`) uses .50/.20/.20/.10 and **hardcodes
`consistency01: 0.7`** at `daily_pipeline.dart:160` — dropping the single most heavily-weighted
component (0.386) to a constant.

### Step-by-step
1. `engines.dart` — add `sleepScore5(...)` implementing the five components + weights above (keep
   `restScore` for back-compat; the pipeline switches to the new one). Match the exact constants.
2. **Wire real consistency.** Add an onset-time history to `DailyPipeline` (a `List<double>
   _onsetHourHist`), append `sleep.startTs`→local hour each night, and compute
   `consistency = clamp(100 − variance(last7)·10, 0, 100)`; use `57.16` until ≥ 3 nights. This is the
   same "schedule regularity" WHOOP rewards and is currently thrown away.
   - Onset hour: `DateTime.fromMillisecondsSinceEpoch(sleep.startTs*1000).hour + minute/60`, with the
     after-noon wrap the reference uses (`onset_mins > 720 → −1440`, see
     `whoop_engine.py:616-619`) so 23:30 and 00:30 don't read as 24 h apart.
3. Feed the resulting sleep score into `SleepRecord.performance` (`models.dart:62`) and into the
   recovery sleep-term (already wired via `sleepPerf`, `daily_pipeline.dart:129`).

**Reuse:** existing `sleep.deepSec/remSec/awakeSec/efficiency`, `engines.sleepNeedMin`, the trailing
`_sleepMinHist`.

**Test:** pin `sleepScore5` on a synthetic night (known deep/rem/awake %, known need) in
`engines_unit_test.dart`. Add a 7-night consistency case (varying onsets → lower score). Confirm
`pipeline_real_data_test` sleep-score summary tightens toward the WHOOP sleep column.

---

## 7. WIN 7 — Sleep staging: portable feature-level gains (and what is NOT portable)

Our `SleepStager` stages epochs on **HR band alone** (`sleep_stager.dart:131-145`) — it never looks
at per-epoch RMSSD or HR variance, which are the signals that actually separate deep from REM.

### Portable (do these)
1. **Add per-epoch HRV + HR-variance features.** `whoop_engine._stage_rules`
   (`whoop_engine.py:351-405`) and `algo11 classify_sleep_phases` both key deep/REM off local RMSSD +
   HR std, not HR level alone:
   - deep: `hr_above_rhr ≤ 8` **and** `hr_std ≤ 3` **and** `local_rmssd ≥ 80` and not late-night.
   - rem: `hr_above_rhr ≥ 5` **and** `hr_std ≥ 4` **and** `movement ≤ 0.3` and not first-hour.
   (algo11 `PHASE_PARAMS`, `engine.py:74-93`.) Our stager already has the time-of-night gates
   (`nightFrac < 0.65` deep / `> 0.35` rem, `sleep_stager.dart:137-142`) — add the RMSSD/HR-std
   conditions. We can compute per-epoch RMSSD by feeding each epoch's RR beats through the same
   `HrvAnalyzer.rmssdRaw`. This is the cleanest accuracy lever that stays pure-Dart.
2. **Edge-trim the sleep window on a restless signal, not HR alone.** `sleep_window_fix.py` diagnosed
   two real failure modes: (A) truncating a long night into a fragment when the stager over-emits
   Awake mid-sleep, and (B) low-HR-only boundaries bleeding into calm pre-bed/post-wake (sitting still
   has sleep-like HR). Fix: pick the block by `duration × circadian_weight`, then trim only the **two
   ends** while `restless = (HR > blockRestingHR + 5) OR (movement z > 1.2)`, capped at 25% of the
   block, never fragmenting the interior (`sleep_window_fix.py:25-52`). Our stager trims on the
   `sleepy` HR flag only (`sleep_stager.dart:94-99`) — add the movement-OR-HR-elevated test with a
   block-relative resting HR (P25 of in-block HR).
3. **Deterministic REM-from-hypnogram** as a cross-check. `common/sleep_algorithm.py::detect_rem_posthoc`
   (lines 918–986) derives REM from (deep ≥10 min → light ≥15 min) transitions with fixed offsets
   (REM starts light_start+10 min; length `min(50, max(5, round5(remaining/2)))` min; no REM in first
   50 min). Fully specified, no ML — usable to sanity-cap our REM segments.

### NOT portable (document, don't attempt)
- **The Sleep-as-Android / Mi-Health actigraphy pipeline** (`common/sleep_algorithm.py`, 2133 lines:
  `HighActivity.NormalizedAmplitudeBased`, `DeepSleepDetectorV8`, `AdaptiveNormalizationFilter`,
  `SleepRecordHypnogram`). `competitor_analysis/RESEARCH_where_to_steal.md` is explicit: these are
  **accel/sound engines with no HR**, and "we proved they fail on wrist data." Our strap accel scalar
  is too noisy to threshold absolutely (already noted in `sleep_stager.dart:80-86` and
  `daily_pipeline.dart:340-346`). **Skip.**
- **The ML HistGBT stager + Viterbi** (`whoop_engine._stage_ml`, `train_whoop_model.py`, the
  `whoop_model.joblib` / `whoop_transition_matrix.joblib` blobs) is the real accuracy ceiling (~77%
  acc, κ0.66) but requires shipping a trained model and a feature pipeline (58 features + rolling
  deltas + Viterbi). That is an ONNX/tflite export effort, not a pure-Dart port — out of scope here.
  `competitor_analysis/RESEARCH_where_to_steal.md` recommends **SleepECG** (BSD-3, pretrained Bi-GRU
  on RR) and **DREAMT** as the highest-leverage *future* direction. Log as backlog, not this pass.

**Test:** staging changes are validated indirectly — `pipeline_real_data_test.dart` prints
nights-staged and deep/REM minutes; assert they stay physiologically plausible (deep 10–25%, REM
15–30% of asleep) and that no long night collapses to a fragment after the edge-trim change.

---

## 8. WIN 8 — Strain-aware sleep need (small, clean)

`whoop_engine.compute_sleep_need` (lines 657–668): `need = 7.5h + max(0,(strain−10)·0.1) +
debt·0.2`. Our `engines.sleepNeedMin` (`engines.dart:175-180`) ignores both strain and debt.

### Step
- Extend `sleepNeedMin` to accept today's Effort and the running sleep-debt (`engines.sleepDebtMin`
  already exists, `engines.dart:183-191`) and add
  `+ max(0,(effort−10)·0.1)·60 + debtMin·0.2`. Feed from `DailyPipeline` where Effort and
  `_sleepMinHist` are already in scope (`daily_pipeline.dart:142-153`). Pin the arithmetic in
  `engines_unit_test.dart`.

Low risk, improves the `need`-driven `hours` component of §6.

---

## 9. Blocked / absent (honest verdicts)

- **Skin-temperature recovery term** (`recovery_scorer.dart:44-48,240-242`, weight 0.05): the capture
  has **no calibrated skin-temp channel** (`CLAUDE.md`: skin temp is "coming soon"; the raw channel is
  uncalibrated). Both reference recovery formulas that use temp assume a real channel. **Leave the
  term dormant** (`skinTempDev` stays null) — do not fabricate. If a future BLE sync adds a real
  temp characteristic, revisit; that *would* be a wire-protocol task (new `CommandNumber` / drift
  column), unlike everything above.
- **SpO2 in recovery:** raw SpO2 reads ~65% uncalibrated (`CLAUDE.md`); we already only display the
  windowed mean and never fold it into a score. Keep it out.
- **Calories / activities:** `whoop_engine` has a zone-load EPOC calorie model
  (`_estimate_calories`, lines 994–1023) and HR-threshold activity detection (`detect_activities`,
  >50% maxHR sustained >5 min). These *are* derivable from our HR stream, but `CLAUDE.md` lists
  calories/workouts as "coming soon / no reliable source." That is a **product** decision, not a data
  blocker — flag as "available if we choose to surface it," not an analytics gap.

---

## 10. Suggested order of work (by confidence × leverage)

1. **§2 deep-lock RMSSD default + Zepp filter** — highest confidence (validated r 0.54→0.70), smallest
   change, machinery already present.
2. **§6 sleep-score 5-component + real consistency** — best-validated model (r 0.97), self-contained.
3. **§5 strain zone weights + coverage correction** — fixes sparse-day underestimation, r 0.88.
4. **§3 real resp rate (RSA/Welch)** — unlocks a "coming soon" metric; prerequisite for §4's resp
   weight.
5. **§4 recovery model A/B** — do last; validate empirically, keep `noop` if it wins.
6. **§7 staging features** + **§8 sleep need** — incremental accuracy, fold in opportunistically.

Every step is gated by `flutter analyze` + `flutter test`; after each, **read the printed report from
`test/pipeline_real_data_test.dart`** (days analysed, nights staged, Charge/Effort/RHR/HRV summary,
resting-HR MAE vs WHOOP) to confirm the direction and magnitude before moving on — per `CLAUDE.md`,
tests are the verification loop, never the app.

---

## Appendix — source map (evidence index)

| Claim | File:line |
|---|---|
| Deep-lock RMSSD r 0.54→0.70, ×0.69 removed, Zepp filter wins | `whoop/algorithms/CHANGELOG.md` (2026-06-25 "Deep-locked RMSSD") |
| `rmssd_zepp` physiological window [0.75,1.5]·meanRR + 3SD | `whoop/algorithms/CHANGELOG.md`; `algo_zepp_recovery/zepp_recovery.py` |
| Resp rate Welch PSD 0.15–0.5 Hz ×60 | `whoop/algorithms/algo11_whoop_optimized/engine.py:311-341` |
| RHR = mean(P25, median) during sleep | `whoop/algorithms/algo11_whoop_optimized/engine.py:101-116` |
| Recovery weights (WHOOP-opt) hrv .26/rhr .459/sleep .045/resp .237 | `whoop/algorithms/algo11_whoop_optimized/engine.py:42-50`; `whoop_master_optimized.json:20-37` |
| Recovery byte-decoded weights .40/.30/.30, subscore, atan resp, [1,100] clamp | `whoop/algorithms/bevel_re/recovery_strain.py:25-110` (vaddr 0x1010b5484, 0x1010b5cf0, 0x1010b69b8) |
| Strain zone weights, k=2.702 c=24.84, coverage^2.59 cap 3 | `whoop/algorithms/algo11_whoop_optimized/engine.py:65-72,266-308`; `whoop_master_optimized.json:48-62` |
| Strain log-curve family / underestimation warning | `whoop/algorithms/strain_analysis.py:277-565` |
| Sleep 5-component weights, r 0.97, consistency default 57.16 | `whoop/algorithms/algo11_whoop_optimized/engine.py:52-63,211-263`; `whoop_master_optimized.json:38-47` |
| Strain-aware sleep need = 7.5 + max(0,(strain-10)·.1) + debt·.2 | `whoop/algorithms/whoop_engine.py:657-668` |
| Rule-staging deep/rem via RMSSD + HR std | `whoop/algorithms/whoop_engine.py:351-405`; `algo11.../engine.py:349-467` |
| Sleep-window edge-trim on restless signal | `whoop/algorithms/sleep_window_fix.py:25-101` |
| Deterministic REM-from-hypnogram | `whoop/algorithms/common/sleep_algorithm.py:918-986` |
| Don't steal Garmin/actigraphy; SleepECG/DREAMT are the ML future | `whoop/algorithms/competitor_analysis/RESEARCH_where_to_steal.md` |
| Overall optimized MAE: recovery 11.7 / sleep 8.6 / strain 2.4 | `whoop/algorithms/whoop_master_optimized.json:9-15` |
