# flutter_app — Notes

## NEVER launch the app — verify with `flutter test`
**Do NOT run/launch/start the app** (`flutter run`, `flutter-hot`, screenshots, any device).
The user runs it himself and does his own hot reload. Our verification loop is tests, not the GUI:

```
change code → flutter analyze → flutter test → read the analysis report → done
```

`flutter test` is the gate. It proves the ported algorithm is correctly implemented on the REAL
data BEFORE anything is built:
- `test/analytics/engines_unit_test.dart` — pins each ported engine (HrvAnalyzer, StrainScorer,
  RecoveryScorer, Baselines) to hand-computed reference numbers. Change a formula/constant → this
  fails first.
- `test/pipeline_real_data_test.dart` — loads the real bundled capture, runs the whole pipeline,
  and **prints an analysis report** (days analysed, nights staged, Charge/Effort/RHR/HRV summary,
  and resting-HR MAE vs Whoop's own ground truth) then asserts it stays sane. After any algorithm
  change, run it and read that report to confirm what/how much was analysed and roughly the scores.

If a change has a runtime surface the tests don't cover, add a test — never reach for the app.

---

## Real data pipeline (the app shows REAL data, real dates)
The app is backed by a genuine reverse-engineered Whoop 4.0/5.0 strap capture, not mock data.

- **Asset:** `assets/data/real_raw.bin.gz` — ~2.7M real per-second sensor rows (HR, beat-to-beat RR,
  accel-magnitude, SpO2) over **88 days (2026-01-28 → 2026-05-26)**, packed little-endian
  (see `lib/analytics/raw_samples.dart` for the wire format) and gzipped. Built from the whoop RE
  repo's `whoop_unified.db`; nights kept full-resolution (contiguous beats for RMSSD/RHR), daytime
  down-sampled.
- **Ported algorithm (Kotlin → Dart):** the Kotlin analytics in `../android/.../analytics/` stay as
  the reference and are **faithfully ported** to `lib/analytics/`:
  `hrv_analyzer.dart` (RMSSD/SDNN/cleaning), `recovery_scorer.dart` (resting HR + recovery logistic),
  `strain_scorer.dart` (Edwards TRIMP → Effort), `baselines.dart` (EWMA personal baselines),
  `sleep_stager.dart` (simplified sleep window + stages — HR-driven, the strap accel is too noisy to
  threshold absolutely), `engines.dart` (rest/stress/sleep-need).
- **Orchestrator:** `lib/analytics/daily_pipeline.dart` runs the ported engines per local day
  (sleep window → RHR/RMSSD/resp over the window → personal baselines → Charge/Effort/Rest/Stress),
  exactly like the Kotlin nightly pipeline. `lib/data/real_repository.dart` loads the asset at
  startup, runs the pipeline, and implements `Repository`; `main()` overrides `repositoryProvider`
  with it (falls back to `MockRepository` only if the asset can't be read).
- **Real, trustworthy metrics:** Recovery/Charge, HRV (RMSSD), Resting HR, Sleep
  (duration/efficiency/stages/hypnogram/performance), Effort (day strain), Stress, intraday HR.
- **"Coming soon" (no reliable source in the capture):** skin temp, respiratory rate (estimator too
  sparse), SpO2/Blood O₂ (raw channel uncalibrated, reads ~65%), steps, calories, hydration,
  fitness age, workouts/activities, journal, weight. These use `lib/ui/components/coming_soon.dart`
  — never fabricate a number in their place.
- **Regenerating the asset:** the packer lives in the session scratchpad (`pack_raw88.py`); it reads
  the whoop RE repo DB. If the ported algorithm changes, no re-pack is needed — the app re-derives
  every score from the raw asset at launch.

---

# Design guidelines (BINDING — follow, do not deviate)

The app must look **consistent** everywhere. Do not hand-roll one-off styling that duplicates
something a shared widget/token already provides. If you need a variant, extend the shared
component with a flag — never copy-paste a second implementation.

**Open-source app — no Pro tier, no accounts.** There is nothing to sign into, no plans, no
paywalled features. Never add a "PRO"/plan badge, account/profile card, sign-in or sign-out. If a
reference screenshot shows account/Pro/upgrade UI, that part is out of scope — drop it, keep only
the real functionality.

## Tokens — the single source of truth
- **Colours:** ONLY `Palette.*` (`lib/ui/theme/palette.dart`). Never raw `Color(0x…)` /
  `Colors.*` in screens except pure black/white/transparent for overlays. Theme-aware via
  `Palette.isLight`. Sleep stages use `Palette.sleepAwake/Light/Deep/REM` (our blues — **no pink**).
- **Type:** ONLY `NoopType.*` (`title1/title2/headline/subhead/body/footnote/caption/overline`,
  `number(size)`, `display(size)`). Never a bare `TextStyle(fontSize: …)`.
- **Spacing / radii:** `Metrics.*` (`space*`, `gap`, `corner*`). Don't invent magic numbers when a
  token fits.

## Shared components — reuse these, don't reinvent
- **Cards:** `NoopCard` (`lib/ui/components/cards.dart`). Flags: `bordered`, `squircle`, `accent`,
  `onTap`, `radius`. **Card corners on the home surfaces use `squircle: true`** (iOS-style
  continuous `RoundedSuperellipseBorder`).
- **Back button:** `NoopBackButton` (`lib/ui/components/scaffold.dart`) — the ONLY back affordance.
  Bare rounded back arrow in a 40×40 circular tap target. Never build another back button.
- **Screen shell:** `ScreenScaffold` for standard title+back+scroll screens. Any screen that can be
  **pushed** (via `noopRoute`) must sit under a `Material` ancestor (ScreenScaffold provides one) —
  otherwise `Text` renders the debug yellow underline.
- **Gauges:** `MetricGauge` (`lib/ui/components/metric_gauge.dart`) — the signature liquid "water"
  vessel (or ring, per `gaugeStyleProvider`). Score heroes use this, not bespoke arc painters.
  Centre colour/shadow via `gaugeCenterColor(style)` / `gaugeCenterShadows(style)`.
- **Charts:** `lib/ui/components/health_charts.dart` — `HealthTimeline` (jagged detail line),
  `HealthMiniLine` / `HealthMiniBars` (card charts), `HealthDetailChart` (large, with target band +
  value axis). `BarSeries` / `Sparkline` in `charts.dart` for simple series.
- **Sheets/toasts/routes:** `showNoopSheet`, `noopToast`, `noopRoute` (`components/behavior.dart`).

## Look
- **Flat — no decorative gradients.** Backgrounds and fills are solid. `ScenicBackground` is a flat
  canvas. The only gradient-bearing exceptions are the liquid/ring gauge internals (the "water"
  animation the user likes) and the Journal purple hero. Don't add new gradients.
- No hover effects on tappable gauges/cards. No visible scrollbar (global `_NoScrollbarBehavior`).
- Bottom nav + floating "+" are frosted/translucent; **pages must fill the whole body** (content
  scrolling *under* the bar) so its transparency reads — never wrap a tab page in its own opaque
  `Scaffold` (use a `Container(color: surfaceBase)` / `Material` root + bottom padding ~120 instead).

## Data
- Screens read through providers (`daysProvider`, `selectedDayProvider`, `weightLogProvider`,
  `gaugeStyleProvider`, …) — never construct repositories directly. Persisted prefs go through
  `Prefs` (secure storage, crash-safe).
