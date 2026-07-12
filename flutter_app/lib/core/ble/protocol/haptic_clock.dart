import 'dart:math' as math;
import 'dart:typed_data';

/// DRV2625 haptic-pattern WIRE PAYLOADS — the bytes a "buzz" command carries (device-config-and-haptics
/// spec §5/§6). Pure, no I/O: body-out only; the transport frames these for the family and writes them.
///
/// Confirmed byte-for-byte from the decompiled official WHOOP app (`NotificationHapticsPattern` +
/// `h0`) and the Kotlin `WhoopBleClient` reference — the same "notify" preset (effects 47 & 152) drives
/// both the notification buzz here and the alarm wake in `alarm_payload.dart`.
class HapticPattern {
  HapticPattern._();

  /// The two DRV2625 waveform-library sequence entries the "notify"/wake preset uses. Only these two of
  /// the eight effect slots are populated; the rest are zero. Kept in lock-step with
  /// `alarm_payload.dart` (which embeds the same pair in the strap-armed alarm haptic).
  static const int notifyEffect1 = 47;
  static const int notifyEffect2 = 152;

  /// The 12-byte WHOOP 5.0/MG "maverick" notification-haptic body (LITTLE_ENDIAN), confirmed from the
  /// official app: `[0x01 lead][8×waveFormEffect u8][loopControlForEffects u16 LE][overallWaveformLoop
  /// u8]`. The notify preset = effects 47,152 then six zeros, loop 0, overall 0. This is exactly the
  /// body the 5/MG one-shot buzz (`RUN_HAPTIC_PATTERN_MAVERICK`, cmd 0x13) carries; a raw legacy 79 is
  /// rejected on real MG hardware (spec §6.2), so the transport sends 0x13 with these bytes on 5/MG.
  static Uint8List maverickNotifyBody() => Uint8List.fromList(<int>[
        0x01,
        notifyEffect1,
        notifyEffect2,
        0, 0, 0, 0, 0, 0, // effects 3..8
        0, 0, // loopControlForEffects u16 LE
        0, // overallWaveformLoopControl
      ]);

  /// The 5-byte WHOOP 4.0 legacy `RUN_HAPTICS_PATTERN` (cmd 79) body: `[patternId, loops, 0, 0, 0]`.
  /// `patternId` 2 is the graduated buzz the official app uses for a locate/notify tap (spec §6.1).
  /// [loops] is clamped to a byte.
  static Uint8List whoop4BuzzBody({int patternId = 2, int loops = 3}) =>
      Uint8List.fromList(
          <int>[patternId & 0xFF, loops.clamp(0, 255) & 0xFF, 0, 0, 0]);
}

/// Faithful Dart port of `HapticClock.kt`.
///
/// Haptic Clock (#460): turn a wall-clock time into a deterministic list of wrist buzzes so a user
/// can read the time off the strap without looking at a screen — a long pulse counts tens, a short
/// pulse counts units, in the order hour-tens, hour-units, minute-tens, minute-units.
///
/// This is a PURE, platform-agnostic encoder: time-in, pulse-list-out, no I/O and no BLE. Kotlin
/// twin of the Apple `HapticClock.swift`; the two pulse lists are pinned identical by matching unit
/// tests on both platforms (e.g. 3:25 → the same list).
///
/// Reading the buzzes:
///  - LONG pulse  = one "ten"   in the current digit group
///  - SHORT pulse = one "unit"  in the current digit group
///  - a short gap separates pulses; a long gap separates the four digit groups (HH-tens, HH-units,
///    MM-tens, MM-units); an extra-long gap separates the hour block from the minute block.
///  - a digit of 0 emits NO pulse — the group is signalled only by the surrounding group gaps.
class HapticClock {
  HapticClock._();

  // Pulse + gap timing (ms). Kept in lock-step with HapticClock.swift — change both together.
  static const int longMs = 550; // a "tens" pulse
  static const int shortMs = 200; // a "units" pulse
  static const int intraGapMs = 450; // silence between two pulses inside one digit group
  static const int groupGapMs = 900; // silence between adjacent digit groups
  static const int blockGapMs = 1500; // silence between the hour block and the minute block

  /// Encode [hour]:[minute] into the buzz schedule.
  ///
  /// [hour] hour of day, 0..23 (24-hour input — the app already stores wall time this way).
  /// [minute] minute of hour, 0..59.
  /// [is24h] if `false`, the hour is mapped to 12-hour clock form (12,1..11) before encoding so
  ///   the wrist count matches a 12-hour face. AM/PM is NOT signalled; only the dial reading is buzzed.
  /// Returns the ordered pulse list. Empty only for the degenerate all-zero 24h midnight 0:00, which
  /// has no pulses to emit; callers should treat an empty list as "nothing to buzz".
  static List<Pulse> pulses(int hour, int minute, {required bool is24h}) {
    // Clamp defensively rather than throw — this can be driven from a stored pref or a strap tap.
    final h24 = hour.clamp(0, 23);
    final m = minute.clamp(0, 59);
    final displayHour = is24h ? h24 : twelveHour(h24);

    final hourTens = displayHour ~/ 10;
    final hourUnits = displayHour % 10;
    final minTens = m ~/ 10;
    final minUnits = m % 10;

    final out = <Pulse>[];

    // Hour block: tens group, then units group.
    _appendGroup(out, hourTens, longMs);
    _closeGroup(out, groupGapMs);
    _appendGroup(out, hourUnits, shortMs);
    // Separate hour block from minute block with the longer block gap.
    _closeGroup(out, blockGapMs);

    // Minute block: tens group, then units group.
    _appendGroup(out, minTens, longMs);
    _closeGroup(out, groupGapMs);
    _appendGroup(out, minUnits, shortMs);

    // The final pulse needs no trailing gap — trim it so the sequence ends on a buzz.
    if (out.isNotEmpty) {
      final last = out[out.length - 1];
      out[out.length - 1] = last.copyWith(gapMs: 0);
    }
    return out;
  }

  /// 24-hour hour → 12-hour dial reading (0→12, 13→1 … 23→11). Noon stays 12.
  static int twelveHour(int h24) {
    final h = h24 % 12;
    return h == 0 ? 12 : h;
  }

  /// Append [count] identical pulses (each duration [durationMs]) separated by the intra-group gap.
  static void _appendGroup(List<Pulse> out, int count, int durationMs) {
    if (count <= 0) return;
    for (var i = 0; i < count; i++) {
      out.add(Pulse(durationMs, intraGapMs));
    }
  }

  /// Widen the trailing pulse's gap to at least [gapMs] (a group/block separator). If nothing has
  /// been emitted yet (a leading zero digit group, e.g. minute-tens of 0), there is no pulse to
  /// widen — the missing pulse is itself the "0", and the surrounding gaps still bound the groups,
  /// so this is a no-op. We take the MAX rather than overwrite so that when later groups are empty
  /// (e.g. 12:00 has no minute pulses) an earlier, wider block separator isn't clobbered by a
  /// narrower group separator that follows it on the same trailing pulse.
  static void _closeGroup(List<Pulse> out, int gapMs) {
    if (out.isEmpty) return;
    final last = out[out.length - 1];
    out[out.length - 1] = last.copyWith(gapMs: math.max(last.gapMs, gapMs));
  }
}

/// One buzz instruction: buzz the wrist for [durationMs], then stay silent for [gapMs].
class Pulse {
  final int durationMs;
  final int gapMs;

  const Pulse(this.durationMs, this.gapMs);

  /// Whether this is a "tens" pulse (long buzz) versus a "units" pulse (short). Swift twin:
  /// `Pulse.isLong`. Lets the trigger weight the buzz without knowing the timing table.
  bool get isLong => durationMs >= HapticClock.longMs;

  Pulse copyWith({int? durationMs, int? gapMs}) =>
      Pulse(durationMs ?? this.durationMs, gapMs ?? this.gapMs);

  @override
  bool operator ==(Object other) =>
      other is Pulse && other.durationMs == durationMs && other.gapMs == gapMs;

  @override
  int get hashCode => Object.hash(durationMs, gapMs);

  @override
  String toString() => 'Pulse(durationMs: $durationMs, gapMs: $gapMs)';
}
