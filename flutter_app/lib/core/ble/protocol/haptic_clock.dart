import 'dart:math' as math;

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
