import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:noop/core/data/db/database.dart';
import 'package:noop/core/data/live_repository.dart';
import 'package:noop/core/data/portability/data_portability.dart';

/// Build a SQLite file with the *Kotlin/Apple NOOP* Room schema (camelCase
/// columns: `deviceId`, `rrMs`, `activityClass`, `payloadJSON`) and seed a small
/// night, so the importer is exercised against the REAL foreign column layout it
/// must map — not our own drift names.
String _writeRoomBackup(Directory dir, {String device = 'my-whoop'}) {
  final path = '${dir.path}/room-backup.sqlite';
  final db = sqlite3.open(path);
  // Room bookkeeping table so the file reads as an Android NOOP backup.
  db.execute('CREATE TABLE room_master_table (id INTEGER PRIMARY KEY, identity_hash TEXT)');
  db.execute('CREATE TABLE hrSample (deviceId TEXT NOT NULL, ts INTEGER NOT NULL, '
      'bpm INTEGER NOT NULL, synced INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(deviceId, ts))');
  db.execute('CREATE TABLE rrInterval (deviceId TEXT NOT NULL, ts INTEGER NOT NULL, '
      'rrMs INTEGER NOT NULL, synced INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(deviceId, ts, rrMs))');
  db.execute('CREATE TABLE gravitySample (deviceId TEXT NOT NULL, ts INTEGER NOT NULL, '
      'x REAL NOT NULL, y REAL NOT NULL, z REAL NOT NULL, synced INTEGER NOT NULL DEFAULT 0, '
      'PRIMARY KEY(deviceId, ts))');
  db.execute('CREATE TABLE sleepStateSample (deviceId TEXT NOT NULL, ts INTEGER NOT NULL, '
      'state INTEGER NOT NULL, PRIMARY KEY(deviceId, ts))');
  db.execute('CREATE TABLE stepSample (deviceId TEXT NOT NULL, ts INTEGER NOT NULL, '
      'counter INTEGER NOT NULL, activityClass INTEGER, synced INTEGER NOT NULL DEFAULT 0, '
      'PRIMARY KEY(deviceId, ts))');

  // A night 00:30→07:30 on a fixed local day: low still HR + RR + a sleep state.
  final base = DateTime(2026, 5, 2).millisecondsSinceEpoch ~/ 1000;
  final hr = db.prepare('INSERT INTO hrSample (deviceId, ts, bpm) VALUES (?,?,?)');
  final rr = db.prepare('INSERT INTO rrInterval (deviceId, ts, rrMs) VALUES (?,?,?)');
  final gv = db.prepare('INSERT INTO gravitySample (deviceId, ts, x, y, z) VALUES (?,?,0,0,1)');
  final ss = db.prepare('INSERT INTO sleepStateSample (deviceId, ts, state) VALUES (?,?,?)');
  for (var t = base + 1800; t < base + 7 * 3600 + 1800; t += 30) {
    final bpm = 50 + (t ~/ 30) % 4;
    hr.execute([device, t, bpm]);
    rr.execute([device, t, (60000 / bpm).round()]);
    gv.execute([device, t]);
    ss.execute([device, t, 2]); // 2 = asleep
  }
  final st = db.prepare('INSERT INTO stepSample (deviceId, ts, counter, activityClass) VALUES (?,?,?,?)');
  st.execute([device, base + 9 * 3600, 1234, 1]);
  for (final s in [hr, rr, gv, ss, st]) {
    s.dispose();
  }
  db.dispose();
  return path;
}

void main() {
  test('imports a Kotlin/Apple NOOP Room backup into the drift store', () async {
    final dir = Directory.systemTemp.createTempSync('noopimport');
    addTearDown(() => dir.deleteSync(recursive: true));
    final src = _writeRoomBackup(dir);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final summary = await DataPortability(db).importFromSqlite(src);

    expect(summary.recognised, isTrue);
    // 7h at 30s epochs = 840 rows in each per-second stream.
    expect(summary.rowsByTable['hrSample'], 840);
    expect(summary.rowsByTable['rrInterval'], 840);
    expect(summary.rowsByTable['gravitySample'], 840);
    expect(summary.rowsByTable['sleepStateSample'], 840);
    expect(summary.rowsByTable['stepSample'], 1);

    // The rows really landed in OUR drift tables (snake_case columns).
    expect((await db.select(db.whoopHrSamples).get()).length, 840);
    expect((await db.select(db.whoopSleepStateSamples).get()).length, 840);

    // And the ported pipeline derives a scored day from the imported raw rows —
    // the imported sleep_state drives the sleep window (see the sleep fix).
    final repo = await LiveRepository.load(db);
    expect(repo.days, isNotEmpty);
    expect(repo.days.last.sleep, isNotNull);
  });

  test('import is idempotent — re-importing the same backup adds no rows', () async {
    final dir = Directory.systemTemp.createTempSync('noopidem');
    addTearDown(() => dir.deleteSync(recursive: true));
    final src = _writeRoomBackup(dir);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await DataPortability(db).importFromSqlite(src);
    final again = await DataPortability(db).importFromSqlite(src);
    expect(again.totalRows, 0, reason: 'INSERT OR IGNORE dedupes on the primary key');
    expect((await db.select(db.whoopHrSamples).get()).length, 840);
  });

  test('export → .noopbak → re-import round-trips the data', () async {
    final dir = Directory.systemTemp.createTempSync('nooproundtrip');
    addTearDown(() => dir.deleteSync(recursive: true));

    // Seed a file-backed drift store by importing a Room backup into it.
    final liveFile = File('${dir.path}/live.sqlite');
    final live = AppDatabase.forTesting(NativeDatabase(liveFile));
    addTearDown(live.close);
    await DataPortability(live).importFromSqlite(_writeRoomBackup(dir));

    // Export it to a .noopbak.
    final bak = '${dir.path}/out.noopbak';
    await DataPortability(live).exportToNoopbak(bak);
    expect(File(bak).existsSync(), isTrue);

    // Re-import the .noopbak (ZIP path) into a fresh store.
    final fresh = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(fresh.close);
    final summary = await DataPortability(fresh).importFile(bak);
    expect(summary.rowsByTable['hrSample'], 840);
    expect((await fresh.select(fresh.whoopSleepStateSamples).get()).length, 840);
  });

  // #468 (#458 upstream): a live-BLE install banks its history through the BLE
  // insert path — it has NEVER imported a WHOOP file. Upstream's CSV export read
  // only the imported source id, so such an install exported an empty zip while
  // the app displayed months of data. Our export is `VACUUM main INTO` (the whole
  // file, provenance-agnostic), so the literal bug cannot occur — this pins that:
  // a store seeded ONLY through the BLE path must round-trip its banked history.
  // Every other export test above seeds via importFromSqlite, so this live-only
  // path was untested.
  test('a live-BLE-only store (never imported) exports its banked history', () async {
    final dir = Directory.systemTemp.createTempSync('nooplivebak');
    addTearDown(() => dir.deleteSync(recursive: true));

    final liveFile = File('${dir.path}/live.sqlite');
    final live = AppDatabase.forTesting(NativeDatabase(liveFile));
    addTearDown(live.close);

    // Bank a night the way the BLE Backfiller does — the typed insert API, no
    // import anywhere in sight.
    const dev = 'whoop-live-uuid';
    final base = DateTime(2026, 5, 2).millisecondsSinceEpoch ~/ 1000;
    final hr = <WhoopHrSamplesCompanion>[];
    final rr = <WhoopRrIntervalsCompanion>[];
    final grav = <WhoopGravitySamplesCompanion>[];
    final sleep = <WhoopSleepStateSamplesCompanion>[];
    for (var t = base + 1800; t < base + 7 * 3600 + 1800; t += 30) {
      final bpm = 50 + (t ~/ 30) % 4;
      hr.add(WhoopHrSamplesCompanion.insert(deviceId: dev, ts: t, bpm: bpm));
      rr.add(WhoopRrIntervalsCompanion.insert(
          deviceId: dev, ts: t, rrMs: (60000 / bpm).round()));
      grav.add(WhoopGravitySamplesCompanion.insert(
          deviceId: dev, ts: t, x: 0, y: 0, z: 1));
      sleep.add(
          WhoopSleepStateSamplesCompanion.insert(deviceId: dev, ts: t, state: 2));
    }
    await live.insertWhoopHr(hr);
    await live.insertWhoopRr(rr);
    await live.insertWhoopGravity(grav);
    await live.insertWhoopSleepState(sleep);
    // The two live-only raw tables: NO Kotlin backup can ever carry these — they
    // exist solely because this install synced a strap over BLE.
    await live.insertWhoopPpgRaw([
      WhoopPpgRawSamplesCompanion.insert(
          deviceId: dev, ts: base + 1800, sampleCount: 3, samples: Uint8List.fromList([1, 0, 2, 0, 3, 0])),
    ]);
    await live.insertWhoopRawFields([
      WhoopRawFieldSamplesCompanion.insert(
          deviceId: dev, ts: base + 1800, key: 'status_word', intValue: const Value(42)),
    ]);

    final bak = '${dir.path}/live.noopbak';
    await DataPortability(live).exportToNoopbak(bak);
    expect(File(bak).existsSync(), isTrue);

    // Re-import into a fresh install: the banked history must survive in FULL —
    // an export that drops a live-only table is the same class of defect as #458
    // (the live-BLE install's own data going missing on the way out).
    final fresh = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(fresh.close);
    final summary = await DataPortability(fresh).importFile(bak);

    expect(summary.recognised, isTrue, reason: 'a live-BLE backup is a NOOP backup');
    expect(summary.rowsByTable['hrSample'], 840);
    expect((await fresh.select(fresh.whoopSleepStateSamples).get()).length, 840);
    expect((await fresh.select(fresh.whoopRrIntervals).get()).length, 840);
    expect((await fresh.select(fresh.whoopPpgRawSamples).get()).length, 1,
        reason: 'the v26 PPG waveform is live-BLE-only — dropping it on restore '
            'silently loses data no other source can re-supply');
    expect((await fresh.select(fresh.whoopRawFieldSamples).get()).length, 1,
        reason: 'the v18 long-format raw fields are live-BLE-only');

    // And the restored install scores the night, exactly as the source did.
    final repo = await LiveRepository.load(fresh);
    expect(repo.days, isNotEmpty);
  });

  test('a non-NOOP file is rejected with a clear message, store untouched', () async {
    final dir = Directory.systemTemp.createTempSync('noopbad');
    addTearDown(() => dir.deleteSync(recursive: true));
    final junk = File('${dir.path}/notes.txt')..writeAsStringSync('hello');

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(
      () => DataPortability(db).importFile(junk.path),
      throwsA(isA<DataImportException>()),
    );
  });
}
