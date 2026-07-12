# Raw data storage & re-analysis

Audit of the on-device WHOOP data path: is **every decoded sensor value persisted
durably and immutably** so a future algorithm update can re-derive all scores from
complete raw data?

Scope: the BLE decode → persistence path
(`lib/core/ble/protocol/*`, `lib/core/ble/sync/*`, `lib/core/data/db/database.dart`).
Verified against the Kotlin reference schema
(`android/app/src/main/java/com/noop/data/Entities.kt`).

---

## The principle (what we are trying to guarantee)

Raw sensor rows are the **durable source of truth**. Scores (Charge, HRV, sleep
stages, …) are *derivations* — they can and will change when the algorithm improves.
So the raw layer must be:

- **Lossless** — every decoded field lands in a column, even fields the current
  pipeline ignores. If a value was worth decoding, it is worth keeping.
- **Immutable / append-only** — a raw row is written once and never updated,
  trimmed, or deleted. Re-syncing the same second is a no-op, never an overwrite.
- **Independent of analysis** — data is kept whether or not anything reads it today.
  A future engine re-runs over the stored raw rows, not over a bundled demo asset.

Why it matters in money terms: the strap **destroys its own flash copy** once we ack a
chunk (safe-trim). After that ack, the phone's SQLite file is the **only** copy. Anything
decoded-but-dropped, or acked-but-not-stored, is gone for good — you cannot re-derive a
better score from data you threw away, and you cannot re-offload it.

---

## Coverage matrix (decoded field → column → verdict)

Legend: **PERSISTED** (column + write path) · **DROPPED** (decoded, no column, no write)
· **NEVER-WRITTEN** (table/column exists but nothing inserts) · **DERIVED-ONLY** (raw
input discarded, only a computed product stored).

### Live path — `extractStreams` → `Streams` → `StreamPersistence.toBatch` → insert

| Decoded carrier | Column (Room/drift) | Verdict |
|---|---|---|
| `HrSample(ts,bpm)` | `hrSample` | PERSISTED |
| `RrInterval(ts,rrMs)` | `rrInterval` | PERSISTED |
| `WhoopEvent(ts,kind,payload)` | `event` (+ sorted-key JSON payload) | PERSISTED |
| `BatterySample(ts,soc,mv,charging)` | `battery` | PERSISTED |
| `Spo2Sample` (only a live optical source, e.g. Oura) | `spo2Sample` | PERSISTED |
| `SkinTempSample` (Oura live) | `skinTempSample` | PERSISTED |

`toBatch` carries every field on the live `Streams` object 1:1. resp/gravity/steps/
sleepState/ppgHr are empty on the live WHOOP path by design (type-47-only), so no loss.

### Historical offload — WHOOP 4.0 v24/v12 (`decodeHistorical`)

| Decoded key | Column | Verdict |
|---|---|---|
| `unix` + `heart_rate` | `hrSample` | PERSISTED |
| `rr_intervals` (≤4) | `rrInterval` | PERSISTED |
| `spo2_red`, `spo2_ir` | `spo2Sample` | PERSISTED |
| `skin_temp_raw` | `skinTempSample` | PERSISTED |
| `resp_rate_raw` | `respSample` | PERSISTED |
| `gravity_x/y/z` | `gravitySample` | PERSISTED |
| `hist_version` | — | DROPPED (diagnostic tag, not sensor data — fine) |

WHOOP 4.0 **v25**: gravity vector → `gravitySample` PERSISTED; no per-second HR exists
in v25 (PPG-derived on-device), so none is stored. Correct.

### Historical offload — WHOOP 5/MG v18 (`_decodeWhoop5Historical`)

Persisted:

| Decoded key | Column | Verdict |
|---|---|---|
| `heart_rate` | `hrSample` | PERSISTED |
| `rr_intervals` | `rrInterval` | PERSISTED |
| `skin_temp_raw` | `skinTempSample` | PERSISTED |
| `step_motion_counter` (+ `activity_class`) | `stepSample` | PERSISTED |
| `sleep_state` (@81 high nibble) | `sleepStateSample` | PERSISTED |
| `gravity_x/y/z` | `gravitySample` | PERSISTED |

The three physiologically-meaningful fields below are now **PERSISTED** (v3): the
parser's keys are threaded through `extractHistoricalStreams` → `StreamBatch` (on the
`HrRow` / `GravityRow` carriers) → the drift insert, into additive nullable columns.

| Decoded key | What it is | Column | Verdict |
|---|---|---|---|
| `hr_fixed_8_8` | **sub-bpm HR (8.8 fixed), corr 0.989 vs bpm** | `hrSample.hrFixed88` | **PERSISTED** ✓ |
| `onwrist` (@81 bits 0-1) | **on-wrist flag** (wear gating) | `hrSample.onwrist` | **PERSISTED** ✓ |
| `dynamic_acceleration` | per-second motion scalar (0–8 g) | `gravitySample.dynamicAccel` | **PERSISTED** ✓ |

Still **DROPPED** (low-value raw/status bytes — deliberately not captured; documented):

| Decoded key | What it is | Verdict |
|---|---|---|
| `wake_quality` (@81 bits 2-3) | band wake-quality field | DROPPED |
| `motion_wear_quality` (@63) | wear-quality 0–2 | DROPPED |
| `step_cadence` (@59) | per-step cadence byte | DROPPED |
| `cardiac_flags` (@33) | cardiac status flags | DROPPED |
| `cardiac_status` (@40) | cardiac status | DROPPED |
| `rr_packed` (@38) | packed R-R word | DROPPED |
| `record_index` (@11) | per-record counter | DROPPED |
| `temp_aux_1_raw` / `temp_aux_2_raw` (@69/@71) | aux thermal | DROPPED |
| `status_word` / `_1` / `_2` (@75/@77/@79) | status words | DROPPED |
| `aux_byte_82` (@82) | raw aux byte | DROPPED |
| `unknown_f32_113` (@113) | unknown f32 | DROPPED |

Most are low-value raw/status bytes; the three physiologically-meaningful ones
(`hr_fixed_8_8`, `onwrist`, `dynamic_acceleration`) are now persisted (see above).

### Historical offload — WHOOP 5/MG v26 (raw PPG)

| Decoded | Column | Verdict |
|---|---|---|
| 24 Hz i16 PPG waveform | `ppgRawSample` (packed LE i16 blob, 1 row/sec) | **PERSISTED** ✓ |
| → `PpgHr.estimate` → `PpgHrRow` | `ppgHrSample` | PERSISTED (derived HR) |

The raw 24 Hz optical waveform is now stored **losslessly** (`WhoopPpgRawSamples`,
append-only, idempotent on `(deviceId, ts)`): each v26 record's own unix second + its
24 i16 samples packed little-endian into a blob, carried on `StreamBatch.ppgRaw` from
`extractHistoricalStreams` and inserted alongside the derived HR. A future PPG algorithm
(SpO2, HRV-from-PPG, artifact rejection) can now re-run over the exact samples. This is
the densest stream in the pipeline; its growth is the storage line-item tracked in the
**BACKLOG** section below — raw preservation wins over the growth concern for now.

### Tables/paths that exist but are never written — now WIRED (v3)

| Artifact | Intended purpose | Verdict |
|---|---|---|
| `RawSensorArchive` table | lossless archive of raw BLE frames + still-undecoded bytes | **WRITTEN** ✓ — `DriftRejectedFrameArchive` (`lib/core/ble/sync/raw_archive.dart`) appends one immutable row per rejected frame (`capturedAtMs`, `trimCursor`, `family`, `rawHex`) |
| `Backfiller.rejectedSink` | durably archive CRC-ok-but-undecodable frames **before** ack | **WIRED** ✓ — `WhoopBleClient` derives a `RejectedFrameArchive` from its drift-backed repository and passes it as `rejectedSink`; the sink is now `async` and its durable write is **awaited before the ack** |

The `#77/#91` design is now enforced on device: an undecodable historical frame
(unmapped firmware layout that fails the v24 plausibility gate, or a CRC edge) is
archived durably into `RawSensorArchive` **before** the trim is acked. The safe-trim
invariant holds: durable rows → cursor → ack. If the archive write **fails** (returns
false / throws), the Backfiller does **not** ack, so the strap keeps the records and
re-sends them next offload — never ack unarchived data. A later release that maps the
layout can replay the archive to recover the bytes.

---

## Immutability verdict — PASS (for what is stored)

- **No deletes touch the raw stream tables.** Every `delete(...)` in the codebase targets
  user-entered domain tables only (`foodEntries`, `weightLog`, `waterLog`, `alarms`).
  No DELETE / UPDATE / DROP / vacuum / prune runs against `hrSample`, `rrInterval`,
  `gravitySample`, `spo2Sample`, `skinTempSample`, `respSample`, `stepSample`,
  `sleepStateSample`, `event`, `battery`, `ppgHrSample`.
- **Append-only inserts.** Every stream insert goes through `_insertIgnoreCounting` with
  `InsertMode.insertOrIgnore` on the natural key (`deviceId, ts[, rrMs/kind]`), mirroring
  Room `OnConflictStrategy.IGNORE`. Re-syncing the same second is a no-op — an existing
  row is **never overwritten**, so a re-offload cannot corrupt stored raw data.
- **Trim = strap-side only.** `_ackTrim` sends `HISTORICAL_DATA_RESULT` to advance the
  **strap's** flash cursor. It performs no local deletion. The `strap_trim` cursor lives
  in `syncCursor` and only records how far the strap has been told it may forget.
- **Safe ordering preserved.** `_finishChunk` writes decoded rows (durable) → persists the
  trim cursor → acks. Any failure early-returns *without* acking, so the strap re-sends;
  idempotent inserts make the re-send harmless.

The one immutability hole that was upstream of storage — **acking undecodable frames
without archiving them** — is now **CLOSED** (v3): the rejected-frame archive is wired
and its durable write is awaited before the ack (see WIRED above), so the strap can no
longer trim data the phone never stored.

---

## Raw-vs-analyzed gap — the disconnect

**The analytics pipeline does not read the synced raw tables at all.**

- `RealRepository.load()` (`lib/core/data/real_repository.dart`) loads
  `assets/data/real_raw.bin.gz`, gunzips it, and `RawCapture.decode`s the bundled 88-day
  demo capture. `DailyPipeline` runs entirely over those `RawDay`/`RawSample` objects.
- Nothing in `lib/core/analytics/*` issues a `select` against `hrSample`, `rrInterval`,
  `gravitySample`, or any WHOOP stream table. The only readers of those tables are the
  insert methods themselves.

So today: a real strap sync **writes** raw rows into SQLite that **nothing analyzes**.
The scores on screen come from the frozen bundled asset, independent of whatever the user
just offloaded. The persistence layer (Wave D1) and the analytics layer are two disjoint
halves that have not been joined yet.

**Is the stored raw lossless enough to re-run the whole pipeline later?** For the signals
the pipeline needs — per-second HR, beat-to-beat RR (RMSSD/SDNN/RHR), gravity/accel (sleep
staging), skin temp, resp, SpO2 — **yes**, those are all persisted per-second at full
resolution by natural key. The gaps above (`hr_fixed_8_8`, `onwrist`,
`dynamic_acceleration`, and especially the raw v26 PPG waveform) limit *future* algorithms
that would want richer inputs, but the **current** engine's inputs are all present. The
missing piece is not the data — it is the **read seam**: a repository that derives days
from the drift tables instead of the asset.

---

## Growth sizing (money/perf risk)

Continuous wear banks ~1 type-47 record/second, and each second fans out into several
rows across tables. On WHOOP 5/MG v18 one banked second yields roughly:
HR (1) + RR (~1–2) + gravity (1) + skinTemp (1) + steps (1) + sleepState (1) ≈ **6–8 rows/s**.

- 86,400 s/day × ~7 rows ≈ **~600 k rows/day**.
- SQLite cost per narrow `(deviceId, ts, int)` row with its composite-PK index is roughly
  50–70 B effective (gravity rows ~90 B). Blended ≈ **~65 B/row**.
- ⇒ **~25–40 MB/day**, i.e. **~9–15 GB/year** of continuous wear.

Sanity check against the bundled asset: 88 days ≈ 2.7 M rows — but that asset is *daytime-
downsampled* and packs all channels into one 16-byte record/second, so it understates a
full-resolution multi-table offload by a large factor. The real drift footprint is denser.

This is the real cost: a multi-GB SQLite file on a phone means slower range queries, longer
backups, storage-pressure eviction risk, and a heavier re-analysis pass. It does not
threaten correctness, but it will threaten UX and app-store storage complaints within a
year of heavy use.

---

## FUTURE / BACKLOG — do NOT solve now

Mitigations for the growth risk, explicitly deferred:

- **Retention window** — keep the last N months of per-second raw at full resolution;
  older-than-N gets compacted. Requires deciding N against the re-analysis promise.
- **Downsample-old / keep-recent** — collapse aged per-second HR/gravity to per-minute
  aggregates while keeping night RR full-res (RMSSD needs beat-to-beat). Recent data stays
  lossless; old data keeps trend fidelity only.
- **Columnar / compaction** — store aged data as per-day compressed blobs (the
  `RawSensorArchive`-style approach) instead of millions of individual rows; index by day.
- **Export / offload** — let the user export raw to a file / their own storage and prune
  locally, so the durable copy survives off-device.

Any of these **breaks the "never deleted" invariant for old data**, so it is a product
decision (how long is "forever"?), not a quick fix. Until then, append-only wins.

## DONE (v3, schema 2 → 3) — the loss holes are CLOSED

All three cheap loss-holes that protect the "we have all the data" promise are fixed,
with tests (`test/ble/sync/raw_data_loss_test.dart`) and an additive `onUpgrade`
migration (no drop/wipe; append-only immutability preserved):

1. ✅ **`rejectedSink` wired + `RawSensorArchive` written** — undecodable-but-CRC-ok
   frames are archived durably (awaited) *before* the ack; a failed write holds the ack
   so the strap re-sends. (`lib/core/ble/sync/raw_archive.dart`,
   `whoop_ble_client.dart`, `backfiller.dart` — the sink is now `async` + family-aware.)
2. ✅ **`hr_fixed_8_8`, `onwrist`, `dynamic_acceleration` persisted** — nullable columns
   `hrSample.hrFixed88` / `hrSample.onwrist` / `gravitySample.dynamicAccel`, threaded
   through `HrRow` / `GravityRow` → `StreamBatch` → `DriftStreamRepository.insert`.
3. ✅ **Raw v26 PPG waveform stored** — new append-only `ppgRawSample` table (one row per
   strap-second, 24 i16 samples packed LE), carried on `StreamBatch.ppgRaw`.

The ~12 low-value v18 status/aux bytes (`wake_quality`, `motion_wear_quality`,
`step_cadence`, `cardiac_flags`/`cardiac_status`, `rr_packed`, `record_index`,
`temp_aux_1/2_raw`, `status_word*`, `aux_byte_82`, `unknown_f32_113`) are intentionally
**not** captured — documented as skipped, low-value.

## Re-analysis strategy — design note

Once a read seam exists, three options for *when* to re-derive scores:

- **Re-derive ALL days** on an algorithm-version bump — simplest, correct, but a full pass
  over multi-GB is slow and battery-hungry; fine as a background/one-shot migration keyed on
  a stored `analyticsVersion`.
- **Current day only** — cheap, keeps "today" live, but leaves history scored by the old
  algorithm until touched (inconsistent trends).
- **On-demand / lazy** — re-derive a day the first time it is viewed, cache the result,
  invalidate on `analyticsVersion` change. Best UX/cost tradeoff; needs a per-day
  "scored-with-version" stamp so a stale cache is detected.

Recommended shape: store `analyticsVersion` per scored day; lazily re-derive on view, with an
optional background sweep. The raw tables never change across any of these — only the derived
`dailyMetrics` / `sleepSessions` cache is rewritten. That is exactly the point of keeping raw
immutable: re-analysis is a pure function of stored raw + algorithm version.
