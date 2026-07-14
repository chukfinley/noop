# flutter_app — Notes

## NEVER launch the app — verify with `flutter test`
**Do NOT run/launch/start the app** (`flutter run`, `flutter-hot`, screenshots, any device).
The user runs it himself and does his own hot reload. Our verification loop is tests, not the GUI:

```
change code → flutter analyze → flutter test → read the analysis report → done
```

`flutter test` is the gate. It proves the ported algorithm is correct BEFORE anything is built:
- `test/analytics/engines_unit_test.dart` — pins each ported engine (HrvAnalyzer, StrainScorer,
  RecoveryScorer, Baselines) to hand-computed reference numbers. Change a formula/constant → this
  fails first.
- `test/live_repository_test.dart` — seeds synthetic strap rows into the drift store and asserts the
  live pipeline scores them (incl. the strap-`sleep_state` sleep path).
- `test/db/data_portability_test.dart` — round-trips a Kotlin/Apple `.noopbak`/`.sqlite` import and
  our own export.

If a change has a runtime surface the tests don't cover, add a test — never reach for the app.

---

## Live-only data pipeline (no bundled personal data)
The app is **live-only**: it starts EMPTY and fills from the user's OWN WHOOP strap over BLE. There
is **no bundled capture and no personal data in the repo** — synthetic test data only. Never add a
real capture, DB, screenshot or ground-truth of anyone's biometrics.

- **Source:** the strap's synced per-second rows in the local drift store (`hrSample` / `rrInterval`
  / `gravitySample` / `sleepStateSample` / …). `lib/core/data/live_repository.dart` regroups them
  per local day into `RawDay`/`RawSample` (`lib/core/analytics/raw_samples.dart`) and scores them.
- **Ported algorithm (Kotlin → Dart):** the Kotlin analytics in `../android/.../analytics/` are the
  reference, faithfully ported to `lib/core/analytics/`: `hrv_analyzer.dart`, `recovery_scorer.dart`,
  `strain_scorer.dart`, `baselines.dart`, `sleep_stager.dart` (strap `sleep_state` first, HR
  heuristic fallback), `engines.dart`.
- **Orchestrator:** `lib/core/analytics/daily_pipeline.dart` runs the ported engines per local day.
  `main()` builds a `LiveRepository` from the DB (empty until the strap syncs) — never a bundled
  asset. `MockRepository` provides synthetic data for widget tests only.
- **Import/export:** `lib/core/data/portability/data_portability.dart` imports a Kotlin/Apple NOOP
  backup (raw sensor tables map 1:1) and exports our own `.noopbak`; the pipeline re-derives scores.
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
