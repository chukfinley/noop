# NOOP

**Offline WHOOP companion.** Pair your WHOOP strap over Bluetooth, keep every byte of
your data on your own device. No cloud, no account, no subscription.

NOOP is a full **Flutter** app (Android + iOS from one codebase). It connects to the
strap over BLE, offloads its banked history, streams live heart rate, and scores
recovery, HRV, resting HR, sleep and strain **entirely on-device** — from your own
strap's data.

> The original native apps (SwiftUI for macOS/iOS, Kotlin for Android) are preserved
> under [`archive/`](archive/). This repository is now the Flutter rewrite.

## Download

Grab the latest signed APK from **[Releases](../../releases/latest)**:

- `noop-*-arm64-v8a.apk` — almost every phone from the last ~8 years. **Start here.**
- `noop-*-armeabi-v7a.apk` — older 32-bit phones.

Install on Android (allow installing from your browser / file manager). Requires
Bluetooth. iOS is built from the same codebase; a signed build is not distributed here yet.

## What it does

- **Recovery / Charge** — a single morning score from HRV, resting heart rate and sleep.
- **Sleep** — staging driven by the strap's own per-second sleep state, with hypnogram,
  efficiency and a nightly Rest score.
- **Strain / Effort** — continuous heart-rate strain (Edwards TRIMP) across the day.
- **Live heart rate** streamed over Bluetooth, and re-broadcast as a standard 0x180D
  sensor a treadmill / bike / Zwift can read.
- **Background sync** — keeps offloading while backgrounded; the notification clears
  itself when a sync finishes.
- **Import / export** — bring in a `.noopbak` / `.sqlite` backup from another phone or
  the archived Kotlin/iOS app, and export your whole store as a `.noopbak`. Import is
  additive — it never deletes what you already have.

Everything runs offline. Nothing leaves your device except through an explicit,
user-driven export.

## How it works

- **UI + logic:** Flutter / Dart (`flutter_app/lib`), one codebase for Android + iOS.
- **BLE:** `flutter_blue_plus` (native Android/iOS Bluetooth under the hood) driving a
  reverse-engineered WHOOP protocol — AA01 framing, ~40 opcodes, CRC, a chunked
  historical-offload state machine with an inactivity watchdog.
- **Storage:** a local SQLite store via `drift`. Raw per-second sensor rows in, scored
  days derived by the analytics pipeline.
- **Analytics:** RMSSD HRV, robust resting HR, Edwards-TRIMP strain, EWMA personal
  baselines, a recovery model — pinned to reference numbers by tests.

The BLE reverse-engineering is done under EU Directive 2009/24/EC Art. 6 / German UrhG
§69e (interoperability).

## Build from source

```bash
cd flutter_app
flutter pub get
flutter build apk --release --split-per-abi   # per-CPU APKs in build/app/outputs/flutter-apk
flutter test                                    # the test suite is the correctness gate
```

Release builds are signed with a private keystore configured via
`flutter_app/android/key.properties` (git-ignored); without it, the build falls back to
debug signing so a fresh clone still compiles.

## Archive

The pre-Flutter apps live under [`archive/`](archive/) for reference:

- `archive/android/` — the original Kotlin Android app.
- `archive/Strand/`, `archive/StrandiOS/`, `archive/Packages/`, `archive/NOOPWatch/`, … —
  the original SwiftUI macOS / iOS / watch app and its Swift packages.

They are no longer built or maintained; the Flutter app in `flutter_app/` supersedes them.

## License

See [LICENSE](LICENSE). Not affiliated with, endorsed by, or connected to WHOOP, Inc.
"WHOOP" is a trademark of its respective owner; used here only to describe interoperability.
