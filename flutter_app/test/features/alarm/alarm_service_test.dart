import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/data/db/database.dart';
import 'package:noop/features/alarm/state/alarm.dart';

/// Radio-free tests for the smart-alarm write-side status model (spec §5). With no [WhoopBleClient]
/// injected, every BLE write no-ops so the status stays honestly "queued" — exactly today's contract —
/// while the single-slot target selection and the armed/fired DB transitions are exercised directly.
void main() {
  late AppDatabase db;
  late AlarmService svc;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    svc = AlarmService(db); // no client → no radio
  });
  tearDown(() async {
    svc.dispose();
    await db.close();
  });

  Future<Alarm> row(String id) async =>
      (await db.allAlarms()).firstWhere((a) => a.id == id);

  test('enabling an alarm with no strap link stays queued (safe no-device default)', () async {
    await svc.save(id: 'a', hour: 6, minute: 30);
    expect((await row('a')).status, 'queued');
  });

  test('disabling an alarm sets it idle', () async {
    await svc.save(id: 'a', hour: 6, minute: 30);
    final a = await row('a');
    await svc.setEnabled(a, false);
    expect((await row('a')).status, 'idle');
  });

  test('currentTarget picks the enabled alarm whose next occurrence is soonest', () async {
    await svc.save(id: 'early', hour: 6, minute: 30);
    await svc.save(id: 'late', hour: 7, minute: 0);
    final now = DateTime(2026, 1, 1, 5, 0); // both later today → 06:30 wins
    final target = AlarmService.currentTarget(await db.allAlarms(), now);
    expect(target?.id, 'early');
  });

  test('currentTarget ignores disabled alarms', () async {
    await svc.save(id: 'off', hour: 6, minute: 0, enabled: false);
    await svc.save(id: 'on', hour: 8, minute: 0);
    final now = DateTime(2026, 1, 1, 5, 0);
    expect(AlarmService.currentTarget(await db.allAlarms(), now)?.id, 'on');
  });

  test('nextWakeFor is null when nothing is enabled', () async {
    await svc.save(id: 'off', hour: 6, minute: 0, enabled: false);
    expect(AlarmService.nextWakeFor(await db.allAlarms(), DateTime(2026, 1, 1, 5, 0)), isNull);
  });

  test('handleArmedAck flips the target queued→armed and stamps lastArmedTs', () async {
    await svc.save(id: 'a', hour: 6, minute: 30);
    expect((await row('a')).status, 'queued');
    await svc.handleArmedAck();
    final a = await row('a');
    expect(a.status, 'armed');
    expect(a.lastArmedTs, isNotNull);
  });

  test('handleFired flips the target to fired', () async {
    await svc.save(id: 'a', hour: 6, minute: 30);
    await svc.handleArmedAck();
    expect((await row('a')).status, 'armed');
    await svc.handleFired();
    expect((await row('a')).status, 'fired');
  });

  test('alarmStatusLabel maps the real states honestly', () async {
    await svc.save(id: 'a', hour: 6, minute: 30);
    expect(alarmStatusLabel(await row('a')), startsWith('Queued'));
    await svc.handleArmedAck();
    expect(alarmStatusLabel(await row('a')), 'Armed on strap');
    await svc.handleFired();
    expect(alarmStatusLabel(await row('a')), 'Fired');
    final a = await row('a');
    await svc.setEnabled(a, false);
    expect(alarmStatusLabel(await row('a')), 'Off');
  });
}
