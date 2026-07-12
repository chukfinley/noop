# Untapped WHOOP strap data channels — reverse-engineering + implementation spec

**Status:** recon complete · **Scope:** every sensor/data channel the official WHOOP app reads
off the strap over BLE that our Flutter app does **not** obtain or persist yet.
**Audience:** the implementer who will wire the missing channels into
`lib/core/ble/**` + the drift store.

This document is the single source of truth for the *raw-completeness* goal: what the strap can
emit, whether we already tap it, the byte layout/opcode, and a concrete plan. Server-side and
phone-side signals are documented honestly as **not on the strap** so nobody wastes time chasing a
BLE channel that does not exist.

---

## 0. What we already tap (baseline, so gaps are unambiguous)

Our BLE stack (`lib/core/ble/protocol/`, `.../transport/`, `.../sync/`) is today a **historical
offload + realtime-HR** client. Evidence — the only commands the transport ever sends
(`lib/core/ble/transport/whoop_ble_client.dart`):

- `setClock` (10) — L1113/1115
- `sendR10R11Realtime` (63) — L1117
- `getDataRange` (34) — L1119
- `sendHistoricalData` (22) — L1161
- `historicalDataResult` (23) — L1224
- plus `toggleRealtimeHr` (3) for the live HR toggle.

**Packet types decoded on the LIVE path** (`Framing._parseWhoop4` / `_parseWhoop5`,
framing.dart:318–364): `REALTIME_DATA` (40), `EVENT` (48), `COMMAND_RESPONSE` (36),
`METADATA` (49), and `CONSOLE_LOGS` (50, WHOOP5). Fields: `heart_rate`, `rr_intervals`, battery,
event codes, firmware/version, trim cursor.

**Packet type decoded on the HISTORICAL path** (`decodeHistorical`, historical_streams.dart):
`HISTORICAL_DATA` (47) — WHOOP4 v24/v12/v25 and WHOOP5 v18/v26. This is where most biometrics
come from. Rows persisted to the drift store (`lib/core/data/db/database.dart`, Room-mirrored
tables): `hrSample` (+`hrFixed88`,`onwrist`), `rrInterval`, `spo2Sample`, `skinTempSample`,
`respSample`, `gravitySample` (+`dynamicAccel`), `stepSample` (`counter`+`activityClass`),
`sleepStateSample`, `ppgHrSample`, `ppgRawSample`, `event`, `battery`. Undecodable frames are
archived verbatim in `RawSensorArchive` (rawHex), so nothing on the offload path is ever *lost*.

Everything below is a channel that path does **not** cover.

---

## 1. Canonical command-opcode table (the ground truth for gaps)

The authoritative reversed opcode list lives in the RE repo at
`/home/user/git/whoop/apps/ble-sync/app/src/main/java/com/whoopcapture/WhoopProtocol.kt`
(hardware-verified against HCI snoop logs + the decompiled official APK; the file cites
`Io/e.java` and `AbstractC9475q.java` in the smali). Comparing it to our `CommandNumber` enum
(`lib/core/ble/protocol/enums.dart`) yields the gap.

| Opcode (hex/dec) | Name (WhoopProtocol.kt) | In our enum? | Data channel it unlocks |
|---|---|---|---|
| 0x01 / 1 | LINK_VALID | no | handshake only |
| 0x02 / 2 | GET_MAX_PROTOCOL_VERSION | no | handshake only |
| 0x03 / 3 | TOGGLE_REALTIME_HR | **yes** (`toggleRealtimeHr`) | live HR (tapped) |
| 0x07 / 7 | REPORT_VERSION_INFO | **yes** | firmware ver (tapped) |
| 0x0A / 10 | SET_CLOCK | **yes** | — |
| 0x0B / 11 | GET_CLOCK | **yes** | — |
| **0x0E / 14** | **TOGGLE_GENERIC_HR_PROFILE** | no | standard 0x180D HR broadcast (WHOOP4) |
| **0x10 / 16** | **TOGGLE_R7_DATA** | no | WHOOP4 "R7" realtime deep packet |
| 0x13 / 19 | RUN_HAPTIC_PATTERN_MAVERICK | **yes** | — |
| 0x14 / 20 | ABORT_HISTORICAL | no | offload control |
| 0x16 / 22 | SEND_HISTORICAL_DATA | **yes** | offload (tapped) |
| 0x17 / 23 | HISTORICAL_DATA_RESULT | **yes** | offload ack (tapped) |
| 0x19 / 25 | FORCE_TRIM | no (deliberately excluded — destructive) | — |
| 0x1A / 26 | GET_BATTERY_LEVEL | **yes** | SoC (tapped) |
| **0x21 / 33** | **SET_READ_POINTER** | no | random-access historical replay |
| 0x22 / 34 | GET_DATA_RANGE | **yes** | offload range (tapped) |
| 0x23 / 35 | GET_HELLO_HARVARD | **yes** (`getHelloHarvard`) | identity (tapped) |
| 0x42 / 66 | SET_ALARM_TIME | **yes** | — |
| 0x43 / 67 | GET_ALARM_TIME | **yes** | — |
| 0x44 / 68 | RUN_ALARM | **yes** | — |
| 0x45 / 69 | DISABLE_ALARM | **yes** | — |
| 0x4F / 79 | RUN_HAPTICS_PATTERN | **yes** | — |
| 0x50 / 80 | GET_ALL_HAPTICS_PATTERN | **yes** | — |
| 0x51 / 81 | START_RAW_DATA | **yes (enum only, NEVER sent)** | **live raw DSP block (type 43)** |
| 0x52 / 82 | STOP_RAW_DATA | **yes (enum only, NEVER sent)** | — |
| **0x54 / 84** | **GET_BODY_LOCATION** | no | wrist + on/off-wrist wear status |
| **0x60 / 96** | **ENTER_HIGH_FREQ_SYNC** | no | faster offload (interval/duration) |
| **0x61 / 97** | **EXIT_HIGH_FREQ_SYNC** | no | — |
| **0x62 / 98** | **GET_EXTENDED_BATTERY_INFO** | no | battery temp / cycles / health |
| **0x69 / 105** | **TOGGLE_IMU_MODE_HISTORICAL** | no | historical IMU stream (type 52) |
| **0x6A / 106** | **TOGGLE_IMU_MODE** | no | **live tri-axial accel + gyro (type 51)** |
| **0x6B / 107** | **ENABLE_OPTICAL_DATA** | no | **live raw optical PPG (WHOOP4)** |
| **0x6C / 108** | **TOGGLE_OPTICAL_MODE** | no | optical channel select |
| 0x77 / 119 | SET_DEVICE_CONFIG | **yes** (`setDeviceConfig`) | broadcast-HR flag (tapped, gated) |
| 0x78 / 120 | SET_CONFIG / SET_FF_VALUE | **yes** (`setConfig`) | WHOOP5 R22 deep-stream unlock (tapped, gated) |
| 0x7A / 122 | STOP_HAPTICS | **yes** | — |
| 0x7B / 123 | SELECT_WRIST | **yes** | — |
| 0x8D / 141 | GET_ADVERTISING_NAME | no | BLE name read |
| 0x91 / 145 | GET_HELLO_EXT | **yes** (`getHello`) | WHOOP5 identity (tapped) |

The **bold** rows are the untapped *data* channels. The rest are handshake/control.

---

## 2. Untapped channels — ranked by raw-completeness value

> **Capture status (v4):** every channel in this section is **WON'T-CAPTURE (yet)** and the reason is
> the same for all of them, so it is stated once here. Each requires **sending a battery-costly opt-in
> command** to make the strap emit the channel AND has an **on-wire byte layout that is NOT
> byte-confirmed** (the §5 open questions). The only way to pin those offsets/endianness is an
> **on-device BLE capture**, which the project's test-only workflow (`flutter test`, NEVER launch the
> app, no hardware) cannot produce. Adding a decoder now would mean **inventing offsets** — which would
> silently poison the typed store — so the honest action is to defer until a real capture exists. What
> WAS captured in this pass is the decoded-but-dropped §3 fields, which need no new BLE and no unknown
> layout. The honest negatives in §4 (server-side/derived) remain out of scope permanently.

### 2.1 Live raw DSP block — REALTIME_RAW_DATA (packet type 43 / 0x2B) via START_RAW_DATA (0x51)

**Highest-value gap.** `START_RAW_DATA` (0x51) is already in our `CommandNumber` enum but the
transport never sends it, and `Framing._parseWhoop4` has **no `case` for type 43**, so even if the
frames arrived they would fall through to the envelope-only path and be discarded live. The
historical extractor (`extractHistoricalStreams`, historical_streams.dart:1022) *does* have a
type-43 fallback branch, but only for HR/RR off the header — it ignores the accel/gyro/SpO2 block.

**Byte layout of the inner 0x2F/type-43 record** — reversed and hardware-verified in
`/home/user/git/whoop/apps/ble-sync/.../WhoopDataDecoder.kt` (`decodeAA01SensorPacket`, L117–177).
After AA01-envelope extraction the inner payload is:

| Offset (inner) | Type | Field | Notes |
|---|---|---|---|
| [0] | u8 | packet type | 0x2F |
| [1–6] | — | seq/routing/sub-header | |
| [7–10] | u32 LE | timestamp | Unix seconds; sanity-gated 1.6e9…2.1e9 (WhoopDataDecoder.kt:120) |
| [11–13] | — | flags/sample info | |
| [14] | u8 | SpO2 raw | percentage ≈ raw + 10 (L123–124) |
| [15] | u8 | rr_count | 112-byte form (L145) |
| [16–17] | u16 LE | RR1 (ms) | HR = 60000/RR1 (L146,149) |
| [18–19] | u16 LE | RR2 (ms) | |
| **[36–39]** | **f32 BE** | **gyro magnitude** | big-endian float (L153) |
| **[40–43]** | **f32 BE** | **accel X (g)** | big-endian float (L154) |
| **[44–47]** | **f32 BE** | **accel Y (g)** | (L155) |
| **[48–51]** | **f32 BE** | **accel Z (g)** | (L156) |
| [55] | u8 | SpO2 raw (legacy 124-byte form) | +10 for % (L199) |

> Note the endianness split: timestamp/RR are **little-endian**, the accel/gyro floats are
> **big-endian**. This matches the WHOOP4 v24 historical DSP block where gravity is f32 too, but the
> historical path reads those LE (`_histF32`, Endian.little) — the *live* 0x2F block is BE per the
> verified decoder. Confirm on-device before trusting the axis signs.

There is also a 76-byte "not-worn" variant (inner ≤ 80) with a **direct HR byte at inner[19]** and
RR at [20–26] (WhoopDataDecoder.kt:136–142).

**What this adds over what we have:** high-rate (multi-Hz) live accelerometer/gyro + live SpO2-raw
+ live RR while connected, without waiting for the nightly offload. Today live accel is *zero* (the
`accelSample`/`gravitySample` rows only ever come from 1 Hz historical records).

### 2.2 Live realtime IMU stream — packet type 51 (0x33) via TOGGLE_IMU_MODE (0x6A)

`PacketType.realtimeImuDataStream(51)` and `historicalImuDataStream(52)` are **already declared** in
our enum (enums.dart) but **no decoder exists** for either — `_typeName` will label them
`REALTIME_IMU_DATA_STREAM` / `HISTORICAL_IMU_DATA_STREAM` and the switch has no case, so `parsed`
stays empty. `TOGGLE_IMU_MODE` (0x6A) is the enable; payload `[0x01, enable?1:0]`
(WhoopProtocol.kt:243). `TOGGLE_IMU_MODE_HISTORICAL` (0x69) banks the same stream into the offload
(payload `[0x01, enable]`, L246).

**Layout: NOT byte-confirmed in the repo.** The RE app never decoded type 51 (it only handled
0x2F). This is an **open question** (§5). The enable opcode + payload are verified; the on-wire
sample format is not. Do not invent offsets — capture first.

### 2.3 Live raw optical PPG (WHOOP4) — ENABLE_OPTICAL_DATA (0x6B) / TOGGLE_OPTICAL_MODE (0x6C)

Payload `[0x01, enable]` for both (WhoopProtocol.kt:249–253). We already preserve the **WHOOP5 v26**
historical PPG waveform losslessly (`ppgRawSample`, 24 Hz i16), but there is **no WHOOP4 live optical
path and no WHOOP4 PPG storage at all**. Enabling 0x6B streams the raw optical channel the WHOOP4
DSP normally consumes internally.

**Layout: NOT byte-confirmed.** The historical WHOOP4 v25 record comment (historical_streams.dart:187)
notes "bytes 23-72 are the optical PPG waveform" but that block is not currently decoded either.
Open question (§5).

### 2.4 Body location & wear status — GET_BODY_LOCATION (0x54)

`getBodyLocationAndStatus()` = `buildCommand(0x54)` (WhoopProtocol.kt:325, cmd const L57). Returns
which wrist the strap is on and its worn/not-worn status as a COMMAND_RESPONSE. We infer wear from
`WRIST_ON(9)`/`WRIST_OFF(10)` events and the v18 `onwrist` flag today, but never *query* location.
Low-volume, one-shot; useful for the Devices card and for gating analytics.

**Response layout: NOT byte-confirmed** (the RE app builds the request but did not log a decoded
response). Open question.

### 2.5 Extended battery info — GET_EXTENDED_BATTERY_INFO (0x62)

`getExtendedBatteryInfo()` = `buildCommand(0x62)` (WhoopProtocol.kt:222, const L61). Richer than the
plain `GET_BATTERY_LEVEL` SoC we already store — the official app surfaces battery temperature,
charge cycles and health from it. **Response layout NOT byte-confirmed.** Open question.

### 2.6 High-frequency sync — ENTER/EXIT_HIGH_FREQ_SYNC (0x60/0x61)

Not a data channel — a *throughput* mode for the existing offload. `enterHighFreqSync(interval,
duration)` payload = `[0x02, intervalSec u16 LE, durationSec u16 LE]` (WhoopProtocol.kt:327–332).
Worth adding to make the multi-night backfill faster, but it changes no schema.

---

## 3. Decoded-but-not-persisted fields (schema gaps, NOT new BLE) — **CAPTURED (v4)**

These are already produced by `decodeHistorical`/`_decodeWhoop5Historical` into the parsed map but
`extractHistoricalStreams` used to never map them onto a drift column. **As of schema v4 they are all
CAPTURED** into a new append-only long-format table `rawFieldSample`
`(deviceId, ts, key) -> intValue|realValue`, threaded on `StreamBatch.rawFields`
(historical_streams.dart) → `DriftStreamRepository.insert` → `AppDatabase.insertWhoopRawFields`.
Idempotent on the natural key `(deviceId, ts, key)`, so a re-offload is a no-op (immutability held).

| Parsed key (historical_streams.dart) | Source | Column | Status |
|---|---|---|---|
| `step_cadence` (@59, WHOOP5 v18) | per-step cadence byte | `rawFieldSample` (int) | **CAPTURED** ✓ |
| `cardiac_flags` (@33) | cardiac status flags | `rawFieldSample` (int) | **CAPTURED** ✓ |
| `rr_packed` (@38) | packed RR | `rawFieldSample` (int) | **CAPTURED** ✓ |
| `cardiac_status` (@40) | cardiac status enum | `rawFieldSample` (int) | **CAPTURED** ✓ |
| `record_index` (@11) | per-record counter | `rawFieldSample` (int) | **CAPTURED** ✓ |
| `motion_wear_quality` (@63) | 0/1/2 wear quality | `rawFieldSample` (int) | **CAPTURED** ✓ |
| `wake_quality` (band @81 bits2-3) | sleep wake-quality | `rawFieldSample` (int) | **CAPTURED** ✓ |
| `temp_aux_1_raw` / `temp_aux_2_raw` (@69/@71) | aux thermal, °C=raw/10 | `rawFieldSample` (int) | **CAPTURED** ✓ |
| `status_word` / `_1` / `_2` (@75/@77/@79) | 16-bit status words | `rawFieldSample` (int) | **CAPTURED** ✓ |
| `aux_byte_82` (@82) | raw byte | `rawFieldSample` (int) | **CAPTURED** ✓ |
| `unknown_f32_113` (@113) | unknown f32 | `rawFieldSample` (real) | **CAPTURED** ✓ |

The three physiologically-meaningful siblings (`hr_fixed_8_8`, `onwrist`, `dynamic_acceleration`)
already have their own typed columns (v3, §0 baseline). Combined, **every field the historical
decoder emits now lands in a durable column** — nothing decoded is dropped. Verified by
`test/ble/sync/raw_data_loss_test.dart` Fix 4 (decode→persist round-trip + append-only idempotency)
and `test/db/migration_test.dart` (v3→v4, plus v1→v4 / v2→v4 idempotency).

---

## 4. Honest verdicts — NOT strap BLE channels

Do not build a BLE decoder for these; they are not on the strap:

- **Stress Monitor score (0–100).** Derived from HRV/HR, computed app/cloud-side, not transmitted
  by the strap. Our own `StressSamples` table is a *local re-derivation*, not a strap read. WHOOP
  "sleep stress" is likewise a **computed** component (`docs/reports/SLEEP_SCORE_ANALYSIS_REPORT.md`
  fits it as `stress = -3.16 + 0.66 * awake_pct`).
- **GPS / workout route.** Comes from the **phone's** location services during a live activity, not
  from the strap. `Workouts.gpsRouteJson` is a phone-sourced polyline. No BLE channel exists.
- **Step count as a finished metric (WHOOP4).** WHOOP4 straps do **not** bank a step field; only
  WHOOP5 v18 carries `step_motion_counter`/`step_cadence`/`activity_class` (all on the type-47
  path we already decode). WHOOP4 "steps" would have to be derived from accel, not read.
- **Workout/activity auto-detection markers.** The strap does not send "workout start/stop" frames.
  Auto-detection runs server-side over offloaded HR+motion; on-strap the only user marker is the
  `DOUBLE_TAP(14)` event (already decoded). Calories/kJ and day-strain are computed, not read.
- **Skin temp absolute °C on WHOOP4.** The register exists (v24 @72) and we decode it, but the °C
  scale is provisional single-anchor (streams.dart:113–147) — a calibration gap, not a missing
  channel.

---

## 5. Open questions (must be answered by an on-device capture before coding decoders)

1. **type-51 realtime IMU sample layout** — sample rate, axis order, endianness, fixed-point vs
   float, samples-per-frame. Unknown; the RE app never logged it.
2. **type-52 historical IMU layout** and whether it duplicates the v24 gravity block or adds raw
   (non-gravity-separated) accel.
3. **WHOOP4 live optical (0x6B) frame type + PPG sample format** (rate, i16 vs packed, DC/AC split).
4. **GET_BODY_LOCATION (0x54) response bytes** — wrist enum + wear enum offsets.
5. **GET_EXTENDED_BATTERY_INFO (0x62) response bytes** — temp/cycles/health field offsets/units.
6. **Live 0x2F accel/gyro endianness** — confirm BE (per WhoopDataDecoder) vs the LE used on the
   historical gravity block; the two references disagree and only hardware settles it.
7. Whether WHOOP5 exposes the same 0x6A/0x6B opcodes or gates live IMU/optical behind the R22
   `SET_CONFIG` flags we already send (`whoop5_config.dart`).

---

## 6. Implementation plan (Flutter)

Reuse the existing ported machinery — do **not** re-frame or re-CRC by hand:

- **Send commands:** `Framing.buildCommand(CommandNumber, payload:, seq:)` for WHOOP4
  (framing.dart:621) and `Framing.puffinCommandFrame(cmd:, seq:, payload:)` for WHOOP5
  (framing.dart:666). Both already pad-to-4 and CRC correctly.
- **Transport:** `WhoopBleClient._send(CommandNumber, payload:, withResponse:)`
  (whoop_ble_client.dart — see the existing offload sends around L1113–1224).
- **Decode:** add `case` branches in `Framing._parseWhoop4` / `_parseWhoop5` (framing.dart:318/348),
  or extend `extractHistoricalStreams` for banked streams (historical_streams.dart:856).
- **Persist:** add drift tables mirroring the Room naming convention (`@override String get
  tableName`), register in `@DriftDatabase(tables:[…])`, bump `schemaVersion`, add an additive
  `onUpgrade` block (database.dart:703–743) and an `insert…` helper using
  `_insertIgnoreCounting` (database.dart:757).

### Phase 0 — cheap wins (no new BLE, no capture needed)

**0a. Persist `step_cadence`.** Add a nullable `cadence` column to `StepRow`/`WhoopStepSamples`
(historical_streams.dart:635, database.dart:581), read `p.intOrNull('step_cadence')` in the steps
branch (historical_streams.dart:1002), and thread it through `stream_persistence.dart`. schemaVersion
3→4, `addColumn` in onUpgrade.

**0b. (optional) A generic `rawFieldSample(deviceId, ts, key, value)` table** to catch the other
dropped keys in §3 without a column each — mirrors the existing `MetricSamples` long-format idea.
Populate from the parsed map for keys not otherwise columned.

### Phase 1 — Body location + extended battery (one-shot, low-risk)

1. Add `getBodyLocation(84)` and `getExtendedBatteryInfo(98)` to `CommandNumber` (enums.dart) —
   both are **safe reads**, consistent with the enum's "no destructive commands" rule.
2. In `WhoopBleClient`, after the hello/identity step, send them `withResponse: true`.
3. Add `COMMAND_RESPONSE` sub-decoders in `_decodeCommandResponse*` keyed on the new cmd codes
   (framing.dart:400 shows the existing pattern for GET_BATTERY_LEVEL / GET_HELLO).
4. **Blocked on §5 Q4/Q5** — capture the response bytes first, then fill offsets. Until then, log
   `event_payload_hex` only (the WHOOP5 event decoder already carries an opaque-hex fallback,
   framing.dart:382 — reuse that discipline: store raw hex, never invent a field).
5. Persist body location onto `DeviceInfo` (add `wrist`, `wornStatus` columns) and extended battery
   onto `BatteryLog` (add `tempC`, `cycleCount` nullable columns).

### Phase 2 — Live raw DSP block (type 43 / START_RAW_DATA) — highest value

1. Wire the already-present `startRawData(81)` / `stopRawData(82)` behind an **explicit opt-in**
   (mirror the broadcast-HR / R22 gating — these change what the strap emits and cost battery).
2. Add a `REALTIME_RAW_DATA` case to `_parseWhoop4` (and the +4-shifted WHOOP5 variant) that decodes
   the §2.1 layout: ts@7 (u32 LE), spo2Raw@14, RR@15–19, gyro@36 / accelXYZ@40/44/48 (**f32 BE —
   verify on hardware, §5 Q6**). Port `decodeAA01SensorPacket` (WhoopDataDecoder.kt:117) verbatim.
3. Route decoded rows: accel/gyro → `AccelSamples`/`gravitySample`, spo2Raw → `spo2Sample`,
   RR → `rrInterval`, all stamped with the wall-clock offset (`_toWall`, streams.dart:226) since the
   live 0x2F timestamp is device-epoch, not RTC-unix like historical.
4. **Always** also append the verbatim frame to `RawSensorArchive` (raw_archive.dart) before trusting
   the decode, exactly as the offload path does — a new live decoder is exactly where a bad offset
   would otherwise silently corrupt rows.

### Phase 3 — Live IMU (type 51) + WHOOP4 optical (0x6B) — capture-gated

1. Add `toggleImuMode(106)`, `toggleImuModeHistorical(105)`, `enableOpticalData(107)`,
   `toggleOpticalMode(108)` to `CommandNumber` with their `[0x01, enable]` payloads.
2. **Do NOT write a decoder yet.** Enable the stream, dump every type-51/optical frame to
   `RawSensorArchive`, and answer §5 Q1–Q3 from real captures. Add a decoder + `imuSample` /
   `opticalRawSample` table (model the latter on the existing lossless `ppgRawSample`,
   database.dart:492) only once the layout is byte-confirmed.

### Phase 4 (optional) — High-freq sync

Add `enterHighFreqSync(96)`/`exitHighFreqSync(97)` and bracket the offload loop in the Backfiller
(sync/backfiller.dart) with them. Pure throughput; no schema change.

---

## 7. On-device validation notes

- **Never trust a new decoder without the archive.** Every phase above must archive the raw frame
  (`RawSensorArchive`) before/independent of decoding, so a wrong offset can be re-decoded later
  instead of poisoning the typed tables. This is the established pattern (database.dart:216 comment).
- **CRC-gate everything.** Reuse `Framing.parseFrame`'s `crcOk`/`ok` — a forged/garbled frame must
  never inject rows (the historical decoder already refuses non-CRC-OK frames,
  historical_streams.dart:174).
- **Gate battery-costly streams behind opt-in.** START_RAW_DATA, TOGGLE_IMU_MODE and
  ENABLE_OPTICAL_DATA keep the sensors hot and drain the strap; treat them like the existing
  broadcast-HR / R22 opt-ins, not as always-on.
- **Endianness is the top trap.** LE for timestamps/RR/counters, BE for the live 0x2F accel/gyro
  floats per the verified reference — assert `|accel| ≈ 1 g` at rest before believing the axes,
  the same plausibility gate the historical gravity decode already uses
  (historical_streams.dart:204–211).
- **WHOOP4 vs WHOOP5 offsets differ by +4** for envelope-shifted types; the puffin inner record
  starts at byte 8. Do not shift blindly — REALTIME_DATA is the only +4 offset hardware-confirmed
  so far (framing.dart:344–347 comment).

---

## 8. Evidence index

- Canonical opcode table + CRC + builders: `/home/user/git/whoop/apps/ble-sync/app/src/main/java/com/whoopcapture/WhoopProtocol.kt`
- Live 0x2F/type-43 byte layout (accel/gyro/SpO2): `/home/user/git/whoop/apps/ble-sync/app/src/main/java/com/whoopcapture/WhoopDataDecoder.kt:117–177,186–218`
- Puffin envelope + verified WHOOP5 offsets: `/home/user/git/whoop/apps/app/lib/services/whoop_frame.dart`
- Our enum (gap baseline): `lib/core/ble/protocol/enums.dart`
- Our live decoder: `lib/core/ble/protocol/framing.dart:297–367`
- Our historical decoder (fields already produced): `lib/core/ble/protocol/historical_streams.dart:165–398,856–1085`
- Our transport (commands actually sent): `lib/core/ble/transport/whoop_ble_client.dart:1113–1224`
- Our drift schema (persistence gaps): `lib/core/data/db/database.dart`
- WHOOP5 R22 deep-stream unlock (already tapped, gated): `lib/core/ble/protocol/whoop5_config.dart`
- Stress/sleep-stress are computed, not read: `/home/user/git/whoop/docs/reports/SLEEP_SCORE_ANALYSIS_REPORT.md`

> Note on smali: the official app's `com/whoop/**` BLE packages
> (`connectivityDataPackets`, `straphistorysync`, `strapMetadata`, `sensorDataUpload`,
> `pulseinformationpacket`, `researchPacket`) are single-letter-obfuscated
> (`a.smali`…`i.smali`) with no readable field/method names, so the opcode/byte facts above are
> sourced from the RE repo's already-de-obfuscated `WhoopProtocol.kt`/`WhoopDataDecoder.kt`, which
> themselves cite the smali classes (`Io/e.java`, `AbstractC9475q.java`) they were reversed from.
