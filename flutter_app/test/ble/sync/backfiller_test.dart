import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/crc.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';
import 'package:noop/core/ble/sync/backfiller.dart';

/// Ports the device-independent Backfiller coverage:
///   - `BackfillerSessionTallyTest.kt` — the pure tally / summary / no-cursor / future-RTC helpers.
///   - `Whoop5OffloadTest.kt` — the family-aware `Backfiller.endData` +4 slice.
/// plus a state-machine drive of `ingest` (START → records → repeated HISTORY_END → COMPLETE) that
/// exercises the per-chunk safe-trim invariant and the repeated-END accumulation, which is the
/// on-device half the wave is about and needs no BLE hardware.

// ── frame builders (valid CRCs, exactly as the strap would emit) ────────────

Uint8List _whoop4Metadata(int metaType, {int unix = 0, int trim = 0}) {
  final inner = Uint8List(17);
  inner[0] = 0x31; // METADATA (type 49)
  inner[1] = 0x00; // seq
  inner[2] = metaType & 0xFF;
  for (var i = 0; i < 4; i++) {
    inner[3 + i] = (unix >> (8 * i)) & 0xFF; // unix @ frame[7..10]
  }
  for (var i = 0; i < 4; i++) {
    inner[13 + i] = (trim >> (8 * i)) & 0xFF; // trim_cursor @ frame[17..20]
  }
  return _wrap(inner);
}

/// A WHOOP4 v24 type-47 HISTORICAL_DATA record carrying unix + heart-rate.
Uint8List _whoop4Record({required int unix, required int hr}) {
  final inner = Uint8List(19);
  inner[0] = 47; // HISTORICAL_DATA
  inner[1] = 24; // v24 layout
  for (var i = 0; i < 4; i++) {
    inner[7 + i] = (unix >> (8 * i)) & 0xFF; // unix @ frame[11..14]
  }
  inner[17] = hr & 0xFF; // heart_rate @ frame[21]
  inner[18] = 0; // rr_count @ frame[22]
  return _wrap(inner);
}

Uint8List _wrap(Uint8List inner) {
  final length = 4 + inner.length; // crc32 sits at offset = length
  final out = Uint8List(length + 4);
  out[0] = 0xAA;
  out[1] = length & 0xFF;
  out[2] = (length >> 8) & 0xFF;
  out[3] = Crc.crc8(Uint8List.fromList(<int>[out[1], out[2]])) & 0xFF;
  out.setRange(4, 4 + inner.length, inner);
  final crc32 = Crc.crc32(inner);
  for (var i = 0; i < 4; i++) {
    out[length + i] = (crc32 >> (8 * i)) & 0xFF;
  }
  return out;
}

/// A fake sink that records the batches it was handed and reports all-new insert counts.
class _FakeRepo implements BackfillRepository {
  final List<StreamBatch> batches = [];

  @override
  Future<InsertCounts> insert(StreamBatch batch, String deviceId) async {
    batches.add(batch);
    return InsertCounts(
      hr: batch.hr.length + batch.ppgHr.length,
      rr: batch.rr.length,
      events: batch.events.length,
      battery: batch.battery.length,
      spo2: batch.spo2.length,
      skinTemp: batch.skinTemp.length,
      steps: batch.steps.length,
      resp: batch.resp.length,
      gravity: batch.gravity.length,
    );
  }
}

void main() {
  // A plausible offload timestamp window (2023-11 floor, near "now" for the future gate).
  final baseUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600;

  group('endData — family-aware +4 slice', () {
    test('whoop4 is frame[17:25]', () {
      final f = Uint8List(26);
      for (var i = 17; i < 25; i++) {
        f[i] = i - 16; // 1..8 at [17..24]
      }
      expect(Backfiller.endData(f, DeviceFamily.whoop4),
          Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]));
    });

    test('whoop5 is frame[21:29]', () {
      final f = Uint8List(30);
      for (var i = 21; i < 29; i++) {
        f[i] = i - 20; // 1..8 at [21..28]
      }
      expect(Backfiller.endData(f, DeviceFamily.whoop5),
          Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]));
    });

    test('null when the frame is too short', () {
      expect(Backfiller.endData(Uint8List(10), DeviceFamily.whoop4), isNull);
    });
  });

  group('chunkTally', () {
    test('sums biometric rows and gravity only', () {
      const counts = InsertCounts(
          hr: 10, rr: 4, events: 99, battery: 7, spo2: 3, skinTemp: 2, steps: 50, resp: 1, gravity: 5);
      final t = Backfiller.chunkTally(counts, const []);
      expect(t.rows, 10 + 4 + 3 + 2 + 1 + 5); // 25 — events/battery/steps excluded
      expect(t.motion, 5);
      expect(t.nights, isEmpty);
    });

    test('nights are distinct day-keys', () {
      const day0 = 1700000000;
      final sameDay = day0 + 3600;
      final nextDay = day0 + 86400;
      final t = Backfiller.chunkTally(const InsertCounts(), [day0, sameDay, nextDay]);
      expect(t.nights, {day0 ~/ 86400, nextDay ~/ 86400});
      expect(t.nights, hasLength(2));
    });
  });

  group('sessionSummaryLine', () {
    test('null when no rows', () {
      expect(Backfiller.sessionSummaryLine(0, 0, 0, 0), isNull);
    });
    test('format', () {
      expect(Backfiller.sessionSummaryLine(240, 180, 12, 3),
          'Backfill: session persisted 240 rows (180 with motion, 12 skin-temp) across 3 night(s).');
    });
    test('shows zero skin-temp', () {
      expect(Backfiller.sessionSummaryLine(872, 172, 0, 1),
          'Backfill: session persisted 872 rows (172 with motion, 0 skin-temp) across 1 night(s).');
    });
  });

  group('noCursorLine (#783)', () {
    test('no rows gives no-history guidance', () {
      final line = Backfiller.noCursorLine(0);
      expect(line.contains('no banked history to offload'), isTrue);
      expect(line.contains('fully charge'), isTrue);
    });
    test('after rows gives caught-up line', () {
      final line = Backfiller.noCursorLine(240);
      expect(line.contains('reached the end of available history'), isTrue);
      expect(line.contains('240 row(s)'), isTrue);
      expect(line.contains('no banked history'), isFalse);
      expect(line.contains('fully charge'), isFalse);
    });
    test('no em-dash in either branch', () {
      expect(Backfiller.noCursorLine(0).contains('—'), isFalse);
      expect(Backfiller.noCursorLine(5).contains('—'), isFalse);
    });
  });

  group('future-RTC detection (#773)', () {
    const now = 1700000000;
    test('not flagged for past date', () {
      expect(Backfiller.isCorruptFutureRtc(now - 86400, now), isFalse);
      expect(Backfiller.isCorruptFutureRtc(now, now), isFalse);
    });
    test('tolerates small skew', () {
      expect(Backfiller.isCorruptFutureRtc(now + 3600, now), isFalse);
      expect(Backfiller.isCorruptFutureRtc(now + Backfiller.futureRtcToleranceSeconds, now), isFalse);
    });
    test('flagged for far-future date', () {
      expect(Backfiller.isCorruptFutureRtc(now + 10 * 86400, now), isTrue);
    });
    test('recovery line wording', () {
      final line = Backfiller.futureRtcLine(now + 10 * 86400, now);
      expect(line.contains('10 day(s) in the FUTURE'), isTrue);
      expect(line.contains('clock (RTC) is corrupt'), isTrue);
      expect(line.contains('Fully charge'), isTrue);
      expect(line.contains('—'), isFalse);
    });
  });

  group('ingest state machine (safe-trim invariant + repeated-END accumulation)', () {
    late _FakeRepo repo;
    late InMemoryTrimCursorStore cursors;
    late List<(int, Uint8List)> acks;
    late List<StreamBatch> committed;
    late Backfiller bf;

    setUp(() {
      repo = _FakeRepo();
      cursors = InMemoryTrimCursorStore();
      acks = [];
      committed = [];
      bf = Backfiller(
        repository: repo,
        deviceId: 'my-whoop',
        cursorStore: cursors,
        ackTrim: (trim, endData) => acks.add((trim, endData)),
        onChunkCommitted: committed.add,
      );
    });

    test('a records-bearing HISTORY_END persists, sets the cursor, then acks', () async {
      bf.begin(DeviceFamily.whoop4);
      expect(bf.isBackfilling, isTrue);
      await bf.ingest(_whoop4Record(unix: baseUnix, hr: 60));
      await bf.ingest(_whoop4Metadata(2, unix: baseUnix, trim: 1000));

      expect(repo.batches, hasLength(1));
      expect(repo.batches.single.hr, hasLength(1));
      expect(repo.batches.single.hr.single.bpm, 60);
      // Cursor is persisted BEFORE the ack (both must have happened).
      expect(await cursors.get(Backfiller.strapTrimCursor), 1000);
      expect(acks, hasLength(1));
      expect(acks.single.$1, 1000);
      expect(acks.single.$2, hasLength(8)); // the 8-byte end_data
      expect(bf.lastAckedTrim, 1000);
      expect(bf.sessionRowsPersisted, 1);
      expect(committed, hasLength(1)); // a non-empty chunk fired onChunkCommitted
    });

    test('repeated HISTORY_END keeps the chunk open — later records become the next chunk', () async {
      bf.begin(DeviceFamily.whoop4);
      await bf.ingest(_whoop4Record(unix: baseUnix, hr: 60));
      await bf.ingest(_whoop4Metadata(2, unix: baseUnix, trim: 1000));
      // A second record arrives AFTER the first END; it must land in a fresh chunk on the next END.
      await bf.ingest(_whoop4Record(unix: baseUnix + 1, hr: 61));
      await bf.ingest(_whoop4Metadata(2, unix: baseUnix + 1, trim: 2000));

      expect(repo.batches, hasLength(2));
      expect(repo.batches[1].hr.single.bpm, 61);
      expect(await cursors.get(Backfiller.strapTrimCursor), 2000);
      expect(acks.map((a) => a.$1), [1000, 2000]);
      expect(bf.sessionRowsPersisted, 2);
    });

    test('an empty HISTORY_END still acks (advances the trim) but persists nothing', () async {
      bf.begin(DeviceFamily.whoop4);
      await bf.ingest(_whoop4Metadata(2, unix: baseUnix, trim: 3000));

      expect(repo.batches, isEmpty); // no records → no insert
      expect(await cursors.get(Backfiller.strapTrimCursor), 3000);
      expect(acks.single.$1, 3000);
      expect(committed, isEmpty); // metadata-only END does not fire onChunkCommitted
      expect(bf.sessionRowsPersisted, 0);
    });

    test('HISTORY_COMPLETE ends the session and clears the open chunk', () async {
      bf.begin(DeviceFamily.whoop4);
      await bf.ingest(_whoop4Record(unix: baseUnix, hr: 60));
      await bf.ingest(_whoop4Metadata(3)); // HISTORY_COMPLETE
      expect(bf.isBackfilling, isFalse);
      // A stray record after COMPLETE is not accumulated, so a following END has nothing to persist.
      await bf.ingest(_whoop4Record(unix: baseUnix, hr: 60));
      await bf.ingest(_whoop4Metadata(2, unix: baseUnix, trim: 9));
      expect(repo.batches, isEmpty);
    });

    test('timeoutFired clears state WITHOUT acking the open chunk', () async {
      bf.begin(DeviceFamily.whoop4);
      await bf.ingest(_whoop4Record(unix: baseUnix, hr: 60));
      bf.timeoutFired();
      expect(bf.isBackfilling, isFalse);
      // The open chunk was dropped: a subsequent END sees no records.
      await bf.ingest(_whoop4Metadata(2, unix: baseUnix, trim: 1000));
      expect(repo.batches, isEmpty);
      // But the (empty) END still advances the trim, matching finishChunk.
      expect(acks.single.$1, 1000);
    });

    test('a failed cursor write holds the ack (safe-trim invariant)', () async {
      final failing = Backfiller(
        repository: repo,
        deviceId: 'my-whoop',
        cursorStore: _ThrowingCursorStore(),
        ackTrim: (trim, endData) => acks.add((trim, endData)),
      );
      failing.begin(DeviceFamily.whoop4);
      await failing.ingest(_whoop4Record(unix: baseUnix, hr: 60));
      await failing.ingest(_whoop4Metadata(2, unix: baseUnix, trim: 1000));
      // Rows were persisted, but the cursor write failed → NO ack (strap re-sends next session).
      expect(repo.batches, hasLength(1));
      expect(acks, isEmpty);
      expect(failing.lastAckedTrim, isNull);
    });
  });
}

class _ThrowingCursorStore implements TrimCursorStore {
  @override
  Future<int?> get(String name) async => null;
  @override
  Future<void> set(String name, int value) async => throw StateError('disk full');
}
