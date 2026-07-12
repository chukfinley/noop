import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/ble/protocol/alarm_payload.dart';
import 'package:noop/core/ble/transport/whoop_ble_client.dart';
import 'package:noop/core/ble/transport/whoop_providers.dart';
import 'package:noop/core/data/db/database.dart';
import 'package:noop/core/state/providers.dart';

/// Smart-alarm write-side. The schedule is persisted to the drift store; when a [WhoopBleClient] is
/// wired the enabled alarm is also programmed onto the strap's OWN firmware wake slot over BLE
/// (smart-alarm spec §5), so it fires even with the phone away.
///
/// Honest status model (spec §5):
///  - **queued** — an alarm is enabled but no strap link has confirmed it yet (also the safe no-device
///    default: with no client, or disconnected, every write no-ops and the status stays queued).
///  - **armed**  — the strap ACKed our SET_ALARM_TIME ([WhoopBleClient.alarmArmed]); never written
///    optimistically.
///  - **fired**  — the strap ran its own wake haptic (live event 57, [WhoopBleClient.alarmFired]).
///
/// The strap has a single firmware-alarm slot, so we arm the EARLIEST enabled alarm's next occurrence
/// and disarm when none is enabled (spec §5 single-slot reconcile).
class AlarmService {
  AlarmService(this._db, [this._client]) {
    // Keep an in-memory view of the alarms so the transport's connect-time reconcile lookup can be
    // answered synchronously (it can't await the drift store).
    _alarmsSub = _db.watchAlarms().listen((rows) => _alarms = rows);
    final client = _client;
    if (client != null) {
      client.strapAlarmReconcileLookup = () => nextWakeFor(_alarms, DateTime.now());
      _armedSub = client.alarmArmed.listen((_) => unawaited(handleArmedAck()));
      _firedSub = client.alarmFired.listen((_) => unawaited(handleFired()));
    }
  }

  final AppDatabase _db;
  final WhoopBleClient? _client;

  List<Alarm> _alarms = const [];
  StreamSubscription<List<Alarm>>? _alarmsSub;
  StreamSubscription<void>? _armedSub;
  StreamSubscription<void>? _firedSub;

  Future<void> save({
    required String id,
    required int hour,
    required int minute,
    bool enabled = true,
    int daysMask = 0,
  }) async {
    await _db.upsertAlarm(AlarmsCompanion.insert(
      id: id,
      hour: hour,
      minute: minute,
      enabled: Value(enabled),
      daysMask: Value(daysMask),
      status: Value(enabled ? 'queued' : 'idle'),
    ));
    await _reconcileNow();
  }

  Future<void> setEnabled(Alarm a, bool on) => save(
        id: a.id,
        hour: a.hour,
        minute: a.minute,
        enabled: on,
        daysMask: a.daysMask,
      );

  Future<void> delete(String id) async {
    await _db.deleteAlarm(id);
    await _reconcileNow();
  }

  /// Recompute the single-slot target from the live DB and push it to the strap: arm the earliest
  /// enabled alarm's next occurrence, or DISABLE the slot when none is enabled. No-op without a client;
  /// off-link the transport no-ops so the status stays queued (spec §5).
  Future<void> _reconcileNow() async {
    final client = _client;
    if (client == null) return;
    final alarms = await _db.allAlarms();
    final wake = nextWakeFor(alarms, DateTime.now());
    if (wake == null) {
      await client.setStrapAlarm(DateTime.now(), enabled: false);
    } else {
      await client.setStrapAlarm(wake, enabled: true);
    }
  }

  /// The strap ACKed a SET_ALARM_TIME → mark the current single-slot target 'armed' (spec §5). Only a
  /// real ACK ([WhoopBleClient.alarmArmed]) reaches here, so 'armed' is never written optimistically.
  /// Reads the DB fresh so the write is deterministic (independent of the async watch cache).
  Future<void> handleArmedAck() async {
    final t = currentTarget(await _db.allAlarms(), DateTime.now());
    if (t != null) {
      await _setStatus(t, 'armed',
          lastArmedTs: DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// The strap fired its own wake haptic (live event 57) → mark the target 'fired', then re-arm the
  /// next occurrence (repeat alarms roll forward; a one-shot just re-arms to tomorrow harmlessly —
  /// twin of the Kotlin daily re-arm).
  Future<void> handleFired() async {
    final t = currentTarget(await _db.allAlarms(), DateTime.now());
    if (t != null) await _setStatus(t, 'fired');
    await _reconcileNow();
  }

  /// Update one alarm row's [status] (and optionally [lastArmedTs]) without disturbing its schedule,
  /// reusing the existing upsert (no new DB method needed).
  Future<void> _setStatus(Alarm a, String status, {int? lastArmedTs}) =>
      _db.upsertAlarm(AlarmsCompanion.insert(
        id: a.id,
        hour: a.hour,
        minute: a.minute,
        enabled: Value(a.enabled),
        daysMask: Value(a.daysMask),
        status: Value(status),
        lastArmedTs:
            Value(lastArmedTs ?? a.lastArmedTs),
      ));

  /// The enabled alarm whose next occurrence is soonest (the single-slot target), or null when none is
  /// enabled. Pure — unit-testable without a radio.
  static Alarm? currentTarget(List<Alarm> alarms, DateTime now) {
    Alarm? best;
    int? bestEpoch;
    for (final a in alarms) {
      if (!a.enabled) continue;
      final e = AlarmPayload.nextWakeEpochMs(
          a.hour, a.minute, now.millisecondsSinceEpoch,
          zoneOffset: now.timeZoneOffset);
      if (bestEpoch == null || e < bestEpoch) {
        bestEpoch = e;
        best = a;
      }
    }
    return best;
  }

  /// The next wake [DateTime] to arm (earliest enabled alarm's next occurrence), or null when none is
  /// enabled. Pure — unit-testable without a radio.
  static DateTime? nextWakeFor(List<Alarm> alarms, DateTime now) {
    final t = currentTarget(alarms, now);
    if (t == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(AlarmPayload.nextWakeEpochMs(
        t.hour, t.minute, now.millisecondsSinceEpoch,
        zoneOffset: now.timeZoneOffset));
  }

  void dispose() {
    _client?.strapAlarmReconcileLookup = null;
    _alarmsSub?.cancel();
    _armedSub?.cancel();
    _firedSub?.cancel();
  }
}

final alarmServiceProvider = Provider<AlarmService>((ref) {
  final svc = AlarmService(
    ref.watch(databaseProvider),
    ref.watch(whoopBleClientProvider),
  );
  ref.onDispose(svc.dispose);
  return svc;
});

/// Reactive list of saved alarms, ordered by time.
final alarmsProvider = StreamProvider<List<Alarm>>(
    (ref) => ref.watch(databaseProvider).watchAlarms());

/// Human status line for an alarm given the real strap-link state (spec §5).
String alarmStatusLabel(Alarm a) {
  if (!a.enabled) return 'Off';
  return switch (a.status) {
    'armed' => 'Armed on strap',
    'fired' => 'Fired',
    _ => 'Queued · arms on next strap connect',
  };
}
