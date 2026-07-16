import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/data/db/database.dart';

/// Migration tests for [AppDatabase] (schemaVersion 5).
///
/// Every migration here is ADDITIVE — nothing has ever been dropped or rewritten,
/// which is load-bearing rather than incidental: an `adb install -r` upgrade must
/// never cost a user a synced row. Each step is therefore pinned from EVERY prior
/// version, and the v4→v5 case additionally asserts pre-existing rows survive.
///
/// The Wave-D1 additive migration must be correct AND idempotent from EVERY
/// prior version. The bug this pins (MASTER-BACKLOG §4 HIGH-1): the `from < 2`
/// step calls `createTable` with the LIVE v3 table defs — which already carry
/// the new-in-v3 columns (`hrSample.hrFixed88/onwrist`, `gravitySample.
/// dynamicAccel`). If the `from < 3` step then `addColumn`s those same columns
/// unconditionally, a v1→v3 upgrade throws SQLite "duplicate column name", the
/// transaction rolls back, and the DB never opens (app bricked on upgrade).
///
/// These tests seed a real on-disk sqlite file at an OLD schema version (the
/// `user_version` pragma is how drift decides onCreate-vs-onUpgrade), then open
/// the genuine [AppDatabase] so drift runs its REAL open + [MigrationStrategy]
/// path — not a hand-invoked callback.

/// Minimal [QueryExecutorUser] so a raw [NativeDatabase] executor can be opened
/// to run seed DDL — drift's raw executor never runs onCreate/onUpgrade itself
/// (that is the generated database's job), so we control the whole schema here.
class _SeedUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;
  @override
  Future<void> beforeOpen(_, __) async {}
}

/// Seed a temp sqlite file with the v1/v2 baseline schema, stamp `user_version`,
/// and close it — leaving a file drift will treat as an upgrade-from-[version].
Future<File> _seedOldDb(
    int version, List<String> ddl) async {
  final dir = Directory.systemTemp.createTempSync('noop_migration_test');
  final file = File('${dir.path}/noop.sqlite');
  final exec = NativeDatabase(file);
  await exec.ensureOpen(_SeedUser());
  for (final stmt in ddl) {
    await exec.runCustom(stmt, const []);
  }
  await exec.runCustom('PRAGMA user_version = $version', const []);
  await exec.close();
  return file;
}

/// `raw_sensor_archive` AS IT EXISTED AT v1 — WITHOUT the v3 `trim_cursor` /
/// `family` columns. onCreate makes this at v1 and the `from < 2` step does NOT
/// re-create it, so a real v1/v2 DB carries this exact shape into the migration.
const _v1RawSensorArchive =
    'CREATE TABLE raw_sensor_archive ('
    'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
    'captured_at_ms INTEGER NOT NULL, '
    'characteristic TEXT, '
    'packet_type INTEGER, '
    'spo2_raw_adc INTEGER, '
    'raw_hex TEXT NOT NULL)';

/// The v2 shape of the two whoop stream tables the guarded v3 addColumns target
/// — built WITHOUT the new-in-v3 columns (as a real v2 build did).
const _v2HrSample =
    'CREATE TABLE hrSample ('
    'device_id TEXT NOT NULL, '
    'ts INTEGER NOT NULL, '
    'bpm INTEGER NOT NULL, '
    'synced INTEGER NOT NULL DEFAULT 0, '
    'PRIMARY KEY (device_id, ts))';

const _v2GravitySample =
    'CREATE TABLE gravitySample ('
    'device_id TEXT NOT NULL, '
    'ts INTEGER NOT NULL, '
    'x REAL NOT NULL, '
    'y REAL NOT NULL, '
    'z REAL NOT NULL, '
    'synced INTEGER NOT NULL DEFAULT 0, '
    'PRIMARY KEY (device_id, ts))';

/// The v3 shape of the two whoop stream tables — built WITH the new-in-v3 columns
/// (hr_fixed88/onwrist, dynamic_accel) but WITHOUT anything new-in-v4, so a v3→v4
/// upgrade only needs to create the brand-new `rawFieldSample` table.
const _v3HrSample =
    'CREATE TABLE hrSample ('
    'device_id TEXT NOT NULL, '
    'ts INTEGER NOT NULL, '
    'bpm INTEGER NOT NULL, '
    'hr_fixed88 INTEGER, '
    'onwrist INTEGER, '
    'synced INTEGER NOT NULL DEFAULT 0, '
    'PRIMARY KEY (device_id, ts))';

const _v3GravitySample =
    'CREATE TABLE gravitySample ('
    'device_id TEXT NOT NULL, '
    'ts INTEGER NOT NULL, '
    'x REAL NOT NULL, '
    'y REAL NOT NULL, '
    'z REAL NOT NULL, '
    'dynamic_accel REAL, '
    'synced INTEGER NOT NULL DEFAULT 0, '
    'PRIMARY KEY (device_id, ts))';

const _v3PpgRawSample =
    'CREATE TABLE ppgRawSample ('
    'device_id TEXT NOT NULL, '
    'ts INTEGER NOT NULL, '
    'sample_count INTEGER NOT NULL, '
    'samples BLOB NOT NULL, '
    'PRIMARY KEY (device_id, ts))';

/// `raw_sensor_archive` AS IT EXISTED AT v3 — WITH the trim_cursor/family columns
/// already added, so the v3→v4 path must NOT re-add them.
const _v3RawSensorArchive =
    'CREATE TABLE raw_sensor_archive ('
    'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
    'captured_at_ms INTEGER NOT NULL, '
    'characteristic TEXT, '
    'packet_type INTEGER, '
    'spo2_raw_adc INTEGER, '
    'raw_hex TEXT NOT NULL, '
    'trim_cursor INTEGER, '
    'family TEXT)';

/// `rawFieldSample` AS IT EXISTED AT v4 — the new-in-v4 long-format capture table,
/// so a v4→v5 upgrade has only the new-in-v5 indexes left to add.
const _v4RawFieldSample =
    'CREATE TABLE rawFieldSample ('
    'device_id TEXT NOT NULL, '
    'ts INTEGER NOT NULL, '
    'key TEXT NOT NULL, '
    'int_value INTEGER, '
    'real_value REAL, '
    'PRIMARY KEY (device_id, ts, key))';

/// The v4 shape of the two remaining streams the new-in-v5 `ts` indexes target —
/// built WITHOUT any index, as every real pre-v5 build had them.
const _v4RrInterval =
    'CREATE TABLE rrInterval ('
    'device_id TEXT NOT NULL, '
    'ts INTEGER NOT NULL, '
    'rr_ms INTEGER NOT NULL, '
    'synced INTEGER NOT NULL DEFAULT 0, '
    'PRIMARY KEY (device_id, ts, rr_ms))';

const _v4SleepStateSample =
    'CREATE TABLE sleepStateSample ('
    'device_id TEXT NOT NULL, '
    'ts INTEGER NOT NULL, '
    'state INTEGER NOT NULL, '
    'PRIMARY KEY (device_id, ts))';

/// Column names on a table, from sqlite's own `table_info` pragma.
Future<Set<String>> _columns(AppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.map((r) => r.data['name'] as String).toSet();
}

/// Every index sqlite holds for [table], from its own `index_list` pragma — the
/// authority on whether the v5 step actually landed (and landed once).
Future<List<String>> _indexes(AppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA index_list($table)').get();
  return rows.map((r) => r.data['name'] as String).toList();
}

/// The four `ts` indexes new in v5, and the streams they belong to.
const _v5Indexes = <String, String>{
  'hrSample': 'ix_hr_sample_ts',
  'rrInterval': 'ix_rr_interval_ts',
  'gravitySample': 'ix_gravity_sample_ts',
  'sleepStateSample': 'ix_sleep_state_sample_ts',
};

/// Assert every new-in-v5 index exists EXACTLY once, and that sqlite will really
/// use it for the day-window range scan `LiveRepository._buildDays` issues.
///
/// Existence alone is not the property that matters: the index is there to keep
/// the per-day walk linear, and a `ts` range that falls back to a full table scan
/// would still pass a name check while making a 90-day reload ~58 s. So this also
/// reads sqlite's own query plan.
Future<void> _expectV5Indexes(AppDatabase db) async {
  for (final entry in _v5Indexes.entries) {
    final found = (await _indexes(db, entry.key))
        .where((n) => n == entry.value)
        .toList();
    expect(found, hasLength(1),
        reason: '${entry.key} must carry ${entry.value} exactly once — a second '
            'copy means a migration step ran that should not have');
  }
  final plan = await db
      .customSelect('EXPLAIN QUERY PLAN SELECT ts, bpm FROM hrSample '
          'WHERE ts >= 1000 AND ts < 2000')
      .get();
  expect(plan.map((r) => r.data['detail']).join(' '), contains('ix_hr_sample_ts'),
      reason: 'the day-window read must resolve through the ts index, not a scan');
}

Future<bool> _tableExists(AppDatabase db, String table) async {
  final rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
        variables: [Variable<String>(table)],
      )
      .get();
  return rows.isNotEmpty;
}

void main() {
  test('fresh install (onCreate) creates all v3 tables + columns', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    // Force the DB open (runs onCreate → createAll).
    await db.customSelect('SELECT 1').get();

    expect(await _tableExists(db, 'ppgRawSample'), isTrue);
    expect(await _tableExists(db, 'rawFieldSample'), isTrue);
    expect(await _columns(db, 'hrSample'),
        containsAll(['hr_fixed88', 'onwrist']));
    expect(await _columns(db, 'gravitySample'), contains('dynamic_accel'));
    expect(await _columns(db, 'raw_sensor_archive'),
        containsAll(['trim_cursor', 'family']));
    expect(await _columns(db, 'rawFieldSample'),
        containsAll(['device_id', 'ts', 'key', 'int_value', 'real_value']));
    // onCreate goes through createAll(), which creates indexes as well as tables.
    await _expectV5Indexes(db);
  });

  test('v4 → v5 upgrade adds ONLY the four ts indexes (nothing dropped)',
      () async {
    // A v4 DB: every table at its current shape, no index on any stream, plus rows
    // that PREDATE the upgrade — the additive-forever invariant means an
    // `adb install -r` must not lose a single one of them to an index migration.
    //
    // The seed rows go through `_seedOldDb` rather than a second open on purpose:
    // it stamps `user_version` AFTER its statements, and any later
    // `ensureOpen(_SeedUser())` would re-stamp the file back to _SeedUser's own
    // version 1 — silently turning this into a v1→v5 test.
    final file = await _seedOldDb(4, [
      _v3RawSensorArchive,
      _v3HrSample,
      _v3GravitySample,
      _v3PpgRawSample,
      _v4RawFieldSample,
      _v4RrInterval,
      _v4SleepStateSample,
      "INSERT INTO hrSample (device_id, ts, bpm) VALUES ('strap-1', 1700000000, 55)",
      "INSERT INTO rrInterval (device_id, ts, rr_ms) "
          "VALUES ('strap-1', 1700000000, 1090)",
    ]);
    addTearDown(() => file.parent.deleteSync(recursive: true));

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get(); // drives onUpgrade(4, 5)

    await _expectV5Indexes(db);
    // The pre-existing rows survived untouched.
    final hr = await db.select(db.whoopHrSamples).get();
    expect(hr.single.bpm, 55);
    expect(hr.single.ts, 1700000000);
    final rr = await db.select(db.whoopRrIntervals).get();
    expect(rr.single.rrMs, 1090);
  });

  test('v1 → v3 upgrade opens without throwing; new cols exist EXACTLY once',
      () async {
    // A v1 DB: raw_sensor_archive without v3 columns; NO whoop tables yet.
    final file = await _seedOldDb(1, [_v1RawSensorArchive]);
    addTearDown(() => file.parent.deleteSync(recursive: true));

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    // Opening drives the real onUpgrade(1, 3). Pre-fix this threw
    // "duplicate column name" and the DB never opened.
    await db.customSelect('SELECT 1').get();

    // The `from < 2` step created the whoop tables from the live v3 def, so the
    // new columns are present exactly once (the guarded `from == 2` skip means
    // they were NOT added a second time).
    final hr = await _columns(db, 'hrSample');
    expect(hr, containsAll(['hr_fixed88', 'onwrist']));
    expect(await _columns(db, 'gravitySample'), contains('dynamic_accel'));

    // New-in-v3 table + syncCursor + archive tags applied on the v1 path too.
    expect(await _tableExists(db, 'ppgRawSample'), isTrue);
    expect(await _tableExists(db, 'syncCursor'), isTrue);
    expect(await _columns(db, 'raw_sensor_archive'),
        containsAll(['trim_cursor', 'family']));
    // New-in-v4 long-format capture table applied on the v1 path too.
    expect(await _tableExists(db, 'rawFieldSample'), isTrue);
    // New-in-v5 indexes applied on the v1 path too, exactly once: the `from < 2`
    // step creates the stream TABLES from the live def, but `Migrator.createTable`
    // never creates a table's indexes (only `createAll()` does), so the `from < 5`
    // step is the sole creator on every upgrade path.
    await _expectV5Indexes(db);
  });

  test('v2 → v3 upgrade adds new-in-v3 columns/table to existing v2 tables',
      () async {
    // A v2 DB: raw_sensor_archive (v1 shape) + whoop tables built WITHOUT the
    // new-in-v3 columns — the branch that genuinely needs addColumn.
    // rrInterval/sleepStateSample are seeded too because a genuine v2 DB HAS them
    // (the `from < 2` step created every stream table): they have never changed
    // shape, so they are v2-accurate as written, and the v5 index step targets
    // them.
    final file = await _seedOldDb(2, [
      _v1RawSensorArchive,
      _v2HrSample,
      _v2GravitySample,
      _v4RrInterval,
      _v4SleepStateSample,
    ]);
    addTearDown(() => file.parent.deleteSync(recursive: true));

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get(); // drives onUpgrade(2, 3)

    final hr = await _columns(db, 'hrSample');
    expect(hr, containsAll(['hr_fixed88', 'onwrist']));
    expect(await _columns(db, 'gravitySample'), contains('dynamic_accel'));
    expect(await _tableExists(db, 'ppgRawSample'), isTrue);
    expect(await _tableExists(db, 'rawFieldSample'), isTrue);
    expect(await _columns(db, 'raw_sensor_archive'),
        containsAll(['trim_cursor', 'family']));
    await _expectV5Indexes(db);
  });

  test('v3 → v4 upgrade adds ONLY the new rawFieldSample table (idempotent)',
      () async {
    // A v3 DB: whoop tables + archive already carry all new-in-v3 columns; only the
    // new-in-v4 `rawFieldSample` table is missing. rrInterval/sleepStateSample are
    // seeded for the same reason as the v2 case above — a genuine v3 DB has them.
    final file = await _seedOldDb(3, [
      _v3RawSensorArchive,
      _v3HrSample,
      _v3GravitySample,
      _v3PpgRawSample,
      _v4RrInterval,
      _v4SleepStateSample,
    ]);
    addTearDown(() => file.parent.deleteSync(recursive: true));

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get(); // drives onUpgrade(3, 4)

    // The brand-new table exists; nothing pre-existing was duplicated/rewritten.
    expect(await _tableExists(db, 'rawFieldSample'), isTrue);
    expect(await _columns(db, 'rawFieldSample'),
        containsAll(['device_id', 'ts', 'key', 'int_value', 'real_value']));
    expect(await _columns(db, 'hrSample'),
        containsAll(['hr_fixed88', 'onwrist']));
    expect(await _columns(db, 'gravitySample'), contains('dynamic_accel'));

    // The migrated DB is usable: a raw-field insert round-trips.
    await db.insertWhoopRawFields([
      WhoopRawFieldSamplesCompanion.insert(
        deviceId: 'strap-1',
        ts: 1700000000,
        key: 'status_word',
        intValue: const Value(1792),
      ),
    ]);
    final rows = await db.select(db.whoopRawFieldSamples).get();
    expect(rows.single.intValue, 1792);
    expect(rows.single.realValue, null);
    await _expectV5Indexes(db);
  });

  test('migrated v1 DB is usable — round-trips a whoop HR insert', () async {
    final file = await _seedOldDb(1, [_v1RawSensorArchive]);
    addTearDown(() => file.parent.deleteSync(recursive: true));

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);

    // The point of the fix: the DB opens and works after the upgrade (the txn
    // was not rolled back).
    final n = await db.insertWhoopHr([
      const WhoopHrSamplesCompanion(
        deviceId: Value('strap-1'),
        ts: Value(1000),
        bpm: Value(60),
        hrFixed88: Value(15360),
        onwrist: Value(1),
      ),
    ]);
    expect(n, 1);
    final rows = await db.select(db.whoopHrSamples).get();
    expect(rows.single.hrFixed88, 15360);
    expect(rows.single.onwrist, 1);
  });
}
