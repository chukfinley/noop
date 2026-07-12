import 'dart:typed_data';

/// Faithful Dart port of `AlarmPayload.kt`.
///
/// WHOOP 5.0/MG ("puffin") firmware wake-alarm command payload encoder.
///
/// These are WHOOP 5.0/MG protocol facts — command numbers, field offsets, byte layouts — documented
/// as factual wire-format observations for interoperability; no proprietary code is reproduced.
/// (Adopted from PR #85, iHateSubscriptions.)
///
/// EXPERIMENTAL / UNCONFIRMED: unlike the maverick buzz (hardware-confirmed on a real MG), the rev4
/// alarm layout below is self-consistent and modelled on the official app but has NOT been confirmed
/// to actually wake a strap on our side (no captured STRAP_DRIVEN_ALARM_EXECUTED event). The caller
/// therefore gates it behind the Experimental opt-in so a normal user can't rely on an alarm that
/// might silently not fire. All multi-byte fields are little-endian.
///
/// Kotlin uses `java.time.ZoneId` for the wall-clock zone. This pure-Dart port takes a fixed UTC
/// offset ([zoneOffset], default `Duration.zero` = UTC) instead — Dart's core `DateTime` supports
/// only UTC/system-local, not arbitrary IANA zones without a package. For a wake within the next 24h
/// a fixed offset is equivalent to the Kotlin behaviour (the UTC-based unit tests are unchanged).
class AlarmPayload {
  AlarmPayload._();

  static const int _overallLoop = 7; // overallWaveformLoopControl (alarm pattern)
  static const int _durationSeconds = 30; // alarmDurationInSeconds

  /// The canonical WHOOP wake waveform-effect pair (same 47/152 the notification buzz uses).
  static final Uint8List _waveformEffects =
      Uint8List.fromList(<int>[47, 152, 0, 0, 0, 0, 0, 0]);

  /// Next future epoch-millis for local wake [hour]:[minute], relative to [nowMs] in [zoneOffset].
  /// Today's occurrence if strictly in the future, else tomorrow's (next occurrence after now).
  static int nextWakeEpochMs(
    int hour,
    int minute,
    int nowMs, {
    Duration zoneOffset = Duration.zero,
  }) {
    final offMs = zoneOffset.inMilliseconds;
    // Wall clock in the target zone, carried as a UTC-labelled DateTime.
    final wall = DateTime.fromMillisecondsSinceEpoch(nowMs + offMs, isUtc: true);
    final candidateWall = DateTime.utc(wall.year, wall.month, wall.day, hour, minute);
    final candidateEpoch = candidateWall.millisecondsSinceEpoch - offMs;
    // Today's occurrence if strictly in the future, else tomorrow's.
    final target = candidateEpoch > nowMs
        ? candidateEpoch
        : candidateEpoch + const Duration(days: 1).inMilliseconds;
    return target;
  }

  /// SET_ALARM_TIME (cmd 66) REVISION_4 body — 20 bytes; the strap arms its own RTC and fires the
  /// wake haptic itself (a strap-driven wake event) even with the phone away. Wire layout:
  /// ```
  ///   [0]      0x04 (REVISION_4)
  ///   [1]      alarmId
  ///   [2..5]   u32 LE epoch seconds
  ///   [6..7]   u16 LE subseconds = (ms % 1000) * 32768 / 1000   (1/32768-s fixed point)
  ///   [8..19]  haptic pattern: 8 effects + u16 LE loopControl(0) + overallLoop(7) + duration(30)
  /// ```
  static Uint8List build(int wakeEpochMs, {int alarmId = 1}) {
    final seconds = wakeEpochMs ~/ 1000;
    final subseconds = ((wakeEpochMs % 1000) * 32768) ~/ 1000; // u16 fixed point
    final out = Uint8List(20);
    out[0] = 4; // REVISION_4
    out[1] = alarmId & 0xFF;
    out[2] = seconds & 0xFF;
    out[3] = (seconds >> 8) & 0xFF;
    out[4] = (seconds >> 16) & 0xFF;
    out[5] = (seconds >> 24) & 0xFF;
    out[6] = subseconds & 0xFF;
    out[7] = (subseconds >> 8) & 0xFF;
    out.setRange(8, 16, _waveformEffects);
    out[16] = 0x00; // loopControlForEffects LE lo
    out[17] = 0x00; // loopControlForEffects LE hi
    out[18] = _overallLoop;
    out[19] = _durationSeconds;
    return out;
  }

  /// DISABLE_ALARM (cmd 69) REVISION_2 body `[0x02, 0xFF]` (the 5/MG form).
  static Uint8List disableRev2() => Uint8List.fromList(<int>[0x02, 0xFF]);
}
