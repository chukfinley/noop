# WHOOP connect + bond + reconnect state machine

**Reverse-engineering spec + hardening plan for the Flutter transport.**

Scope: the FULL connect → bond → reconnect state machine of the WHOOP strap link — bonding, pairing
hints, bond-refusal recovery, keep-alive, MTU, timeouts, and every recovery transition. Goal: harden
`flutter_app`'s bonding **beyond** the Kotlin twin, not just re-match it.

Sources cross-checked:
- Decompiled official app smali: `/home/user/git/whoop/research/work/whoop_apk/base_full/smali_classes*/`
- Kotlin reference transport: `/home/user/git/noop/android/app/src/main/java/com/noop/ble/WhoopBleClient.kt` (3.3k lines) + the pure bond helpers.
- Our Dart port: `/home/user/git/noop/flutter_app/lib/core/ble/**`.

Honesty note up front: the low-level ordering (**MTU → discover → bond → subscribe → init**) is not
WHOOP application code — the official app delegates it to the **Nordic Android BLE library**. WHOOP's
own smali only carries the GATT *profile* (UUIDs) and the scan layer; the sequencing is Nordic's.
Everything protocol-specific (the confirmed-write "bond", the handshake command burst) lives in *our*
reverse-engineered Kotlin/Swift, which is the hardware-verified reference. Both facts are cited below.

---

## 1. Reverse-engineered facts (with evidence)

### 1.1 The official app uses the Nordic BLE library, not hand-rolled GATT

The strap link in the official app is driven by `no.nordicsemi.android.ble.BleManager` /
`BleManagerHandler`, plus the Nordic DFU library for firmware.

- `smali_classes7/no/nordicsemi/android/ble/BleManagerHandler.smali:562` →
  `invoke-virtual {v0, p1}, Landroid/bluetooth/BluetoothGatt;->requestMtu(I)Z` — the MTU request.
- `.../BleManagerHandler.smali:2663` → `invoke-virtual {p1}, Landroid/bluetooth/BluetoothDevice;->createBond()Z` — an **explicit** `createBond()`, and the log strings `"device.createBond()"` (:3182) and `"gatt.requestMtu("` (:3202) confirm both are live paths.
- Nordic DFU present: `smali_classes5/no/nordicsemi/android/dfu/SecureDfuImpl.smali` etc.

**Implication:** the official connect sequence is the standard Nordic `BleManager` flow — connect →
(optional) `requestConnectionPriority` → `requestMtu` → `discoverServices` → **initialize** callback
queue (which is where the encrypted reads/writes force the OS just-works bond) → device ready. WHOOP
requests a **larger MTU** and relies on `createBond()`; it does not do the Swift/Kotlin
"confirmed GET_BATTERY_LEVEL write" trick — that trick is *our* re-implementation of the just-works
bond because we hand-roll GATT. This validates two of our hardening moves below (request MTU; keep the
explicit `createBond()` the Dart port already uses).

### 1.2 The GATT profile: FIVE device families, not two

`smali_classes6/cq0/p.smali` is the WHOOP GATT profile constants class (obfuscated). It enumerates
**five** strap families, each with the identical characteristic layout `NNNN0002` (write/cmd),
`NNNN0003 / 0004 / 0005` (notify), `NNNN0007` (extra), under service `NNNN0001`:

| Family service UUID base                    | Our name           | Ported? |
|---------------------------------------------|--------------------|---------|
| `61080001-8d6d-82b8-614a-1c8cb0f8dcc6`      | WHOOP 4.0          | ✅ `whoop4` |
| `fd4b0001-cce1-4033-93ce-002d5875f58a`      | WHOOP 5.0 / MG     | ✅ `whoop5` |
| `11500001-6215-11ee-8c99-0242ac120002`      | (newer family)     | ❌ |
| `59830001-5955-419b-bb8d-c8262926af23`      | (newer family)     | ❌ |
| `8a580001-2fe8-4796-9267-b87a2b0c8234`      | (newer family)     | ❌ |

Evidence: `grep -oE '<uuid>' smali_classes6/cq0/p.smali` returns all five bases with the `0002..0007`
suffixes. Char roles per family: `0002` = command write, `0003/0004/0005` = the three notify channels
(cmd-response / events / fragmented data), `0007` = a fifth channel (memfault/DFU-adjacent; unused by
us). This matches the Kotlin `CMD_WRITE_CHAR … DATA_NOTIFY_CHAR` mapping (WhoopBleClient.kt:385-388).

**Implication:** the strap discovery + bring-up must key on the *family whose service is present*, not
a hardcoded pair. Our `DeviceFamily` enum only knows `whoop4`/`whoop5`
(`lib/core/ble/protocol/device_family.dart:19-24`). New straps (`1150/5983/8a58`) will scan-miss today.

### 1.3 The bond itself is OS just-works pairing; the app never sees a PIN

Both the official app (`createBond()`) and our reference reach a **just-works encrypted bond** — no
passkey, no numeric compare. On our hand-rolled side the bond is *provoked* by touching an encrypted
characteristic: WHOOP 4.0 sends a confirmed (`WRITE_TYPE_DEFAULT`, with-response) `GET_BATTERY_LEVEL`
frame to `61080002`; its `onCharacteristicWrite(GATT_SUCCESS)` **is** the proof of bond
(WhoopBleClient.kt:4006-4021, 3038-3047). WHOOP 5/MG provokes it with a confirmed `CLIENT_HELLO` write
to `fd4b0002` (:4031-4048, ack at :3007-3021). A **refused** bond surfaces as GATT status **5**
(`INSUFFICIENT_AUTHENTICATION`) or **15** (`INSUFFICIENT_ENCRYPTION`) on that write — meaning the strap
is still bonded to another central (the official app) or the phone holds a stale pairing
(WhoopBleClient.kt:530-531, 2979-3006).

`flutter_blue_plus` exposes `device.createBond()` / `device.bondState` on Android, so the Dart port
takes the *official-app* route (explicit `createBond`) rather than the write-trick — see §4.

---

## 2. The reference state machine (byte-precise, from the Kotlin twin)

This is the hardware-verified flow the Flutter app must equal or beat. Line numbers are
`WhoopBleClient.kt` unless noted.

### 2.1 Constants / opcodes / timeouts

| Name | Value | Source |
|------|-------|--------|
| WHOOP4 service / chars | `61080001` svc, `…0002` cmd-write, `…0003` cmd-notify, `…0004` event-notify, `…0005` data-notify | :384-388 |
| WHOOP5 service / chars | `fd4b0001` svc, `…0002` cmd-write, `…0003/4/5/7` notify | :390-401 |
| Standard HR profile | svc `0000180d`, char `00002a37` (works **unbonded**) | :404-405 |
| Standard battery profile | svc `0000180f`, char `00002a19` (plain %) | :406-407 |
| CCCD descriptor | `00002902`, value `ENABLE_NOTIFICATION_VALUE` | :411, :4124 |
| `GATT_MTU` | **247** (requested before discovery) | :506 |
| `MTU_FALLBACK_MS` | **1500** (discover anyway if `onMtuChanged` never lands) | :509 |
| `DUPLICATE_MTU_WINDOW_MS` | **1000** (OnePlus double-`onMtuChanged` dedup) | :524, 2881-2899 |
| `RSSI_READ_DELAY_MS` | **3000** (deferred so it can't starve the MTU op) | :636, 2855 |
| `SCAN_TIMEOUT_MS` | **20000** | :466, 1102-1108 |
| `BOND_WATCHDOG_MS` | **7000** base handshake window | :516 |
| `ONEPLUS_CCCD_SETTLE_MS` | **450** (settle before first CCCD write) | :521, 2965-2967 |
| Bond-refusal GATT codes | **5** / **15** | :530-531 |
| `GATT_CONN_TIMEOUT` | **0x08** (strap/link supervision timeout → #617 loop tell) | :535 |
| `GATT_CONN_TERMINATE_LOCAL_HOST` | **0x16 / 22** (our own `gatt.disconnect()`, incl. watchdog bounce) | :540 |
| `PIN_BOND_REFUSAL_LIMIT` | **3** (multi-WHOOP stale-pin re-adopt) | :572 |
| `BOND_REFUSAL_HINT_THRESHOLD` | **2** (surface pairing hint) | :577 |
| `KEEPALIVE_INTERVAL_MS` | **30000** keep-alive tick | :601-619 |
| `KEEPALIVE_QUIET_MS` | re-subscribe if quiet this long (one-shot per episode) | :612, 3670 |
| `KEEPALIVE_STALL_MS` | **120000** → bounce the link | :3644-3664 |
| `BOND_LOOP_SALVAGE_FLOOR_MS` | **600000** (10 min) between salvage probes | :450-463 |
| Bond command opcodes | `GET_BATTERY_LEVEL`=26, `TOGGLE_REALTIME_HR`=3, `SET_CLOCK`=10, `GET_CLOCK`=11, `REPORT_VERSION_INFO`=7, `GET_HELLO_HARVARD`=35, `GET_HELLO`=145, `SEND_R10_R11_REALTIME`=63, `GET_DATA_RANGE`=34 | `enums.dart:88-127` |

### 2.2 Happy-path connect sequence (Android)

```
connect(model)                                   :1502
  → startScan(model, allowFallback)              :1567  (filter by WHOOP4|WHOOP5 service UUID; 20s scanTimeout)
  → onScanResult: stopScan, connectToDevice(dev, autoConnect=false)   :2753
       reset(); lastDevice=dev; gatt = device.connectGatt(
             ctx, autoConnect, gattCallback, TRANSPORT_LE, PHY_LE_1M_MASK, handler)   :2779-2783
             // handler PINS every GATT callback to the main looper (API 28+) — critical:
             // without it discovery races the CCCD writes and the bond wins the single GATT
             // slot, so subscriptions silently drop (issue #12).  :2765-2778
  → onConnectionStateChange(STATE_CONNECTED)      :2799
       resetReconnectBackoff()                    :2806  (failedReconnectAttempts=0)
       connectGeneration++                        :2819
       postDelayed(readRemoteRssi, 3000ms)        :2855  (deferred, non-starving)
       requestMtu(247)                            :2864
         if accepted → postDelayed(kickServiceDiscovery,"mtu timeout", 1500ms)   :2867
         else        → kickServiceDiscovery immediately   :2871
  → onMtuChanged(mtu,status)                       :2881
       dedup spurious same-value callback <1000ms  :2888-2892  (OnePlus #50)
       kickServiceDiscovery("mtu=$mtu")            :2898   (idempotent via serviceDiscoveryKicked CAS :2740)
  → kickServiceDiscovery                           :2739
       armBondWatchdog()                           :2747   (postDelayed onBondWatchdog, currentWindowMs()=7s base)
       discoverServices()                          :2749
  → onServicesDiscovered                           :2908
       whoop4 present → connectedFamily=WHOOP4; cmdChar=…0002;
             queue CCCD subs [cmd-notify, event-notify, data-notify]   :2926-2930
       whoop5 present → connectedFamily=WHOOP5; cmdChar=fd4b0002; statusNote(experimental)   :2931-2942
       queue standard HR (0x2A37) + battery (0x2A19) CCCDs             :2951-2954
       drainCccdQueue()   (OnePlus: postDelayed 450ms first)           :2965-2969
  → drainCccdQueue (one CCCD at a time)            :4073
       setCharacteristicNotification(ch,true) + writeDescriptor(CCCD, ENABLE)   :4113-4127
       BUSY (false) → re-queue + retry ≤8× @60ms   :4128-4143
       queue empty → startSession(g)               :4104
  → startSession                                   :4058
       WHOOP4 → writeBondFrame(): confirmed GET_BATTERY_LEVEL write to …0002   :4067,4006
       WHOOP5 → writeClientHello(): confirmed CLIENT_HELLO write to fd4b0002   :4068,4031
  → onCharacteristicWrite(GATT_SUCCESS)            :2973
       == BOND PROVEN.  didBond=true; cancelBondWatchdog();               :3038-3047 / :3012-3021
       noteGenuineBond(); clearPairingHint(); state.bonded=encryptedBond=true;
       bondedAtMs=now (arms the #617 loop tell)
       runConnectHandshake() exactly once (WHOOP4)   :3053-3056, :3571
  → runConnectHandshake                            :3571
       send GET_HELLO_HARVARD; REPORT_VERSION_INFO|GET_HELLO;
       SET_CLOCK (both forms); GET_CLOCK (empty + [0x00] forms, fw #120);
       SEND_R10_R11_REALTIME[0]; GET_DATA_RANGE;
       backfillStarted=true; postDelayed(requestSync, INITIAL_BACKFILL_DELAY_MS);
       startBackfillTimer(); startKeepAlive();
       arm realtime HR if a screen/continuous-capture wants it   :3596-3607
```

### 2.3 Keep-alive (the "un-stick" loop) — :3614-3702

Every **30s** (`keepAliveFire`), only while `connected && bonded`, and **only when not backfilling**
(the offload has its own 60s idle watchdog and must not be bounced):

1. `silentMs = now - lastDataAtMs`. If `silentMs > 120000` (or `KEEPALIVE_STALL_5MG_EMPTY_MS` for a
   known-empty 5/MG) → **bounce**: `gatt.disconnect()` → `handleDisconnect` → auto-reconnect. This is
   the automatic version of the manual "disconnect/reconnect un-sticks frozen HR" fix (:3652-3664).
2. Else if `silentMs > KEEPALIVE_QUIET_MS` and not already re-subscribed this quiet episode →
   `enableLiveNotifications()` once (recovers a silently-dropped CCCD) (:3670-3673).
3. `reconcileRealtime()`; WHOOP4 only: re-arm `TOGGLE_REALTIME_HR[1]` and poll `GET_BATTERY_LEVEL`
   every other tick (~60s), which also keeps the link warm (:3687-3695).
4. Always re-arm the 30s cadence (:3701).

### 2.4 Failure + recovery transitions (the hard part)

There are **four** distinct pathological loops, each with its own detector, and they must not be
conflated — they key on different GATT status codes and timings:

| # | Failure | Tell | Detector | Threshold | Recovery |
|---|---------|------|----------|-----------|----------|
| #52 | Stale multi-WHOOP **pin**: pinned strap refuses bond but another bonds fine | write status 5/15 on the pinned MAC | `pinnedBondRefusals` | **3** | `readoptWorkingStrap`: clear pin, drop link, rescan → working strap connects (:2613-2652) |
| #78/#747/#750 | Strap **keeps refusing** the just-works bond (held by official app / stale phone pairing) | consecutive 5/15 refusals, 5/MG | `BondRefusalGiveUp` (giveUpThreshold **5**); pairing hint at **2** | 5 | **Pause auto-reconnect**, write PII-free **epitaph**, surface `pausedHint()` (bond_refusal_give_up) |
| #50/#971 | Bond handshake **never lands** inside the window (slow phone/strap) | `didBond` still false after escalating window; our `gatt.disconnect()` reports **0x16** | `BondWatchdogBackoff` (7→10→13→16s, cap 4) | 4 | Escalate window; on give-up pause + re-pair guide (bond_watchdog_backoff) |
| #617/#844 | Strap **bonds then drops ~1s later** with a real **0x08** timeout, forever | `wasBonded && timedOut(0x08) && msSinceBond ≤ 8000` | `PostBondTimeoutLoopDetector` | **2** | Surface re-pair guide + pause (:4700-4750) |
| #982 | Strap connects + subscribes but **never bonds**, self-drops (status 0) *before* the 7s watchdog | `wasConnected && !didBond && status≠0x16 && !paused` | folded into `BondWatchdogBackoff` streak | — | Same re-pair guide + pause (:4753-4785) |

Reconnect scheduling after an involuntary drop (`handleDisconnect`, :4700):

- **Paused for bond loop** → schedule **nothing**; wait for user Connect (:4815-4823).
- **Stale direct bond** (`bondedDirectAttempt && !didBond`) → drop `lastDevice`, rescan @3s; after
  **2** consecutive → surface the firmware-reset re-pair guide (:4847-4871).
- Known `lastDevice` and still preferred → **direct** `connectToDevice(dev, autoConnect=true)` after
  `ReconnectBackoff.nextDelayMs()` (3/6/12/24/48/60s) (:4873-4892).
- Else → **rescan** after the same backoff (:4893-4900).
- Every scheduled callback re-checks `!intentionalDisconnect && !autoReconnectPausedForBondLoop`
  before firing (#78 hole-3, :4869/4891/4898).

Salvage probe: while paused, a foregrounded app may fire **one bounded** reconnect attempt if
`≥ 600000ms` since the pause tripped (`shouldSalvageProbe`, :450-463) — so a strap the user has since
freed self-heals without a manual Connect.

Bluetooth-radio watch: `onBluetoothRadioOff/On` (:1667-1689) tears the orphaned GATT down the instant
the OS radio flips off (else the link lingers "connected" and the next write crashes on a dead binder,
#314). Owned by the foreground service's `ACTION_STATE_CHANGED` receiver
(`WhoopConnectionService.kt:129-176`).

---

## 3. What the Flutter port already has

`lib/core/ble/transport/whoop_ble_client.dart` (1735 lines) + the three pure bond helpers are a
faithful partial port:

- **Scan → connect → discover → bring-up**: `_startScan` / `_connectToDevice` / `_onConnected`
  (:859-965). Uses `flutter_blue_plus`: `device.connect(license: nonprofit, timeout: 35s)`,
  `device.discoverServices()`, `ch.setNotifyValue(true)`.
- **Explicit bond** via `_ensureBonded` → `device.bondState` + `device.createBond(timeout:)`
  (:986-1013) — the **official-app** route (§1.1), gated to Android.
- **Bond give-up + watchdog + loop detector**, all three pure helpers ported byte-for-byte:
  `bond/bond_refusal_give_up.dart`, `bond/bond_watchdog_backoff.dart`,
  `bond/post_bond_timeout_loop_detector.dart`. Wired: `_onBondFailed` feeds both give-ups (:1033-1045);
  `_onDisconnected` feeds `PostBondTimeoutLoopDetector.connectionEnded` (:1446-1452).
- **Pause + salvage-probe** latch: `_autoReconnectPausedForBondLoop`, `_bondLoopPausedAtMs`,
  `shouldSalvageProbe` (:697-723, 1051-1058).
- **Reconnect backoff**: `ReconnectBackoff.nextDelayMs` on involuntary drop; direct-reconnect to
  `_device` else rescan (:1454-1490).
- **Connect handshake**: `_runConnectHandshake` (:1110) sends SET_CLOCK/GET_CLOCK/R10-R11/GET_DATA_RANGE.
- Reusable framing already present: `Framing.buildCommand(cmd, payload:, seq:)` and
  `Framing.puffinCommandFrame(...)`; `_send(CommandNumber, payload:, withResponse:)` (:1522).

---

## 4. GAPS — what to build to beat the Kotlin twin

Ranked by link-reliability impact. Each is a concrete edit to
`lib/core/ble/transport/whoop_ble_client.dart` unless noted.

### GAP-1 (HIGH) — No MTU negotiation → offload capped at 20-byte notifications

The Kotlin twin and the official app both request a **large MTU before discovery**
(`GATT_MTU=247`, WhoopBleClient.kt:2864; Nordic `requestMtu`, BleManagerHandler.smali:562). The Dart
port never calls `requestMtu` — it rides the BLE default (23 → 20-byte ATT payload), so every
fragmented `DATA_NOTIFY` frame is chopped into ~20-byte pieces, inflating offload time and reassembly
load. **flutter_blue_plus** exposes `Future<int> device.requestMtu(int, {timeout})`.

Plan: in `_onConnected`, immediately after `_connected = true` and **before**
`device.discoverServices()`:
```dart
if (_blePlatform && Platform.isAndroid) {
  try {
    final granted = await device.requestMtu(247, timeout: 5); // GATT_MTU
    _log('MTU negotiated: $granted');
  } catch (e) {
    _log('requestMtu failed: $e — continuing at default MTU'); // non-fatal, mirror :2871
  }
}
```
No fallback timer is needed (flutter_blue_plus awaits the exchange); the `try` mirrors the Kotlin
"discover anyway if the stack ignores it" branch. iOS negotiates MTU automatically — gate to Android.
Constant: add `static const int gattMtu = 247;`.

### GAP-2 (HIGH) — No keep-alive → frozen HR never self-un-sticks

The single most user-visible reliability feature (Reddit "HR freezes, only reconnect fixes it") is the
30s keep-alive (§2.3). The Dart port has `_liveFlushTimer` and `_offloadKickTimer` but **no
keep-alive**. Add a `Timer.periodic(Duration(seconds:30))` started in `_runConnectHandshake` and
cancelled in `_onDisconnected` + `_cancelTimers`:

- Track `int _lastDataAtMs`; stamp it wherever an inbound frame/HR lands (`_onCustomFrameBytes`,
  `_onStandardHr`). Start it at `now` when the handshake runs (mirror :3618).
- Each tick, only if `_connected && _didBond && !_syncing`:
  - `silentMs > 120000` → **bounce**: `await device.disconnect()` (the existing `_onDisconnected` path
    reconnects). Add `static const int keepAliveStallMs = 120000;`.
  - else `silentMs > keepAliveQuietMs && !_resubscribedSinceData` → re-run the custom-notify subscribe
    once (recover a dropped CCCD); reset the flag on data.
  - WHOOP4: re-arm `_send(CommandNumber.toggleRealtimeHr, payload:[1])` when a screen wants realtime,
    and `_send(CommandNumber.getBatteryLevel)` every other tick.

Reuse: `_send`, `_subscribe`, the existing realtime-want predicate. This is a pure additive port of
`keepAliveFire`.

### GAP-3 (MED) — Loop detector can't tell timeout from local-terminate

Dart `_onDisconnected` calls `connectionEnded(timedOut: !_intentionalDisconnect)` (:1446-1452) — it
treats **every** involuntary drop as a timeout. The Kotlin twin keys #617 specifically on
`status == GATT_CONN_TIMEOUT (0x08)` and separates our-own-bounce `0x16` (:4723, :540). flutter_blue_plus
surfaces the reason via `device.disconnectReason` (a `DisconnectReason` with `.code`/`.description`
after a disconnect). Harden:

- Read `device.disconnectReason?.code` in `_onDisconnected`; map the Android HCI code **0x08** →
  `timedOut = true`, **0x16** and clean closes → `false`. This stops a benign late flap or our own
  keep-alive/bond bounce from being mis-counted as a #617 bond-loop.
- This also unlocks the **#982** never-bonded-self-drop path: if `wasConnected && !_didBond &&
  code != 0x16 && !paused`, feed `_bondWatchdog.recordBounce()` and, on give-up, `_enterBondLoopPause`.
  Port `shouldCountNeverBondedSelfDrop` (WhoopBleClient.kt:558-566) — it's a pure gate, add it to
  `bond/bond_watchdog_backoff.dart` or inline.

Caveat to validate on-device: confirm flutter_blue_plus reports the raw HCI status (some Android
versions/plugin builds normalise it). If the raw code is unavailable, fall back to the current coarse
behaviour but log the reason so we can calibrate — do **not** silently regress.

### GAP-4 (MED) — Only two device families known

`DeviceFamily` (`device_family.dart:19-24`) has `whoop4`/`whoop5` only; the profile has five
(§1.2). A `1150/5983/8a58` strap scan-misses entirely. Extend the enum with the three new bases and
their `0002/0003/0004/0005` chars, and drive scan + bring-up off the enum (the scan filter at
`whoop_ble_client.dart:569-570, 833-834` and `_fallbackFamily` already iterate families — add the new
ones to the filter list and the bring-up switch). Bond/handshake bytes for the new families are
**unverified** — treat them like the `whoop5` experimental path (CLIENT_HELLO-style confirmed write,
`statusNote` experimental) until captured on hardware. Mark clearly as speculative.

### GAP-5 (LOW) — createBond timeout vs the escalating window; scan timeout mismatch

- `_ensureBonded` passes `timeout: (windowMs/1000).ceil()` to `createBond` (:1006) — good, it already
  uses the escalating `BondWatchdogBackoff` window. But note `createBond()` throwing does **not**
  give us the 5/15 status, so `_onBondFailed` can't distinguish a refusal (→ #747 give-up, correct
  threshold 5) from a slow-but-healthy handshake (→ #971 watchdog). It currently feeds **both**
  (:1034-1035), which is defensible but conflates the counters. If flutter_blue_plus ever exposes the
  bond failure reason (`BluetoothBondState` transitions expose `BOND_NONE` with an
  `EXTRA_REASON` on Android), route refusals (`UNBOND_REASON_AUTH_FAILED/AUTH_REJECTED`) to the
  give-up and timeouts to the watchdog, matching the Kotlin split.
- Scan timeout is **15s** (`scanTimeout`, :226) vs the reference **20s** (:466). Bump to 20s for
  parity so a slow-advertising strap isn't abandoned early.

### GAP-6 (LOW) — Bond epitaph + connection history are log-only (not persisted)

The Kotlin epitaph and every reconnect transition are `log()`-only; the Dart port likewise `_log`s
them. For real on-device hardening we want a durable, PII-free trail. There is a **drift** DB
(`lib/core/data/db/database.dart`) with a `DeviceInfo` table (:239) and `SyncCursors` (:646) but **no**
connection/bond-event table. Add a small `BondEvents` table (columns: `deviceId TEXT`, `tsMs INT`,
`kind TEXT` [`bond`,`refusal`,`give_up`,`loop_trip`,`bounce`,`reconnect`], `opaqueId TEXT`,
`detail TEXT`) and write one row from `_enterBondLoopPause`, `_onGenuineBond`, and each reconnect
schedule. Use the existing `BondRefusalGiveUp.opaqueId(address)` (SHA-256 first-4-bytes, already ported
in `bond/bond_refusal_give_up.dart`) so no MAC ever hits disk. This gives the Devices screen a real
"why did it stop" history and a metric for tuning thresholds — strictly beyond the Kotlin twin.

---

## 5. Concrete implementation order

1. **GAP-1 MTU** — smallest, highest offload payoff; 8 lines in `_onConnected` + one const. Add a unit
   test that a stubbed `requestMtu` throw is swallowed and discovery still proceeds.
2. **GAP-2 keep-alive** — port `keepAliveFire`; add `_lastDataAtMs`, `_resubscribedSinceData`,
   `_keepAliveTimer`. Test: with a fake clock, `silentMs>120s` triggers exactly one `disconnect()`;
   `silentMs>quiet` triggers exactly one re-subscribe; ticks stop when `_syncing`.
3. **GAP-3 disconnect-reason mapping** — thread `device.disconnectReason?.code` into
   `_onDisconnected`; port `shouldCountNeverBondedSelfDrop`. Test the four-loop truth table
   (bond+0x08+≤8s → trips at 2; bond+late → clears; never-bonded self-drop → watchdog streak).
4. **GAP-5 scan-timeout 20s + bond-reason split** (if the plugin exposes `EXTRA_REASON`).
5. **GAP-4 device families** — enum + scan filter + bring-up switch; new families flagged experimental.
6. **GAP-6 BondEvents drift table** — schema bump + writes + Devices-screen read.

Reused ported pieces (do **not** re-implement): `Framing.buildCommand` / `Framing.puffinCommandFrame`
(`protocol/framing.dart`), `CommandNumber` (`protocol/enums.dart`), `DeviceFamily`
(`protocol/device_family.dart`), `ReconnectBackoff` (`sync/reconnect_backoff.dart`), the three bond
helpers (`bond/*.dart`), and the transport `WhoopBleClient` itself. Every new timeout goes in as a
named `static const` mirroring the Kotlin constant, so a future audit diffs cleanly.

---

## 6. Open questions (need hardware / capture to close)

1. **Does flutter_blue_plus surface the raw HCI disconnect status (0x08 vs 0x16) and the bond-failure
   `EXTRA_REASON`?** GAP-3/GAP-5 fidelity depends on it. Validate on a real Pixel + WHOOP 4.0 by
   forcing a stale-pairing drop and logging `device.disconnectReason`.
2. **MTU the official app actually requests.** We cited that it *requests* one (Nordic `requestMtu`,
   BleManagerHandler.smali:562) but the value is passed by WHOOP's Nordic subclass and wasn't resolved
   to a literal in smali (it's a parameter, not an inline const). 247 (our Kotlin value) is safe; if a
   capture shows 517/523 we can raise it. Not blocking.
3. **New families `1150/5983/8a58`** — bond provocation bytes and notify-channel semantics are
   unverified. Need a BLE sniff / strap capture before promoting them past experimental.
4. **`NNNN0007` characteristic role** — present in the profile for every family but unused by us
   (memfault/DFU-adjacent guess). Confirm before touching.
5. **Does the just-works bond survive a WHOOP firmware update?** The #78/#617 re-pair guides assume it
   often does **not** (the stale-OS-bond path). Worth an explicit test after the next OTA.

---

## 7. On-device validation notes

The project rule is **verify with `flutter test`, never launch the app** (`CLAUDE.md`). For BLE the
runtime surface can't be fully unit-tested, so:

- **Unit tests (the gate):** every pure gap gets a fake-clock / stub-GATT test in
  `test/` alongside the existing bond-helper tests. The state machine is already structured for this —
  the bond helpers are pure, and `_onConnected`/`_onDisconnected` take injectable inputs. Prove: MTU
  throw is swallowed; keep-alive bounce/re-subscribe edges; the four-loop truth table; reconnect
  backoff sequence (3/6/12/24/48/60); pause + salvage-probe floor.
- **Manual hardware matrix (user-run, documented here for when he does):** (a) fresh never-paired
  WHOOP 4.0 → first bond within 7s; (b) strap held by official app → 5/15 refusal → pairing hint at 2,
  pause + epitaph at 5; (c) stale OS pairing after firmware update → #617 or #982 loop → re-pair guide,
  no battery-draining hammer; (d) walk out of range → backoff caps at 60s, reconnects on return; (e)
  frozen-HR test → keep-alive bounces after 120s of silence and HR resumes without a manual reconnect;
  (f) toggle phone Bluetooth mid-session → no crash, link resumes on radio-on.
- Log every transition through the existing `ConnLogEntry`/`_log` seam (`whoop_ble_client.dart:163`)
  and, once GAP-6 lands, the `BondEvents` table — that log **is** the on-device validation artifact,
  since we can't screenshot the GUI under the project rule.
