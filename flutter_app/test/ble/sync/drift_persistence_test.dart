import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';
import 'package:noop/core/ble/sync/backfiller.dart';
import 'package:noop/core/ble/sync/stream_persistence.dart';
import 'package:noop/core/data/db/database.dart';

/// Headless drift round-trip for the WHOOP sync tables: build a [StreamBatch], persist it via
/// [DriftStreamRepository] (the `WhoopRepository.insert` port) into an in-memory [AppDatabase], and
/// read the rows back. Mirrors the in-memory DB setup in `test/db/database_test.dart` — no platform
/// channels, no app launch.
void main() {
  late AppDatabase db;
  late DriftStreamRepository repo;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftStreamRepository(db);
  });
  tearDown(() async => db.close());

  test('the sync schema opens and every WHOOP stream table is empty', () async {
    expect(await db.select(db.whoopHrSamples).get(), isEmpty);
    expect(await db.select(db.whoopGravitySamples).get(), isEmpty);
    expect(await db.getSyncCursor(Backfiller.strapTrimCursor), isNull);
  });

  test('a StreamBatch round-trips through DriftStreamRepository', () async {
    final batch = StreamBatch(
      hr: [const HrRow(1700000000, 60), const HrRow(1700000001, 61)],
      rr: [const RrRow(1700000000, 850), const RrRow(1700000000, 855)],
      events: [const EventEntry(1700000002, 'WRIST_OFF(10)', '{"a":1}')],
      battery: [const BatteryRow(ts: 1700000003, soc: 88, mv: 4100, charging: true)],
      spo2: [const Spo2Row(1700000004, 97, 12)],
      skinTemp: [const SkinTempRow(1700000005, 3327)],
      steps: [const StepRow(1700000006, 1234, activityClass: 1)],
      sleepState: [const SleepStateRow(1700000007, 2)],
      resp: [const RespRow(1700000008, 512)],
      gravity: [const GravityRow(1700000009, x: 0.1, y: 0.2, z: 0.98)],
      ppgHr: [const PpgHrRow(ts: 1700000010, bpm: 62, conf: 0.7)],
    );

    final counts = await repo.insert(batch, 'my-whoop');

    // hr = measured HR + v26 PPG-derived HR (folded), matching WhoopRepository.insert.
    expect(counts.hr, 3);
    expect(counts.rr, 2);
    expect(counts.events, 1);
    expect(counts.battery, 1);
    expect(counts.spo2, 1);
    expect(counts.skinTemp, 1);
    expect(counts.steps, 1);
    expect(counts.resp, 1);
    expect(counts.gravity, 1);

    final hrRows = await db.select(db.whoopHrSamples).get();
    expect(hrRows.map((r) => (r.deviceId, r.ts, r.bpm)),
        containsAll([('my-whoop', 1700000000, 60), ('my-whoop', 1700000001, 61)]));
    // Two R-R at the same ts land under the composite (deviceId, ts, rrMs) key.
    expect(await db.select(db.whoopRrIntervals).get(), hasLength(2));
    final battery = (await db.select(db.whoopBattery).get()).single;
    expect((battery.soc, battery.mv, battery.charging), (88, 4100, true));
    final grav = (await db.select(db.whoopGravitySamples).get()).single;
    expect((grav.x, grav.y, grav.z), (0.1, 0.2, 0.98));
    expect((await db.select(db.whoopSleepStateSamples).get()).single.state, 2);
    expect((await db.select(db.whoopStepSamples).get()).single.activityClass, 1);
    expect((await db.select(db.whoopPpgHrSamples).get()).single.bpm, 62);
    expect((await db.select(db.whoopEvents).get()).single.payloadJson, '{"a":1}');
  });

  test('re-inserting the same batch is idempotent (natural-key IGNORE)', () async {
    final batch = StreamBatch(hr: [const HrRow(1700000000, 60)]);
    final first = await repo.insert(batch, 'my-whoop');
    final second = await repo.insert(batch, 'my-whoop');
    expect(first.hr, 1); // newly inserted
    expect(second.hr, 0); // already present → ignored, not counted
    expect(await db.select(db.whoopHrSamples).get(), hasLength(1));
  });

  test('trim-cursor KV round-trips (DriftTrimCursorStore)', () async {
    final store = DriftTrimCursorStore(db);
    expect(await store.get(Backfiller.strapTrimCursor), isNull);
    await store.set(Backfiller.strapTrimCursor, 112193);
    expect(await store.get(Backfiller.strapTrimCursor), 112193);
    await store.set(Backfiller.strapTrimCursor, 999999); // last-write-wins
    expect(await store.get(Backfiller.strapTrimCursor), 999999);
  });

  test('an empty batch inserts nothing and returns zeroed counts', () async {
    final counts = await repo.insert(StreamBatch(), 'my-whoop');
    expect(counts.hr, 0);
    expect(await db.select(db.whoopHrSamples).get(), isEmpty);
  });
}
