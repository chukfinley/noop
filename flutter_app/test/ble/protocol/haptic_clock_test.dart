import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/haptic_clock.dart';

/// Faithful Dart port of `HapticClockTest.kt`.
///
/// Pure-logic tests for the Haptic Clock encoder (#460). These pin the EXACT pulse list for sample
/// times; the Apple `HapticClockTests.swift` asserts the same lists so the two platforms buzz
/// identically (e.g. 3:25 → the same list).
void main() {
  Pulse lng(int gap) => Pulse(HapticClock.longMs, gap);
  Pulse shrt(int gap) => Pulse(HapticClock.shortMs, gap);

  test('pulses_0325_24h_exactList', () {
    // 3:25 in 24-hour form: hour 03 (no tens, 3 units) — block — minute 25 (2 tens, 5 units).
    const g = HapticClock.intraGapMs;
    final expected = <Pulse>[
      // hour-tens 0 → nothing; hour-units 3 → three short pulses, last carries the block gap.
      shrt(g), shrt(g), shrt(HapticClock.blockGapMs),
      // minute-tens 2 → two long pulses, last carries the group gap.
      lng(g), lng(HapticClock.groupGapMs),
      // minute-units 5 → five short pulses; the very last pulse has no trailing gap.
      shrt(g), shrt(g), shrt(g), shrt(g), shrt(0),
    ];
    expect(HapticClock.pulses(3, 25, is24h: true), expected);
  });

  test('pulses_1525_12h_mapsTo0325', () {
    // 12-hour mapping: 15:25 → dial reads 3:25, so it must equal the 24h 3:25 list exactly.
    expect(
      HapticClock.pulses(15, 25, is24h: false),
      HapticClock.pulses(3, 25, is24h: true),
    );
  });

  test('pulses_1005_24h_handlesZeroDigits', () {
    // 10:05 in 24-hour form: hour 10 (1 ten, 0 units) — block — minute 05 (0 tens, 5 units).
    const g = HapticClock.intraGapMs;
    final expected = <Pulse>[
      // hour-tens 1 → one long; hour-units 0 → nothing, so this long carries the block gap.
      lng(HapticClock.blockGapMs),
      // minute-tens 0 → nothing; minute-units 5 → five short, last with no trailing gap.
      shrt(g), shrt(g), shrt(g), shrt(g), shrt(0),
    ];
    expect(HapticClock.pulses(10, 5, is24h: true), expected);
  });

  test('pulses_midnight_24h_isEmpty', () {
    // Midnight 0:00 in 24-hour form has no nonzero digits — there is nothing to buzz.
    expect(HapticClock.pulses(0, 0, is24h: true), <Pulse>[]);
  });

  test('pulses_midnight_12h_readsTwelve', () {
    // Midnight 0:00 in 12-hour form reads "12:00" → one ten + two units of hour, no minute pulses.
    final expected = <Pulse>[
      lng(HapticClock.groupGapMs),
      shrt(HapticClock.intraGapMs), shrt(0),
    ];
    expect(HapticClock.pulses(0, 0, is24h: false), expected);
  });

  test('twelveHour_mapping', () {
    // Noon stays 12 in 12-hour form (it does not collapse to 0).
    expect(HapticClock.twelveHour(12), 12);
    expect(HapticClock.twelveHour(0), 12);
    expect(HapticClock.twelveHour(13), 1);
    expect(HapticClock.twelveHour(23), 11);
  });

  test('pulses_clampsOutOfRange', () {
    // Out-of-range inputs are clamped, not crashed (the trigger can be driven from a stored pref).
    expect(
      HapticClock.pulses(99, 99, is24h: true),
      HapticClock.pulses(23, 59, is24h: true),
    );
    expect(
      HapticClock.pulses(-5, -5, is24h: true),
      HapticClock.pulses(0, 0, is24h: true),
    );
  });
}
