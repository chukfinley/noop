import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/data/db/database.dart';

/// Migration tests for [AppDatabase] (schemaVersion 3).
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

/// Column names on a table, from sqlite's own `table_info` pragma.
Future<Set<String>> _columns(AppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.map((r) => r.data['name'] as String).toSet();
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
    expect(await _columns(db, 'hrSample'),
        containsAll(['hr_fixed88', 'onwrist']));
    expect(await _columns(db, 'gravitySample'), contains('dynamic_accel'));
    expect(await _columns(db, 'raw_sensor_archive'),
        containsAll(['trim_cursor', 'family']));
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
  });

  test('v2 → v3 upgrade adds new-in-v3 columns/table to existing v2 tables',
      () async {
    // A v2 DB: raw_sensor_archive (v1 shape) + whoop tables built WITHOUT the
    // new-in-v3 columns — the branch that genuinely needs addColumn.
    final file = await _seedOldDb(
        2, [_v1RawSensorArchive, _v2HrSample, _v2GravitySample]);
    addTearDown(() => file.parent.deleteSync(recursive: true));

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    await db.customSelect('SELECT 1').get(); // drives onUpgrade(2, 3)

    final hr = await _columns(db, 'hrSample');
    expect(hr, containsAll(['hr_fixed88', 'onwrist']));
    expect(await _columns(db, 'gravitySample'), contains('dynamic_accel'));
    expect(await _tableExists(db, 'ppgRawSample'), isTrue);
    expect(await _columns(db, 'raw_sensor_archive'),
        containsAll(['trim_cursor', 'family']));
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
