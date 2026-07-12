import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/crc.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';

/// Faithful Dart port of `HistoricalStreamsClockCorrectionTest.kt`.
///
/// FIX #72: a grossly-stale strap RTC misdates offloaded history. The extractor corrects type-47/EVENT
/// timestamps by the (wall - device) clock offset when grossly stale, SNAPPED to a 5-min grid so
/// re-syncs dedupe, and is a no-op for a normal clock. Plus the #547 ingest gate (absolute + session
/// relative). Uses the same real worn v18 frame (unix=1780916150) as the decode test.
void main() {
  Uint8List bytes(String s) {
    final out = Uint8List(s.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  const wornV18 =
      'aa01740001003fb12f1280733d8401b69f266a66460066025a0265020000000000007b0a8d656463ff0012163cf6a439bf2924fd3ed763fe3e3200aa000000000000000000f7000901f10b0007010c020c00000000000000000000000000000000000000000000000100656f1e1e0000009d61a7c00000003e862817';

  /// Overwrite the v18 record's unix (u32 LE @15) and recompute the WHOOP5 CRC32 trailer (over
  /// frame[8..total-4]) so the frame still passes the integrity gate.
  Uint8List wornV18WithUnix(int unix) {
    final f = bytes(wornV18);
    final declaredLength = (f[2] & 0xFF) | ((f[3] & 0xFF) << 8);
    final total = declaredLength + 8;
    for (var i = 0; i < 4; i++) {
      f[15 + i] = (unix >> (8 * i)) & 0xFF;
    }
    final crc = Crc.crc32(f, from: 8, to: total - 4);
    for (var i = 0; i < 4; i++) {
      f[total - 4 + i] = (crc >> (8 * i)) & 0xFF;
    }
    return f;
  }

  test('zeroedStrapRtcKeepsRealUnixInsteadOfFutureDating', () {
    final rawTs = 1780916150;
    final wall = rawTs + 7 * 86400; // offloaded a week later
    final st = extractHistoricalStreams(
        [bytes(wornV18)], 31500000, wall, DeviceFamily.whoop5); // RTC ~1971
    expect(st.hr.first.ts, rawTs); // kept; not rawTs + ~55 years
  });

  test('staleClockShiftsHistoricalTimestampForwardAndSnaps', () {
    final device = 1780920000;
    final wall = device + 60 * 86400 + 137; // ~60 days ahead, +137s exercises snapping
    final st = extractHistoricalStreams([bytes(wornV18)], device, wall, DeviceFamily.whoop5);
    final rawTs = 1780916150;
    final snapped = ((wall - device) + 150) ~/ 300 * 300; // round-half-up; offset > 0
    expect(st.hr.first.ts, rawTs + snapped);
    expect((st.hr.first.ts - rawTs) % 300, 0); // landed on the 5-min grid
  });

  test('staleClockCorrectionIsDedupStableAcrossResync', () {
    final device = 1780920000;
    final a = extractHistoricalStreams(
        [bytes(wornV18)], device, device + 60 * 86400 + 10, DeviceFamily.whoop5);
    final b = extractHistoricalStreams(
        [bytes(wornV18)], device, device + 60 * 86400 + 13, DeviceFamily.whoop5);
    expect(a.hr.first.ts, b.hr.first.ts);
  });

  test('normalClockLeavesHistoricalTimestampUnchanged', () {
    final identity = extractHistoricalStreams([bytes(wornV18)], 0, 0, DeviceFamily.whoop5);
    expect(identity.hr.first.ts, 1780916150);
    final drift = extractHistoricalStreams(
        [bytes(wornV18)], 1780000000, 1780003600, DeviceFamily.whoop5); // 1h
    expect(drift.hr.first.ts, 1780916150);
  });

  // ── #547 ingest gate ────────────────────────────────────────────────────────────────────────────

  test('gateDropsFutureDatedRecord', () {
    final rawTs = 1780916150;
    final now = rawTs - 10 * 86400;
    final st = extractHistoricalStreams(
        [bytes(wornV18)], 0, 0, DeviceFamily.whoop5, now);
    expect(st.hr.isEmpty, isTrue, reason: 'future-dated record must produce no rows');
    expect(st.droppedImplausibleTs, 1);
  });

  test('gateKeepsRecordWithinOneDayFuture', () {
    final rawTs = 1780916150;
    final now = rawTs - 86400 + 10; // record is +1 day - 10s ahead → inside the margin
    final st = extractHistoricalStreams(
        [bytes(wornV18)], 0, 0, DeviceFamily.whoop5, now);
    expect(st.hr.first.ts, rawTs);
    expect(st.droppedImplausibleTs, 0);
  });

  test('gateDropsFarPastRecord', () {
    final farPast = 1550000000; // 2019-02, < minPlausibleUnix (1_700_000_000)
    final st = extractHistoricalStreams(
        [wornV18WithUnix(farPast)], 0, 0, DeviceFamily.whoop5, 1780916150);
    expect(st.hr.isEmpty, isTrue, reason: 'far-past record must produce no rows');
    expect(st.droppedImplausibleTs, 1);
  });

  test('gateKeepsNormalRecentTimestampByteIdentical', () {
    final recent = 1780916150;
    final st = extractHistoricalStreams(
        [wornV18WithUnix(recent)], 0, 0, DeviceFamily.whoop5, recent + 3600);
    expect(st.hr.first.ts, recent); // byte-identical pass-through
    expect(st.droppedImplausibleTs, 0);

    // And the floor boundary: exactly minPlausibleUnix is kept (inclusive).
    final floor = minPlausibleUnix;
    final atFloor = extractHistoricalStreams(
        [wornV18WithUnix(floor)], 0, 0, DeviceFamily.whoop5, 1780916150);
    expect(atFloor.hr.first.ts, floor);
    expect(atFloor.droppedImplausibleTs, 0);
  });

  // ── #547 SESSION-RELATIVE gate ────────────────────────────────────────────────────────────────

  test('sessionRelativeBoundsMatchSwift', () {
    expect(sessionRangeMargin, 7 * 86400);
  });

  test('sessionRelativeDropsFloorClearingOutOfWindowRecord', () {
    final newest = 1780916150; // strap's newest banked record
    final oldest = newest - 14 * 86400; // strap banked a ~2-week window
    final badYule = 1735084800; // 2024-12-25 00:00 UTC — months before `oldest`
    final st = extractHistoricalStreams([wornV18WithUnix(badYule)], 0, 0,
        DeviceFamily.whoop5, newest, oldest, newest);
    expect(st.hr.isEmpty, isTrue,
        reason: 'a floor-clearing record months before the strap window is dropped');
    expect(st.droppedImplausibleTs, 1);
  });

  test('sessionRelativeKeepsLegitimatelyOldInWindowBackfill', () {
    final newest = 1780916150;
    final oldest = newest - 30 * 86400; // a month of banked backlog
    final realOld = oldest + 2 * 86400; // 2 days into the window — real history
    final st = extractHistoricalStreams([wornV18WithUnix(realOld)], 0, 0,
        DeviceFamily.whoop5, newest, oldest, newest);
    expect(st.hr.first.ts, realOld);
    expect(st.droppedImplausibleTs, 0);
  });

  test('sessionRelativeFallsBackToAbsoluteWithoutMarkers', () {
    final badYule = 1735084800;
    final st = extractHistoricalStreams(
        [wornV18WithUnix(badYule)], 0, 0, DeviceFamily.whoop5, badYule + 3600);
    expect(st.hr.first.ts, badYule);
    expect(st.droppedImplausibleTs, 0);
  });

  test('sessionRelativeIgnoresMalformedMarkers', () {
    final newest = 1780916150;
    final realRecent = newest - 3600;
    final st = extractHistoricalStreams([wornV18WithUnix(realRecent)], 0, 0,
        DeviceFamily.whoop5, newest, 12345, newest);
    expect(st.hr.first.ts, realRecent);
    expect(st.droppedImplausibleTs, 0);
  });
}
