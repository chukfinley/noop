# WHOOP workouts & activities — BLE recon + implementation spec

**Status:** cross-verified against the decompiled official app, the strap command/event enums, the
whoop RE repo, and our own port. **Verdict is negative and firm** — see TL;DR.
**Scope:** does starting/stopping a workout involve the strap over BLE? What command starts an
activity, what events mark it, and how does the official app surface strain/effort from a workout?

---

## TL;DR for the implementer

- **There is NO "start workout" / "stop workout" / "mark activity" BLE command on the strap, and NO
  strap event that marks an activity period.** A workout/activity is a **phone-side + cloud-side
  construct**, not a strap-side one. The strap has no concept of "I am in a workout."
- Evidence: the official app's complete BLE command enum (`vp0.e`, **76 opcodes**) and the complete
  strap→app event enum (`yp0.a$b`, **55 events**) contain **zero** activity/workout/exercise/strain
  entries. See §2 and §3 for the full dumps.
- What the strap actually does during a workout is exactly what it does the rest of the day: stream
  **REALTIME HR + RR** (opcode `TOGGLE_REALTIME_HR = 0x03`, already ported) and/or bank the same
  samples into its historical buffer for later offload. The strap does not know a workout is
  happening.
- The official app creates an activity via a **cloud REST call** — `CreateActivityRequestV1`
  `{activityInternalName, startTime, endTime, garmentId, gpsEnabled}` (§4). Strain/effort for that
  activity is computed **server-side** (or, for the live tile, phone-side over the streamed HR).
- Our own noop Kotlin app already does the right thing: `AppViewModel.startWorkout()` sends **no BLE
  command** — it records a `{sport, startMs}` window in app state, buzzes the strap for feedback, and
  computes strain over the HR samples flowing in (§5).
- **So the Flutter implementation is 100% local**: capture a `{sport, start, end}` window, pull the
  HR/RR samples inside it, run the already-ported `StrainScorer`, and write a row into the existing
  (already-declared) `Workouts` drift table. No new opcode, no new framing, no protocol work. Full
  step-by-step in §7.

---

## 1. Evidence base

| # | Source | Path | What it gives |
|---|--------|------|---------------|
| A | Official WHOOP Android app v5.458.0 (decompiled smali) | `/home/user/git/whoop/research/work/whoop_apk/base_full/` | The authoritative list of what the real app can send to / receive from the strap. |
| B | Our ported protocol layer | `lib/core/ble/protocol/enums.dart`, `framing.dart` | The opcodes/framing we already ship. |
| C | Our noop Kotlin reference app | `android/app/src/main/java/com/noop/ui/{AppViewModel,WorkoutStart,LiveWorkoutScreen}.kt` | How the sibling app already models workouts (app-side). |
| D | Flutter drift schema | `lib/core/data/db/database.dart` | The `Workouts` table already declared for this feature. |
| E | Ported analytics | `lib/core/analytics/strain_scorer.dart` | The Edwards/Banister TRIMP→Effort engine to reuse. |

---

## 2. The strap BLE command enum — no activity opcode

The official app's outbound command opcodes live in one Kotlin enum, obfuscated to `vp0.e`:
`/home/user/git/whoop/research/work/whoop_apk/base_full/smali/com/whoop/... → smali_classes6/vp0/e.smali`.
Each constant carries a `byteValue:B` (`smali_classes6/vp0/e.smali:176`), assigned in `<clinit>`
via `<init>(Ljava/lang/String;II)V` where the 3rd arg is the on-wire byte
(`smali_classes6/vp0/e.smali:1240-1242`). The strap reads that byte at inner-frame offset `[cmd]`
(our `Framing.buildCommand` byte 6 / `puffinCommandFrame` inner[2]).

**All 76 opcodes** (name → byteValue, decoded from `<clinit>`):

```
LINK_VALID=0x01  GET_MAX_PROTOCOL_VERSION=0x02  TOGGLE_REALTIME_HR=0x03
TOGGLE_R7_DATA_COLLECTION=0x10  SET_CLOCK=0x0a  GET_CLOCK=0x0b  REPORT_VERSION_INFO=0x07
TOGGLE_GENERIC_HR_PROFILE=0x0e  RUN_HAPTIC_PATTERN_MAVERICK=0x13
ABORT_HISTORICAL_TRANSMITS=0x14  SEND_HISTORICAL_DATA=0x16  HISTORICAL_DATA_RESULT=0x17
GET_BATTERY_LEVEL=0x1a  REBOOT_STRAP=0x0c  FORCE_TRIM=0x0d  POWER_CYCLE_STRAP=0x19
SET_READ_POINTER=0x1d  GET_DATA_RANGE=0x22  GET_HELLO_HARVARD=0x23
START_FIRMWARE_LOAD=0x24  LOAD_FIRMWARE_DATA=0x25  PROCESS_FIRMWARE_IMAGE=0x26
START_FIRMWARE_LOAD_NEW=0x8e  LOAD_FIRMWARE_DATA_NEW=0x8f  PROCESS_FIRMWARE_IMAGE_NEW=0x90
VERIFY_FIRMWARE_IMAGE=0x53  SET_LED_DRIVE=0x27  GET_LED_DRIVE=0x28  SET_TIA_GAIN=0x29
GET_TIA_GAIN=0x2a  SET_BIAS_OFFSET=0x2b  GET_BIAS_OFFSET=0x2c  ENTER_BLE_DFU=0x2d
SET_DP_TYPE=0x34  FORCE_DP_TYPE=0x35  SEND_R10_R11_REALTIME=0x3f  SET_ALARM_TIME=0x42
GET_ALARM_TIME=0x43  RUN_ALARM=0x44  DISABLE_ALARM=0x45  GET_ADVERTISING_NAME_HARVARD=0x4c
SET_ADVERTISING_NAME_HARVARD=0x4d  RUN_HAPTICS_PATTERN=0x4f  GET_ALL_HAPTICS_PATTERN=0x50
START_RAW_DATA=0x51  STOP_RAW_DATA=0x52  GET_BODY_LOCATION_AND_STATUS=0x54
ENTER_HIGH_FREQ_SYNC=0x60  EXIT_HIGH_FREQ_SYNC=0x61  GET_EXTENDED_BATTERY_INFO=0x62
TOGGLE_IMU_MODE_HISTORICAL=0x69  TOGGLE_IMU_MODE=0x6a  TOGGLE_OPTICAL_MODE=0x6c
START_FF_KEY_EXCHANGE=0x75  … SET_FF_VALUE  GET_FF_VALUE  SEND_NEXT_FF  SET_DEVICE_CONFIG_VALUE
GET_DEVICE_CONFIG_VALUE  SEND_NEXT_DEVICE_CONFIG  START_DEVICE_CONFIG_KEY_EXCHANGE  SET_READ_POINTER
GET_HELLO  GET_RESEARCH_PACKET  SET_RESEARCH_PACKET  SET_ADVERTISING_NAME  GET_ADVERTISING_NAME
TOGGLE_LABRADOR_DATA_GENERATION  TOGGLE_LABRADOR_FILTERED  TOGGLE_LABRADOR_RAW_SAVE
TOGGLE_PERSISTENT_R20  TOGGLE_PERSISTENT_R21  ENABLE_OPTICAL_DATA  STOP_HAPTICS
GET_BATTERY_PACK_INFO  SELECT_WRIST  TRIM_ALL_DATA(FORCE_TRIM)
```

Full alphabetical name list (from `grep -o 'Lvp0/e;->[A-Z_0-9]*:'`):

```
ABORT_HISTORICAL_TRANSMITS DISABLE_ALARM ENABLE_OPTICAL_DATA ENTER_BLE_DFU ENTER_HIGH_FREQ_SYNC
EXIT_HIGH_FREQ_SYNC FORCE_DP_TYPE FORCE_TRIM GET_ADVERTISING_NAME GET_ADVERTISING_NAME_HARVARD
GET_ALARM_TIME GET_ALL_HAPTICS_PATTERN GET_BATTERY_LEVEL GET_BATTERY_PACK_INFO GET_BIAS_OFFSET
GET_BODY_LOCATION_AND_STATUS GET_CLOCK GET_DATA_RANGE GET_DEVICE_CONFIG_VALUE GET_EXTENDED_BATTERY_INFO
GET_FF_VALUE GET_HELLO GET_HELLO_HARVARD GET_LED_DRIVE GET_MAX_PROTOCOL_VERSION GET_RESEARCH_PACKET
GET_TIA_GAIN HISTORICAL_DATA_RESULT LINK_VALID LOAD_FIRMWARE_DATA LOAD_FIRMWARE_DATA_NEW
POWER_CYCLE_STRAP PROCESS_FIRMWARE_IMAGE PROCESS_FIRMWARE_IMAGE_NEW REBOOT_STRAP REPORT_VERSION_INFO
RUN_ALARM RUN_HAPTIC_PATTERN_MAVERICK RUN_HAPTICS_PATTERN SELECT_WRIST SEND_HISTORICAL_DATA
SEND_NEXT_DEVICE_CONFIG SEND_NEXT_FF SEND_R10_R11_REALTIME SET_ADVERTISING_NAME
SET_ADVERTISING_NAME_HARVARD SET_ALARM_TIME SET_BIAS_OFFSET SET_CLOCK SET_DEVICE_CONFIG_VALUE
SET_DP_TYPE SET_FF_VALUE SET_LED_DRIVE SET_READ_POINTER SET_RESEARCH_PACKET SET_TIA_GAIN
START_DEVICE_CONFIG_KEY_EXCHANGE START_FF_KEY_EXCHANGE START_FIRMWARE_LOAD START_FIRMWARE_LOAD_NEW
START_RAW_DATA STOP_HAPTICS STOP_RAW_DATA TOGGLE_GENERIC_HR_PROFILE TOGGLE_IMU_MODE
TOGGLE_IMU_MODE_HISTORICAL TOGGLE_LABRADOR_DATA_GENERATION TOGGLE_LABRADOR_FILTERED
TOGGLE_LABRADOR_RAW_SAVE TOGGLE_OPTICAL_MODE TOGGLE_PERSISTENT_R20 TOGGLE_PERSISTENT_R21
TOGGLE_R7_DATA_COLLECTION TOGGLE_REALTIME_HR VERIFY_FIRMWARE_IMAGE
```

**None of these is `START_ACTIVITY`, `START_WORKOUT`, `MARK_ACTIVITY`, `BEGIN_EXERCISE`, or
anything of the kind.** A direct grep confirms it:

```
$ grep -ri "START_WORKOUT\|START_ACTIVITY\|BEGIN_ACTIVITY\|MARK_ACTIVITY\|WORKOUT_START" \
    smali*/vp0/ smali*/li0/     # → no matches
```

The commands are entirely device-level: HR/RR streaming, historical offload, alarm, haptics,
firmware, raw/IMU/optical data collection, config feature-flags, battery, clock. Nothing workout-aware.

### The closest "activity-flavoured" commands (still not workout markers)

- `TOGGLE_REALTIME_HR = 0x03` — turns the live HR/RR notification stream on/off. This is what feeds
  the live-workout HR tile, but it is not workout-specific: it is the same stream used any time the
  app wants live HR. **Already ported** as `CommandNumber.toggleRealtimeHr(3)`.
- `ENTER_HIGH_FREQ_SYNC = 0x60` / `EXIT_HIGH_FREQ_SYNC = 0x61` — request faster historical offload;
  about sync throughput, not workouts.
- `TOGGLE_IMU_MODE = 0x6a` / `TOGGLE_OPTICAL_MODE = 0x6c` / `START_RAW_DATA = 0x51` — raise the
  sensor sample rate (accelerometer/PPG). These *could* be toggled during an activity to get denser
  data, but they are generic sensor-mode switches, not activity boundaries, and the app can leave
  them off entirely and still record a workout from ordinary 1 Hz HR.
- `RUN_HAPTICS_PATTERN = 0x4f` — the buzz the app fires as start/stop *feedback*. Cosmetic; carries
  no workout semantics.

---

## 3. The strap→app event enum — no activity event

The strap emits asynchronous EVENT frames (packet type 48). The official app decodes them through
the event enum obfuscated to `yp0.a$b` (`smali_classes6/yp0/a$b.smali`). **All 55 events:**

```
ACCELEROMETER_RESET ACCELEROMETER_SATURATION_DETECTED AFE_RESET APP_DRIVEN_ALARM_EXECUTED
BATTERY_LEVEL BATTERY_PACK_CONNECTED BATTERY_PACK_INFO BATTERY_PACK_REMOVED BLE_BONDED
BLE_CONNECTION_DOWN BLE_CONNECTION_UP BLE_HR_PROFILE_DISABLED BLE_HR_PROFILE_ENABLED
BLE_REALTIME_HR_OFF BLE_REALTIME_HR_ON BLE_SYSTEM_INITIALIZED BLE_SYSTEM_ON BLE_SYSTEM_RESET
BOOT BOOT_REPORT CAPTOUCH_AUTOTHRESHOLD_ACTION CHARGING_OFF CHARGING_ON CONSOLE_OUTPUT
DOUBLE_TAP ERROR EXIT_VIRGIN_MODE EXTENDED_BATTERY_INFORMATION FLASH_INIT_COMPLETE
GENERIC_FIRMWARE_EVENT HAPTICS_FIRED HAPTICS_TERMINATED HIGH_FREQ_SYNC_DISABLED
HIGH_FREQ_SYNC_ENABLED HIGH_FREQ_SYNC_PROMPT PAIRING_MODE RAW_DATA_COLLECTION_OFF
RAW_DATA_COLLECTION_ON RTC_LOST SERIAL_HEAD_CONNECTED SERIAL_HEAD_REMOVED SET_RTC
SHIP_MODE_BOOT SHIP_MODE_DISABLED SHIP_MODE_ENABLED STRAP_CONDITION_REPORT
STRAP_DRIVEN_ALARM_DISABLED STRAP_DRIVEN_ALARM_EXECUTED STRAP_DRIVEN_ALARM_SET SYSTEM_CONTROL
TEMPERATURE_LEVEL TRIM_ALL_DATA TRIM_ALL_DATA_ENDED UNDEFINED WRIST_OFF WRIST_ON
```

**No `ACTIVITY_STARTED`, `WORKOUT_DETECTED`, `EXERCISE_*`, `STRAIN_*`, or similar.** The strap
reports hardware state transitions only (battery, wrist on/off, charging, alarms, haptics, boot,
double-tap, sensor-mode toggles). There is no auto-detect-workout event on the wire.

- `DOUBLE_TAP` (raw 14, our `EventNumber.doubleTap(14)`) is the only user-gesture event. In the
  official app a double-tap is a generic UI trigger (e.g. log a marker/haptic ack), **not** a
  workout start/stop. It could be *repurposed* by us as a "tap to start/stop" affordance, but that
  is our product choice layered on top — the strap attaches no activity meaning to it.
- `WRIST_ON` / `WRIST_OFF` bound *wear* periods (used for sleep/off-wrist gating), not workouts.

**Auto-workout detection is server/phone-side.** WHOOP's "we detected an activity" nudge is inferred
from HR/motion after the fact by the app/cloud, not signalled by the strap. (Our sibling app mirrors
this with a phone-side heuristic: `com/noop/ui/AutoWorkoutNudge.kt`.)

---

## 4. How the official app models an activity — a cloud REST object

Creating an activity is a network call, not a strap write. The request DTO is
`com/whoop/addactivity/network/CreateActivityRequestV1`
(`smali/com/whoop/addactivity/network/CreateActivityRequestV1.smali`), a kotlinx-serializable class:

| Field (Kotlin) | JSON key | Type | Meaning |
|---|---|---|---|
| `activityInternalName` | `activity_internal_name` | String | sport identifier (e.g. running/cycling) |
| `startTime` | `start_time` | String (ISO-8601) | window start |
| `endTime` | `end_time` | String (ISO-8601) | window end |
| `garmentId` | `garment_id` | Int | which strap/garment recorded it |
| `gpsEnabled` | `gps_enabled` | Bool | whether a GPS route was captured |

Related server DTOs in the same package: `CreateActivityResponse`, `CoreDetailsActivityResponse`,
`EditedActivityPayload` (edit an existing activity's sport/time). The app's start-activity UI is
`com/whoop/startactivity/**` and `com/whoop/realtime/presentation/{StartActivityActivity,
RealTimeRecordActivity,RealTimeFinishPromptActivity}` — a screen + a cloud call, with the live HR
number coming from the ordinary realtime stream.

**Where does strain/effort come from?** The activity object carries a start/end window; the strap
supplies the HR/RR inside that window (live-streamed and/or historically offloaded). Strain is then
computed **from those HR samples over the window** — server-side for the authoritative number, and
phone-side for the live tile. It is *not* a value the strap emits. (Per project scope, the cloud
strain math itself is out of scope — we recompute it locally with our own `StrainScorer`.)

---

## 5. What our noop Kotlin app already does (the correct model to port)

`com/noop/ui/AppViewModel.kt:964 startWorkout(sport, gpsEnabled)`:

- Guards against a double-start, sets `_activeWorkout = ActiveWorkout(startMs, sport, gpsEnabled)` —
  a pure in-memory window.
- `buzz(1)` — a single haptic as start feedback (that is the only strap interaction, and it is
  `RUN_HAPTICS_PATTERN`, not an activity command).
- If GPS: hands the window to a process-level `GpsSession` + foreground service for route capture.
- If not GPS: snapshots the window to durable storage so an OS kill can rehydrate it.
- **No `TOGGLE_REALTIME_HR`, no activity opcode, no strap write of any kind is required to *start* a
  workout** — HR is already streaming whenever bonded, and the live strain (`ActiveWorkout.liveStrain`,
  `avgHr`, `peakHr`) is accumulated on the phone from those samples.

`endWorkout()` closes the window and finalizes a workout record. The UI (`WorkoutStart.kt`,
`LiveWorkoutScreen.kt`) is a sport picker + a live timer/HR/strain card — all phone-side.

**Conclusion:** the Flutter port is a straight lift of this app-side model. There is nothing to
reverse-engineer on the wire because the wire is not involved.

---

## 6. Reusable pieces already in the Flutter app

| Piece | Location | Use in this feature |
|---|---|---|
| `CommandNumber.toggleRealtimeHr(3)` | `lib/core/ble/protocol/enums.dart:89` | (Optional) ensure the live HR stream is on while a workout is open. Already wired via `WhoopBleClient._send`. |
| `Framing.buildCommand` / `puffinCommandFrame` | `lib/core/ble/protocol/framing.dart:621,666` | Only needed for the optional realtime-HR toggle above; **no new command to build.** |
| `WhoopBleClient._send(cmd,…)` | `lib/core/ble/transport/whoop_ble_client.dart:1522` | The single send path if we choose to force-enable realtime HR on workout start. |
| Live HR/RR stream → persistence | `lib/core/ble/sync/stream_persistence.dart` → `HrSamples`/`RrSamples`/`WhoopHrSamples`/`WhoopRrIntervals` tables | Source of the HR samples inside the workout window. |
| `Workouts` drift table (already declared) | `lib/core/data/db/database.dart:147-170` | Destination row. Columns already fit: `id, sport, sportId, startTs, durationSec, avgHr, maxHr, effort, calories, distanceKm, elevationGainM, source, zonesJson, gpsRouteJson, strainBreakdownJson, weightliftingDetailsJson`. |
| `StrainScorer` | `lib/core/analytics/strain_scorer.dart` | Compute `effort` over the window: `edwardsTRIMP(...)` / `banisterTRIMP(...)` → `trimpToStrain(...)`, plus `zoneWeight`/`pctHRR` for the per-zone breakdown. |

No schema migration is required — the `Workouts` table already exists and covers every field.

---

## 7. Step-by-step implementation plan (Flutter, all local)

**Design note:** treat a workout as an app-side `{sport, startTs, endTs, gpsEnabled}` window over the
HR/RR streams. No protocol work; reuse the transport only to keep the live stream on.

1. **State/provider for the active workout.** In `lib/core/state/` add an `activeWorkoutProvider`
   (a `StateNotifier<ActiveWorkout?>`) holding `{id, sport, sportId, startMs, gpsEnabled, samples,
   avgHr, maxHr, liveStrain}`. Mirror `com/noop/ui/AppViewModel.kt:914-1008`. Persist a snapshot
   (secure `Prefs`, per project rule) so an app kill mid-workout can be rehydrated + closed.

2. **Start.** `startWorkout(sport, {gpsEnabled})`:
   - guard against an already-open workout; set the notifier with `startMs = now`.
   - (Optional but recommended) if bonded, call the transport to ensure realtime HR is streaming —
     `WhoopBleClient._send(CommandNumber.toggleRealtimeHr, payload:[1])` (expose a thin
     `client.setRealtimeHr(bool)` wrapper rather than reaching into `_send`). This is the *only*
     BLE touch, and it is optional — samples flow whenever bonded.
   - fire a start haptic via the existing haptics command for parity feedback (optional).

3. **Accumulate live.** While open, subscribe to the same live-sample stream that
   `stream_persistence.dart` already consumes; append `{ts, bpm}` to the window, and maintain running
   `avgHr`/`maxHr`. For the live strain tile, feed the running HR list to `StrainScorer` (Edwards
   TRIMP → `trimpToStrain`) once per few seconds. Reuse `StrainScorer.pctHRR`/`zoneWeight` for the
   zone bars.

4. **Stop.** `endWorkout()`:
   - close the window (`endTs = now`, `durationSec`).
   - pull the authoritative HR/RR samples for `[startTs, endTs]` from the DB
     (`HrSamples`/`RrSamples`, or `WhoopHrSamples`/`WhoopRrIntervals`) rather than trusting only the
     in-memory buffer, so a mid-workout reconnect/offload is included.
   - compute final `effort` with `StrainScorer` (guard `minReadings`/`minSpanSeconds`), plus per-zone
     seconds for `zonesJson` and a `strainBreakdownJson`.
   - (Optional) restore realtime HR to its prior state if we forced it on in step 2.

5. **Persist.** Insert a `Workouts` row (`database.dart:147`): `id` (uuid), `sport`, `sportId`,
   `startTs`, `durationSec`, `avgHr`, `maxHr`, `effort`, `zonesJson`, `gpsRouteJson` (encoded
   polyline if GPS), `source:'noop'`. Idempotent upsert keyed on `id`.

6. **Repository + read model.** Add `watchWorkouts()` / `recentWorkouts()` to the repository seam
   (`lib/core/data/repository.dart` + real impl) returning the `Workouts` rows, and a
   `workoutsProvider`. Screens read through the provider (never the DB directly), per project rule.

7. **UI.** A `StartWorkoutSheet` (sport picker + GPS toggle) and a `LiveWorkoutScreen` (timer, live
   HR gauge via `MetricGauge`, live strain, zone bars) mirroring the Kotlin `WorkoutStart.kt` /
   `LiveWorkoutScreen.kt`, built from the shared widget set (`NoopCard`, `ScreenScaffold`,
   `HealthTimeline`). A finished workout shows on a Workouts list card.

8. **GPS route (optional, later).** Distance sports capture a route via the platform location plugin
   into `gpsRouteJson`; strain is unaffected (it is HR-driven). Not a strap concern.

9. **Tests (the gate — no app launch).** Add `test/analytics/` coverage that feeds a synthetic HR
   window to `StrainScorer` and pins the resulting workout `effort`, and a drift round-trip test that
   starts→ends a workout over seeded `HrSamples` and asserts the persisted `Workouts` row. This keeps
   the feature verified by `flutter test`, per CLAUDE.md.

---

## 8. Open questions / caveats

- **Auto-detect workouts:** WHOOP's "looks like you worked out" nudge is inferred, not strap-signalled.
  If we want it, it is a phone-side heuristic over HR/motion (see `AutoWorkoutNudge.kt`), not a BLE
  event to subscribe to. Out of scope for the BLE layer.
- **Calories/kJ:** WHOOP computes energy expenditure from HR + user anthropometrics server-side. The
  `Workouts.calories/kilojoules` columns exist; we can estimate locally (HR-based kcal) but it will
  not match WHOOP's number exactly. Mark honestly or leave 0 (project rule: never fabricate).
- **Strength/weightlifting details** (`weightliftingDetailsJson`, `strengthActivitySec`): reps/sets/
  volume come from WHOOP's on-device strength-trainer classifier, which we have not reversed. Treat as
  future/"coming soon" — do not invent.
- **`sportId` mapping:** the official app uses `activity_internal_name` (string) + a numeric sport id.
  We can keep our own small sport catalog; a full WHOOP sport-id table is a separate data-collection
  task and not needed to record a workout.
- **Did the app ever write a workout marker to the strap on older firmware?** Not in v5.458.0 — the
  command enum has no such opcode and none of the removed/legacy opcodes (`SET_DP_TYPE`, research
  packets) carry activity semantics. If a future firmware adds one it would appear as a new `vp0.e`
  constant; re-dump that enum to check.

---

## 9. On-device validation notes

- **No strap risk:** this feature issues at most `TOGGLE_REALTIME_HR` (a reversible, already-shipped
  toggle) and an optional haptic buzz — never a destructive opcode. Nothing here touches the trim
  pointer or firmware.
- **Verify without launching the app** (per CLAUDE.md): drive `StrainScorer` + the drift round-trip
  in `flutter test`. A real-data sanity check can reuse `test/pipeline_real_data_test.dart`'s bundled
  capture: pick any high-HR window, run it through `StrainScorer`, and confirm the workout `effort`
  is in a sane 0–100 range and monotonic with intensity.
- **If you later add the realtime-HR force-on:** confirm on hardware that `BLE_REALTIME_HR_ON`
  (event) is observed after the toggle and `BLE_REALTIME_HR_OFF` after cleanup, so we don't leave the
  strap streaming (battery drain) after a workout ends.
```