import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Schema — the local store of everything NOOP knows, mirroring the native
// GRDB/Room domain plus the new nutrition domain. Day-grain rows are keyed by an
// ISO `yyyy-MM-dd` day string (the app's `isoDay`), matching the native tables;
// time-series and nutrition rows carry their own ids/timestamps.
//
// The replay build re-derives biometric rows from the bundled capture each
// launch and caches them here; user-entered data (journal, weight, water,
// nutrition) is the durable source of truth.
// ─────────────────────────────────────────────────────────────────────────────

/// One scored calendar day — the app spine (mirrors Flutter `DayRecord`,
/// native `dailyMetric`, and WHOOP's per-cycle trend keys).
class DailyMetrics extends Table {
  TextColumn get day => text()(); // ISO yyyy-MM-dd (local)
  TextColumn get cycleId => text().nullable()(); // WHOOP cycle this day belongs to
  RealColumn get charge => real().withDefault(const Constant(0))(); // recovery %
  RealColumn get effort => real().withDefault(const Constant(0))(); // internal 0..100 strain
  RealColumn get dayStrain => real().nullable()(); // WHOOP DAY_STRAIN 0..21
  RealColumn get rest => real().withDefault(const Constant(0))();
  RealColumn get stress => real().withDefault(const Constant(0))();
  RealColumn get hrv => real().withDefault(const Constant(0))();
  RealColumn get rhr => real().withDefault(const Constant(0))();
  RealColumn get respiratoryRate => real().withDefault(const Constant(0))();
  RealColumn get skinTempDelta => real().withDefault(const Constant(0))(); // sleep-derived
  RealColumn get spo2 => real().withDefault(const Constant(0))(); // sleep-derived
  IntColumn get steps => integer().withDefault(const Constant(0))();
  IntColumn get calories => integer().withDefault(const Constant(0))(); // kcal
  RealColumn get kilojoules => real().nullable()(); // WHOOP stores kJ separately
  IntColumn get hrZone13Sec => integer().nullable()(); // HR_ZONES_1_3
  IntColumn get hrZone45Sec => integer().nullable()(); // HR_ZONES_4_5
  IntColumn get strengthActivitySec => integer().nullable()();

  // 30-day baselines WHOOP ships alongside each metric (for the trend arrows).
  RealColumn get hrvBaseline => real().nullable()();
  RealColumn get rhrBaseline => real().nullable()();
  RealColumn get respRateBaseline => real().nullable()();
  IntColumn get stepsBaseline => integer().nullable()();

  // App-only (Bevel-derived, no WHOOP source).
  IntColumn get fitnessAge => integer().withDefault(const Constant(0))();
  IntColumn get vitality => integer().withDefault(const Constant(0))();
  RealColumn get hydration => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {day};
}

/// A WHOOP cycle — its fundamental unit, which can span more than one calendar
/// day (so day-grain bucketing alone mis-handles multi-day cycles / day-zero).
class Cycles extends Table {
  TextColumn get id => text()();
  IntColumn get startTs => integer()(); // unix seconds
  IntColumn get endTs => integer().nullable()(); // null while open
  BoolColumn get isMultiDay => boolean().withDefault(const Constant(false))();
  BoolColumn get isDayZero => boolean().withDefault(const Constant(false))();
  TextColumn get sleepState => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One night of sleep (mirrors Flutter `SleepRecord` / native `sleepSession`).
/// The hypnogram is stored as a JSON array of `{start,dur,stage}` segments; the
/// per-epoch restlessness/band-state arrays are stored as JSON too (they are
/// dense but bounded to one night).
class SleepSessions extends Table {
  TextColumn get day => text()(); // ISO logical morning
  IntColumn get bedtimeTs => integer()(); // unix seconds
  IntColumn get wakeTs => integer()();
  IntColumn get inBedSec => integer()();
  IntColumn get asleepSec => integer()();
  IntColumn get deepSec => integer()();
  IntColumn get remSec => integer()();
  IntColumn get lightSec => integer()();
  IntColumn get awakeSec => integer()();
  RealColumn get efficiency => real()();
  IntColumn get needSec => integer().withDefault(const Constant(0))();
  RealColumn get respiratoryRate => real().withDefault(const Constant(0))();
  IntColumn get disturbances => integer().withDefault(const Constant(0))();

  // Per-night physiology carried on the session itself (native parity).
  RealColumn get restingHr => real().nullable()();
  RealColumn get avgHrv => real().nullable()();
  RealColumn get spo2 => real().nullable()();
  RealColumn get skinTempDelta => real().nullable()();

  // WHOOP headline sleep scores (distinct from raw efficiency).
  IntColumn get sleepPerformancePct => integer().nullable()();
  IntColumn get sleepConsistencyPct => integer().nullable()();
  IntColumn get hoursVsNeededPct => integer().nullable()();
  IntColumn get restorativeSleepSec => integer().nullable()(); // deep+REM
  IntColumn get sleepLatencySec => integer().nullable()();
  IntColumn get wakeEventsCount => integer().nullable()();
  IntColumn get highSleepStressPct => integer().nullable()();
  IntColumn get noDataSec => integer().nullable()(); // off-wrist within window

  // Sleep Need broken into WHOOP's components (baseline + debt + strain + nap).
  IntColumn get sleepDebtSec => integer().nullable()();
  IntColumn get sleepNeedBaselineSec => integer().nullable()();
  IntColumn get sleepNeedFromStrainSec => integer().nullable()();
  IntColumn get sleepNeedFromNapSec => integer().nullable()();

  // Linkage to the WHOOP activity/cycle (sleep is an editable activity).
  TextColumn get activityId => text().nullable()();
  TextColumn get cycleId => text().nullable()();

  // Provenance + edit state (native `sleepSession.userEdited/startTsAdjusted`).
  TextColumn get source => text().withDefault(const Constant('on-device'))(); // on-device|whoop|import
  BoolColumn get isNap => boolean().withDefault(const Constant(false))();
  BoolColumn get userEdited => boolean().withDefault(const Constant(false))();
  IntColumn get startTsAdjusted => integer().nullable()(); // hand-set onset

  // Dense per-epoch arrays (JSON), one night each.
  TextColumn get hypnogramJson => text().withDefault(const Constant('[]'))();
  TextColumn get restlessnessJson => text().withDefault(const Constant('[]'))(); // 0..1 per epoch
  TextColumn get sleepStateJson => text().withDefault(const Constant('[]'))(); // band-state per epoch

  @override
  Set<Column> get primaryKey => {day};
}

/// Per-epoch sleep-state samples. WHOOP's vocabulary is Awake / Light /
/// SWS(Deep) / REM plus a no-data/off-wrist state, so `state` encodes 0 awake ·
/// 1 light · 2 deep · 3 rem · 4 no-data (the native band-detector codes map in).
/// `source` distinguishes the strap's own signal from the on-device model.
class SleepStateSamples extends Table {
  IntColumn get ts => integer()(); // unix seconds
  IntColumn get state => integer()();
  TextColumn get source => text().withDefault(const Constant('whoop'))();

  @override
  Set<Column> get primaryKey => {ts};
}

/// A workout / activity (mirrors Flutter `Workout` / native `workout` / WHOOP
/// cardio-details). Rich WHOOP fields are optional so imports fill what they can.
class Workouts extends Table {
  TextColumn get id => text()();
  TextColumn get activityId => text().nullable()(); // WHOOP activity uuid
  TextColumn get sport => text()();
  IntColumn get sportId => integer().nullable()(); // numeric WHOOP sport id
  IntColumn get startTs => integer()();
  IntColumn get durationSec => integer()();
  RealColumn get avgHr => real().withDefault(const Constant(0))();
  RealColumn get maxHr => real().withDefault(const Constant(0))();
  RealColumn get effort => real().withDefault(const Constant(0))(); // activity strain
  IntColumn get calories => integer().withDefault(const Constant(0))();
  RealColumn get kilojoules => real().nullable()();
  RealColumn get distanceKm => real().nullable()();
  RealColumn get elevationGainM => real().nullable()();
  TextColumn get source => text().withDefault(const Constant('my-whoop'))();
  TextColumn get zonesJson => text().withDefault(const Constant('[]'))();
  TextColumn get gpsRouteJson => text().nullable()(); // encoded polyline
  TextColumn get strainBreakdownJson => text().nullable()();
  TextColumn get tagsJson => text().nullable()();
  TextColumn get weightliftingDetailsJson => text().nullable()(); // reps/sets/volume

  @override
  Set<Column> get primaryKey => {id};
}

/// Per-second/binned heart-rate thread (high-volume). Derived — prefer
/// [RrSamples] as the source of truth and treat this as a downsample.
class HrSamples extends Table {
  IntColumn get ts => integer()(); // unix seconds
  RealColumn get bpm => real()();

  @override
  Set<Column> get primaryKey => {ts};
}

/// Beat-to-beat RR intervals — WHOOP's actual transmitted signal and the ONLY
/// source from which RMSSD/SDNN/pNN50 can be recomputed (bpm alone can't).
/// High-volume; a sample second can carry more than one RR, hence rrIndex.
class RrSamples extends Table {
  IntColumn get tsMs => integer()(); // epoch milliseconds
  IntColumn get rrIndex => integer().withDefault(const Constant(0))();
  IntColumn get rrMs => integer()(); // interval length, ms
  IntColumn get hrBpm => integer().nullable()();

  @override
  Set<Column> get primaryKey => {tsMs, rrIndex};
}

/// Accelerometer / gravity samples (g) — the movement signal the on-device
/// sleep-stager and activity classifier read. High-volume.
class AccelSamples extends Table {
  IntColumn get ts => integer()(); // unix seconds
  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get z => real()();
  RealColumn get gyro => real().nullable()(); // gravity/gyro magnitude

  @override
  Set<Column> get primaryKey => {ts};
}

/// Lossless archive of the raw BLE frames + still-undecoded bytes (raw SpO2 ADC,
/// optical/PPG/temp bytes), so data we can't decode yet is never lost. Append-only
/// (autoincrement id, no natural key, no updates/deletes) — mirrors the Kotlin
/// `RawHistoryArchive` JSONL: a durable, immutable corpus of undecodable HISTORICAL
/// frames written BEFORE the strap trim is acked, so a future decoder can recover
/// them. [trimCursor] is the HISTORY_END trim the frame belonged to and [family]
/// tags the firmware generation ('whoop4'|'whoop5') so one mapping toolchain reads
/// both. Both are nullable (additive v3) — legacy/live rows leave them null.
class RawSensorArchive extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get capturedAtMs => integer()();
  TextColumn get characteristic => text().nullable()();
  IntColumn get packetType => integer().nullable()();
  IntColumn get spo2RawAdc => integer().nullable()();
  TextColumn get rawHex => text()();
  IntColumn get trimCursor => integer().nullable()(); // HISTORY_END trim (v3)
  TextColumn get family => text().nullable()(); // 'whoop4'|'whoop5' (v3)
}

/// Strap battery over time (native `battery`).
class BatteryLog extends Table {
  IntColumn get ts => integer()(); // unix seconds
  IntColumn get soc => integer()(); // state of charge, %
  BoolColumn get charging => boolean().nullable()();
  IntColumn get mv => integer().nullable()(); // millivolts

  @override
  Set<Column> get primaryKey => {ts};
}

/// Connected strap identity + firmware (single-row-ish registry, keyed by id).
class DeviceInfo extends Table {
  TextColumn get id => text()(); // strapId
  TextColumn get serial => text().nullable()();
  TextColumn get mac => text().nullable()();
  TextColumn get model => text().nullable()(); // e.g. "Whoop 5.0"
  TextColumn get name => text().nullable()();
  TextColumn get hwVersion => text().nullable()();
  TextColumn get fwVersion => text().nullable()();
  TextColumn get dspVersion => text().nullable()();
  IntColumn get lastSeenTs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// WHOOP stress timeline (0..100). High-volume.
class StressSamples extends Table {
  IntColumn get ts => integer()(); // unix seconds
  RealColumn get value => real()(); // 0..100

  @override
  Set<Column> get primaryKey => {ts};
}

/// Strap events — wear on/off, history start/end, etc. (native `event` / 0x31).
class Events extends Table {
  IntColumn get ts => integer()(); // unix seconds
  TextColumn get kind => text()(); // wear_on|wear_off|history_start|...
  TextColumn get payloadJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {ts, kind};
}

/// User body measurements over time (height, weight, max HR).
class BodyMeasurements extends Table {
  TextColumn get day => text()(); // ISO yyyy-MM-dd
  RealColumn get heightCm => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get maxHr => integer().nullable()();

  @override
  Set<Column> get primaryKey => {day};
}

/// A journal answer for one behaviour on one day (mirrors native `journal` —
/// adds notes + a numeric value for measured items like caffeine mg).
class JournalEntries extends Table {
  TextColumn get day => text()();
  TextColumn get questionId => text()();
  BoolColumn get answeredYes => boolean().withDefault(const Constant(false))();
  RealColumn get numericValue => real().nullable()(); // magnitude answers
  TextColumn get unit => text().nullable()(); // e.g. mg, drinks
  TextColumn get timeLabel => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {day, questionId};
}

/// Server-driven catalogue of journal behaviours (WHOOP journal-service). The
/// answer rows in [JournalEntries] reference these by id.
class JournalQuestions extends Table {
  TextColumn get questionId => text()();
  TextColumn get category => text().nullable()();
  TextColumn get title => text()();
  TextColumn get questionText => text().nullable()();
  TextColumn get questionType => text().withDefault(const Constant('binary'))(); // binary|magnitude|scale
  TextColumn get unit => text().nullable()();
  RealColumn get minVal => real().nullable()();
  RealColumn get maxVal => real().nullable()();
  RealColumn get interval => real().nullable()();
  TextColumn get choicesJson => text().nullable()();
  BoolColumn get deprecated => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {questionId};
}

/// User-entered daily body weight (kg).
class WeightLog extends Table {
  TextColumn get day => text()();
  RealColumn get kg => real()();

  @override
  Set<Column> get primaryKey => {day};
}

/// User-entered daily water intake (millilitres).
class WaterLog extends Table {
  TextColumn get day => text()();
  RealColumn get ml => real()();

  @override
  Set<Column> get primaryKey => {day};
}

/// Smart alarms (WHOOP sets the strap's built-in alarm over BLE). Stored here so
/// the schedule survives; the live-BLE arm/readback lands when a BLE bridge
/// exists — until then an enabled alarm is 'queued' (honest, never claims armed).
class Alarms extends Table {
  TextColumn get id => text()();
  IntColumn get hour => integer()(); // wake-by hour 0..23
  IntColumn get minute => integer()(); // 0..59
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get daysMask => integer().withDefault(const Constant(0))(); // bit0=Mon..bit6=Sun; 0 = one-shot
  TextColumn get status => text().withDefault(const Constant('idle'))(); // idle|queued|armed|fired
  IntColumn get lastArmedTs => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Generic long-format store (native `metricSeries` parity): one real value per
/// (day, key). A catch-all so ANY metric — current or future, standard or
/// miscellaneous — can be persisted without a schema change. Standard metrics
/// live in their typed tables above; this holds the long tail.
class MetricSamples extends Table {
  TextColumn get day => text()(); // ISO yyyy-MM-dd
  TextColumn get key => text()(); // e.g. 'vo2max', 'bloodGlucose', 'mood'
  RealColumn get value => real()();
  TextColumn get unit => text().nullable()();

  @override
  Set<Column> get primaryKey => {day, key};
}

// ── Nutrition domain (new) ──────────────────────────────────────────────────

/// A food product — a cached Open Food Facts lookup, a manual entry, or an AI
/// estimate. Nutriments are canonicalised per 100 g (per-serving is derived).
class FoodItems extends Table {
  TextColumn get id => text()(); // barcode, or a generated id for manual/AI
  TextColumn get name => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get servingSizeRaw => text().nullable()(); // "30 g"
  RealColumn get servingGrams => real().nullable()();
  RealColumn get kcal100 => real().nullable()();
  RealColumn get carbs100 => real().nullable()();
  RealColumn get protein100 => real().nullable()();
  RealColumn get fat100 => real().nullable()();
  RealColumn get sugar100 => real().nullable()();
  RealColumn get fiber100 => real().nullable()();
  RealColumn get salt100 => real().nullable()();
  TextColumn get source => text().withDefault(const Constant('off'))(); // off|manual|ai

  @override
  Set<Column> get primaryKey => {id};
}

/// A meal slot on a day (breakfast/lunch/dinner/snack).
class Meals extends Table {
  TextColumn get id => text()();
  TextColumn get day => text()(); // ISO yyyy-MM-dd
  TextColumn get type => text()(); // breakfast|lunch|dinner|snack
  IntColumn get createdTs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A logged portion within a meal. Macros are SNAPSHOTTED at log time (kcal/…)
/// so edits to upstream OFF data never rewrite the user's history.
class FoodEntries extends Table {
  TextColumn get id => text()();
  TextColumn get mealId => text().references(Meals, #id, onDelete: KeyAction.cascade)();
  TextColumn get foodItemId => text().nullable()();
  TextColumn get name => text()();
  RealColumn get grams => real()();
  RealColumn get kcal => real()();
  RealColumn get carbs => real().withDefault(const Constant(0))();
  RealColumn get protein => real().withDefault(const Constant(0))();
  RealColumn get fat => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A day's rolled-up nutrition totals (summed from snapshotted entry macros).
class DayNutrition {
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final int entries;
  const DayNutrition({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.entries,
  });

  static const empty =
      DayNutrition(kcal: 0, protein: 0, carbs: 0, fat: 0, entries: 0);
}

// ── WHOOP strap sync — sensor-stream tables (Wave D1) ───────────────────────
//
// These mirror the Room stream tables (android .../data/Entities.kt) 1:1 so the
// on-device WHOOP offload lands byte-identical rows to the native app: every
// stream row is stamped with the strap `deviceId` and its natural key matches
// Room exactly, so drift's `InsertMode.insertOrIgnore` behaves like the Room
// `OnConflictStrategy.IGNORE` (idempotent re-inserts). Additive — the bundled
// asset analytics tables above are untouched. `ts` is wall-clock unix SECONDS.
// The sqlite table names are pinned to the Room names (hrSample, rrInterval, …)
// via [tableName], distinct from the app tables' drift-default names.

/// Heart-rate sample. Room `hrSample`. PK (deviceId, ts).
class WhoopHrSamples extends Table {
  TextColumn get deviceId => text()();
  IntColumn get ts => integer()(); // unix seconds
  IntColumn get bpm => integer()();
  // WHOOP5/MG v18 sub-bpm HR (@36, 8.8 fixed → bpm = value/256; corr 0.989 vs bpm)
  // and the @81 on-wrist flag (bits 0-1). Additive nullable (v3): the strap-derived
  // higher-precision HR + wear gating a future engine can use. Null on the live path
  // and on families/versions that don't carry them.
  IntColumn get hrFixed88 => integer().nullable()();
  IntColumn get onwrist => integer().nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'hrSample';
  @override
  Set<Column> get primaryKey => {deviceId, ts};
}

/// HR derived from the WHOOP 5/MG v26 optical PPG waveform (#156). Room
/// `ppgHrSample`. Kept separate from measured HR; [conf] is autocorrelation
/// strength (0…1). PK (deviceId, ts).
class WhoopPpgHrSamples extends Table {
  TextColumn get deviceId => text()();
  IntColumn get ts => integer()();
  IntColumn get bpm => integer()();
  RealColumn get conf => real()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'ppgHrSample';
  @override
  Set<Column> get primaryKey => {deviceId, ts};
}

/// Raw WHOOP 5/MG v26 optical PPG waveform — the 24 Hz i16 buffer, ONE row per
/// strap-second, stored LOSSLESLY so a future optical algorithm (SpO2, HRV-from-PPG,
/// artifact rejection) can re-run over the exact samples. Today the waveform is
/// consumed to derive HR ([WhoopPpgHrSamples]) then discarded; this table preserves
/// it. [samples] is the packed little-endian i16 buffer ([sampleCount] shorts,
/// `sampleCount*2` bytes) — matches how the v26 decoder exposes `List<int>`.
/// Append-only, idempotent on (deviceId, ts). NOTE: 24 samples/s is the densest
/// stream in the pipeline; the growth budget is tracked as separate backlog
/// (docs/raw-data-storage-and-reanalysis.md) — raw preservation wins here.
class WhoopPpgRawSamples extends Table {
  TextColumn get deviceId => text()();
  IntColumn get ts => integer()(); // unix seconds (the record's own unix)
  IntColumn get sampleCount => integer()();
  BlobColumn get samples => blob()(); // little-endian i16, sampleCount*2 bytes

  @override
  String get tableName => 'ppgRawSample';
  @override
  Set<Column> get primaryKey => {deviceId, ts};
}

/// R-R interval. Room `rrInterval`. PK (deviceId, ts, rrMs) — many R-R per ts.
class WhoopRrIntervals extends Table {
  TextColumn get deviceId => text()();
  IntColumn get ts => integer()();
  IntColumn get rrMs => integer()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'rrInterval';
  @override
  Set<Column> get primaryKey => {deviceId, ts, rrMs};
}

/// Strap event. Room `event`. `payloadJson` is the deterministic sorted-keys
/// JSON of the residual fields (event/event_timestamp removed). PK (deviceId,
/// ts, kind).
class WhoopEvents extends Table {
  TextColumn get deviceId => text()();
  IntColumn get ts => integer()();
  TextColumn get kind => text()();
  TextColumn get payloadJson => text()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'event';
  @override
  Set<Column> get primaryKey => {deviceId, ts, kind};
}

/// Battery sample. Room `battery`. soc %, mv millivolts, charging only from
/// BATTERY_LEVEL events. PK (deviceId, ts).
class WhoopBattery extends Table {
  TextColumn get deviceId => text()();
  IntColumn get ts => integer()();
  RealColumn get soc => real().nullable()();
  IntColumn get mv => integer().nullable()();
  BoolColumn get charging => boolean().nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'battery';
  @override
  Set<Column> get primaryKey => {deviceId, ts};
}

/// SpO2 raw-ADC sample (type-47). Room `spo2Sample`. PK (deviceId, ts).
class WhoopSpo2Samples extends Table {
  TextColumn get deviceId => text()();
  IntColumn get ts => integer()();
  IntColumn get red => integer()();
  IntColumn get ir => integer()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'spo2Sample';
  @override
  Set<Column> get primaryKey => {deviceId, ts};
}

/// Skin-temperature raw-register sample (type-47). Room `skinTempSample`.
/// PK (deviceId, ts).
class WhoopSkinTempSamples extends Table {
  TextColumn get deviceId => text()();
  IntColumn get ts => integer()();
  IntColumn get raw => integer()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'skinTempSample';
  @override
  Set<Column> get primaryKey => {deviceId, ts};
}

/// Step / motion counter sample (WHOOP5 step_motion_counter@57). Room
/// `stepSample`. `counter` is the cumulative u16 counter; `activityClass` is
/// the @63 enum (0=still/1=walk/2=run), null when invalid/absent. PK (deviceId,
/// ts).
class WhoopStepSamples extends Table {
  TextColumn get deviceId => text()();
  IntColumn get ts => integer()();
  IntColumn get counter => integer()();
  IntColumn get activityClass => integer().nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'stepSample';
  @override
  Set<Column> get primaryKey => {deviceId, ts};
}

/// The strap's OWN @81 high-nibble band sleep_state (#175). Room
/// `sleepStateSample`. `state` = 0 wake / 1 still / 2 asleep / 3 up. PK
/// (deviceId, ts).
class WhoopSleepStateSamples extends Table {
  TextColumn get deviceId => text()();
  IntColumn get ts => integer()();
  IntColumn get state => integer()();

  @override
  String get tableName => 'sleepStateSample';
  @override
  Set<Column> get primaryKey => {deviceId, ts};
}

/// Respiration raw-register sample (type-47). Room `respSample`. PK (deviceId,
/// ts).
class WhoopRespSamples extends Table {
  TextColumn get deviceId => text()();
  IntColumn get ts => integer()();
  IntColumn get raw => integer()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'respSample';
  @override
  Set<Column> get primaryKey => {deviceId, ts};
}

/// DSP-separated gravity/orientation vector (type-47, unit "g"). Room
/// `gravitySample`. PK (deviceId, ts).
class WhoopGravitySamples extends Table {
  TextColumn get deviceId => text()();
  IntColumn get ts => integer()();
  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get z => real()();
  // WHOOP5/MG v18 per-second motion scalar (dynamic_acceleration@41, 0–8 g) — a
  // motion signal independent of the DSP gravity vector. Additive nullable (v3);
  // null when absent/off-range and on families/versions that don't carry it.
  RealColumn get dynamicAccel => real().nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'gravitySample';
  @override
  Set<Column> get primaryKey => {deviceId, ts};
}

/// Long-format capture of the WHOOP 5/MG v18 per-second fields the historical
/// decoder produces but that have no typed column of their own — `record_index`,
/// `cardiac_flags`/`cardiac_status`, `rr_packed`, `step_cadence`,
/// `motion_wear_quality`, the aux thermal registers (`temp_aux_1/2_raw`), the
/// status words (`status_word`/`_1`/`_2`), `wake_quality`, `aux_byte_82`, and the
/// unknown float (`unknown_f32_113`). Room `rawFieldSample` (new-in-v4). Each is a
/// genuine strap-emitted byte that used to be dropped one line before the store; a
/// catch-all so no decoded value is lost without a column-per-field explosion.
/// Exactly one of [intValue]/[realValue] is set per row (integer registers vs the
/// one float). Append-only, idempotent on (deviceId, ts, key). PK (deviceId, ts,
/// key).
class WhoopRawFieldSamples extends Table {
  TextColumn get deviceId => text()();
  IntColumn get ts => integer()(); // unix seconds
  TextColumn get key => text()(); // e.g. 'status_word', 'step_cadence'
  IntColumn get intValue => integer().nullable()();
  RealColumn get realValue => real().nullable()();

  @override
  String get tableName => 'rawFieldSample';
  @override
  Set<Column> get primaryKey => {deviceId, ts, key};
}

/// Durable key/value cursor store for the historical-offload safe-trim
/// watermark (`strap_trim`). Mirrors the native `PrefsTrimCursorStore`: a small
/// KV separate from the sensor rows, written AFTER decoded rows are durable and
/// BEFORE the trim is acked to the strap. `value` is a u32 carried as int.
class SyncCursors extends Table {
  TextColumn get name => text()();
  IntColumn get value => integer()();

  @override
  String get tableName => 'syncCursor';
  @override
  Set<Column> get primaryKey => {name};
}

@DriftDatabase(tables: [
  DailyMetrics,
  Cycles,
  SleepSessions,
  SleepStateSamples,
  Workouts,
  HrSamples,
  RrSamples,
  AccelSamples,
  RawSensorArchive,
  BatteryLog,
  DeviceInfo,
  StressSamples,
  Events,
  BodyMeasurements,
  JournalEntries,
  JournalQuestions,
  WeightLog,
  WaterLog,
  Alarms,
  MetricSamples,
  FoodItems,
  Meals,
  FoodEntries,
  // WHOOP strap sync (Wave D1) — additive sensor-stream tables + cursor KV.
  WhoopHrSamples,
  WhoopPpgHrSamples,
  WhoopPpgRawSamples,
  WhoopRrIntervals,
  WhoopEvents,
  WhoopBattery,
  WhoopSpo2Samples,
  WhoopSkinTempSamples,
  WhoopStepSamples,
  WhoopSleepStateSamples,
  WhoopRespSamples,
  WhoopGravitySamples,
  WhoopRawFieldSamples,
  SyncCursors,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openOnDevice());

  /// In-memory (or any) executor for headless `flutter test` — no platform
  /// channels, no `path_provider`, so tests never launch the app.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // v1 → v2 (Wave D1): additively create the WHOOP sensor-stream tables +
        // the sync-cursor KV. Purely additive — existing user data (journal,
        // weight, water, nutrition) and the cached biometric rows are untouched.
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            for (final t in <TableInfo>[
              whoopHrSamples,
              whoopPpgHrSamples,
              whoopRrIntervals,
              whoopEvents,
              whoopBattery,
              whoopSpo2Samples,
              whoopSkinTempSamples,
              whoopStepSamples,
              whoopSleepStateSamples,
              whoopRespSamples,
              whoopGravitySamples,
              syncCursors,
            ]) {
              await m.createTable(t);
            }
          }
          // v2 → v3: close the raw-data LOSS holes the audit found. Purely additive —
          // a new lossless PPG-waveform table, three previously-dropped v18 fields as
          // nullable columns, and the rejected-frame archive's trim/family tags. No
          // existing column meaning changes; nothing is dropped or rewritten.
          //
          // IMPORTANT — idempotency across ALL prior versions: `createTable` above
          // uses the LIVE (v3) generated table defs, which already carry the
          // new-in-v3 columns (`hrSample.hrFixed88/onwrist`, `gravitySample.
          // dynamicAccel`). So on the v1→v3 path the `from < 2` step already created
          // those tables WITH those columns — re-`addColumn`ing them here would throw
          // SQLite "duplicate column name" and roll the whole migration back (app
          // bricked on upgrade). They must only be added for a DB whose whoop tables
          // were built at v2 (WITHOUT them): guard those three on `from == 2`.
          if (from < 3) {
            // New-in-v3 table: never created by the `from < 2` step, so create it on
            // every pre-v3 path (v1→v3 and v2→v3).
            await m.createTable(whoopPpgRawSamples);
            // `raw_sensor_archive` is created by onCreate at v1 (not re-created in
            // the `from < 2` step) WITHOUT these, so add them on every pre-v3 path.
            await m.addColumn(rawSensorArchive, rawSensorArchive.trimCursor);
            await m.addColumn(rawSensorArchive, rawSensorArchive.family);
            // These three live on tables the `from < 2` step (re)creates from the
            // live v3 def — which already carries them. Only a v2 DB (whose whoop
            // tables were built without them) needs the addColumn; adding on the
            // v1→v3 path would duplicate. Hence `from == 2`, not `from < 3`.
            if (from == 2) {
              await m.addColumn(whoopHrSamples, whoopHrSamples.hrFixed88);
              await m.addColumn(whoopHrSamples, whoopHrSamples.onwrist);
              await m.addColumn(
                  whoopGravitySamples, whoopGravitySamples.dynamicAccel);
            }
          }
          // v3 → v4: capture EVERY decoded-but-uncolumned WHOOP5 v18 field into a new
          // append-only long-format table (`rawFieldSample`). Purely additive — a
          // brand-new table only, no existing column meaning changes, nothing dropped or
          // rewritten. `WhoopRawFieldSamples` is new-in-v4, so it is never created by any
          // earlier step: create it on every pre-v4 path (v1→v4, v2→v4, v3→v4) — idempotent
          // because it can't already exist on a genuine <v4 DB. (Stepwise pattern mirrors
          // the from<3 `whoopPpgRawSamples` create above.)
          if (from < 4) {
            await m.createTable(whoopRawFieldSamples);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ── WHOOP sync — stream inserts (idempotent by natural key) ─────────────────
  //
  // Each mirrors a WhoopDao `@Insert(onConflict = IGNORE)` returning the count
  // of rows ACTUALLY inserted (an existing natural key is a no-op that does not
  // count), exactly like the Room `List<Long>` of rowids where -1 == ignored.
  // `insertReturningOrNull` yields null on an ignored conflict (drift's own
  // documented insertOrIgnore idiom), so counting non-null results is faithful.

  Future<int> _insertIgnoreCounting<D>(
    TableInfo table,
    List<Insertable<D>> rows,
  ) async {
    if (rows.isEmpty) return 0;
    var inserted = 0;
    for (final row in rows) {
      final r = await into(table)
          .insertReturningOrNull(row, mode: InsertMode.insertOrIgnore);
      if (r != null) inserted++;
    }
    return inserted;
  }

  Future<int> insertWhoopHr(List<WhoopHrSamplesCompanion> rows) =>
      _insertIgnoreCounting(whoopHrSamples, rows);

  Future<int> insertWhoopPpgHr(List<WhoopPpgHrSamplesCompanion> rows) =>
      _insertIgnoreCounting(whoopPpgHrSamples, rows);

  /// Raw v26 PPG waveform (persist-only, NOT counted). Append-only, idempotent on
  /// (deviceId, ts) so a re-offload of the same second is a no-op.
  Future<void> insertWhoopPpgRaw(List<WhoopPpgRawSamplesCompanion> rows) async =>
      _insertIgnoreCounting(whoopPpgRawSamples, rows);

  Future<int> insertWhoopRr(List<WhoopRrIntervalsCompanion> rows) =>
      _insertIgnoreCounting(whoopRrIntervals, rows);

  Future<int> insertWhoopEvents(List<WhoopEventsCompanion> rows) =>
      _insertIgnoreCounting(whoopEvents, rows);

  Future<int> insertWhoopBattery(List<WhoopBatteryCompanion> rows) =>
      _insertIgnoreCounting(whoopBattery, rows);

  Future<int> insertWhoopSpo2(List<WhoopSpo2SamplesCompanion> rows) =>
      _insertIgnoreCounting(whoopSpo2Samples, rows);

  Future<int> insertWhoopSkinTemp(List<WhoopSkinTempSamplesCompanion> rows) =>
      _insertIgnoreCounting(whoopSkinTempSamples, rows);

  Future<int> insertWhoopSteps(List<WhoopStepSamplesCompanion> rows) =>
      _insertIgnoreCounting(whoopStepSamples, rows);

  /// Band sleep_state (#175). Persist-only, NOT counted (no consumer reads a
  /// count), mirroring `WhoopRepository.insert`.
  Future<void> insertWhoopSleepState(
          List<WhoopSleepStateSamplesCompanion> rows) async =>
      _insertIgnoreCounting(whoopSleepStateSamples, rows);

  Future<int> insertWhoopResp(List<WhoopRespSamplesCompanion> rows) =>
      _insertIgnoreCounting(whoopRespSamples, rows);

  Future<int> insertWhoopGravity(List<WhoopGravitySamplesCompanion> rows) =>
      _insertIgnoreCounting(whoopGravitySamples, rows);

  /// Fires whenever synced WHOOP biometric rows change — the HR / RR / gravity
  /// streams the live analytics are derived from. The live repository listens to
  /// this so scores re-derive as new syncs land (debounced by the caller). Other
  /// table writes (water/weight/nutrition) are intentionally excluded.
  Stream<void> watchWhoopStreams() => tableUpdates(TableUpdateQuery.allOf([
        TableUpdateQuery.onTable(whoopHrSamples),
        TableUpdateQuery.onTable(whoopRrIntervals),
        TableUpdateQuery.onTable(whoopGravitySamples),
      ])).map((_) {});

  /// Decoded-but-uncolumned v18 raw fields (long-format). Persist-only, NOT counted —
  /// no consumer reads a count. Append-only, idempotent on (deviceId, ts, key) so a
  /// re-offload of the same strap-second is a no-op (immutability preserved).
  Future<void> insertWhoopRawFields(
          List<WhoopRawFieldSamplesCompanion> rows) async =>
      _insertIgnoreCounting(whoopRawFieldSamples, rows);

  /// Append one or more raw undecodable BLE frames to [RawSensorArchive] durably.
  /// Append-only (autoincrement id, no natural key) — mirrors the Kotlin
  /// `RawHistoryArchive.append`. The caller (the Backfiller's rejectedSink) must NOT
  /// ack the strap trim until this future completes without throwing.
  Future<void> insertRawArchive(List<RawSensorArchiveCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) => b.insertAll(rawSensorArchive, rows));
  }

  // ── WHOOP sync — trim-cursor KV ─────────────────────────────────────────────

  /// Durably store a cursor value (last-write-wins on the name key). Mirrors
  /// `PrefsTrimCursorStore.set` (synchronous commit before the strap ack).
  Future<void> setSyncCursor(String name, int value) =>
      into(syncCursors).insertOnConflictUpdate(
          SyncCursorsCompanion.insert(name: name, value: value));

  /// Read a cursor value, or null when unset. Mirrors `PrefsTrimCursorStore.get`.
  Future<int?> getSyncCursor(String name) async {
    final row = await (select(syncCursors)..where((t) => t.name.equals(name)))
        .getSingleOrNull();
    return row?.value;
  }

  // ── Nutrition queries ──────────────────────────────────────────────────────

  /// Cache/refresh a food product (OFF lookup, manual entry, or AI item).
  Future<void> upsertFoodItem(FoodItemsCompanion item) =>
      into(foodItems).insertOnConflictUpdate(item);

  /// Insert a meal, ignoring a conflict on its id (idempotent "ensure meal").
  Future<void> insertMeal(MealsCompanion meal) =>
      into(meals).insert(meal, mode: InsertMode.insertOrIgnore);

  Future<void> insertFoodEntry(FoodEntriesCompanion entry) =>
      into(foodEntries).insert(entry);

  Future<void> deleteFoodEntry(String id) =>
      (delete(foodEntries)..where((t) => t.id.equals(id))).go();

  /// A day's meals, oldest-created first.
  Future<List<Meal>> mealsForDay(String day) => (select(meals)
        ..where((m) => m.day.equals(day))
        ..orderBy([(m) => OrderingTerm(expression: m.createdTs)]))
      .get();

  /// Every logged food entry on a day (joined across that day's meals).
  Future<List<FoodEntry>> entriesForDay(String day) {
    final q = select(foodEntries).join(
        [innerJoin(meals, meals.id.equalsExp(foodEntries.mealId))])
      ..where(meals.day.equals(day));
    return q.map((row) => row.readTable(foodEntries)).get();
  }

  /// A day's total intake, summed from the snapshotted entry macros.
  Future<DayNutrition> dayNutrition(String day) async =>
      _rollup(await entriesForDay(day));

  /// The join query for a day's entries (reused by the future + stream reads).
  JoinedSelectStatement<HasResultSet, dynamic> _entriesForDayQuery(String day) =>
      select(foodEntries).join(
          [innerJoin(meals, meals.id.equalsExp(foodEntries.mealId))])
        ..where(meals.day.equals(day));

  /// Reactive stream of a day's meals (re-emits on any insert/delete).
  Stream<List<Meal>> watchMealsForDay(String day) => (select(meals)
        ..where((m) => m.day.equals(day))
        ..orderBy([(m) => OrderingTerm(expression: m.createdTs)]))
      .watch();

  /// Reactive stream of a day's food entries.
  Stream<List<FoodEntry>> watchEntriesForDay(String day) => _entriesForDayQuery(day)
      .watch()
      .map((rows) => rows.map((r) => r.readTable(foodEntries)).toList());

  /// Reactive stream of a day's rolled-up totals.
  Stream<DayNutrition> watchDayNutrition(String day) =>
      watchEntriesForDay(day).map(_rollup);

  // ── User logs (weight / water / journal) ────────────────────────────────────

  Future<Map<String, double>> allWeights() async {
    final rows = await select(weightLog).get();
    return {for (final r in rows) r.day: r.kg};
  }

  Future<void> setWeight(String day, double kg) => into(weightLog)
      .insertOnConflictUpdate(WeightLogCompanion.insert(day: day, kg: kg));

  Future<void> deleteWeight(String day) =>
      (delete(weightLog)..where((t) => t.day.equals(day))).go();

  Future<Map<String, double>> allWater() async {
    final rows = await select(waterLog).get();
    return {for (final r in rows) r.day: r.ml};
  }

  Future<void> setWater(String day, double ml) => into(waterLog)
      .insertOnConflictUpdate(WaterLogCompanion.insert(day: day, ml: ml));

  Future<void> deleteWater(String day) =>
      (delete(waterLog)..where((t) => t.day.equals(day))).go();

  /// All journal yes/no answers as a `day|questionId` → bool map (the shape the
  /// journal UI uses).
  Future<Map<String, bool>> allJournalAnswers() async {
    final rows = await select(journalEntries).get();
    return {for (final r in rows) '${r.day}|${r.questionId}': r.answeredYes};
  }

  Future<void> setJournalAnswer(String day, String questionId, bool yes) =>
      into(journalEntries).insertOnConflictUpdate(JournalEntriesCompanion.insert(
        day: day,
        questionId: questionId,
        answeredYes: Value(yes),
      ));

  // ── Alarms ──────────────────────────────────────────────────────────────────

  Future<List<Alarm>> allAlarms() =>
      (select(alarms)..orderBy([(a) => OrderingTerm(expression: a.hour)])).get();

  Stream<List<Alarm>> watchAlarms() =>
      (select(alarms)..orderBy([(a) => OrderingTerm(expression: a.hour)])).watch();

  Future<void> upsertAlarm(AlarmsCompanion alarm) =>
      into(alarms).insertOnConflictUpdate(alarm);

  Future<void> deleteAlarm(String id) =>
      (delete(alarms)..where((t) => t.id.equals(id))).go();

  static DayNutrition _rollup(List<FoodEntry> entries) {
    var kcal = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0;
    for (final e in entries) {
      kcal += e.kcal;
      protein += e.protein;
      carbs += e.carbs;
      fat += e.fat;
    }
    return DayNutrition(
        kcal: kcal, protein: protein, carbs: carbs, fat: fat, entries: entries.length);
  }

  static LazyDatabase _openOnDevice() => LazyDatabase(() async {
        final dir = await getApplicationDocumentsDirectory();
        return NativeDatabase.createInBackground(
          File(p.join(dir.path, 'noop.sqlite')),
        );
      });
}
