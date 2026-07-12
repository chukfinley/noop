# WHOOP strap SMART-ALARM BLE protocol — implementation spec

**Status:** byte-precise, cross-verified against three independent sources. Ready to implement.
**Scope:** program the strap's *own* firmware wake alarm over BLE (it fires even with the phone away),
read it back, and disable it. This is a **strap GATT characteristic write**, not a cloud/server call —
the official app really does write these opcodes to the strap.

## TL;DR for the implementer

- **SET alarm** = command **66 / `0x42` `SET_ALARM_TIME`**, 20-byte REVISION_4 payload, written to the
  family command characteristic (`…0002`), framed by our existing `Framing.buildCommand` (WHOOP4) /
  `Framing.puffinCommandFrame` (WHOOP5).
- **Our `AlarmPayload.build()` is already byte-identical to the official app** and to the whoop RE
  capture app. No change to the payload encoder is needed. See the reconciliation table below.
- **READ back** = command **67 / `0x43` `GET_ALARM_TIME`** (payload `[0x04,0x01]` = rev4, alarmId 1).
  The COMMAND_RESPONSE body layout is **undocumented**; parse it defensively (do not gate behaviour on it).
- **DISABLE** = command **69 / `0x45` `DISABLE_ALARM`**, payload `[0x02, 0xFF]` (our `disableRev2()`).
- **RUN now** (test buzz) = command **68 / `0x44` `RUN_ALARM`**, payload `[0x02, 0x01]`.
- The transport (`WhoopBleClient`) and the write-side service (`AlarmService`) currently have **zero**
  BLE alarm wiring — this is the gap to fill. The payload/opcode layer is done.

---

## 1. Evidence base (three independent sources, all agreeing)

| # | Source | What it gives |
|---|--------|---------------|
| A | **Official WHOOP Android app v5.458.0**, decompiled smali under `/home/user/git/whoop/research/work/whoop_apk/base_full/` | The authoritative wire format the real app emits. |
| B | **whoop RE capture app** `WhoopProtocol.kt` at `/home/user/git/whoop/apps/ble-sync/app/src/main/java/com/whoopcapture/WhoopProtocol.kt:255-290` | An independent hand-written re-implementation, hardware-captured. |
| C | **Our port** `lib/core/ble/protocol/alarm_payload.dart` + Kotlin twin `android/.../protocol/AlarmPayload.kt`, pinned by `Whoop4AlarmPayloadTest` / `AlarmReadbackDecodeTest`. | What we already ship. |

All three produce the **same 20 bytes** for a given wake time. The layout below is not a guess.

### Opcode enum (Source A: `smali_classes6/vp0/e.smali:741-779`, values at `:743-773`)

| Command | Hex | Dec | Our `CommandNumber` (`enums.dart`) |
|---------|-----|-----|-----|
| `SET_ALARM_TIME` | `0x42` | 66 | `setAlarmTime(66)` ✓ |
| `GET_ALARM_TIME` | `0x43` | 67 | `getAlarmTime(67)` ✓ |
| `RUN_ALARM` | `0x44` | 68 | `runAlarm(68)` ✓ |
| `DISABLE_ALARM` | `0x45` | 69 | `disableAlarm(69)` ✓ |

Our enum values are already correct.

---

## 2. SET the alarm — `SET_ALARM_TIME` (cmd 66 / 0x42)

### 2.1 Payload byte layout (REVISION_4, 20 bytes, all multi-byte fields little-endian)

Decoded from Source A `smali_classes6/li0/p0$a.smali` (`b(int alarmId, AlarmHapticsPattern, long timeMillis)`)
and the haptics serializer `smali_classes6/li0/q0.smali`; byte order `smali_classes6/vp0/d.smali:14`
(`LITTLE_ENDIAN`); revision value `smali_classes6/vp0/h.smali:80-82` (`REVISION_4 = 0x04`).

```
offset  size  field                     value / encoding
------  ----  ------------------------  ------------------------------------------------
[0]      1    revision                  0x04  (REVISION_4)
[1]      1    alarmId                   0x01  (single alarm slot; default id 1)
[2..5]   4    epoch SECONDS  u32 LE     wakeEpochMs / 1000
[6..7]   2    subSeconds     u16 LE     (wakeEpochMs % 1000) * 32768 / 1000   (1/32768-s fixed point)
[8..15]  8    waveFormEffect1..8        47, 152, 0, 0, 0, 0, 0, 0   (one byte each)
[16..17] 2    loopControlForEffects u16 LE   0x0000
[18]     1    overallWaveformLoopControl     0x07  (7)
[19]     1    alarmDurationInSeconds         0x1E  (30 seconds)
```

- **Epoch is in SECONDS, not millis** — confirmed by `cb2/a.i()` (integer seconds) at
  `.../cb2/a.smali:415` and the `putInt` at `p0$a.smali:91`. Our port divides ms by 1000. ✓
- **Subseconds** use a `1/32768`-second fixed point (`0x8000` constant at `cb2/a.smali:344/436`,
  `putShort` at `p0$a.smali:107`). For a minute-precision wake this is `0x0000`. ✓
- **Haptics tail is exactly 12 bytes** — `q0.smali` `allocate(0xc)`, 8 effect bytes + `putShort(loopControl)`
  + `overallLoop` byte + `duration` byte, then `flip()`. There is **no `alarmType` byte on the wire**
  (`AlarmHapticsPattern.alarmType` exists as a field but is never serialized). ✓
- **Default haptic constants** come from `smali_classes6/pb1/g.smali:60-86`, which constructs the app's
  default `AlarmHapticsPattern(47, 152, 0,0,0,0,0,0, loop=0, overallLoop=7, duration=30, alarmType=0)`
  and a default `StrapAlarmIdentifiable(alarmId=1)`. These are the same 47/152/7/30 the notification buzz
  uses. **Byte-for-byte identical to our `AlarmPayload._waveformEffects` / `_overallLoop` / `_durationSeconds`.**

### 2.2 Reconciliation with our `AlarmPayload.build()` — MATCH, with one cosmetic note

`lib/core/ble/protocol/alarm_payload.dart:60-78` emits precisely the 20 bytes above. Verified against:
- Source B `WhoopProtocol.kt:260-278` → `ByteBuffer.allocate(20)`, identical field order & values.
- Source C test `android/.../ble/Whoop4AlarmPayloadTest.kt` (WHOOP4 short form) and the rev4 doc-comment.

**Authoritative: our 20-byte form is correct. Do not change it.**

**One discrepancy, non-blocking:** the official app's builder calls `ByteBuffer.allocate(0x15)` = **21 bytes**
(`p0$a.smali:55`) but only writes 20 (rev+id+4+2+12). The 21st byte is never `put` and is not flipped, so
it is a spare/reserved trailing `0x00` at most. Source B (an independent capture-driven impl) uses
`allocate(20)` and works on hardware. **Conclusion:** 20 bytes is the meaningful payload; treat the 21st
byte as noise. If on-device testing ever shows the strap rejecting a 20-byte frame, append a single
trailing `0x00` — but there is no evidence it is required, and our 20-byte form is the safer default.

### 2.3 WHOOP4 vs WHOOP5 — two payload forms exist, pick by family

The rev4 20-byte payload above is what the **current official app** and the **WHOOP 5.0/MG** path use.
Our Kotlin client deliberately sends a **different, shorter form on gen-4 hardware** because a real WHOOP4
btsnoop capture (#535) proved the strap only *buzzes* with the 9-byte form:

| Family | Payload builder | Bytes | Source |
|--------|-----------------|-------|--------|
| WHOOP 4.0 | `whoop4AlarmPayload(epochSec)` = `[0x01][u32 LE epoch sec][0x00,0x00][0x00,0x00]` | 9 | `WhoopBleClient.kt:5165-5176`, pinned by `Whoop4AlarmPayloadTest.kt` |
| WHOOP 5.0/MG | `AlarmPayload.build(epochMs)` (rev4, above) | 20 | `alarm_payload.dart:60`, EXPERIMENTAL / unconfirmed to wake |

**Honesty flag (carried from the Kotlin source):** the WHOOP4 9-byte form is hardware-confirmed to buzz.
The WHOOP5 rev4 20-byte form is self-consistent and matches the official app, but **we have never captured
a `STRAP_DRIVEN_ALARM_EXECUTED` on our own 5/MG** — so gate it behind the Experimental opt-in and never
promise the user it will fire until on-device validation lands (see §7).

### 2.4 Framing & characteristic

- Written to the **command characteristic `…0002`** of the family's custom service
  (`device_family.dart:75-81`): WHOOP4 `61080002-8d6d-82b8-614a-1c8cb0f8dcc6`,
  WHOOP5 `fd4b0002-cce1-4033-93ce-002d5875f58a`.
- **WHOOP4 envelope:** `Framing.buildCommand(CommandNumber.setAlarmTime, payload: <9 bytes>, seq: …)`
  → `[0xAA][len u16 LE][crc8][35][seq][66][payload][crc32 LE]` (`framing.dart:621`).
- **WHOOP5 envelope:** `Framing.puffinCommandFrame(cmd: 66, seq: …, payload: <20 bytes>)`
  → CRC16-Modbus header + inner `[35][seq][66][payload]` padded to a 4-byte boundary + CRC32
  (`framing.dart:666`). The RE app CLAUDE.md warns puffin payloads **must be 4-byte aligned or the strap
  rejects with "error = 4"**; `puffinCommandFrame` already pads (`framing.dart:686-693`), and the 20-byte
  rev4 payload is already 4-aligned. Inner layout confirmed: frame byte 8 = `0x23`(35 COMMAND),
  byte 10 = command number — matches the RE app's "byte 10 = command" note.

Our existing `_send()` (`whoop_ble_client.dart:1300-1323`) already routes to the right framer per
`connectedFamily`, so a new alarm method just calls `_send(CommandNumber.setAlarmTime, payload: …)`.

---

## 3. READ BACK — `GET_ALARM_TIME` (cmd 67 / 0x43)

### 3.1 Request

- Payload (Source B `WhoopProtocol.kt:280`, and Source A `li0/i.smali` rev4 constructor):
  **`[0x04, 0x01]`** (revision 4, alarmId 1). The official builder `li0/i$a.a(revision, int)` accepts a
  rev-1 or rev-4 form (`li0/i.smali:68/114` throw guards: "Only packet revision 1/4 can call this
  constructor"). Use the rev4 `[0x04,0x01]` form for 5/MG; the WHOOP4 client historically sends `[0x01]`.
- Send with response so the strap answers.

### 3.2 Response — layout is UNDOCUMENTED; parse defensively

There is **no decompiled parser for the GET_ALARM_TIME response** in the official smali that maps cleanly
to a fixed offset (the app round-trips it through its own domain model). Our port therefore treats the
reply as best-effort and **never gates behaviour on it** — it is a log/telemetry aid only. Follow the
already-written, test-pinned decoder in `WhoopBleClient.kt:5205-5225` (`whoop4ArmedAlarmEpoch`):

- Frame is a `COMMAND_RESPONSE` (type 36) with inner `[36][seq][cmd=67][origin_seq][result][payload…]`;
  payload starts at **absolute offset 9** (`whoop4CommandResponsePayload`, `WhoopBleClient.kt:5185-5191`).
- Try two shapes, first match wins:
  1. **SET-mirror form** — `payload[0] == 0x01` then `u32 LE` epoch at `payload[1..5]`.
  2. **bare `u32 LE`** epoch at `payload[0..4]`.
- Accept a candidate only if it passes the plausibility gate **`1_500_000_000 ≤ epoch ≤ 4_102_444_800`**
  (2017-07 … 2100), else return null and log the raw payload hex. Pinned by `AlarmReadbackDecodeTest.kt`.
- "enabled" state: a plausible near-future epoch ⇒ an alarm is armed; null / implausible / empty ⇒ treat
  as "no alarm armed" (do not surface a bogus date).

**Do not invent a strict offset for the 5/MG COMMAND_RESPONSE.** Our `Framing._decodeCommandResponseWhoop5`
(`framing.dart:400`) does not yet decode cmd 67 — add it only as best-effort mirroring the Kotlin
defensive decoder, or decode in the client after `parseFrame`.

---

## 4. RUN now / DISABLE

- **`RUN_ALARM` (68 / 0x44)** — fire the alarm haptic immediately (test/preview). Payload `[0x02, 0x01]`
  (rev2, alarmId 1) per Source B `WhoopProtocol.kt:283`. On WHOOP4 the Kotlin client also uses it as a
  belt-and-suspenders after a one-shot buzz (`WhoopBleClient.kt:2010`).
- **`DISABLE_ALARM` (69 / 0x45)** — clear the strap alarm. Payload **`[0x02, 0xFF]`** = our
  `AlarmPayload.disableRev2()` (`alarm_payload.dart:81`), confirmed by Source A `li0/c$a.smali:80-105`
  (the rev-2 branch writes `put(0x02); put(0xFF)`) and Source B `WhoopProtocol.kt:286`. Sent
  unconditionally — clearing is safe even if arming was gated off (a no-op on a strap with no alarm).
  Note: rev-4 has no distinct disable form; the app disables a rev4-set alarm with this rev2 `[0x02,0xFF]`.

---

## 5. Status model — what the strap actually confirms

The strap has **exactly one firmware-alarm slot** (`StrapAlarmReconcileTest.kt` header). Map states:

| App state | Meaning | Signal |
|-----------|---------|--------|
| `queued` | user enabled an alarm but no strap is connected yet | local only; our current honest default |
| `armed`  | we wrote `SET_ALARM_TIME` and the strap **ACKed** it | `COMMAND_RESPONSE` for cmd 66 with `result = SUCCESS(1)` (5/MG result codes decoded at `framing.dart:275-288`). On WHOOP4 the write-with-response completing is the ack. Optionally corroborate with a `GET_ALARM_TIME` readback (§3) that decodes to the epoch we set. |
| `fired`  | the strap ran the wake haptic itself | live **`EVENT` `STRAP_DRIVEN_ALARM_EXECUTED` (event 57)** (`enums.dart:69`). Route it exactly like the Kotlin `smartAlarmFiredForEvent` (`WhoopBleClient.kt:738`): true only for a LIVE event 57, never a historical replay during backfill. |

Key correctness rule from `StrapAlarmReconcileTest`: **the single slot is shared** (smart-alarm + any
"buzz companion"). The arm/disarm decision must be the *earliest requested epoch across all enabled
features*, re-evaluated on every change — never let one feature's disable clobber another's armed slot.
For the Flutter app today there is only the smart alarm, so this is just: enabled ⇒ arm to next
occurrence; disabled ⇒ disarm. Keep the reconcile shape so a future companion doesn't reintroduce the clobber.

---

## 6. Step-by-step implementation instructions

### 6.1 Transport — `WhoopBleClient` (`lib/core/ble/transport/whoop_ble_client.dart`)

The client currently has **no** alarm methods (grep: 0 hits for "alarm"). Add:

1. **`Future<void> setStrapAlarm(DateTime wakeLocal, {bool enabled = true})`**
   - If `!enabled` → `_send(CommandNumber.disableAlarm, payload: AlarmPayload.disableRev2(), withResponse: true)` and return.
   - Compute the next-occurrence epoch. Reuse `AlarmPayload.nextWakeEpochMs(hour, minute, DateTime.now().millisecondsSinceEpoch, zoneOffset: <device UTC offset>)` (`alarm_payload.dart:33`). Pass the device's current UTC offset (`DateTime.now().timeZoneOffset`) since Dart lacks IANA zones.
   - Build payload **per family**:
     - `if (_family == DeviceFamily.whoop5)` → `AlarmPayload.build(wakeEpochMs)` (20-byte rev4). **Gate behind the Experimental opt-in** (mirror `WhoopBleClient.kt:2306-2318`); if not opted in, log and skip arming (still allow disable).
     - `else` (whoop4) → the 9-byte form. Port `whoop4AlarmPayload(epochSec)` from `WhoopBleClient.kt:5165` into a small helper next to `AlarmPayload` (e.g. `AlarmPayload.buildWhoop4(epochSec)`), since the Dart `AlarmPayload` only ships the rev4/disable forms today.
   - `_send(CommandNumber.setAlarmTime, payload: payload, withResponse: true)`.
   - Then fire the readback: `_send(CommandNumber.getAlarmTime, payload: <family form>, withResponse: true)` — `[0x04,0x01]` for 5/MG, `[0x01]` for WHOOP4 (log-only).
   - **Ordering:** the strap RTC must be correct or the alarm fires at the wrong wall-clock time
     (`WhoopBleClient.kt:2300`). `_startSession` already sends `SET_CLOCK` early
     (`whoop_ble_client.dart:914`). Arm the alarm **after** clock-set in the bring-up sequence, or on demand
     once connected — never before the clock write in a fresh session.

2. **`Future<void> getStrapAlarm()`** — `_send(CommandNumber.getAlarmTime, payload: [0x04,0x01], withResponse: true)`.
   Decode in the inbound `COMMAND_RESPONSE` path defensively (port `whoop4ArmedAlarmEpoch` + the
   plausibility gate). Expose the decoded epoch (or null) via a callback/stream.

3. **Inbound routing** — in the frame handler, when a live `EVENT` has
   `event == 'STRAP_DRIVEN_ALARM_EXECUTED'` (57) and it is not a replayed offload, invoke an
   `onStrapAlarmFired` callback (mirror `WhoopBleClient.kt:732-739, 1085-1091`). Also surface the cmd-66
   `COMMAND_RESPONSE` `result` so the service can flip `queued → armed`.

### 6.2 Write-side — `AlarmService` (`lib/features/alarm/state/alarm.dart`)

Today it only persists to drift and reports `queued` (`alarm.dart:11-40`). Wire it to BLE:

1. Inject the `WhoopBleClient` (via provider) into `AlarmService`.
2. On the strap **connect / bond-confirmed** lifecycle event, call a `reconcileStrapAlarm()` that:
   - reads the persisted alarms, computes the earliest enabled next-occurrence epoch (single-slot rule, §5),
   - calls `client.setStrapAlarm(wake, enabled: true)` — or `setStrapAlarm(_, enabled: false)` if none enabled,
   - on the cmd-66 SUCCESS ack, update the row `status = 'armed'`; on send-without-connection keep `'queued'`.
3. On `onStrapAlarmFired` (event 57), set the fired alarm's `status = 'fired'` and re-arm the next
   occurrence (repeat alarms) — twin of the Kotlin `onSmartAlarmFired` daily re-arm.
4. Keep `alarmStatusLabel` (`alarm.dart:50-57`) honest: it already maps `armed / fired / queued` correctly;
   just make sure `'armed'` is only ever written after a real ACK, never optimistically.

### 6.3 Providers / UI

- Minimal. The alarms screen exists (`lib/features/alarm/presentation/alarms_screen.dart`) and reads
  `alarmsProvider`. No new screen needed.
- Add a provider that exposes the last strap-reported armed epoch (from `getStrapAlarm`) if you want a
  "confirmed on strap at HH:MM" line — optional, log-only quality.
- If shipping the 5/MG rev4 path, surface the Experimental gate the same way the deep-data/broadcast-HR
  opt-ins are surfaced, and show the "keep a backup alarm" caveat (`WhoopBleClient.kt:5162`).

---

## 7. Open questions / risks / on-device validation needed

1. **Does the 5/MG rev4 alarm actually wake a real strap?** UNCONFIRMED on our side — no captured
   `STRAP_DRIVEN_ALARM_EXECUTED (57)` from a 5/MG. The payload matches the official app and the RE capture
   app byte-for-byte, but "matches the bytes" ≠ "observed firing." Validate by arming a near-future alarm
   on a real MG with the phone in airplane mode and watching for event 57 on reconnect. **Gate behind the
   Experimental opt-in until then.**
2. **The 20-vs-21 byte question.** Official app `allocate(21)`, writes 20; RE app `allocate(20)` and it
   works. Ship 20. Only revisit (append one `0x00`) if a strap rejects the 20-byte frame — no evidence it will.
3. **GET_ALARM_TIME response offsets are undocumented.** We decode defensively and never gate on it. If a
   future capture reveals the true layout, tighten `whoop4ArmedAlarmEpoch`. Until then it is telemetry only.
4. **RTC dependency.** The alarm fires on the strap's own clock. If `SET_CLOCK` hasn't run (or the strap
   reports "RTC timestamp invalid" in its console logs), the wake time is wrong. Always arm after a
   successful clock set.
5. **WHOOP4 form is the confirmed-buzzing one** (9 bytes, #535). It is *not* the official app's current
   rev4 form — it is a shorter form we found buzzes real gen-4 firmware. Keep both; select by
   `connectedFamily`. Do not "unify" them onto rev4 without a gen-4 re-capture.
6. **4-byte alignment (5/MG only).** Puffin payloads must be 4-aligned or the strap answers "error = 4".
   `puffinCommandFrame` pads the inner record; the rev4 payload is already aligned. Any new 5/MG alarm
   payload must stay 4-aligned.

---

## 8. Citations (file:line)

- Official APK opcodes: `whoop/research/work/whoop_apk/base_full/smali_classes6/vp0/e.smali:741-779`
- SET builder: `.../smali_classes6/li0/p0.smali`, `.../smali_classes6/li0/p0$a.smali:46-118`
- Haptics serializer (12 bytes): `.../smali_classes6/li0/q0.smali`
- Byte order LE: `.../smali_classes6/vp0/d.smali:14`
- REVISION_4 = 0x04: `.../smali_classes6/vp0/h.smali:80-82`
- Default haptic pattern 47/152/7/30 + alarmId 1: `.../smali_classes6/pb1/g.smali:60-88`
- Time seconds/subseconds (0x8000): `.../smali_classes*/cb2/a.smali:344,415,436`
- DISABLE payload `[0x02,0xFF]`: `.../smali_classes*/li0/c$a.smali:80-105`
- GET builder rev1/rev4 guards: `.../smali_classes11/li0/i.smali:59-116`
- RE capture app reference impl: `whoop/apps/ble-sync/app/src/main/java/com/whoopcapture/WhoopProtocol.kt:255-290`
  and command table `whoop/apps/ble-sync/CLAUDE.md:88-98`
- Our Dart payload: `flutter_app/lib/core/ble/protocol/alarm_payload.dart:33-81`
- Our Dart enums: `flutter_app/lib/core/ble/protocol/enums.dart:69-135`
- Our framing (buildCommand / puffinCommandFrame / CR decode): `flutter_app/lib/core/ble/protocol/framing.dart:275,400,621,666`
- Command characteristics: `flutter_app/lib/core/ble/protocol/device_family.dart:43-81`
- Kotlin arm/disarm/readback + status routing: `android/app/src/main/java/com/noop/ble/WhoopBleClient.kt:1923,2298-2343,3373-3390,5165-5225`
- Kotlin tests pinning it: `android/app/src/test/java/com/noop/ble/Whoop4AlarmPayloadTest.kt`,
  `.../AlarmReadbackDecodeTest.kt`, `.../ui/StrapAlarmReconcileTest.kt`
- Current Flutter write-side (no BLE yet): `flutter_app/lib/features/alarm/state/alarm.dart`
