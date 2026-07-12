import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/db/database.dart';
import 'package:noop/core/state/providers.dart';

/// Smart-alarm write-side. The schedule is persisted to the drift store; the
/// live-BLE arm/readback (setting the strap's own alarm, ryanbr #34) lands when
/// a BLE bridge exists. Until then an enabled alarm is reported as **queued** —
/// it will arm on the next strap connection — never falsely "armed".
class AlarmService {
  AlarmService(this._db);
  final AppDatabase _db;

  Future<void> save({
    required String id,
    required int hour,
    required int minute,
    bool enabled = true,
    int daysMask = 0,
  }) =>
      _db.upsertAlarm(AlarmsCompanion.insert(
        id: id,
        hour: hour,
        minute: minute,
        enabled: Value(enabled),
        daysMask: Value(daysMask),
        status: Value(enabled ? 'queued' : 'idle'),
      ));

  Future<void> setEnabled(Alarm a, bool on) => save(
        id: a.id,
        hour: a.hour,
        minute: a.minute,
        enabled: on,
        daysMask: a.daysMask,
      );

  Future<void> delete(String id) => _db.deleteAlarm(id);
}

final alarmServiceProvider =
    Provider<AlarmService>((ref) => AlarmService(ref.watch(databaseProvider)));

/// Reactive list of saved alarms, ordered by time.
final alarmsProvider = StreamProvider<List<Alarm>>(
    (ref) => ref.watch(databaseProvider).watchAlarms());

/// Human status line for an alarm given the (current) no-live-BLE reality.
String alarmStatusLabel(Alarm a) {
  if (!a.enabled) return 'Off';
  return switch (a.status) {
    'armed' => 'Armed on strap',
    'fired' => 'Fired',
    _ => 'Queued · arms on next strap connect',
  };
}
