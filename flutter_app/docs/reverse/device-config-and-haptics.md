# SET_DEVICE_CONFIG / SET_CONFIG (feature-flag) & HAPTICS — reverse-engineering spec

Byte-precise, implementation-ready notes for the three "write a command to the strap" families this
app cares about:

1. **SET_CONFIG / SET_FF_VALUE (0x78)** — persistent *feature-flag* writes (the R22 deep-stream unlock).
2. **SET_DEVICE_CONFIG (0x77)** — persistent *device-config* writes (the Broadcast-HR flag).
3. **HAPTICS** — how a wrist buzz is actually triggered over BLE (WHOOP 4.0 vs 5.0/MG), plus the
   Haptic Clock schedule and the strap-armed alarm haptic.

It cross-checks our already-ported Dart (`lib/core/ble/protocol/whoop5_config.dart`,
`haptic_clock.dart`, `alarm_payload.dart`, `framing.dart`, `enums.dart`) against the Kotlin reference
(`com/noop/protocol/*`, `com/noop/ble/WhoopBleClient.kt`) and against the decompiled **official** WHOOP
v5.458.0 Android app + the RE firmware report, and it flags the gaps the Flutter transport still has.

> **Honesty up front.** Everything in sections 3–6 is on-strap / on-wire. Two things people expect to
> find here are **NOT** app-writable and are called out explicitly in §9: the RGB **status LED**
> (firmware-driven, no app BLE command) and **on-wrist state** (a strap→app *event*, read-only; the app
> only *tunes* wear detection via a config, it does not "set on-wrist"). Broadcast-HR advertising is
> **not** its own opcode either — it is one `SET_DEVICE_CONFIG` key.

---

## 0. Evidence index (what proves what)

| Claim | Evidence |
|---|---|
| Haptic IC is TI **DRV2625**; LED is TI **LP5562** | `whoop/firmware/MAVERICK_FIRMWARE_REVERSE_ENGINEERING.md:141,158,163,184-185,345`; `whoop/firmware/WHOOP_FIRMWARE_REPORT.md:66,128` |
| Firmware BLE command names incl. `BLE_CMD_HAPTICS_RUN_NTF`, `BLE_CMD_HAPTICS_STOP`, `BLE_CMD_CONFIG_VALUE_SET_DEVICE_CONFIG`, `BLE_CMD_SIGPROC_SET_WRIST_DETECT`, `BLE_CMD_SET_REALTIME_HR`, `BLE_CMD_ADV_NAME_SET`, `BLE_CMD_ECG_SELECT_WRIST` | `whoop/firmware/MAVERICK_FIRMWARE_REVERSE_ENGINEERING.md:205-232` |
| AA01 header CRC = **CRC-16/MODBUS init 0xFFFF** | `whoop/firmware/MAVERICK_FIRMWARE_REVERSE_ENGINEERING.md:388` |
| Notification haptic wire struct = 8×`waveFormEffect` (byte) + `loopControlForEffects` (u16/short) + `overallWaveformLoopControl` (byte) | official app `com/whoop/domain/model/haptics/NotificationHapticsPattern.smali:27,70-88` (ctor `(IIIIIIIISI)V`) |
| That struct serialises to a **12-byte (0xc) LITTLE_ENDIAN** buffer: `put(B)` lead + 8×`put(B)` effects + `putShort(S)` loop + `put(B)` overall | official app `smali_classes11/li0/h0.smali` (`b(NotificationHapticsPattern)` → `ByteBuffer.allocate(0xc).order(...)`, put sequence) |
| Alarm haptic adds `alarmDurationInSeconds` after the same fields | official app `smali_classes6/li0/q0.smali` (`b(AlarmHapticsPattern)`), `AlarmHapticsPattern.smali` |
| Command-packet classes live in `com.whoop.ble.packets.commandpackets` (obf `li0/*`); `RunAlarmPacketParams.Rev2` referenced | official app `smali_classes11/li0/e0$a.smali:71` |
| R22 golden frame (seq=1, `enable_r22_packets`) | `android/.../protocol/Whoop5ConfigTest.kt:17-24`, ported `flutter_app/test/ble/protocol/whoop5_config_test.dart:16-23` |
| Broadcast-HR device-config body layout | `android/.../protocol/BroadcastHrConfigTest.kt`, ported `flutter_app/test/ble/protocol/broadcast_hr_config_test.dart` |
| Maverick 0x13 opcode + payload for 5/MG buzz; 79 rejected with result 0x03 on real MG | `android/.../ble/WhoopBleClient.kt:1953-1968` (comment records the real-MG capture) |
| Third-party corroboration of key names + 0x78 opcode | judes.club "Cracking the WHOOP 5 Bluetooth Protocol"; Asherlc/dofek `docs/whoop-ble-protocol.md` (cited in `Whoop5Config.kt:6-18`) |

Effect IDs **47** and **152** (the "notify"/wake preset) are DRV2625 waveform-library sequence
entries; the same pair is used for both the notification buzz and the alarm wake
(`flutter_app/lib/core/ble/protocol/alarm_payload.dart:28-29`).

---

## 1. Two transports (recap — the envelope the commands ride in)

Commands are written to the strap's **command characteristic**. The envelope differs by family; both
builders already exist in Dart (`Framing.buildCommand`, `Framing.puffinCommandFrame` —
`flutter_app/lib/core/ble/protocol/framing.dart:621,666`).

### WHOOP 4.0 ("harvard", AA00 / SOF 0xAA)
```
[0]      0xAA (SOF)
[1..2]   length u16 LE   = (3 + payload.len) + 4
[3]      CRC8(len bytes) (poly 0x07)
[4]      packet type = 0x23 (COMMAND)
[5]      seq (u8)
[6]      cmd opcode (u8)
[7..]    payload
[tail]   CRC32 (zlib, LE) over frame[4 .. len)
```

### WHOOP 5.0 / MG ("puffin", AA01)
```
[0]      0xAA (SOF)
[1]      0x01 (format byte)
[2..3]   declLen u16 LE  = inner.len + 4        ; inner padded up to a 4-byte boundary
[4..5]   header = 0x00 0x01
[6..7]   CRC16/MODBUS over frame[0..6)  (init 0xFFFF, poly 0xA001, reflected) — LE
[8..]    inner = [type=0x23][seq][cmd] + payload   (4-byte padded)
[tail]   CRC32 (zlib, LE) over the padded inner
```
The inner **type** for a command is `0x23` (PacketType.command / 35). The **4-byte inner padding** is
mandatory and is exactly what makes the 12-byte haptic payload frameable (inner 15 → 16); without it
the declared length + CRC32 cover the wrong byte count and the strap rejects the frame
(`framing.dart:682-693`, WhoopBleClient.kt:1957).

CRC-16/MODBUS is firmware-confirmed for the AA01 header (evidence §0). Our `Crc.crc16Modbus`
(`crc.dart:10,81`) already matches.

---

## 2. Opcode table (the ones this spec covers)

`CommandNumber` raw values are decimal in `enums.dart`; hex is what goes on the wire at inner`[2]`.

| Name (our enum) | dec | **hex** | Family | Purpose | Firmware string |
|---|---:|---|---|---|---|
| `toggleRealtimeHr` | 3 | 0x03 | both | live-HR stream on/off | `BLE_CMD_SET_REALTIME_HR` |
| `runHapticPatternMaverick` | 19 | **0x13** | 5/MG | one-shot notification buzz | `BLE_CMD_HAPTICS_RUN_NTF` |
| `setAdvertisingName` | 77 | 0x4D | 4.0 | rename BLE adv name | `BLE_CMD_ADV_NAME_SET` |
| `runHapticsPattern` | 79 | 0x4F | 4.0 | legacy buzz pattern | (4.0 firmware) |
| `setDeviceConfig` | 119 | **0x77** | 5/MG | one persistent device-config value | `BLE_CMD_CONFIG_VALUE_SET_DEVICE_CONFIG` |
| `setConfig` (SET_FF_VALUE) | 120 | **0x78** | 5/MG | one persistent feature flag | (config-value family) |
| `stopHaptics` | 122 | 0x7A | 4.0 | stop an in-progress pattern | `BLE_CMD_HAPTICS_STOP` |
| `selectWrist` | 123 | 0x7B | — | wrist select (see §9) | `BLE_CMD_ECG_SELECT_WRIST` |

> On 5/MG, `runHapticsPattern`(0x4F=79) is **remapped to 0x13** by the sender; a real MG strap
> answered a raw 79 with `COMMAND_RESPONSE result=0x03` (rejected). See §6.

---

## 3. SET_CONFIG / SET_FF_VALUE — 0x78 (feature flags, the R22 unlock)

WHOOP 5/MG straps withhold their deep biometric streams (high-rate "R22" optical/HR/motion packets,
inner type **0x2F**) from a fresh third-party client. The official app switches them on by writing a
burst of persistent feature flags right after the hello handshake.

### 3.1 Payload body — 40 bytes (`Whoop5Config.payloadBody`)
```
[0..31]  flag NAME, US-ASCII, NUL-padded to 32
[32]     value byte = ASCII digit '1'(0x31) or '2'(0x32)
[33..39] 7 × 0x00
```

### 3.2 Command payload = `[0x01] + body` (b3 lead byte, like CLIENT_HELLO), framed as puffin 0x78.
`Whoop5Config.frame(flag, seq)` (`whoop5_config.dart:89`) does exactly:
`puffinCommandFrame(cmd=0x78, seq, payload=[0x01]+payloadBody(name,value))`.

### 3.3 Golden frame (pinned by test — do not drift)
`Whoop5Config.frame(enable_r22_packets, seq=1)` ==
```
aa0130000001 eb11 23017801 656e61626c655f7232325f7061636b657473 00…(pad to 32)… 32 00000000000000 d2eeb0b7
└header────┘ └c16┘ └inner hd┘└ "enable_r22_packets" ───────────┘ pad  val  7×zero    └crc32──┘
```
- header `aa 01 30 00 00 01` → declLen 0x0030 = 48 (inner 44 + 4 crc32).
- inner header `23 01 78 01` = type 0x23, seq 0x01, cmd 0x78, b3 0x01.
- Pinned in `flutter_app/test/ble/protocol/whoop5_config_test.dart:16-23`.

### 3.4 The 15-flag `enableR22Sequence` (verbatim, `whoop5_config.dart:39-55`)
`enable_r22_packets`=2, `…_v2`=2, `…_v3`=2, `…_v4`=**1**, `…_v5`=2, `…_v6`=2, `…_v8`=2,
`make_hrfm_visible`=2, `disable_pip_r26_packets`=2, `wear_detect_bias`=2, `hr_ch_switching`=2,
`ir_hw_switching`=2, `enable_passive_strap_fit_gen5`=**1**, `enable_sig11_during_sleep`=2,
`dorset_inhibit_wpt`=2. (Only v4 and passive-strap-fit are '1'.) Sent **with response**, ~80 ms apart.

**Gating (safety):** these are persistent writes — only ever on an explicit deep-data opt-in, a bonded
(encrypted-bond, not live-HR-only) **worn** 5/MG (Kotlin `enableWhoop5DeepData`, WhoopBleClient.kt:3840).
Reversible (only changes which data the strap emits).

---

## 4. SET_DEVICE_CONFIG — 0x77 (Broadcast HR)

Distinct opcode, distinct body shape from §3. Makes the strap advertise its HR as a standard BLE HR
sensor (**0x180D** + live HR in the manufacturer data) so a Garmin / Zwift / gym HR client can pair to
it directly. This is **not** a dedicated "broadcast" opcode — it is one device-config **key**.

### 4.1 Device-config body — **33 bytes** (`Whoop5Config.deviceConfigBody`)
```
[0..31]  key NAME, US-ASCII, NUL-padded to 32
[32]     value byte = ASCII '1'(0x31)=on / '0'(0x30)=off
```
No trailing 7-zero padding (contrast §3.1's 40-byte body). Key: `whoop_live_hr_in_adv_ind_pkt`
(28 chars → NUL @[28..31], value @[32]).

### 4.2 Command payload = `[0x01] + deviceConfigBody(key, value)`, framed as puffin **0x77**.
Kotlin `setBroadcastHr(on)` (WhoopBleClient.kt:3812) sends `SET_DEVICE_CONFIG`,
`byteArrayOf(0x01) + deviceConfigBody("whoop_live_hr_in_adv_ind_pkt", on?0x31:0x30)`, with response.
Validated on real hardware (paired to a Garmin Edge 840). Reversible; re-applied on reconnect if the
opt-in is still on (WhoopBleClient.kt:4264-4265).

Body layout pinned in `flutter_app/test/ble/protocol/broadcast_hr_config_test.dart`.

### 4.3 Chunked config (firmware exposes it; we do NOT need it)
Firmware also has `BLE_CMD_START_DEVICE_CONFIG_KEY_EX` / `BLE_CMD_SEND_NEXT_DEVICE_CONFIG`
(evidence §0) for multi-fragment config values. Our keys are single-write (≤33-byte body); the chunked
path is out of scope unless a future key exceeds one write.

---

## 5. HAPTIC pattern struct (DRV2625) — the payload a buzz carries

Confirmed byte-for-byte from the official app (`NotificationHapticsPattern.smali` + `h0.smali`) and
mirrored in our alarm builder. The DRV2625 plays up to 8 sequenced waveform-library effects.

### 5.1 Notification haptic body — **12 bytes**, LITTLE_ENDIAN
```
[0]      0x01                       ; lead/subcommand byte (h0 first put(B))
[1..8]   waveFormEffect1..8 (u8 ea) ; DRV2625 effect IDs; "notify" preset = 47,152,0,0,0,0,0,0
[9..10]  loopControlForEffects u16 LE ; 0 for the notify preset
[11]     overallWaveformLoopControl u8 ; 0 for notify
```
This is exactly the 5/MG maverick payload in Kotlin:
`byteArrayOf(0x01, 47, 152, 0,0,0,0,0,0, 0,0, 0)` (WhoopBleClient.kt:1961-1962).

### 5.2 Alarm haptic body — 12 bytes, adds a duration (strap-armed wake)
The alarm variant (`AlarmHapticsPattern`, `q0.smali`) replaces the trailing loop/overall tail with
loop + overall + `alarmDurationInSeconds`. Our `alarm_payload.dart` embeds it inside the 20-byte
SET_ALARM_TIME rev-4 body at `[8..19]`: `8 effects(47,152,0…) + u16 loop(0) + overall(7) + duration(30)`
(`alarm_payload.dart:52-76`). Effects match the notification preset; `overall=7`, `duration=30 s`.

---

## 6. Triggering a buzz over BLE (per family)

### 6.1 WHOOP 4.0 — `RUN_HAPTICS_PATTERN` (0x4F / 79)
Payload `[patternId, loops, 0, 0, 0]`; `patternId=2` is the graduated alarm buzz the official app uses.
- `buzz(loops=2)` → `[2, loops, 0,0,0]` (WhoopBleClient.kt:1984).
- `buzzStrapOnce()` → `[2,3,0,0,0]` **with response**, then a belt-and-suspenders `RUN_ALARM(68) [0x01]`
  (a bare pattern write was reported ignored on some 4.0 firmware) (WhoopBleClient.kt:2004).
- `stopHaptics()` → `STOP_HAPTICS(0x7A) [0x00]` (WhoopBleClient.kt:2028) → `BLE_CMD_HAPTICS_STOP`.

### 6.2 WHOOP 5.0 / MG — maverick `0x13` (`BLE_CMD_HAPTICS_RUN_NTF`)
The sender **remaps** cmd 79 → **0x13** and swaps the 4.0 `[patternId,loops,…]` body for the 12-byte
DRV2625 notify body of §5.1. A raw 79 is rejected (`result=0x03`). Frame = puffin 0x13 with
`[0x01,47,152,0,0,0,0,0,0,0,0,0]` (WhoopBleClient.kt:1959-1968).
- `buzzStrapOnce()` on 5/MG = the single maverick buzz (no RUN_ALARM follow-up — not allow-listed).
- `STOP_HAPTICS` is **not** allow-listed for 5/MG (the one-shot isn't a sustained pattern); calling it
  on a 5/MG is a logged no-op, **not** a guessed opcode (WhoopBleClient.kt:2021-2026). Keep that verdict.

### 6.3 5/MG command allow-list (the gate the Dart port is missing)
Kotlin `send()` drops any 5/MG command not on this list: `TOGGLE_REALTIME_HR`, `RUN_HAPTICS_PATTERN`,
`SEND_HISTORICAL_DATA`, `HISTORICAL_DATA_RESULT`, `SET_CLOCK`, `GET_CLOCK`, `GET_DATA_RANGE`,
`SET_ALARM_TIME`, `DISABLE_ALARM`, `SET_CONFIG` (only if deep-data opt-in), `SET_DEVICE_CONFIG` (only if
broadcast-HR opt-in) (WhoopBleClient.kt:1938-1952). This prevents un-framed/un-honored opcodes going out
on a 5/MG. **Our Dart `_send` has neither the allow-list nor the 0x13 remap yet** (see §10).

---

## 7. Haptic Clock (buzz the time out on the wrist)

Pure encoder already ported: `HapticClock.pulses(hour, minute, is24h)` (`haptic_clock.dart:37`) → an
ordered `List<Pulse(durationMs, gapMs)>`. Long pulse = a "ten", short = a "unit", in order
HH-tens / HH-units / MM-tens / MM-units; a 0-digit emits no pulse; timing constants
`LONG=550 SHORT=200 INTRA=450 GROUP=900 BLOCK=1500` ms. Unit tests pin it
(`flutter_app/test/ble/protocol/haptic_clock_test.dart`).

**The trigger is not ported.** Kotlin `buzzTimeNow(is24h)` (WhoopBleClient.kt:2049) walks the pulse
list and `handler.postDelayed({ buzz(loops) }, offset)` at each pulse's start, `offset += duration+gap`;
a **long** pulse fires 2 stacked loops, a **short** 1 (the motor pulse length is fixed, so loop-count is
the only "longer vs shorter" lever). Only the *schedule* is new; the buzz is the confirmed one.

---

## 8. Firmware BLE command table (for grounding / future work)

From `MAVERICK_FIRMWARE_REVERSE_ENGINEERING.md:205-232` (firmware strings on the AA01 CMD_TO_STRAP
characteristic). Relevant rows: `BLE_CMD_SET_CLOCK`, `BLE_CMD_GET_ALARM_TIME`, `BLE_CMD_SET_ALARM_INFO`,
`BLE_CMD_ALARM_DISABLE`, `BLE_CMD_SET_REALTIME_HR`, `BLE_CMD_GET_ADV_NAME`, `BLE_CMD_ADV_NAME_SET`,
`BLE_CMD_FORGET_BONDING`, `BLE_CMD_RAW_DATA_STOP`, `BLE_CMD_IMU_SET_DATA_STREAM`,
`BLE_CMD_HAPTICS_RUN_NTF`, `BLE_CMD_HAPTICS_STOP`, `BLE_CMD_HISTORY_ENABLE_HIGH_FREQ`,
`BLE_CMD_CONFIG_VALUE_SET_DEVICE_CONFIG`, `BLE_CMD_START_DEVICE_CONFIG_KEY_EX`,
`BLE_CMD_SEND_NEXT_DEVICE_CONFIG`, `BLE_CMD_BODY_LOC_GET_STATUS`, `BLE_CMD_SIGPROC_SET_WRIST_DETECT`,
`BLE_CMD_ECG_SELECT_WRIST`. (Firmware-load/ECG rows exist but are deliberately out of scope — see the
`CommandNumber` "SAFE commands only" note in `enums.dart:87`.)

---

## 9. Honest verdicts on the things people assume are here

- **Broadcast-HR "enable" flag** → **on-strap, but not its own opcode.** It is `SET_DEVICE_CONFIG`
  (0x77) with key `whoop_live_hr_in_adv_ind_pkt` = '1'/'0' (§4). The 0x180D advertising is a *side
  effect* the firmware produces once that key is set.
- **On-wrist / wear state** → **read-only strap→app EVENT, not a config you set.** The app receives
  `wristOn`(9)/`wristOff`(10) events (`enums.dart:66-68`) and a `WEAR_DETECT` biometric flag. The only
  *write* is tuning detection: `wear_detect_bias` (a §3 feature flag) and firmware
  `BLE_CMD_SIGPROC_SET_WRIST_DETECT`. There is **no** "force on-wrist" command. Do not invent one.
- **Status LED (colour/pattern/brightness)** → **firmware-driven, no app BLE command.** The strap has an
  LP5562 RGB driver and internal `LED_UI` patterns (evidence §0), but the official app exposes **no**
  BLE opcode to set LED colour/pattern. Treat LED as out of scope; do not fabricate one.
- **`selectWrist` (0x7B)** → firmware string is `BLE_CMD_ECG_SELECT_WRIST` — it is the **ECG** wrist
  selection, not a general "which wrist you wear it on" setting. It is in our SAFE enum but currently
  unused; leave it unless/until ECG work lands.
- **`STOP_HAPTICS` on 5/MG** → intentionally a no-op (§6.2). Not a gap; a deliberate refusal to guess.

---

## 10. Cross-check: current Flutter port vs the Kotlin reference (the gaps)

What the Dart transport (`lib/core/ble/transport/whoop_ble_client.dart`) has today:
- ✅ `_sendR22EnableSequence()` (auto-fires the 15 `SET_CONFIG` flags during 5/MG bring-up,
  `whoop_ble_client.dart:1090`). **Note:** it runs on *every* 5/MG bring-up with no opt-in gate — Kotlin
  gates it behind the deep-data experiment + worn/encrypted-bond checks.
- ✅ `Framing.puffinCommandFrame` / `buildCommand`, `Whoop5Config`, `HapticClock` encoder, `alarm_payload`.

What it is **missing** vs Kotlin (the work this spec unblocks):
1. **`_send` has no 5/MG allow-list and no 0x13 haptic remap** (`whoop_ble_client.dart:1522-1545`). A
   `runHapticsPattern`(79) sent to a 5/MG would go out as raw 79 and be rejected. Fix in §11.
2. **No `buzz` / `buzzStrapOnce` / `stopHaptics` public API.**
3. **No `buzzTimeNow` Haptic-Clock trigger** (the encoder exists; the scheduler doesn't).
4. **No `setBroadcastHr(on)`** (device-config 0x77 write) and no reconnect re-apply.
5. **No opt-in prefs** (`isDeepDataEnabled`, `broadcastHr`) — Kotlin has `PuffinExperiment`.
6. **No reversible off-path for R22** (Kotlin only enables; parity is fine, but note it).

---

## 11. Step-by-step implementation plan (Flutter)

All byte-building already exists; this is transport + UI wiring. Reuse
`Framing.puffinCommandFrame` / `Framing.buildCommand`, `CommandNumber`, `Whoop5Config`, `HapticClock`,
and the existing `_write` / `_send` / `_seq` machinery in `WhoopBleClient`.

### Step 1 — Opt-in prefs (persisted, crash-safe)
- Add two bools to the app's prefs store (`lib/core/state/prefs.dart` → `Prefs`, secure storage):
  `blePuffinDeepData` and `bleBroadcastHr`, both default **false**.
- Surface them read-only to the transport via the provider layer
  (`lib/core/ble/transport/whoop_providers.dart`).

### Step 2 — Harden `_send` for 5/MG (transport/whoop_ble_client.dart:1522)
- Before framing, when `_family == whoop5`, apply the **allow-list** from §6.3 (gate `SET_CONFIG` on the
  deep-data pref and `SET_DEVICE_CONFIG` on the broadcast-HR pref); log-and-return otherwise.
- Add the **haptic remap**: if `cmd == CommandNumber.runHapticsPattern`, send puffin `cmd=0x13`
  (`runHapticPatternMaverick.rawValue`) with payload `[0x01,47,152,0,0,0,0,0,0,0,0,0]` instead of the
  passed body. Keep 4.0 untouched (79 + `buildCommand`).
- Honour `withResponse` intent (the char supports write-with-response; use it for acked commands).

### Step 3 — Haptic public API (new methods on `WhoopBleClient`)
- `void buzz({int loops = 2})` → `_send(CommandNumber.runHapticsPattern, payload: [2, loops.clamp(0,255), 0,0,0])`.
- `void buzzStrapOnce()` → `_send(runHapticsPattern, [2,3,0,0,0], withResponse:true)`; on 4.0 only,
  follow with `_send(runAlarm, [0x01], withResponse:true)`. (`runAlarm` = `CommandNumber(68)` already
  exists in `enums.dart:114` — no enum change needed.)
- `void stopHaptics()` → `_send(CommandNumber.stopHaptics, payload: [0])` (the §6.3 allow-list already
  makes this a no-op on 5/MG — keep that).

### Step 4 — Haptic Clock trigger (`buzzTimeNow`)
- Port WhoopBleClient.kt:2049 with Dart timers. `HapticClock.pulses(now.hour, now.minute, is24h)`; if
  empty, log and return. Walk the list with cumulative offset; schedule each with
  `Timer(Duration(milliseconds: offset), () => buzz(loops: p.isLong ? 2 : 1))`, `offset += p.durationMs +
  p.gapMs`. Track the timers in a list and cancel them in `_teardownConnection` / `dispose` so a
  disconnect mid-sequence doesn't fire on a dead characteristic.
- `is24h` from the app's existing clock/format pref (`lib/core/state/format.dart`).

### Step 5 — Broadcast HR (`setBroadcastHr`)
- Port WhoopBleClient.kt:3812: require `_family == whoop5` + connected + bonded; else log-and-return.
  `value = on ? 0x31 : 0x30`; `_send(CommandNumber.setDeviceConfig, payload: [0x01] +
  Whoop5Config.deviceConfigBody('whoop_live_hr_in_adv_ind_pkt', value), withResponse: true)`.
- On successful send, persist the pref (Step 1). In `_onConnected` / post-bond, **re-apply** if the pref
  is on (mirror WhoopBleClient.kt:4264).

### Step 6 — Gate the R22 sequence behind the opt-in
- In `_bringUpWhoop5` (`whoop_ble_client.dart:1073`), only call `_sendR22EnableSequence()` when
  `blePuffinDeepData` is true **and** the strap is worn/encrypted-bonded (add the checks Kotlin has). On
  a default install this must not fire.

### Step 7 — UI (Settings / Device screen)
- In `lib/features/settings/presentation/device_settings_screen.dart`: two toggles ("Broadcast heart
  rate", "Deep data (R22)") bound to the Step-1 prefs → call `setBroadcastHr` / `enableWhoop5DeepData`;
  a "Buzz strap" button → `buzzStrapOnce`; a "Buzz the time" button → `buzzTimeNow`. Use the shared
  widgets (`NoopCard`, controls) — no bespoke styling (project design rules).

### Step 8 — Drift (only if you want an audit trail)
- The drift DB (`lib/core/data/db/database.dart`) is **not required** for any of this — prefs cover the
  opt-ins. Optional: log haptic/config writes to a strap-log table for the device screen's log view
  (mirrors Kotlin `StrapLogBuffer`). Not load-bearing; skip unless the log UI needs persistence.

### Step 9 — Tests (the gate — `flutter test`, never the app)
- Extend `test/ble/protocol/`:
  - `whoop5_config_test.dart` already pins the R22 golden frame + body — keep.
  - `broadcast_hr_config_test.dart` already pins the 33-byte device-config body — keep.
  - **Add** a framing test that `Framing.puffinCommandFrame(cmd:0x13, seq:1, payload:[0x01,47,152,
    0,0,0,0,0,0,0,0,0])` produces a valid frame that round-trips through `parseFrame(frame, whoop5)`
    (inner padded 15→16, declLen/CRC correct) — this is the one new byte-level surface.
  - **Add** a pure encoder→schedule test for the `buzzTimeNow` offset math (durations sum) without BLE,
    by extracting the schedule into a testable pure function (list of `(offsetMs, loops)`).
- Do **not** add an integration test that opens a device; the transport methods are only exercisable on
  real hardware (see §12).

---

## 12. Open questions & on-device validation

Everything below is **hardware-only** — it cannot be settled by `flutter test`; it needs a bonded strap
and the strap log.

1. **5/MG buzz duration / feel.** The motor pulse length is fixed; "long vs short" is faked with 1 vs 2
   stacked loops. Whether that reads as distinguishable on a real MG wrist is unverified
   (WhoopBleClient.kt:2045-2047). Validate by running `buzzTimeNow` on a known time and feeling it.
2. **`loopControlForEffects` / `overallWaveformLoopControl` semantics.** We only ever send the
   `47,152` "notify" preset with loop=0/overall=0 (buzz) or overall=7 (alarm). The full DRV2625 effect
   table and how loop-control repeats the sequence are **not** mapped. Deeper patterns are speculative
   until captured from the official app or read from firmware.
3. **Broadcast-HR advertising format.** Confirmed a Garmin Edge 840 pairs (WhoopBleClient.kt:3808), but
   the exact 0x180D manufacturer-data bytes the strap advertises aren't decoded here — out of scope
   (this spec is about the *write* that enables it, not the resulting advertisement).
4. **R22 acceptance & the 0x2F stream.** Whether all 15 flags ACK (`COMMAND_RESPONSE` to 0x78) and the
   type-0x2F records actually start flowing is on-wrist-gated and must be confirmed from the strap log
   after `enableWhoop5DeepData` (Kotlin tallies `r22FlagsAccepted`; parity work could add the same
   counter to the Dart client). Reversibility (writing '1'/'0' to turn a flag back off) is untested.
5. **`STOP_HAPTICS` on 5/MG.** Deliberately not sent (no confirmed opcode). If a 5/MG ever wedges
   mid-pattern, that's the first thing to capture from the official app.
6. **Chunked device-config** (`START_DEVICE_CONFIG_KEY_EX` / `SEND_NEXT_DEVICE_CONFIG`) is unused; only
   needed if a future config value exceeds a single ≤33-byte body.

---

### File map (what to touch)

| File | Change |
|---|---|
| `lib/core/state/prefs.dart` | add `blePuffinDeepData`, `bleBroadcastHr` bools |
| `lib/core/ble/transport/whoop_ble_client.dart` | `_send` allow-list + 0x13 remap; `buzz`/`buzzStrapOnce`/`stopHaptics`/`buzzTimeNow`/`setBroadcastHr`; gate R22; timer cleanup |
| `lib/core/ble/transport/whoop_providers.dart` | expose prefs → client |
| `lib/features/settings/presentation/device_settings_screen.dart` | toggles + buzz buttons (shared widgets only) |
| `test/ble/protocol/*` | new puffin-0x13 frame round-trip test; pure `buzzTimeNow` schedule test |

No new byte layouts are invented — every wire format above is already pinned by an existing test or by
the cited official-app / firmware evidence. The remaining work is transport wiring + UI, gated by
`flutter test`.
