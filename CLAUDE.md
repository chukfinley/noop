# noop — project notes

## Companion reverse-engineering repo (BLE sync ground-truth)

**`/home/user/git/whoop`** is the sibling WHOOP reverse-engineering repo. It is the
**ground-truth source for this app's Flutter BLE sync** (`flutter_app/lib/core/ble`).
When working on WHOOP BLE — sync, framing, opcodes, sensor decode, battery, live
metrics — match the official app's behaviour as documented there:

- **Official WHOOP app, decompiled smali**: `research/work/whoop_apk/base_src/smali_classes*/`
  - Official sync packages: `com/whoop/straphistorysync/sync/`, `com/whoop/puffin/sync/`
- **Working RE'd Kotlin BLE client**: `apps/ble-sync/app/src/main/java/com/whoopcapture/`
  (`WhoopProtocol.kt`, `WhoopDataDecoder.kt`, `AutoSyncWorker.kt`)
- **Protocol doc**: `apps/ble-sync/CLAUDE.md` (AA01 framing, 40+ commands, CRC)

Legal basis for the RE: EU Directive 2009/24/EC Art. 6 / German UrhG §69e (interoperability).

The whoop repo's own top-level CLAUDE.md marks *its app/algorithm work* as parked —
that does not apply here; we mine it as the BLE reference for noop.
