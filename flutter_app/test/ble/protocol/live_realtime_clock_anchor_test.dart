import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/parsed_frame.dart';
import 'package:noop/core/ble/protocol/streams.dart';

/// Faithful Dart port of `LiveRealtimeClockAnchorTest.kt`.
///
/// #126: live REALTIME_DATA carries the strap's OWN timestamp. On a strap with an invalid RTC that
/// value is a bogus uptime counter, not unix time — so an identity clock (device==wall==now) would
/// stamp live HR thousands of days off-today, and the Today 24h HR trend reads empty even though live
/// HR streamed all session.
///
/// The live path now anchors the batch's NEWEST realtime timestamp to wall-clock `now` and lets
/// earlier samples fall relative to it, so live HR lands on today's timeline whatever the strap's
/// clock says — and is a no-op when the clock is already valid (newest frame ≈ now). Guards
/// `extractStreams`' mapping.
void main() {
  ParsedFrame realtime(int deviceTs, int hr) => ParsedFrame(
        ok: true,
        crcOk: true,
        typeName: 'REALTIME_DATA',
        parsed: <String, Object?>{'timestamp': deviceTs, 'heart_rate': hr},
      );

  test('bogusRtcLiveHrLandsOnTodayWhenAnchoredToNow', () {
    const now = 1780000000;
    // Strap RTC is a ~31M-second uptime counter (not unix time); three 1 Hz readings.
    final frames = <ParsedFrame>[
      realtime(31000000, 58),
      realtime(31000001, 60),
      realtime(31000002, 61),
    ];
    final newest = frames
        .map((f) => f.parsed.intOrNull('timestamp'))
        .whereType<int>()
        .reduce((a, b) => a > b ? a : b); // == 31_000_002
    final streams = extractStreams(frames, newest, now);
    // Anchored to today, spacing kept.
    expect(streams.hr.map((h) => h.ts).toList(), <int>[now - 2, now - 1, now]);
    expect(streams.hr.map((h) => h.bpm).toList(), <int>[58, 60, 61]);
  });

  test('identityClockWouldHaveStampedOffToday', () {
    const now = 1780000000;
    final frames = <ParsedFrame>[realtime(31000000, 58)];
    final identity = extractStreams(frames, now, now);
    expect(identity.hr.first.ts, 31000000); // the bug: nowhere near `now`
  });

  test('validClockIsUnchanged', () {
    const now = 1780000000;
    final frames = <ParsedFrame>[
      realtime(now - 2, 58),
      realtime(now - 1, 60),
      realtime(now, 61),
    ];
    final streams = extractStreams(frames, now, now);
    expect(streams.hr.map((h) => h.ts).toList(), <int>[now - 2, now - 1, now]);
  });
}
