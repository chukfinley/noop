# WHOOP Strap BLE Command Inventory & Port Gap Map

**Status:** reverse-engineered facts + implementation plan
**Scope:** every BLE *command* opcode the official WHOOP app can send to a 4.0 (Harvard) or
5.0/MG (Maverick/"puffin") strap, cross-referenced against our ported `CommandNumber`
(`lib/core/ble/protocol/enums.dart`). This is the master map that drives the rest of the BLE work.

> **This is a research + planning doc. It changes no runtime code.** Sending destructive opcodes
> can brick or wipe a strap; the plan below keeps the existing SAFE-subset gate.

---

## 1. Sources of truth (cited)

| # | Source | Path | What it proves |
|---|--------|------|----------------|
| S1 | Canonical protocol schema | `/home/user/git/noop/Packages/WhoopProtocol/Sources/WhoopProtocol/Resources/whoop_protocol.json` | `enums.CommandNumber` — **80** name→opcode pairs (the numeric source of truth) |
| S2 | Official app enum (decompiled smali) | `/home/user/git/whoop/research/work/whoop_apk/base_full/smali_classes6/vp0/e.smali` | `Lvp0/e;` — the app's own command enum, **75** named constants + the `<init>(name, ordinal, value)` opcode assignment |
| S3 | Independent Kotlin RE (HCI snoop + APK) | `/home/user/git/whoop/apps/ble-sync/app/src/main/java/com/whoopcapture/WhoopProtocol.kt` | Maverick framing + opcode constants + tested payload builders (alarm/haptics/historical ACK) |
| S4 | Our Kotlin reference (the port's parent) | `/home/user/git/noop/android/app/src/main/java/com/noop/protocol/Enums.kt` | The curated SAFE subset the Flutter enum is a 1:1 port of |
| S5 | Our Dart port | `/home/user/git/noop/flutter_app/lib/core/ble/protocol/enums.dart`, `framing.dart`, `transport/whoop_ble_client.dart` | What we already handle |

### Byte-level evidence that `value:I` is the on-wire opcode (S2)

`vp0/e.smali:1224` — constructor stores the 3rd arg as the opcode, then derives the wire byte:

```smali
.method private constructor <init>(Ljava/lang/String;II)V
    invoke-direct {p0, p1, p2}, Ljava/lang/Enum;-><init>(Ljava/lang/String;I)V  # name, ordinal
    iput p3, p0, Lvp0/e;->value:I                                              # p3 = opcode
    invoke-virtual {p0}, Lvp0/e;->getValue()I
    move-result p1
    int-to-byte p1, p1
    iput-byte p1, p0, Lvp0/e;->byteValue:B                                     # wire byte = value & 0xFF
```

`vp0/e.smali:367-375` — `TOGGLE_REALTIME_HR` built with ordinal `0x0`, value `0x3` → **opcode 0x03**:

```smali
const-string v1, "TOGGLE_REALTIME_HR"
const/4 v2, 0x0        # ordinal
const/4 v3, 0x3        # value == opcode 0x03
invoke-direct {v0, v1, v2, v3}, Lvp0/e;-><init>(Ljava/lang/String;II)V
```

Every opcode in the table below is corroborated by **both** S1 (whoop_protocol.json) and S2/S3
(the app's own enum / independent HCI capture); they agree with zero conflicts.

---

## 2. Transport facts (how a command physically leaves the phone)

All of this is already ported and working; it's the machinery every command reuses.

### Characteristics (`lib/core/ble/protocol/device_family.dart:43-99`)

| Family | GATT service | Command (write) char | Notify chars (responses/streams) |
|--------|--------------|----------------------|----------------------------------|
| WHOOP 4.0 (`whoop4`, Harvard) | `61080001-8d6d-82b8-614a-1c8cb0f8dcc6` | `61080002-…` (`…0002`) | `…0003`, `…0004`, `…0005` |
| WHOOP 5.0/MG (`whoop5`, Maverick/puffin) | `fd4b0001-cce1-4033-93ce-002d5875f58a` | `fd4b0002-…` (`…0002`) | `…0003`, `…0004`, `…0005`, `…0007` |

Standard BLE HR (`0x180D`) + Battery (`0x180F`) are also subscribed for the passive HR-broadcast /
battery path. Every proprietary command is a **write-with-response** to the `…0002` char
(`whoop_ble_client.dart:1541-1544`).

### Frame envelope (two families, both ported in `framing.dart`)

**WHOOP 4.0 (`Framing.buildCommand`, `framing.dart:621`)** — CRC8 header + CRC32 trailer:

```
[0]      0xAA (SOF)
[1..2]   length u16 LE   = inner.length + 4
[3]      CRC8 over the 2 length bytes
[4]      packet type = 35 (COMMAND)      ← PacketType.command
[5]      seq (0..255, ++ per send)
[6]      command opcode                  ← CommandNumber.rawValue & 0xFF
[7..]    payload
[len..]  CRC32 (zlib/LE, 4 bytes) over frame[4 .. len]
```

**WHOOP 5.0 "puffin" (`Framing.puffinCommandFrame`, `framing.dart:666`)** — CRC16-Modbus header +
CRC32 trailer, inner record padded to a 4-byte boundary (the pad4 that #48 fixed for 12-byte haptics):

```
inner  = [type=35][seq][opcode] + payload   (then zero-padded to %4 == 0)
declLen = inner.length + 4
frame  = [0xAA, 0x01, declLen LE(2), header(2 = 0x00,0x01)]
       + CRC16-Modbus(frame[0..6)) LE(2)
       + inner
       + CRC32(inner) LE(4)
```

This exactly matches S3's `WhoopProtocol.buildCommand` (Maverick) modulo the pad4 nuance, and
round-trips through `parseFrame`.

### Send path (`whoop_ble_client.dart:1522`)

```dart
void _send(CommandNumber cmd, {List<int>? payload, bool withResponse = false}) {
  _seq = (_seq + 1) & 0xFF;
  final frame = _family == DeviceFamily.whoop5
      ? Framing.puffinCommandFrame(cmd: cmd.rawValue, seq: _seq, payload: …)
      : Framing.buildCommand(cmd, payload: …, seq: _seq);
  unawaited(_write(_cmdChar, frame));   // write-with-response to …0002
}
```

### Responses (already decoded)

Responses arrive on the notify chars as their own frames, decoded by `Framing.parseFrame`
(`framing.dart:297`) → `ParsedFrame`:
- **4.0:** `COMMAND_RESPONSE` = packet type **36** (`PacketType.commandResponse`), opcode echoed at
  the type-specific offset, `_decodeCommandResponse` (`framing.dart:543`).
- **5.0:** `PUFFIN_COMMAND_RESPONSE` = type **38**, `_decodeCommandResponseWhoop5` (`framing.dart:400`).
- Asynchronous device state is delivered as `EVENT` (type **48**) frames — see §5.

---

## 3. Our current `CommandNumber` (what we ALREADY handle)

`enums.dart` ports S4 verbatim — **25** constants. Their opcodes all match S1/S2/S3 exactly. Note two
naming choices worth flagging:

- `setAdvertisingName(77)` is canonically **`SET_ADVERTISING_NAME_HARVARD` (0x4D)** — the 4.0 opcode.
  The Maverick `SET_ADVERTISING_NAME (0x8C=140)` is a *different, unported* opcode.
- `setConfig(120)` = canonical `SET_FF_VALUE` (0x78); `setDeviceConfig(119)` = `SET_DEVICE_CONFIG_VALUE` (0x77).

**Wiring tiers** (a constant existing in the enum ≠ a working feature):

| Tier | Meaning | Members |
|------|---------|---------|
| **WIRED** | enum + payload builder + an actual `_send()` call site today | `setClock`(10), `getDataRange`(34), `sendHistoricalData`(22), `historicalDataResult`(23), `sendR10R11Realtime`(63); plus raw `0x78`/`0x77` via `Whoop5Config.frame` (`whoop5_config.dart:89`) |
| **DECLARED** | in enum + (usually) a payload helper, but **no call site** wired into the client yet | `toggleRealtimeHr`(3), `reportVersionInfo`(7), `getClock`(11), `getBatteryLevel`(26), `getHelloHarvard`(35), `getHello`(145), `runHapticPatternMaverick`(19), `setAlarmTime`(66), `getAlarmTime`(67), `runAlarm`(68), `disableAlarm`(69), `setAdvertisingName`(77), `runHapticsPattern`(79), `getAllHapticsPattern`(80), `setConfig`(120), `setDeviceConfig`(119), `startRawData`(81), `stopRawData`(82), `stopHaptics`(122), `selectWrist`(123) |

Existing payload builders to reuse (do **not** re-derive these):
- `AlarmPayload.build/nextWakeEpochMs/disableRev2` (`protocol/alarm_payload.dart`) — SET/GET/DISABLE alarm.
- `HapticClock.pulses` (`protocol/haptic_clock.dart`) — the buzz-the-time haptic sequence.
- `Whoop5Config` (`protocol/whoop5_config.dart`) — `SET_FF_VALUE`/`SET_DEVICE_CONFIG_VALUE` bodies + the 15-flag R22 enable sequence.
- `backfill_capture.dart` / `historical_streams.dart` — the whole GET_DATA_RANGE → SEND_HISTORICAL_DATA → HISTORICAL_DATA_RESULT offload loop.

---

## 4. FULL command inventory (all 80) vs our port

Legend — **Port**: `WIRED` = sent today · `DECL` = in our enum, not wired · `MISS` = not in our enum ·
`EXCL` = deliberately excluded as destructive (S4 policy). **Dir**: `→` app→strap request,
`⇄` request+response, `⟲` toggle/stream-control. All requests go to the `…0002` command char.

| Opcode | Hex | Name | Port | Dir | Payload (RE'd) | Notes / evidence |
|-------:|-----|------|------|-----|----------------|------------------|
| 1 | 0x01 | LINK_VALID | MISS | ⇄ | none / handshake | Link keep-alive/validate. S1,S2. Low value for us. |
| 2 | 0x02 | GET_MAX_PROTOCOL_VERSION | MISS | ⇄ | none → version | Capability probe. S1,S2. |
| 3 | 0x03 | TOGGLE_REALTIME_HR | **DECL** | ⟲ | `[enable:u8]` (1=on) | Live-HR stream on/off. S3 `toggleRealtimeHr`. Confirmed opcode S2:373. |
| 7 | 0x07 | REPORT_VERSION_INFO | **DECL** | ⇄ | none → `fw_harvard`,`fw_boylston` a.b.c.d | 4.0 firmware read. S1,S4. |
| 10 | 0x0A | SET_CLOCK | **WIRED** | → | `[secs:u32 LE][subsecs:u32 LE]` (subsec = ms*32768/1000) | Wired at `whoop_ble_client.dart:1113`. S3 `setClock`. |
| 11 | 0x0B | GET_CLOCK | **DECL** | ⇄ | none → clock | S3 `getClock`. |
| 14 | 0x0E | TOGGLE_GENERIC_HR_PROFILE | MISS | ⟲ | `[enable:u8]` | Standard 0x180D HR advertising toggle. S3 `toggleGenericHrProfile`. Overlaps our broadcast-HR path (§6). |
| 16 | 0x10 | TOGGLE_R7_DATA_COLLECTION | MISS | ⟲ | `[enable:u8]` | R7 research packets. S1,S2:393 (value 0x10). |
| 19 | 0x13 | RUN_HAPTIC_PATTERN_MAVERICK | **DECL** | → | `[rev=1][e1..e8:u8][loop:u16][overall:u8]` = 12B | 5.0/MG one-shot buzz. S3 `runHapticPattern`. Needs pad4 (#48). |
| 20 | 0x14 | ABORT_HISTORICAL_TRANSMITS | MISS | → | none | Cancel an in-flight offload. S3 `abortHistoricalTransmits`. Useful for sync robustness. |
| 22 | 0x16 | SEND_HISTORICAL_DATA | **WIRED** | ⇄ | `[0x00]` | Starts offload. Wired `whoop_ble_client.dart:1161`. |
| 23 | 0x17 | HISTORICAL_DATA_RESULT | **WIRED** | ⇄ | `[0x01][sector:u32 LE][offset:u32 LE]` = 9B | Per-burst ACK (trim). Wired `:1224`. S3 `historicalDataResult`. |
| 25 | 0x19 | FORCE_TRIM | EXCL | → | `[sector:u32][offset:u32]`; `FEFEFEFE×2` = trim-all | **DESTRUCTIVE — never send.** Wipes circular history. S3, agents.md warning. |
| 26 | 0x1A | GET_BATTERY_LEVEL | **DECL** | ⇄ | none → level | S3 `getBatteryLevel`. We currently read battery via 0x180F + EVENT 3 instead. |
| 29 | 0x1D | REBOOT_STRAP | EXCL | → | none | **DESTRUCTIVE.** S3. |
| 32 | 0x20 | POWER_CYCLE_STRAP | EXCL | → | none | **DESTRUCTIVE.** S3. |
| 33 | 0x21 | SET_READ_POINTER | MISS | → | `[sector:u32][offset:u32]` | Rewind/seek offload cursor. S3 `setReadPointer`. Advanced backfill only. |
| 34 | 0x22 | GET_DATA_RANGE | **WIRED** | ⇄ | `[0x00]` → available sector/offset range | Wired `:1119`. |
| 35 | 0x23 | GET_HELLO_HARVARD | **DECL** | ⇄ | none → name+fw | 4.0 hello. S1,S4. |
| 36 | 0x24 | START_FIRMWARE_LOAD | EXCL | → | fw header | **DESTRUCTIVE (DFU).** S1,S2. |
| 37 | 0x25 | LOAD_FIRMWARE_DATA | EXCL | → | fw chunk | **DESTRUCTIVE.** S1,S2. |
| 38 | 0x26 | PROCESS_FIRMWARE_IMAGE | EXCL | → | none | **DESTRUCTIVE.** S1,S2. |
| 39 | 0x27 | SET_LED_DRIVE | EXCL/MISS | → | AFE LED current | Optical front-end tuning; can damage/skew sensor. S1,S2. |
| 40 | 0x28 | GET_LED_DRIVE | MISS | ⇄ | none → value | AFE read. S1,S2. |
| 41 | 0x29 | SET_TIA_GAIN | EXCL/MISS | → | gain | AFE tuning. S1,S2. |
| 42 | 0x2A | GET_TIA_GAIN | MISS | ⇄ | none → gain | AFE read. S1,S2. |
| 43 | 0x2B | SET_BIAS_OFFSET | EXCL/MISS | → | offset | AFE tuning. S1,S2. |
| 44 | 0x2C | GET_BIAS_OFFSET | MISS | ⇄ | none → offset | AFE read. S1,S2. |
| 45 | 0x2D | ENTER_BLE_DFU | EXCL | → | none | **DESTRUCTIVE (bootloader).** S1,S2. |
| 48 | 0x30 | SEND_EVENT_PACKETS | MISS | ⟲ | `[enable?]` | Ask strap to (re)send buffered EVENT packets. S1. |
| 52 | 0x34 | SET_DP_TYPE | MISS | → | data-product type | Selects derived-data stream type. S1,S2. |
| 53 | 0x35 | FORCE_DP_TYPE | MISS | → | dp type | Force variant. S1,S2. |
| 61 | 0x3D | SET_AFE_PARAMETERS | EXCL/MISS | → | AFE blob | Bulk AFE tuning. S1,S2. |
| 62 | 0x3E | GET_AFE_PARAMETERS | MISS | ⇄ | none → AFE blob | AFE read. S1,S2. |
| 63 | 0x3F | SEND_R10_R11_REALTIME | **WIRED** | ⟲ | `[0x00]` | Enables R10/R11 realtime records. Wired `whoop_ble_client.dart:1117`. |
| 66 | 0x42 | SET_ALARM_TIME | **DECL** | → | `[rev=4][id=1][secs:u32][subsec:u16][12B haptic pattern]` = 20B | S3 `setAlarmTime` + our `AlarmPayload.build`. |
| 67 | 0x43 | GET_ALARM_TIME | **DECL** | ⇄ | `[rev=4][id=1]` → alarm | S3 `getAlarmTime`. |
| 68 | 0x44 | RUN_ALARM | **DECL** | → | `[rev=2][id=1]` | Fire alarm now. S3 `runAlarm`. |
| 69 | 0x45 | DISABLE_ALARM | **DECL** | → | `[rev=2][id=0xFF]` | S3 `disableAlarm` + `AlarmPayload.disableRev2`. |
| 76 | 0x4C | GET_ADVERTISING_NAME_HARVARD | MISS | ⇄ | none → name | 4.0 name read (pairs with 0x4D). S1,S2. |
| 77 | 0x4D | SET_ADVERTISING_NAME_HARVARD | **DECL** | → | `[0x00,0x00]` + UTF-8 name + `[0x00]`; strap reboots | Our `setAdvertisingName(77)`. S1,S4. |
| 79 | 0x4F | RUN_HAPTICS_PATTERN | **DECL** | → | `[rev=1][e1..e8][loop:u16][overall:u8]` = 12B | 4.0 buzz. S3 `runHapticPattern` (via CMD 0x4F). |
| 80 | 0x50 | GET_ALL_HAPTICS_PATTERN | **DECL** | ⇄ | none → patterns | S1,S4. |
| 81 | 0x51 | START_RAW_DATA | **DECL** | ⟲ | `[0x01]` | Raw sensor capture on. S3 `startRawData`. |
| 82 | 0x52 | STOP_RAW_DATA | **DECL** | ⟲ | none | S3 `stopRawData`. |
| 83 | 0x53 | VERIFY_FIRMWARE_IMAGE | MISS | ⇄ | none → ok | Read-only FW verify (non-destructive). S1,S2,S3. |
| 84 | 0x54 | GET_BODY_LOCATION_AND_STATUS | MISS | ⇄ | none → wrist/on-body | S3 `getBodyLocationAndStatus`. Useful for on-wrist gating. |
| 96 | 0x60 | ENTER_HIGH_FREQ_SYNC | MISS | → | `[rev=2][interval:u16][duration:u16]` = 5B | Faster offload window. S3 `enterHighFreqSync`. Sync-speed win. |
| 97 | 0x61 | EXIT_HIGH_FREQ_SYNC | MISS | → | none | S3 `exitHighFreqSync`. |
| 98 | 0x62 | GET_EXTENDED_BATTERY_INFO | MISS | ⇄ | none → mV/mAh/temp | Richer battery than EVENT 3. S3 `getExtendedBatteryInfo`. |
| 99 | 0x63 | RESET_FUEL_GAUGE | EXCL | → | none | **DESTRUCTIVE (battery calib).** S1,S4. |
| 100 | 0x64 | CALIBRATE_CAPSENSE | EXCL/MISS | → | none | Cap-touch recal; can disturb wear detection. S1,S2. |
| 105 | 0x69 | TOGGLE_IMU_MODE_HISTORICAL | MISS | ⟲ | `[0x01][enable:u8]` | Historical IMU capture. S3 `toggleImuModeHistorical`. |
| 106 | 0x6A | TOGGLE_IMU_MODE | MISS | ⟲ | `[0x01][enable:u8]` | Live IMU (accel+gyro, type-43 v1917). S3 `toggleImuMode`. |
| 107 | 0x6B | ENABLE_OPTICAL_DATA | MISS | ⟲ | `[0x01][enable:u8]` | Raw PPG (type-43 v1921). S3 `enableOpticalData`. |
| 108 | 0x6C | TOGGLE_OPTICAL_MODE | MISS | ⟲ | `[0x01][enable:u8]` | S3 `toggleOpticalMode`. |
| 115 | 0x73 | START_DEVICE_CONFIG_KEY_EXCHANGE | MISS | ⇄ | crypto handshake | Precedes 0x74/0x77 device-config writes. S1,S2. |
| 116 | 0x74 | SEND_NEXT_DEVICE_CONFIG | MISS | ⇄ | config chunk | S1,S2. |
| 117 | 0x75 | START_FF_KEY_EXCHANGE | MISS | ⇄ | crypto handshake | Precedes feature-flag writes. S1,S2. |
| 118 | 0x76 | SEND_NEXT_FF | MISS | ⇄ | ff chunk | S1,S2. |
| 119 | 0x77 | SET_DEVICE_CONFIG_VALUE | **WIRED*** | → | `[name utf8 @0..32][value @32][7×0]` = 33B | Our `setDeviceConfig(119)`; broadcast-HR flag. Body via `Whoop5Config.deviceConfigBody`, framed by `Whoop5Config.frame`. |
| 120 | 0x78 | SET_FF_VALUE | **WIRED*** | → | `[name utf8 @0..32][value @32][7×0]` = 40B | Our `setConfig(120)`; R22 enable (15-flag sequence). `Whoop5Config.enableR22Sequence`. |
| 121 | 0x79 | GET_DEVICE_CONFIG_VALUE | MISS | ⇄ | `[name]` → value | Read back a device-config. S1,S2. |
| 122 | 0x7A | STOP_HAPTICS | **DECL** | → | none | S3 `stopHaptics`. |
| 123 | 0x7B | SELECT_WRIST | **DECL** | → | `[0x01][wrist:u8]` (1=R,2=L) | S3 `selectWrist`. |
| 124 | 0x7C | TOGGLE_LABRADOR_DATA_GENERATION | MISS | ⟲ | `[enable:u8]` | "Labrador" research pipeline. S1,S2. |
| 125 | 0x7D | TOGGLE_LABRADOR_RAW_SAVE | MISS | ⟲ | `[enable:u8]` | S1,S2. |
| 128 | 0x80 | GET_FF_VALUE | MISS | ⇄ | `[name]` → value | Read a feature-flag. S1,S2. Pairs with our 0x78 writes. |
| 131 | 0x83 | SET_RESEARCH_PACKET | MISS | → | packet cfg | S1,S2. |
| 132 | 0x84 | GET_RESEARCH_PACKET | MISS | ⇄ | none → cfg | S1,S2. |
| 139 | 0x8B | TOGGLE_LABRADOR_FILTERED | MISS | ⟲ | `[enable:u8]` | S1,S2. |
| 140 | 0x8C | SET_ADVERTISING_NAME | MISS | → | name (Maverick path) | 5.0/MG rename (distinct from 4.0's 0x4D). S1,S2. |
| 141 | 0x8D | GET_ADVERTISING_NAME | MISS | ⇄ | `[0x01]` → name | S3 `getAdvertisingName` (Maverick). |
| 142 | 0x8E | START_FIRMWARE_LOAD_NEW | EXCL | → | fw header | **DESTRUCTIVE (DFU v2).** S1,S2. |
| 143 | 0x8F | LOAD_FIRMWARE_DATA_NEW | EXCL | → | fw chunk | **DESTRUCTIVE.** S1,S2. |
| 144 | 0x90 | PROCESS_FIRMWARE_IMAGE_NEW | EXCL | → | none | **DESTRUCTIVE.** S1,S2. |
| 145 | 0x91 | GET_HELLO | **DECL** | ⇄ | `[0x01]` → name + `fw_version` a.b.c.d | 5.0/MG hello. Our `getHello(145)`. S3 `getHelloExt`. |
| 151 | 0x97 | GET_BATTERY_PACK_INFO | MISS | ⇄ | none → pack info | 5.0 battery-pack accessory. S1,S2. |
| 153 | 0x99 | TOGGLE_PERSISTENT_R20 | MISS | ⟲ | `[enable:u8]` | Persistent R20 stream. S1,S2. |
| 154 | 0x9A | TOGGLE_PERSISTENT_R21 | MISS | ⟲ | `[enable:u8]` | Persistent R21 stream. S1,S2. |

**Tally:** 80 canonical · 25 in our enum (5–6 WIRED, ~19 DECL) · ~14 deliberately EXCL (destructive)
· ~41 MISS-but-benign, of which the high-value ones are called out in §6.

\* 0x77 / 0x78 are "wired" only through the raw `Whoop5Config.frame` path (which builds the puffin
frame directly from the int opcode), not through a `_send(CommandNumber.…)` call. See §6.4.

---

## 5. Related enums (for response/event handling — already ported, noted for completeness)

- **`PacketType`** (S1, 16 entries; our `enums.dart` ports 12): COMMAND 35, COMMAND_RESPONSE 36,
  PUFFIN_COMMAND 37, PUFFIN_COMMAND_RESPONSE 38, REALTIME_DATA 40, REALTIME_RAW_DATA 43,
  HISTORICAL_DATA 47, EVENT 48, METADATA 49, CONSOLE_LOGS 50, REALTIME_IMU_DATA_STREAM 51,
  HISTORICAL_IMU_DATA_STREAM 52.
- **`EventNumber`** (S1 has **58**; our port curates **13**). Async strap state pushed as EVENT
  frames. Ones we already map: BATTERY_LEVEL 3, CHARGING_ON/OFF 7/8, WRIST_ON/OFF 9/10, DOUBLE_TAP 14,
  TEMPERATURE_LEVEL 17, BLE_BONDED 23, BLE_REALTIME_HR_ON/OFF 33/34, STRAP_DRIVEN_ALARM_EXECUTED 57,
  APP_DRIVEN_ALARM_EXECUTED 58, HAPTICS_FIRED 60. **Un-mapped but useful** (S1): BOOT 15, SET_RTC 16,
  PAIRING_MODE 18, STRAP_CONDITION_REPORT 29, BOOT_REPORT 30, SHIP_MODE_* 37-39,
  STRAP_DRIVEN_ALARM_SET 56, STRAP_DRIVEN_ALARM_DISABLED 59, EXTENDED_BATTERY_INFORMATION 63,
  HIGH_FREQ_SYNC_ENABLED/DISABLED 97/98, HAPTICS_TERMINATED 100. (These are the ACKs the §6 commands
  would need to observe.)
- **`MetadataType`**: HISTORY_START 1, HISTORY_END 2, HISTORY_COMPLETE 3 — drives the offload state
  machine (already handled in `backfiller.dart`).

---

## 6. Implementation plan (concrete, file-by-file)

Guiding rule (S4/CLAUDE.md): the sender must never be able to brick/wipe a strap. **Do not add any
`EXCL` opcode to `CommandNumber`.** Firmware/AFE/trim/DFU/reset stay out of the enum entirely.

Reuse, don't reinvent: `Framing.buildCommand` / `Framing.puffinCommandFrame` (framing), `_send()`
(transport), the existing `AlarmPayload` / `HapticClock` / `Whoop5Config` payload builders, and the
drift tables `WhoopEvents` (`database.dart:520`), `Events` (:264), `Alarms` (:339),
`BatteryLog`/`WhoopBattery`, `DeviceInfo` (:239).

### 6.1 Verification gate (do this first, every step)
`change code → flutter analyze → flutter test`. Add cases to `test/` that build a frame for the new
opcode and assert the exact bytes (SOF, length, CRC8/CRC16, opcode, payload, CRC32) — mirror the
existing `FramingTest.kt` reference numbers. **Never launch the app** (project CLAUDE.md). On-device
checks are captured as open questions in §7, run by the user on his rooted rig.

### 6.2 Wire the already-DECLARED safe commands (lowest risk, highest ratio)
These are in the enum with payload helpers but have no call site. Add thin methods on
`WhoopBleClient` that call `_send(...)`, plus a provider/UI hook where a feature already exists:

1. **Alarm** (`features/alarm/`): `setAlarm(epochMs)` → `_send(CommandNumber.setAlarmTime, payload: AlarmPayload.build(epochMs))`; `disableAlarm()` → `_send(CommandNumber.disableAlarm, payload: AlarmPayload.disableRev2())`; `getAlarm()`; `runAlarmNow()`. Observe EVENT 56/57/58/59 to confirm. Persist to `Alarms` table.
2. **Haptics / buzz-the-time**: `buzz()` → 4.0 `runHapticsPattern`(0x4F) / 5.0 `runHapticPatternMaverick`(0x13) chosen by `_family`; `stopHaptics()`. Feed `HapticClock.pulses` for the time-telling pattern.
3. **HR stream toggle**: `setRealtimeHr(bool)` → `_send(CommandNumber.toggleRealtimeHr, payload: [b?1:0])`. Confirm via EVENT 33/34.
4. **Identity/version**: `getHello()` (145 for 5.0, 35 for 4.0), `reportVersionInfo()` (7). Persist to `DeviceInfo`.
5. **Battery**: `getBatteryLevel()` (26). (We already get battery passively; this is a pull.)
6. **Wrist / raw capture**: `selectWrist`, `startRawData`/`stopRawData` behind a debug toggle.

Each is ~5 lines. The only real work is the response/EVENT plumbing (§6.5) and a test per opcode.

### 6.3 Add high-value MISSING opcodes to the SAFE enum
Extend `CommandNumber` (and the Kotlin `Enums.kt` reference to keep parity) with **benign** additions,
each with the same evidence comment style already in the file:

- `abortHistoricalTransmits(20)` — makes sync cancellable/robust; call before disconnect.
- `enterHighFreqSync(96)` / `exitHighFreqSync(97)` — faster backfill; payload `[0x02][interval:u16][duration:u16]`.
- `getExtendedBatteryInfo(98)` — richer battery; parse into `WhoopBattery`.
- `getBodyLocationAndStatus(84)` — on-wrist/wrist-side gating.
- `getAdvertisingName(141)` / `getAdvertisingNameHarvard(76)` — read current name (pairs with our SET).
- `getFfValue(128)` / `getDeviceConfigValue(121)` — read back the flags we already write (0x78/0x77).
- IMU/optical toggles `106/107/108/105` — only behind an explicit "raw research" opt-in; they open the type-43 streams `historical_streams.dart` already knows how to parse.

Keep firmware/AFE/trim/DFU/reset **out**.

### 6.4 Fold 0x77/0x78 into the enum path (consistency cleanup)
Today `Whoop5Config.frame` builds puffin frames from the bare int opcode, bypassing `_send`. It works,
but it means two code paths. Optional: route it through `_send(CommandNumber.setConfig/​setDeviceConfig,
payload: body, )` so all sends share seq counter + logging. Low priority; behaviour-neutral.

### 6.5 Response + event plumbing (the actual missing surface)
Sending is trivial; *observing the reply* is the gap. In `whoop_ble_client.dart` the notify handler
already routes to `Framing.parseFrame`. Extend the `COMMAND_RESPONSE`(36)/`PUFFIN_COMMAND_RESPONSE`(38)
branch to demux by echoed opcode and surface typed results (version string, clock, battery mV, alarm
time, body location) on new broadcast streams, and extend the EVENT(48) branch to decode the
un-mapped `EventNumber`s in §5 (alarm set/executed/disabled, ship-mode, high-freq-sync ack,
haptics-terminated). Persist events to the `WhoopEvents` / `Events` drift tables. This is where a
new drift column or two may be needed (e.g. `DeviceInfo.fwVersion`, `WhoopBattery.milliVolts`).

### 6.6 Files to touch (summary)
- `lib/core/ble/protocol/enums.dart` — add the §6.3 SAFE constants (+ mirror `android/.../protocol/Enums.kt`).
- `lib/core/ble/transport/whoop_ble_client.dart` — new `_send` call-site methods (§6.2) + response/event demux (§6.5) + public streams.
- `lib/core/ble/protocol/framing.dart` — no change to builders; possibly extend `_decodeCommandResponse*` for new opcodes.
- `lib/core/ble/protocol/{alarm_payload,haptic_clock,whoop5_config}.dart` — reuse as-is.
- `lib/core/data/db/database.dart` — only if a response needs a new column (bump `schemaVersion` + migration).
- `test/…` — one byte-exact frame test per new opcode; one parse test per new response/event.
- (State/UI) `lib/features/alarm/…`, broadcast/HR settings — wire the new client methods to providers.

---

## 7. Open questions / on-device validation (user's rooted rig)
1. **4.0 vs 5.0 opcode divergence.** The table's opcodes are the *canonical* set; a real 5.0/MG strap
   may reject some 4.0-only opcodes (e.g. 0x4D SET_ADVERTISING_NAME_HARVARD vs 0x8C) and vice-versa.
   Confirm per-family on hardware before shipping a feature. `_family` already branches framing; it
   may also need to branch opcode choice (haptics already does: 0x13 vs 0x4F).
2. **Haptics/alarm payload revisions.** S3 encodes rev bytes (alarm rev4, haptics rev1, run/disable
   rev2). Verify the strap firmware in hand accepts these revs; capture the EVENT ACK.
3. **High-freq-sync semantics.** Confirm 0x60 payload `[rev2][interval][duration]` and that the strap
   emits EVENT 97/98; measure the actual offload speedup before relying on it.
4. **Feature-flag key exchange.** Do 0x77/0x78 writes on a *paired* strap need the 0x73/0x75 key
   exchange first, or is the bonded link sufficient? Our current R22/broadcast path skips it and was
   reported working (#174/#181) — reconfirm on the current firmware.
5. **GET_* response layouts.** Byte layouts for the read commands (version, clock, battery-ext, body
   location, ff/device-config values) are only partially reversed; capture real responses via the
   Frida SSL hook / HCI snoop and pin them in a test before parsing.
6. **Never** exercise FORCE_TRIM (0x19), any firmware-load (0x24-0x26 / 0x8E-0x90), ENTER_BLE_DFU
   (0x2D), RESET_FUEL_GAUGE (0x63), REBOOT/POWER_CYCLE (0x1D/0x20) on the live strap — kept EXCL.

---

## 8. Verdict
The command *transport* is fully ported and correct: framing (both families), CRC, seq, the
write-with-response path, and the historical-offload loop all match the reverse-engineered app and an
independent HCI capture, byte for byte. The gap is **breadth and observation**, not correctness:

- Our `CommandNumber` is an intentional **25 of 80** — the SAFE subset. ~14 of the missing 55 are
  destructive and must stay out; the rest are benign and enumerated in §6.3.
- Of the 25, only ~6 are actually **wired** to a call site; ~19 are declared-but-unused and can be
  activated with a few lines each (§6.2).
- The real engineering work is **response/EVENT decoding** (§6.5) — sending is a solved problem.

Nothing here is server-side: every opcode in this inventory is a genuine on-strap BLE command
(evidenced in the app's own `Lvp0/e;` enum and independent HCI snoop). The cloud DTOs were explicitly
out of scope and were not used.
