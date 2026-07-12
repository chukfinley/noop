# BLE OTA Firmware Update — Reverse-Engineering Spec & Implementation Plan

**Slug:** `firmware-update-ota`
**Status:** Recon complete. Protocol is well-understood and byte-precise for the WHOOP 5.0 /
Maverick (GOOSE) path. **Verdict: buildable, but deliberately gated OFF** — see §9. This document is
the byte-level blueprint plus a concrete Flutter plan for a future implementer, and an honest
risk/why-not-yet section.

**Scope of "OTA":** two distinct things live under one word and must not be conflated:
1. **Download** — an HTTPS/JSON call to WHOOP's cloud that returns the firmware image inline
   (Base64 ZIP). This is 100% **server-side**; nothing on the strap is involved. (§2)
2. **Flash** — pushing that image to the strap over BLE GATT. Two different on-strap protocols
   depending on hardware: **Ambiq-native AA01 command OTA** for the Maverick main MCU (§4–§6), and
   **Nordic DFU** for the Puffin / gen-4 Nordic co-processor (§7).

---

## 0. Evidence index (what backs every claim here)

| Source | Path |
|---|---|
| Firmware update doc (app-side, HTTP + Nordic DFU) | `/home/user/git/whoop/firmware/FIRMWARE_UPDATE_DOCUMENTATION.md` |
| Maverick AA01 OTA doc (byte-level BLE) | `/home/user/git/whoop/firmware/SAFE_FIRMWARE_UPDATE_GUIDE.md` (the "Custom Firmware Update Protocol Guide") |
| Maverick firmware RE report (.zbin, strings, CRC) | `/home/user/git/whoop/firmware/MAVERICK_FIRMWARE_REVERSE_ENGINEERING.md` |
| Stock Maverick image | `/home/user/git/whoop/firmware/maverick_ambiq_50.35.2.0.zip` → `maverick-50.35.2.0.zbin` |
| Stock Puffin image | `/home/user/git/whoop/firmware/puffin_3.30.5.0.zip` → `usb_update_puffin_3.30.5.0_5ce45820.bin` |
| **App command enum (authoritative on-wire opcodes)** | `research/work/whoop_apk/base_full/smali_classes6/vp0/e.smali` |
| OTA Retrofit API (endpoints) | `…/base_full/smali_classes6/com/whoop/firmwareUpdateService/data/api/OtaFirmwareUpdateApi.smali` |
| Download response model (`firmware_zip_file`) | `…/smali_classes12/com/whoop/firmwareUpdateService/data/models/DesiredDeviceFirmwareUpdate.smali` |
| Nordic DFU service (Puffin path) | `…/smali_classes12/com/whoop/firmwareUpdateService/strategy/NewDfuService.smali` |
| Update workers | `…/smali_classes6/com/whoop/firmwareUpdateService/workmanager/{PeriodicFwUpdateCheckWorker,FirmwareUpdateWorker}.smali` |

**Already-ported Dart we reuse (do not re-implement):**
- `lib/core/ble/protocol/framing.dart` — `Framing.puffinCommandFrame(...)` builds the exact AA01
  (CRC16-header + pad4 + CRC32-trailer) frame the Maverick OTA needs. `Framing.buildCommand(...)` is
  the WHOOP-4.0 CRC8 variant.
- `lib/core/ble/protocol/enums.dart` — `CommandNumber` (OTA opcodes are **deliberately absent**; see
  the enum's own doc-comment: "Destructive commands (reboot / firmware load / …) are deliberately
  excluded so the in-app sender can never brick or wipe the device.").
- `lib/core/ble/protocol/crc.dart` — `Crc.crc32`, `Crc.crc16Modbus`, `Crc.crc8` (all the checks the
  `.zbin` and the frames use).
- `lib/core/ble/protocol/device_family.dart` — Maverick GATT UUIDs (§3).
- `lib/core/ble/transport/whoop_ble_client.dart` — `WhoopBleClient`: connection, bonding, MTU,
  `_cmdChar`, `_send()`, `_subscribe()`, notify routing.
- `lib/core/data/db/database.dart` — `DeviceInfo` table already has `fwVersion`, `dspVersion`,
  `hwVersion`, `serial`, `mac`, `model`.

---

## 1. Architecture overview

```
┌──────────────┐   HTTPS/JSON (Bearer)   ┌───────────────────────────────┐
│  noop app    │ ──────────────────────► │ api.prod.whoop.com            │
│  (Flutter)   │ ◄────────────────────── │ firmware-service/v4  (§2)      │
└──────┬───────┘   Base64 ZIP inline     └───────────────────────────────┘
       │
       │  unzip → .zbin (Ambiq) and/or .bin (Nordic)
       │
       ├── AA01 command OTA over BLE GATT  ───►  Maverick main MCU  (§4–§6)   ← our focus
       └── Nordic DFU (svc 0xFE59)         ───►  Puffin / Nordic coproc (§7)
```

Key insight (`FIRMWARE_UPDATE_DOCUMENTATION.md` §1, confirmed by
`DesiredDeviceFirmwareUpdate.smali:92,199`): the image is **not** on a CDN. The cloud returns it
inline as Base64 ZIP in the JSON field `firmware_zip_file`.

---

## 2. Cloud download (server-side — NOT on the strap)

Retrofit interface `OtaFirmwareUpdateApi.smali` — annotation values extracted verbatim:
- `firmware-service/v4/firmware/check` (OtaFirmwareUpdateApi.smali:99) — POST, `@Query("deviceName")`
- `firmware-service/v4/firmware/version` (line 69) — POST, download
- `firmware-service/v4/firmware/result` (line 134) — POST, report success/fail

Base URL `https://api.prod.whoop.com`. All three need `Authorization: Bearer {token}` plus
`x-whoop-app-version` / `x-whoop-device-platform` headers.

### 2.1 Check
```
POST /firmware-service/v4/firmware/check?deviceName=GOOSE
Body:  [ {"chip_name":"AMBIQ","version":"50.34.0.0"} ]
→ 200 { "hardware_device":"MAVERICK",
        "chip_firmwares":[{"chip_name":"AMBIQ","version":"50.35.2.0"}],
        "force_update":false, "force_update_reprompt_cadence":null }
```

### 2.2 Download
```
POST /firmware-service/v4/firmware/version?deviceName=GOOSE
Body:  { "current_chip_firmwares":[{"chip_name":"AMBIQ","version":"1.0.0"}],
         "chip_firmwares_of_upgrade":[{"chip_name":"AMBIQ","version":"50.35.2.0"}] }
→ 200 { "desired_device_firmware_config":{…}, "firmware_zip_file":"UEsDBBQ…"(base64 ZIP) }
```
`base64decode(firmware_zip_file)` → ZIP → contains `maverick-50.35.2.0.zbin` (and/or a Nordic
`.bin`). The ZIP may bundle images for **both** chips of a device.

### 2.3 Report result
```
POST /firmware-service/v4/firmware/result?deviceName=GOOSE
Body:  { "chip_firmware":[{"chip_name":"AMBIQ","version":"50.35.2.0"}], "successful":true }
```

### 2.4 Device-name / chip matrix (`FIRMWARE_UPDATE_DOCUMENTATION.md` §3)

| API `deviceName` | Hardware | Chips | Notes |
|---|---|---|---|
| `GOOSE` | MAVERICK (WHOOP 5.0) | `AMBIQ` | Our target. `MAVERICK` name 404s on v4 — use `GOOSE`. |
| `HARVARD` | Gen 4 | `MAXIM`, `NORDIC` | 404 unless account has a gen-4 device registered. |
| `PUFFIN` | Puffin accessory | `NORDIC` | Standalone. |

**Server always returns the newest version** for a device type regardless of the `current` version
you report — there is no way to request a specific/older build through this API (doc §4.3).

---

## 3. Maverick BLE connection (all reused from `device_family.dart`)

`DeviceFamily.whoop5` already carries these UUIDs (`device_family.dart:47,63-69,79`):

| Role | UUID | In our code |
|---|---|---|
| Primary service | `fd4b0001-cce1-4033-93ce-002d5875f58a` | `whoop5.serviceUuidString` |
| **CMD_TO** (write — App→Strap) | `fd4b0002-…` | `whoop5.commandCharacteristicUuidString` → `_cmdChar` |
| **CMD_FROM** (notify — Strap→App) | `fd4b0003-…` | in `_notifyUuids(whoop5)` |
| (other notify: 0004/0005/0007) | `fd4b0004/5/7-…` | subscribed at bring-up |

Connection is already handled by `WhoopBleClient._onConnected → _bringUpWhoop5`: discover service,
bond (just-works), `setNotifyValue(true)` on the notify chars, write `DeviceFamily.whoop5.clientHello`.
OTA needs one extra thing the normal path doesn't: **an MTU bump** so chunks are large (see §5.3).
`flutter_blue_plus` exposes `device.requestMtu(517)` — call it after connect, before OTA.

---

## 4. Maverick OTA command opcodes — AUTHORITATIVE (app-side enum)

The on-wire command byte for each OTA step is the **third `int` arg** of the `vp0/e` enum
constructor `<init>(String name, int ordinal, int value)`, where `value` is the wire opcode read back
by the getter at `vp0/e.smali:1312` (`iget v0, p0, Lvp0/e;->value:I`). Verified against known
commands: `TOGGLE_REALTIME_HR`→`0x3`, `SET_CLOCK`→`0xa`, `GET_CLOCK`→`0xb`, `GET_HELLO`→`0x91`
(all match our ported `CommandNumber`).

| Enum constant | Wire opcode | smali evidence (`vp0/e.smali`) |
|---|---|---|
| `START_FIRMWARE_LOAD` (gen-4/Harvard) | **0x24** (36) | line ~559–565 |
| `LOAD_FIRMWARE_DATA` (gen-4) | **0x25** (37) | ~569–575 |
| `PROCESS_FIRMWARE_IMAGE` (gen-4) | **0x26** (38) | ~577–586 |
| **`START_FIRMWARE_LOAD_NEW`** (Maverick) | **0x8E** (142) | ~591–597 |
| **`LOAD_FIRMWARE_DATA_NEW`** (Maverick) | **0x8F** (143) | ~600–605 |
| **`PROCESS_FIRMWARE_IMAGE_NEW`** (Maverick) | **0x90** (144) | ~607–616 |
| **`VERIFY_FIRMWARE_IMAGE`** (Maverick) | **0x53** (83) | ~618–625 |
| `ENTER_BLE_DFU` (triggers Nordic path) | **0x2d** (45) | ~701–705 |
| `REBOOT_STRAP` | **0x1d** (29) | ~489–496 |

### ⚠️ Correction to the firmware docs
`MAVERICK_FIRMWARE_REVERSE_ENGINEERING.md` §11.5 and `SAFE_FIRMWARE_UPDATE_GUIDE.md` §4.1 tabulate
the Maverick OTA "external AA01" codes as **0x50/0x51/0x52/0x53**. The **app** — i.e. the code that
actually puts bytes on the wire — uses **0x8E/0x8F/0x90** for START/LOAD/PROCESS and **0x53** for
VERIFY (`vp0/e.smali`, table above). The firmware's own dispatch strings agree with the app:
`"Command Start Firmware Load (0x8E)"`, `"Command Process FW Image (0x90)"`
(`MAVERICK_FIRMWARE_REVERSE_ENGINEERING.md` §11.5). Treat **0x8E/0x8F/0x90/0x53** as the on-wire
truth; the 0x50–0x52 column appears to be an analysis artifact and must not be shipped. (Only VERIFY
= 0x53 is common to both tables.)

The `_NEW` suffix = the Maverick/GOOSE path (CRC16 "puffin" framing); the un-suffixed 0x24–0x26 are
the legacy gen-4 path. The two are selected by device family, not a runtime toggle.

---

## 5. AA01 frame + LOAD chunk layout

### 5.1 Envelope (already built by `Framing.puffinCommandFrame`)
The Maverick uses the WHOOP-5 "puffin" envelope. `puffinCommandFrame` (`framing.dart:666`) produces
exactly this, including the **pad4** alignment the OTA requires:

```
[0]      0xAA (SOF)
[1]      0x01 (format/rev)
[2..3]   declLen u16 LE   = inner.length + 4   (inner already pad-4-aligned)
[4..5]   routing header   = 0x00 0x01  (App→Strap; puffinCommandFrame default)
[6..7]   CRC16-Modbus LE  over bytes [0..6)
[8]      type = 0x23 (35, COMMAND)
[9]      seq  (0..0xFF, incrementing)
[10]     cmd  (0x8E / 0x8F / 0x90 / 0x53)
[11..]   params  (pad4 with 0x00 — puffinCommandFrame does this automatically)
[tail]   CRC32 LE over inner bytes [8 .. end-4)
```

So a call is simply:
```dart
Framing.puffinCommandFrame(cmd: 0x8F, seq: seq, payload: params);
```
`puffinCommandFrame` handles `declLen`, both CRCs, and the pad4 — the same machinery already proven
on the 12-byte MG haptics payload (see its doc-comment re: issue #48). **Do not hand-roll AA01.**

### 5.2 Command params

| Step | cmd | params (before pad4) |
|---|---|---|
| **START** (`0x8E`) | 0x8E | `u32 LE fileSize` — total `.zbin` byte count. Erases/preps external NOR. |
| **LOAD** (`0x8F`) | 0x8F | `u32 LE offset` ++ `chunkBytes` — write chunk at `offset`. |
| **PROCESS** (`0x90`) | 0x90 | `0x00` (1 byte → pad4). Triggers whole-image CRC32 over NOR. |
| **VERIFY** (`0x53`) | 0x53 | `0x00` (1 byte → pad4). Chunk-by-chunk readback verify. |

(Source: `SAFE_FIRMWARE_UPDATE_GUIDE.md` §4.2–§4.5; opcodes corrected per §4 above.)

### 5.3 Chunking
- The `.zbin` is streamed head-to-tail. Each LOAD carries `[offset u32][data]`; the strap writes it
  to **external NOR flash**, reads it back, and byte-compares (failure logged
  `"Update Flash: Memory compare failed at addr 0x%x"`,
  `MAVERICK_FIRMWARE_REVERSE_ENGINEERING.md` §11.4).
- **Chunk size:** conservative 512 B works. With MTU 517 the ATT payload is ~512 B, so a chunk of
  `512 - 4(offset) - 3(type/seq/cmd) - 8(hdr) - 4(crc32) ≈ 490 B` data fits one write. The doc's
  Kotlin sample uses a flat 512-B *data* chunk with PRN-style ack-per-chunk; keep it simple and
  **ack every chunk** (await the CMD_FROM response before the next LOAD). Only optimize to larger
  data chunks once MTU 517 is confirmed negotiated on-device.
- Image size ≈ 1.06 MB → ~2,100 chunks at 512 B. At ack-per-chunk this is minutes, not seconds;
  surface a progress bar.

### 5.4 Response frames (CMD_FROM notify)
Responses arrive on `fd4b0003` as AA01 frames with **type = 0x24 (COMMAND_RESPONSE)** and the same
`cmd` echoed. Decode with the existing `Framing.parseFrame(frame, DeviceFamily.whoop5)` → the parser
labels COMMAND_RESPONSE result codes (`framing.dart` `_commandResultLabel`): `1=SUCCESS`, `0=FAILURE`,
`2=PENDING`, `3=UNSUPPORTED`. **Status non-zero on PROCESS/VERIFY ⇒ do NOT let the strap reboot** —
re-transfer from START (NOR is overwritten, MCU untouched). (`SAFE_FIRMWARE_UPDATE_GUIDE.md` §6, §7.2.)

---

## 6. `.zbin` image format & the three integrity checks

512-byte Ambiq secure-OTA header + gzip-compressed ARM Cortex-M4F binary
(`MAVERICK_FIRMWARE_REVERSE_ENGINEERING.md` §1, cross-checked against the stock v50.35.2.0 file):

```
Offset  Size  Field                         v50.35.2.0
0x000   4     Payload CRC32 (of gzip body)  0xA4B443FC
0x004   4     Compressed payload size       0x00102C80 (1,059,968)
0x008   4     Compression algo              0x00000005
0x00C   4     Encryption algo (0x5 = none)  0x00000005
0x010   4     Image type (0x0D = main app)  0x0000000D
0x07C   4     Version major                 50
0x080   4     Version minor                 35
0x084   4     Version patch                 2
0x114   4     Total image size (hdr+payload) 0x00102E80
0x11C   4     Header size                    0x00000200 (512)
0x1F8   4     Header CRC32 (of 0x008..0x1F8) 0xBE9A3236
0x1FC   4     Payload CRC32 copy             0xA4B443FC
0x200+  N     gzip( ARM binary )
```

Three checks the strap enforces (all CRC32, hardware MSPI-DMA; **no signature** —
`MAVERICK_FIRMWARE_REVERSE_ENGINEERING.md` §11.4 found zero RSA/ECDSA/AES/SHA refs):
1. `CRC32(zbin[0x200:]) == zbin[0x000] == zbin[0x1FC]`
2. `CRC32(zbin[0x008:0x1F8]) == zbin[0x1F8]`
3. `zbin[0x004] + zbin[0x11C] == zbin[0x114] == len(zbin)`

For a straight OEM update we ship the `.zbin` **verbatim** — no rebuild, no re-CRC needed. The client
should still *verify* these three before flashing (a corrupt download must never reach the strap).
`Crc.crc32` already computes the exact polynomial (zlib).

---

## 7. The other path: Nordic DFU (Puffin / gen-4 Nordic) — not our target

For `PUFFIN` and the gen-4 Nordic co-processor the app uses the standard **Nordic Semiconductor DFU**
library (`NewDfuService.smali`, `DfuServiceInitiator`), *not* AA01. Config (doc §5.1, §8): buttonless
entry → device re-advertises under DFU service **0xFE59** → init packet → MTU-517 chunks with packet-
receipt-notifications every 12 → CRC/validate → activate. There is **no Flutter Nordic-DFU BLE-DFU
equivalent we already own**; it would be a separate, sizable dependency
(`no.nordicsemi` is Android/iOS-native). Out of scope for the Maverick-first plan.

---

## 8. Implementation plan for the Flutter app

Concrete, file-by-file. Keep everything behind an opt-in flag (§9) and Maverick-only.

### 8.1 New: `lib/core/ble/ota/firmware_download.dart` (cloud, no BLE)
- `FirmwareDownloadClient` with `check()`, `download()`, `reportResult()` mirroring §2. Use the
  existing HTTP stack / auth token the app already holds for WHOOP sync. Returns the decoded ZIP
  bytes; unzip in memory; expose the inner `.zbin` bytes + parsed version.
- Add a small `ZbinImage` value type: parse the §6 header, expose `version`, `imageType`,
  `payloadCrc32`, and a `validate()` that runs the three CRC/size checks using `Crc.crc32`.
- **Do not persist the token or image to shared storage**; keep the `.zbin` in app-private cache
  (`getApplicationSupportDirectory`), namespaced by strap serial, exactly like the official
  `filesDir/whoop_firmware/{serial}/` layout.

### 8.2 New: `lib/core/ble/ota/maverick_ota.dart` (the flasher)
Port of `SAFE_FIRMWARE_UPDATE_GUIDE.md` §6 `MaverickOtaUpdater`, but built on our transport:
```dart
enum OtaStep { start, load, process, verify, rebooting, done, failed }

class MaverickOta {
  MaverickOta(this._client);            // WhoopBleClient (already connected+bonded, MTU bumped)
  Stream<OtaProgress> update(Uint8List zbin);   // emits step + 0..1 fraction
}
```
- Sequence: `START(0x8E, u32 size)` → loop `LOAD(0x8F, u32 offset ++ chunk)` acked per chunk →
  `PROCESS(0x90, [0])` (await up to 30 s) → `VERIFY(0x53, [0])` (await up to 30 s) → watch for BLE
  disconnect = reboot = success.
- Build every frame with `Framing.puffinCommandFrame(cmd:…, seq:…, payload:…)`. Increment `seq`
  through the client's existing counter.
- Decode each response with `Framing.parseFrame(resp, DeviceFamily.whoop5)`; treat result `!= 1`
  (SUCCESS) as fatal at PROCESS/VERIFY and **abort before any reboot**.

### 8.3 Touch: `lib/core/ble/transport/whoop_ble_client.dart`
The private `_send(CommandNumber, …)` only accepts curated `CommandNumber`s and doesn't return the
response. Add a **request/response seam** for OTA without widening the public safe-command surface:
- Add `Future<Uint8List> sendRawAwait(Uint8List frame, {Duration timeout})` that writes to `_cmdChar`
  and completes with the next CMD_FROM frame (a `Completer` set in the notify handler). This mirrors
  the doc's `responseChannel`.
- Expose `requestMtu(int)` passthrough and a `disconnected` future/stream (already have
  `connectionState`) so the flasher can detect the reboot.
- Keep `MaverickOta` in the `ota/` folder, not in the client, so the transport stays generic.

### 8.4 Touch: `lib/core/ble/protocol/enums.dart` — DO NOT add OTA codes to `CommandNumber`
The enum's contract explicitly excludes firmware-load/reboot so the generic sender can't brick the
strap. **Honor that.** OTA opcodes live as private constants inside `maverick_ota.dart`:
```dart
const _kStartFwLoad = 0x8E, _kLoadFwData = 0x8F, _kProcessFwImage = 0x90, _kVerifyFwImage = 0x53;
```
and go out via `puffinCommandFrame(cmd: …)` (which takes a raw `int`, not a `CommandNumber`) — so the
safe-sender invariant is preserved.

### 8.5 Touch: `lib/core/data/db/database.dart` — record state, bump `schemaVersion`
`DeviceInfo` already has `fwVersion`/`dspVersion`. Add an **`OtaHistory`** table (id, strapId,
chipName, fromVersion, toVersion, startedTs, finishedTs, result, error) for audit/resume, then bump
`schemaVersion 3 → 4` and add the `onUpgrade` branch (migration block already at
`database.dart:706`). Update `DeviceInfo.fwVersion` on confirmed success.

### 8.6 New UI (optional, later): `lib/features/settings/presentation/firmware_update_screen.dart`
"Check for update" → show current vs available → explicit, scary-worded confirm → progress
(step + %) → success/fail. Reuse `ScreenScaffold`, `NoopCard`, `NoopBackButton`. Battery gate
(≥50%) before enabling the button, per §9.

---

## 9. Verdict & why it's gated OFF by default

**It is buildable.** The protocol is fully understood, the framing is already ported, and the image
needs no signing (CRC32-only). But shipping an *enabled* firmware flasher in an open-source companion
app is a **business/liability risk, not a technical blocker**:

- **Brick risk is real at exactly one moment.** Everything up to and including VERIFY is safe — the
  image stages on external NOR and the MCU's MRAM is untouched, so any failure just means "retry from
  START" (`SAFE_FIRMWARE_UPDATE_GUIDE.md` §7.2). The unknown is the **SBL in ROM**: it *may* enforce
  checks (image_type, auth fields, anti-rollback) that the application firmware can't reveal
  (`…RE.md` §11.4, §7.4). A rejected image at boot is **untested** and could need JTAG/SWD to recover.
- **No signature ≠ no gatekeeper.** The absence of crypto in the *app* firmware doesn't prove the SBL
  won't reject a modified image. Flashing **stock OEM `.zbin` only** is the sane default; custom
  images are research-only, physical-access-required.
- **The download path binds to a WHOOP account/token** and only ever yields the newest official
  build. That's fine for legit updates, pointless for anything else.

**Recommendation:** implement §8.1 (download + `.zbin` validate) and §8.2/§8.3 (flasher) behind a
**default-off developer flag**, Maverick-only, **stock-image-only**, with a ≥50% battery gate and an
explicit "this can brick your strap" confirm. Do not surface it in the normal settings flow until it
has been validated end-to-end on a sacrificial strap (§10). Until then this doc is the spec and the
code stays dark.

---

## 10. On-device validation notes (before any user ever sees it)

1. **Read-only first.** Confirm we can read the running version via `GET_HELLO` (0x91, already in
   `CommandNumber.getHello`) and store it in `DeviceInfo.fwVersion`. No writes.
2. **Dry-run the download.** Exercise §2 end-to-end, unzip, run the three §6 CRC/size checks against
   the bundled stock `maverick-50.35.2.0.zbin`. Assert our `Crc.crc32` reproduces `0xA4B443FC` (payload)
   and `0xBE9A3236` (header). This needs **no strap** and belongs in `flutter test`.
3. **Frame golden-tests.** Assert `puffinCommandFrame(cmd:0x8E, seq:0, payload:<u32 size>)` produces a
   frame that round-trips through `parseFrame(…, whoop5)` with `crcOk == true` and the right
   `cmd`/`type`. Same for a representative LOAD chunk (verify pad4 on a non-4-aligned chunk length).
4. **Sacrificial strap only.** First real flash re-flashes the **same stock version** (idempotent,
   lowest risk). Charge ≥50%. Keep the stock `.zbin` for recovery. Watch for the post-VERIFY
   disconnect; re-read `GET_HELLO` after reconnect to confirm the version.
5. **Abort testing.** Kill the transfer mid-LOAD and confirm the strap still boots the old image
   (proves the NOR-staging safety net) before trusting the happy path.
6. **Never** wire OTA into CI against real hardware; the tests above (2,3) are the automatable gate,
   consistent with this repo's "verify with `flutter test`, never launch the app" rule.

---

## 11. Quick reference

| Item | Value |
|---|---|
| Download | `POST firmware-service/v4/firmware/version?deviceName=GOOSE` → Base64 ZIP in `firmware_zip_file` |
| Image | `.zbin` = 512-B Ambiq header + gzip ARM binary; CRC32-only integrity (×3) |
| BLE svc / write / notify | `fd4b0001…` / `fd4b0002…` (CMD_TO) / `fd4b0003…` (CMD_FROM) |
| Framing | AA01 puffin envelope via `Framing.puffinCommandFrame` (CRC16 hdr + pad4 + CRC32 tail) |
| Opcodes (on-wire, app-authoritative) | START `0x8E` → LOAD `0x8F` (chunks) → PROCESS `0x90` → VERIFY `0x53` → auto-reboot |
| Response | CMD_FROM AA01 type `0x24`; result `1`=SUCCESS via `parseFrame` |
| Safe-abort window | any time before the post-VERIFY reboot (image on NOR, MRAM untouched) |
| Main unknown | SBL-in-ROM boot checks (untested) → keep to stock images |
| Ship state | **default OFF**, Maverick-only, stock-only, battery-gated (§9) |
