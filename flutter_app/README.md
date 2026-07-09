# NOOP — Flutter

Flutter rewrite of the NOOP recovery / sleep / strain tracker. **UI + presentation
logic live here**; device sync (BLE) and the heavy raw-sample pipelines stay in the
Kotlin/Android app and will feed this UI over a platform channel.

## Status — Kern-Pilot (phase 1)

Working, builds clean (`flutter analyze` = 0 issues, `flutter test` green, web build OK).
Runs on mock data driven through the **real ported scoring engines**, so the numbers are
internally consistent — Charge is computed from HRV/RHR baselines, Rest from sleep stages,
Stress from trailing means, Effort from a TRIMP integral.

### What's in
- **Design system** — the full Titanium/WHOOP palette (dark + light + "Classic" ramps),
  spacing/typography/motion tokens, ported 1:1 from `Theme.kt` / `PaletteTokens.kt`.
- **Analytics engines** (`lib/analytics/`) — faithful Dart ports: winsorized-EWMA
  baselines, Recovery/Charge, Strain/Effort (Edwards TRIMP), Rest/sleep-performance,
  Stress, HR zones, sleep need/debt, caffeine decay.
- **Components** (`lib/ui/components/`) — frosted cards, the ring gauge, metric tiles,
  sparklines, bar series, segment bars, hypnogram, glass bottom bar, scenic background.
- **Screens** — Today (hero rings + dashboard + vitals + key metrics), Trends, Sleep
  (hypnogram + stages + debt), plus via **More**: Workouts, Health, Settings.
  Nav = Today · Trends · Sleep · More (mirrors the Android shell).

### The data seam
`lib/data/repository.dart` defines `abstract class Repository`; everything reads through
it via `repositoryProvider`. Today it's `MockRepository`. To wire real data, implement
`Repository` over a `MethodChannel`/`Pigeon` to the Kotlin sync+calc layer — **no screen
changes needed**.

## Run
```bash
flutter pub get
flutter run                 # device/emulator
flutter run -d chrome       # web
flutter test
```

## Not yet ported (later phases)
BLE stack, real sync, Oura/Apple-Health ingest, and the long tail of secondary screens
(Coach, Insights, Breathe, Automations, …) — these stay native or come in phase 2.
