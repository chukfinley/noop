# WHOOP Integration — MASTER BACKLOG

**Status:** authoritative. This is the single prioritized plan for finishing the WHOOP strap
integration. It supersedes ad-hoc TODOs. Every work item references its recon spec under
`docs/reverse/`, and every confirmed defect names the exact file + fix direction.

---

## 0. DECISIONS & DELIVERY STATUS (updated 2026-07-12)

**Shipped & committed this cycle** (suite green, ~316 tests, `flutter analyze` clean):
- Protocol decode + offload sync engine (DecoderOracle byte-golden), transport (scan/auto-detect/
  reconnect), HR broadcast, permissions, live device screen + honest pills.
- Bonding stack, kill-proof background sync (WorkManager + heartbeat guard), **smart alarm**
  (Phase 1, byte-exact; WHOOP4 confirmed, WHOOP5 experimental), device-config + **haptics** (Phase 2:
  locate buzz + broadcast-HR-on-strap).
- Phase 0 — **all 7 confirmed correctness defects fixed** (migration crash, scan/connect wedges,
  background double-owner, broadcaster leaks).
- Phase 5 — **untapped data capture**: all decoded-but-dropped WHOOP5 v18 fields now persisted
  (`rawFieldSample`, schema v4). Raw data is durable, append-only, immutable.
- **Live-only data**: the app no longer loads the bundled historical capture — it derives everything
  from live strap syncs (drift), recalibrating from scratch.

**User decisions:**
- **Phase 6 (Workouts) → BACKLOG.** Deferred, to be done someday. NOT implemented now.
- **Phase 8 (OTA firmware update) → CANCELLED / STRUCK.** Brick risk = money risk; the user vetoed it.
  Do not build it. `firmware-update-ota.md` stays only as RE reference, marked cancelled. Any future
  build must be an explicit new decision, default-OFF, behind a heavy guard.
- **GB-retention + raw→analytics live re-derivation** — remain deferred (§5, user's call).

**Remaining, un-owned (need a future go):** Phase 3 analytics wins (evaluated, all regressed on our
data — see below; only the resp estimator is a genuine bug worth a validated pass), Phase 4 bond
hardening extras, Phase 7 broader command coverage + EVENT demux.

**All BLE behaviour is compile+test verified but needs ON-DEVICE validation** (GATT can't be unit
tested per CLAUDE.md). Use the in-app connection log + this doc's specs to debug on the real strap.

**Verification gate (BINDING):** `flutter analyze` clean, then `flutter test`. Do NOT launch the
app. Each BLE opcode/frame change ships with a byte-exact frame roundtrip test; each analytics
change is gated on the printed report from `test/pipeline_real_data_test.dart`. See CLAUDE.md.

---

## 1. Executive summary

The reverse-engineering phase is **done and the news is good**: the hard part — the BLE transport —
is already correctly ported. The 4.0 CRC8 and 5.0 puffin CRC16 framing, seq, write-with-response,
and the offload loop are byte-verified against three independent sources (official decompiled app,
an independent HCI-snoop Kotlin RE, and our hardware-captured Kotlin twin). What remains is almost
entirely **breadth and wiring**, not new protocol discovery:

- **Command breadth.** Our Dart `CommandNumber` enum ports 25 of the strap's 80 opcodes; only ~6 are
  wired to an actual `_send()` call-site. Roughly 19 are declared-but-unwired (alarm, haptics, HR
  toggle, hello/version, wrist, raw-data) and ~10 more benign read opcodes are missing entirely. The
  payload encoders for the high-value features (alarm, haptics, config) are **already byte-identical
  to the official app** — they just have no call-site.
- **Correctness debt.** Eight confirmed defects, four of them **high severity**. Two brick the app
  outright (a migration crash and a scan/connect wedge). These block everything else being useful in
  the field and are sequenced first.
- **Analytics.** Eight portable, pure-Dart post-decode wins that measurably improve recovery/sleep/
  strain accuracy against WHOOP ground truth. Zero protocol risk — no wire, framing, or schema change.
- **Honest negatives.** Several intuitively-expected features are **not strap channels** and are
  documented as such so nobody wastes time hunting a nonexistent opcode: workout start/stop, GPS/route,
  the Stress score, WHOOP4 step count, workout auto-detection, and the RGB status LED. These become
  fully-local or are dropped, per the design guidelines.

**Deferred by user decision:** GB-scale raw-capture retention, and re-deriving analytics live from the
raw asset (see §5). Nothing in the ranked plan depends on either.

The plan below is ordered highest-ROI / lowest-risk first. Do the four brick/wedge bug fixes, then the
alarm+haptics wiring (payloads already done), then analytics accuracy (pure Dart), then connection
hardening, then the read-only data channels, and only then the two heavy/risky optional tracks
(background-sync arbitration, OTA) which ship default-OFF.

---

## 2. Ranked implementation plan

Ranking key: **ROI** (user-visible value ÷ effort), **Risk** (brick/regression/hardware-capture
dependency). Highest ROI at lowest risk first. Each phase is independently shippable and test-gated.

### Phase 0 — Stop the bricks (do first, blocks everything)
**Spec:** correctness defects (§4 below). **ROI:** critical. **Risk:** low (small, well-scoped fixes).

Two of the four high defects prevent the app from being usable at all in the upgrade/reconnect path:
the v1→v3 migration crash (DB won't open) and the scan give-up wedge (Connect dies forever). These
gate every other feature because a feature you can't reach through a crashed DB or a dead Connect
button is worthless. Fix all four transport-lifecycle high/low defects and the DB migration defect
here. See §4 for file+line+fix on each. Test-gate: a from-v1 migration test that opens the DB, and a
scan-timeout unit test that asserts `_state` leaves `scanning` and `lastError` is set.

### Phase 1 — Smart alarm (payload done, just wire it)
**Spec:** `docs/reverse/smart-alarm.md`. **ROI:** very high. **Risk:** very low.

`AlarmPayload.build()` is already byte-identical to the official app across all three sources; the
opcodes (`SET/GET/RUN/DISABLE_ALARM` = 0x42–0x45) are already correct in the enum. The only gap is
that `WhoopBleClient`/`AlarmService` have **zero** BLE alarm wiring. Add the four `_send` call-sites
(reuse `Framing.buildCommand`/`puffinCommandFrame`), parse the GET readback defensively (do not gate
behaviour on its undocumented body), and surface it in Settings. This is the single best ROI item:
a headline "strap wakes you even with the phone away" feature that needs no new payload work.
Test-gate: existing `Whoop4AlarmPayloadTest`/`AlarmReadbackDecodeTest` plus a new send-frame roundtrip.

### Phase 2 — Device config + haptics wiring
**Spec:** `docs/reverse/device-config-and-haptics.md`. **ROI:** high. **Risk:** low.

The 0x78 SET_CONFIG (40-byte), 0x77 SET_DEVICE_CONFIG (33-byte broadcast-HR), and the 12-byte
LITTLE_ENDIAN DRV2625 haptics body are all byte-pinned; our `maverick` payload already matches. Wire
`buzz/buzzStrapOnce/stopHaptics/buzzTimeNow/setBroadcastHr` into `whoop_ble_client.dart`, add the
missing Kotlin **5/MG allow-list** and the **0x13 haptic remap** (raw 79 is rejected on 5/MG with
result 0x03; 4.0 keeps RUN_HAPTICS_PATTERN 79 + STOP 0x7A), and add the deep-data/broadcast-HR opt-in
gating. Two new `Prefs` opt-ins + Settings toggles. Honest scope cuts: on-wrist "force" command does
not exist (read-only strap event), and the RGB LED has no app opcode — do not build UI for either.
Test-gate: puffin-0x13 frame roundtrip + a pure `buzzTimeNow` schedule test (no launch).

### Phase 3 — Analytics accuracy (pure Dart, no protocol touch)
**Spec:** `docs/reverse/analytics-improvements.md`. **ROI:** high. **Risk:** low (no wire/schema change).

Eight ranked post-decode DSP wins on samples the transport already delivers. Work the list top-down,
gating each on the printed pipeline report:
1. **Deep-lock the RMSSD window by default + Zepp artifact filter** — highest confidence; fixes the
   1.34×-hot whole-night RMSSD that inverts recovery (validated r 0.54→0.70 HRV, 0.01→0.48 recovery).
   Machinery already exists in `daily_pipeline.dart`/`prefs.dart`; flip default to `deepSleep`, port
   `rmssd_zepp`.
2. **5-component sleep score** with real 7-night onset-consistency instead of hardcoded 0.7 (r 0.97).
3. **Strain** tuned zone weights + k=2.702/c=24.84 log curve + coverage^2.59 correction our sparse
   daytime capture needs (r 0.88).
4. **Real respiratory rate** via RSA Welch-PSD 0.15–0.5Hz — promotes resp out of "coming soon".
5. **Recovery weighting A/B** (both refs weight RHR≥HRV, resp ~0.24–0.30 vs our HRV-.55/resp-.05).
6. Staging feature adds (per-epoch RMSSD + HR-variance, restless-signal edge-trim).
7. Strain-aware sleep need.
8. Blocked/skip (skin-temp/SpO2 uncalibrated; SaA actigraphy + HistGBT/Viterbi ML stager) — documented,
   not attempted.
Test-gate: `engines_unit_test.dart` reference numbers + the `pipeline_real_data_test.dart` report.

### Phase 4 — Connection/bond hardening
**Spec:** `docs/reverse/bond-connection-statemachine.md`. **ROI:** medium-high. **Risk:** medium
(some steps need hardware capture to fully verify).

Overlaps Phase 0's lifecycle fixes; do the byte-precise reference work here. Six gaps vs the Kotlin
twin: (1) `requestMtu(247)` before discovery, (2) the 30s keep-alive that bounces frozen HR after
120s silence, (3) thread `device.disconnectReason` HCI codes into the loop detector to separate
timeout/local-terminate/never-bonded (unlocks #982), (4) extend `DeviceFamily` to the three new
straps (five GATT families total: 61080001/fd4b0001/11500001/59830001/8a580001), (5) 20s scan timeout
+ split bond-refusal vs slow-handshake counters, (6) a PII-free `BondEvents` drift table for durable
connection history. Reuse `Framing.buildCommand`, `CommandNumber`, `ReconnectBackoff`, existing bond
helpers. Open questions needing hardware capture are listed in the spec — capture-gate those.

### Phase 5 — Untapped read-only data channels
**Spec:** `docs/reverse/untapped-data-channels.md`. **ROI:** medium. **Risk:** medium (some byte
layouts unconfirmed → capture-gate).

Add the safe **read** opcodes and decoders: live raw DSP block (type 43/0x2B via START_RAW_DATA 0x51),
realtime/historical IMU (types 51/52 via 0x6A/0x69), WHOOP4 optical PPG (0x6B/0x6C), body-location +
wear (GET_BODY_LOCATION 0x54), extended battery (GET_EXTENDED_BATTERY_INFO 0x62). Plus the cheap schema
win: `step_cadence@59` and ~10 other v18 fields are decoded but dropped before a drift column (still in
`RawSensorArchive.rawHex`) — add additive Room-mirrored columns/tables with a schemaVersion bump.
**Always archive the raw frame first and CRC-gate.** Honest negatives baked in: Stress, GPS/route,
WHOOP4 step count, and workout auto-detect are NOT strap channels — do not add opcodes for them.

### Phase 6 — Local workouts / activities
**Spec:** `docs/reverse/workouts-activities.md`. **ROI:** medium. **Risk:** low (no protocol at all).

Firm NEGATIVE verdict confirmed against the complete 76-opcode command enum and 55-event enum: there
is **no** BLE command that starts/stops/marks a workout and **no** strap event marking an activity. A
workout is phone+cloud side. So build it **fully local**, mirroring our own already-correct Kotlin
model (`AppViewModel.startWorkout` sends zero BLE commands): an active-workout window provider,
accumulate HR from the existing live/persisted streams, run the already-ported `StrainScorer`
(Edwards/Banister TRIMP→Effort), write rows into the already-declared `Workouts` drift table
(`database.dart:147`). No new opcode, framing, or migration. Low risk, decent value, so it sits after
the protocol-bearing phases but is a good "no-hardware-needed" filler.

### Phase 7 — Broader BLE command coverage
**Spec:** `docs/reverse/ble-command-inventory.md`. **ROI:** low-medium. **Risk:** low-medium.

Finish the inventory: wire the remaining already-declared safe commands (hello/version, wrist, etc.)
via `_send` call-sites, add the ~10 benign MISSING read opcodes to the enum (high-freq-sync, extended
battery, body-location, IMU/optical toggles, ff/config reads), and build out the
COMMAND_RESPONSE/EVENT demux persisting to the `WhoopEvents/Events/DeviceInfo/Alarms` drift tables —
this is the real remaining gap (response/EVENT decoding, not correctness). The ~14 destructive opcodes
(firmware/DFU/FORCE_TRIM/reboot/fuel-gauge/AFE) stay **deliberately excluded** from the safe enum.
Byte-exact frame test per opcode.

### Phase 8 — OTA firmware update (OPTIONAL, ship default-OFF)
**Spec:** `docs/reverse/firmware-update-ota.md`. **ROI:** low (nice-to-have parity). **Risk:** HIGH
(the one genuine brick risk — untested ROM SBL boot-time checks).

Last by design. Server download (Base64 ZIP `firmware_zip_file`) + Ambiq-native puffin flash for the
5.0/Maverick main MCU: START_FIRMWARE_LOAD_NEW 0x8E → LOAD 0x8F (acked per chunk) → PROCESS 0x90
(CRC32) → VERIFY 0x53 → auto-reboot. Build `lib/core/ble/ota/{firmware_download,maverick_ota}.dart`
reusing `Framing.puffinCommandFrame`, `Crc.crc32`, `DeviceFamily.whoop5` UUIDs, and the transport (add
a `sendRawAwait` request/response seam + `requestMtu`); add an `OtaHistory` drift table (schema 3→4).
OTA opcodes stay OUT of the safe `CommandNumber` enum. **Ship default-OFF, Maverick + stock-image-only,
battery-gated.** Do not begin until real hardware is available to accept the brick risk.

---

## 3. Cross-phase dependencies (quick reference)

- Phase 0's transport-lifecycle fixes and Phase 4's hardening touch the same file
  (`whoop_ble_client.dart`) — coordinate so the six hardening gaps land on top of the four fixes, not
  in conflict with them.
- `requestMtu(247)` is needed by both Phase 4 (handshake) and Phase 8 (OTA `sendRawAwait`) — implement
  once in Phase 4.
- Phases 5, 7, and 8 each bump the drift `schemaVersion`. **Do not** land them concurrently without
  reconciling the migration chain — and land them only AFTER the §4 migration defect is fixed, or you
  inherit the same duplicate-column trap on a fresh version.
- Phase 3 (analytics) is fully independent of all BLE work — it can proceed in parallel by a second
  workstream with zero coordination.

---

## 4. Confirmed bugs (severity-ordered)

Each is a verified defect with a concrete failure path. Fix direction is given; keep changes minimal
and add the named test.

### HIGH-1 — v1→v3 migration crashes with "duplicate column name" (app bricked on upgrade)
**File:** `lib/core/data/db/database.dart:736` (block 711–742).
**Defect:** For a v1 client upgrading straight to v3, the `from < 2` block calls `createTable` using the
**live** generated table defs, which already carry the v3 columns (`WhoopHrSamplesTable` →
`hrFixed88`+`onwrist` per `database.g.dart:12168-12202`; `gravitySample` → `dynamicAccel`). Then the
`from < 3` block runs unconditionally and `addColumn`s those same three columns → SQLite
`duplicate column name`. Migration throws, transaction rolls back, DB won't open. This is the common
pre-Wave-D v1 → current v3 path (skipping the v2-only build). `rawSensorArchive.trimCursor/family`
(740–741) are unaffected (created by onCreate at v1, not recreated in `from < 2`).
**Fix:** Guard the three v3 `addColumn` calls to run only for `from == 2`
(`if (from == 2) { addColumn... }`), or restructure so tables (re)created in the `from < 2` step are
never re-altered in the `from < 3` step. **Test:** a from-v1 migration test that opens the DB and
asserts the three columns exist exactly once.

### HIGH-2 — Scan give-up missing; client wedges in `scanning` forever
**File:** `lib/core/ble/transport/whoop_ble_client.dart:751`.
**Defect:** The Kotlin reference arms a `scanTimeoutRunnable` (WhoopBleClient.kt:1102-1114) that on no
discovery calls `stopScan()`, resets `scanning=false`, and sets a 'No strap found' note. The Dart port
has no equivalent — it only passes `timeout: scanTimeout` to FlutterBluePlus, which stops the LE scan
but never resets `_state` out of `scanning`, never sets `lastError`. `_scanFallbackTimer` rotates the
family once then also never gives up. Because `connect()/connectToStrap()/connectRemembered()` early-
return while `_state` is scanning/connecting (402–406, 596–600, 640–644), Connect is permanently dead
after a failed scan (strap on charger / official app holds it / out of range). Only app restart
recovers.
**Fix:** Port the scan-timeout runnable: on elapse call `stopScan()`, reset `_state` off `scanning`,
set `lastError` ('No strap found'). **Test:** scan-timeout unit test asserting `_state` leaves
`scanning` and `lastError` is set, and a subsequent `connect()` is no longer a no-op.

### HIGH-3 — discoverServices failure leaves a half-open link stuck in `connecting`
**File:** `lib/core/ble/transport/whoop_ble_client.dart:896`.
**Defect:** `_onConnected` sets `_connected=true` (887) with `_state==connecting`. The
`discoverServices()` catch (897–900) and the 'Custom WHOOP service not found' branch (915–919) just
log and return — they do NOT `device.disconnect()`, schedule a reconnect, or reset `_state` (unlike the
`_ensureBonded==false` branch which does). Result: `_connected=true`, `_state` stuck at `connecting`,
live-but-useless GATT link, no reconnect, and `connect()` early-returns forever (402–406). Common on
Android GATT status≠0.
**Fix:** In both branches, `device.disconnect()` and let `_onDisconnected` back off/reconnect (mirror
the `_ensureBonded==false` path), or explicitly reset `_state` and schedule reconnect. **Test:** a
discovery-failure path test asserting the link is torn down and `_state` is recoverable.

### HIGH-4 — Foreground launch during in-flight WorkManager offload creates two concurrent BLE owners
**File:** `lib/core/ble/background/background_sync_worker.dart:125`.
**Defect:** The single-owner guarantee is asymmetric. `runHeadlessWhoopSync()` calls `appIsAlive(db)`
**once** at start (125) then runs `_runOneOffload` for up to `kBgSyncMaxRuntime` (8 min) with no
re-check. The foreground side (`main.dart:54` `kickWhoopAutoConnect` → `connectRemembered`) fires
unconditionally at launch and never checks whether a headless task owns BLE; there is no reverse guard.
On Android the worker shares the app process and `flutter_blue_plus` is a native singleton, so two
`WhoopBleClient`s drive one strap and two `AppDatabase` handles write one `noop.sqlite`. Worse,
`appIsAlive` returns false on any exception (156) — a lost heartbeat lock **fails open** into exactly
the overlap it should prevent. Result: duplicated/failed GATT ops, offload-cursor races, drift lock
contention.
**Fix:** Make the guard symmetric and re-checked: (a) foreground `kickWhoopAutoConnect` must check for a
live worker heartbeat before connecting and yield if one owns BLE; (b) the worker must re-check
liveness periodically inside the 8-min loop and bail if the foreground claims BLE; (c) make
`appIsAlive` fail **closed** (treat lock-contention/exception as "alive/owned", not "dead"). Use a
single explicit ownership token rather than inferring from a heartbeat timestamp. **Test:** a headless
seam test simulating an overlapping foreground claim, asserting only one owner proceeds.

### MEDIUM-1 — HrBroadcaster leaks subscribers on abrupt central disconnect
**File:** `lib/core/ble/broadcast/hr_broadcaster.dart:165`.
**Defect:** The Kotlin original removes a central in `gattServerCallback.onConnectionStateChange` on
`STATE_DISCONNECTED` (HrBroadcaster.kt:239-246). The Dart port only mutates `_subscribers` from
`characteristicNotifyStateChanged` and never subscribes to `PeripheralManager.connectionStateChanged`.
A central that drops without writing CCCD=0 (treadmill powered off, walking out of range) stays in
`_subscribers` forever; every `update(bpm)` fans out a notify to it, hitting a swallowed
`ArgumentError.notNull()` inside the plugin. No crash, but the set grows unbounded and
`subscriberCount` is wrong.
**Fix:** Subscribe to `PeripheralManager.connectionStateChanged` and remove the central from
`_subscribers` on disconnect (port the Kotlin handler). **Test:** unit test that a disconnect event
prunes the subscriber and keeps the count honest.

### MEDIUM-2 — HrBroadcaster.start() aborts on first enable because manager.state is stale
**File:** `lib/core/ble/broadcast/hr_broadcaster.dart:83`.
**Defect:** `start()` does `if (isAndroid && state==unauthorized) await authorize();` then immediately
`if (state != poweredOn) bail;`. In `bluetooth_low_energy_android`, `authorize()`
(peripheral_manager_impl.dart:118-123) returns only the grant bool and does NOT refresh `_state`
(updated only via async `onStateChanged` or `_getState()`). So right after a first grant, `state` is
still the cached `unauthorized/unknown`, the check fails, and start logs 'Bluetooth not powered on' and
sets `_wantAdvertising=false` without advertising. Only a later toggle (post-resume) works. Kotlin
avoids this by reading live `adapter.isEnabled` (HrBroadcaster.kt:108).
**Fix:** After `authorize()`, refresh state via `_getState()` (or await the state event) before the
`!= poweredOn` check, or query the live adapter state rather than the cached `manager.state`. **Test:**
unit test that a first-time grant path proceeds to advertise.

### LOW-1 — Reconnect backoff counter not reset on user-initiated connect
**File:** `lib/core/ble/transport/whoop_ble_client.dart:407`.
**Defect:** `_reconnectAttempt` is cleared only in `_onConnected` (890). `connect()`,
`connectToStrap()`, `connectRemembered()`, and `_resetBondStateForUserAction()` don't reset it. After
several involuntary drops inflate the counter, a manual Connect that stalls before `_onConnected`
leaves the stale large count in place, so the next involuntary drop waits the capped-max
`ReconnectBackoff` delay instead of restarting the ramp.
**Fix:** Reset `_reconnectAttempt = 0` in the user-initiated connect paths (or in
`_resetBondStateForUserAction`). **Test:** unit test that a user connect resets the backoff counter.

---

## 5. Deferred (per user)

These are explicitly **out of scope for the next implementation workflow** by user decision. Recorded
here so they are not silently re-picked up; nothing in §2 depends on them.

- **GB-scale raw-capture retention.** Long-term persistence of the full per-second raw sensor archive
  (the multi-gigabyte capture footprint) is deferred. Current behaviour — archiving raw frames for the
  active decode window and CRC-gating — stays; we do NOT build unbounded on-device raw retention now.
  Any new decoder (Phase 5/7) still archives its raw frame first for that window, but retention policy
  is unchanged and not expanded.
- **Raw → analytics live re-derivation.** Re-running the full ported pipeline live from the raw asset
  on-device (beyond the existing launch-time derivation the app already does for the bundled capture)
  is deferred. The Phase 3 analytics improvements are pure post-decode DSP on samples the transport
  already delivers per session; they do NOT require the deferred live re-derivation path. Keep the
  existing `real_repository.dart` launch-time derivation as-is.

---

## 6. Spec index

| Spec | Drives phase | One-line |
|------|--------------|----------|
| `smart-alarm.md` | 1 | Strap firmware wake alarm; payload already byte-exact, just wire 0x42–0x45. |
| `device-config-and-haptics.md` | 2 | 0x77/0x78 config + DRV2625 haptics; add 5/MG allow-list + 0x13 remap. |
| `analytics-improvements.md` | 3 | 8 ranked pure-Dart accuracy wins; no protocol/schema change. |
| `bond-connection-statemachine.md` | 4 | MTU 247, keep-alive, HCI-code loop demux, 5 GATT families, BondEvents. |
| `untapped-data-channels.md` | 5 | Safe read opcodes + decoders (raw DSP/IMU/PPG/body/battery) + schema fields. |
| `workouts-activities.md` | 6 | Firm negative: no strap workout opcode; build fully-local via StrainScorer. |
| `ble-command-inventory.md` | 7 | Full 80-command table; wire declared, add benign missing, build EVENT demux. |
| `firmware-update-ota.md` | 8 | Ambiq puffin OTA (0x8E/0x8F/0x90/0x53); default-OFF, brick risk. |
