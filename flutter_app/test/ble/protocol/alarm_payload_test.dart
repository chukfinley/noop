import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/alarm_payload.dart';

/// Faithful Dart port of `AlarmPayloadTest.kt`.
///
/// Byte-exact tests for the WHOOP 5.0/MG firmware wake-alarm payload encoder [AlarmPayload]. The
/// expected vectors are the protocol's own wire-format facts (command numbers, field offsets, byte
/// values) modelled on the official app. The Kotlin uses `ZoneId.of("UTC")`; this port passes the
/// default `zoneOffset` (Duration.zero = UTC), so `nowMs()` and every wake time are computed in UTC.
void main() {
  /// Fixed "now": 2026-06-07 08:00:00 UTC.
  int nowMs() => DateTime.utc(2026, 6, 7, 8, 0).millisecondsSinceEpoch;

  Uint8List bytes(List<int> ints) => Uint8List.fromList(ints.map((i) => i & 0xFF).toList());

  test('alarm_headerAndLength', () {
    final body =
        AlarmPayload.build(AlarmPayload.nextWakeEpochMs(18, 30, nowMs()), alarmId: 1);
    expect(body.length, 20); // 2 header + 4 u32 + 2 u16 + 12 haptics
    expect(body[0], 4); // REVISION_4
    expect(body[1], 1); // alarmId
  });

  test('alarm_secondsAreU32Le', () {
    final wake = AlarmPayload.nextWakeEpochMs(18, 30, nowMs());
    final body = AlarmPayload.build(wake);
    final le = (body[2] & 0xFF) |
        ((body[3] & 0xFF) << 8) |
        ((body[4] & 0xFF) << 16) |
        ((body[5] & 0xFF) << 24);
    expect(le, wake ~/ 1000);
  });

  test('alarm_subsecondsAreU16LeFixedPoint', () {
    // 123 ms remainder → (123*32768)/1000 = 4030 → 0x0FBE → LE [BE, 0F]
    final body = AlarmPayload.build(1700000000000 + 123);
    final expected = (123 * 32768) ~/ 1000; // 4030
    final sub = (body[6] & 0xFF) | ((body[7] & 0xFF) << 8);
    expect(sub, expected);
  });

  test('alarm_hapticsTailMatchesOfficialAlarmPattern', () {
    // [8 effects (47,152,…)][u16 LE loopControl=0][overallLoop=7][durationSeconds=30]
    final body = AlarmPayload.build(AlarmPayload.nextWakeEpochMs(7, 15, nowMs()));
    final tail = Uint8List.sublistView(body, body.length - 12, body.length);
    final expected = bytes(<int>[47, 152, 0, 0, 0, 0, 0, 0, 0, 0, 7, 30]);
    expect(tail, expected);
  });

  test('alarm_defaultAlarmIdIsOne', () {
    expect(AlarmPayload.build(nowMs())[1], 1);
  });

  test('nextWake_laterToday_staysToday', () {
    final wake = AlarmPayload.nextWakeEpochMs(18, 30, nowMs());
    final zdt = DateTime.fromMillisecondsSinceEpoch(wake, isUtc: true);
    expect(zdt.year, 2026);
    expect(zdt.month, 6);
    expect(zdt.day, 7);
    expect(zdt.hour, 18);
    expect(zdt.minute, 30);
    expect(wake > nowMs(), isTrue);
  });

  test('nextWake_earlierThanNow_rollsToTomorrow', () {
    final wake = AlarmPayload.nextWakeEpochMs(6, 0, nowMs());
    final zdt = DateTime.fromMillisecondsSinceEpoch(wake, isUtc: true);
    expect(zdt.year, 2026);
    expect(zdt.month, 6);
    expect(zdt.day, 8);
    expect(wake > nowMs(), isTrue);
  });

  test('nextWake_equalToNow_rollsToTomorrow', () {
    final wake = AlarmPayload.nextWakeEpochMs(8, 0, nowMs());
    final zdt = DateTime.fromMillisecondsSinceEpoch(wake, isUtc: true);
    expect(zdt.year, 2026);
    expect(zdt.month, 6);
    expect(zdt.day, 8);
  });

  test('disableAlarm_rev2_isSentinelFF', () {
    expect(AlarmPayload.disableRev2(), bytes(<int>[0x02, 0xFF]));
  });
}
