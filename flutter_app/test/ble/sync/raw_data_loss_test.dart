import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/crc.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';
import 'package:noop/core/ble/sync/backfiller.dart';
import 'package:noop/core/ble/sync/raw_archive.dart';
import 'package:noop/core/ble/sync/stream_persistence.dart';
import 'package:noop/core/data/db/database.dart';

/// Coverage for the three raw-data LOSS holes the audit found
/// (docs/raw-data-storage-and-reanalysis.md), now closed:
///   1. the rejected-frame archive is wired to the Backfiller's rejectedSink and writes
///      durably BEFORE the ack (a false/failed write HOLDS the ack — safe-trim invariant).
///   2. the WHOOP5 v18 `hr_fixed_8_8` / `onwrist` / `dynamic_acceleration` fields, once
///      decoded-and-dropped, now reach the DB.
///   3. the raw v26 PPG waveform is stored losslessly (not only the derived HR).
void main() {
  Uint8List bytes(String s) {
    final out = Uint8List(s.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  // ── Fix 1: the rejected-frame archive ─────────────────────────────────────

  group('Fix 1 — rejected-frame archive (durable before ack)', () {
    // A real WHOOP 4 v24 record (same fixture the reject filter test uses).
    const realV24Hex =
        'aa6400a12f18054c1c0a023ed0266a5037805418016d022b0234020000000000006b07ff00'
        '85593c1f65cebed7b3e63eb85a5f3f000080401f65cebed7b3e63eb85a5f3f500264025d03'
        '640229014009010c020c00000000000f0001c4020000000000008fdeb278';

    void repairCrc32(Uint8List frame) {
      final length = (frame[1] & 0xFF) | ((frame[2] & 0xFF) << 8);
      final crc = Crc.crc32(frame, from: 4, to: length);
      frame[length] = crc & 0xFF;
      frame[length + 1] = (crc >> 8) & 0xFF;
      frame[length + 2] = (crc >> 16) & 0xFF;
      frame[length + 3] = (crc >> 24) & 0xFF;
    }

    /// A CRC-ok record frame that [decodeHistorical] cannot decode: an unmapped version
    /// whose v24-fallback plausibility gate rejects it (zeroed gravity → |g| = 0). This
    /// is exactly the "acked → trimmed → lost" frame the archive must catch.
    Uint8List undecodableButCrcOk() {
      final f = bytes(realV24Hex);
      f[5] = 99; // unmapped layout version
      for (var i = 40; i < 52; i++) {
        f[i] = 0; // zero gravity x/y/z → fails the physical-plausibility gate
      }
      repairCrc32(f); // envelope stays valid → crcOk true, but decode returns null
      return f;
    }

    /// WHOOP4 HISTORY_END metadata frame (meta_type 2), carrying unix + trim cursor.
    Uint8List whoop4End({required int unix, required int trim}) {
      final inner = Uint8List(17);
      inner[0] = 0x31; // METADATA (type 49)
      inner[1] = 0x00; // seq
      inner[2] = 2; // HISTORY_END
      for (var i = 0; i < 4; i++) {
        inner[3 + i] = (unix >> (8 * i)) & 0xFF; // unix @ frame[7..10]
      }
      for (var i = 0; i < 4; i++) {
        inner[13 + i] = (trim >> (8 * i)) & 0xFF; // trim_cursor @ frame[17..20]
      }
      final length = 4 + inner.length;
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

    late AppDatabase db;
    late DriftStreamRepository repo;
    late List<(int, Uint8List)> acks;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = DriftStreamRepository(db);
      acks = [];
    });
    tearDown(() async => db.close());

    test('an undecodable-but-CRC-ok frame lands in RawSensorArchive, then acks', () async {
      final archive = DriftRejectedFrameArchive(db);
      final bf = Backfiller(
        repository: repo,
        deviceId: 'my-whoop',
        cursorStore: DriftTrimCursorStore(db),
        ackTrim: (trim, endData) => acks.add((trim, endData)),
        rejectedSink: (frames, trim, family) => archive.append(frames, trim, family),
      );

      final bad = undecodableButCrcOk();
      // Sanity: the reject filter agrees this frame is a genuine loss candidate.
      expect(rejectedHistoricalRecords([bad], DeviceFamily.whoop4), hasLength(1));

      bf.begin(DeviceFamily.whoop4);
      await bf.ingest(bad);
      await bf.ingest(whoop4End(unix: 1700001000, trim: 4242));

      // Archived durably (one immutable row, the verbatim frame hex + trim + family)…
      final rows = await db.select(db.rawSensorArchive).get();
      expect(rows, hasLength(1));
      final hex = bad
          .map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0'))
          .join();
      expect(rows.single.rawHex, hex);
      expect(rows.single.trimCursor, 4242);
      expect(rows.single.family, 'whoop4');

      // …and only THEN is the trim acked + persisted.
      expect(acks.map((a) => a.$1), [4242]);
      expect(await db.getSyncCursor(Backfiller.strapTrimCursor), 4242);
    });

    test('a FAILED archive write HOLDS the ack (strap re-sends; no cursor advance)', () async {
      final bf = Backfiller(
        repository: repo,
        deviceId: 'my-whoop',
        cursorStore: DriftTrimCursorStore(db),
        ackTrim: (trim, endData) => acks.add((trim, endData)),
        // Genuine write failure → false → the Backfiller must NOT ack.
        rejectedSink: (frames, trim, family) async => false,
      );

      bf.begin(DeviceFamily.whoop4);
      await bf.ingest(undecodableButCrcOk());
      await bf.ingest(whoop4End(unix: 1700001000, trim: 4242));

      expect(acks, isEmpty, reason: 'unarchived data must never be acked');
      expect(await db.getSyncCursor(Backfiller.strapTrimCursor), isNull);
      expect(bf.lastAckedTrim, isNull);
    });

    test('DriftRejectedFrameArchive.append on an empty list is a no-op that allows the ack',
        () async {
      final archive = DriftRejectedFrameArchive(db);
      expect(await archive.append(const [], 0, DeviceFamily.whoop4), isTrue);
      expect(await db.select(db.rawSensorArchive).get(), isEmpty);
    });
  });

  // ── Fix 2: the dropped WHOOP5 v18 fields reach the DB ─────────────────────

  group('Fix 2 — v18 hr_fixed_8_8 / onwrist / dynamic_acceleration persist', () {
    // Real worn WHOOP 5 v18 frame (hr=102, hr_fixed=25997, onwrist=0, |gravity|≈1).
    const wornV18 =
        'aa01740001003fb12f1280733d8401b69f266a66460066025a0265020000000000007b0a8d656463ff0012163cf6a439bf2924fd3ed763fe3e3200aa000000000000000000f7000901f10b0007010c020c00000000000000000000000000000000000000000000000100656f1e1e0000009d61a7c00000003e862817';

    late AppDatabase db;
    late DriftStreamRepository repo;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = DriftStreamRepository(db);
    });
    tearDown(() async => db.close());

    test('decode → extract → persist carries all three fields into hrSample/gravitySample',
        () async {
      const unix = 1780916150; // the frame's own unix (plausible: past, > 1.7e9)
      final st = extractHistoricalStreams(
          [bytes(wornV18)], unix, unix, DeviceFamily.whoop5);

      // The decoded rows carry the previously-dropped fields.
      expect(st.hr.single.bpm, 102);
      expect(st.hr.single.hrFixed88, 25997);
      expect(st.hr.single.onwrist, 0);
      final da = st.gravity.single.dynamicAccel;
      expect(da, isNotNull);
      expect(da! >= 0.0 && da <= 8.0, isTrue);

      await repo.insert(st, 'my-whoop');

      final hrRow = (await db.select(db.whoopHrSamples).get()).single;
      expect((hrRow.bpm, hrRow.hrFixed88, hrRow.onwrist), (102, 25997, 0));
      final gRow = (await db.select(db.whoopGravitySamples).get()).single;
      expect(gRow.dynamicAccel, isNotNull);
      expect(gRow.dynamicAccel! >= 0.0 && gRow.dynamicAccel! <= 8.0, isTrue);
    });

    test('WHOOP4 rows leave the v18-only columns null (additive, no misfilling)', () async {
      // A WHOOP4 batch built directly — hr_fixed/onwrist/dynamicAccel absent by design.
      final batch = StreamBatch(
        hr: [const HrRow(1700000000, 60)],
        gravity: [const GravityRow(1700000000, x: 0.0, y: 0.0, z: 1.0)],
      );
      await repo.insert(batch, 'my-whoop');
      final hrRow = (await db.select(db.whoopHrSamples).get()).single;
      expect(hrRow.hrFixed88, isNull);
      expect(hrRow.onwrist, isNull);
      expect((await db.select(db.whoopGravitySamples).get()).single.dynamicAccel, isNull);
    });
  });

  // ── Fix 3: the raw v26 PPG waveform is stored losslessly ──────────────────

  group('Fix 3 — raw v26 PPG waveform persists', () {
    /// A synthetic WHOOP5 v26 record: type@8=47, version@9=26, unix@15 (u32 LE), and
    /// 24 i16 PPG samples at [27:75]. The v26 raw-collection path does not gate on CRC
    /// (the derived-HR path already handles that), so this exercises the real extractor.
    Uint8List v26Frame(int unix, List<int> samples) {
      final f = Uint8List(80);
      f[0] = 0xAA;
      f[8] = 47; // HISTORICAL_DATA
      f[9] = 26; // layout v26
      for (var i = 0; i < 4; i++) {
        f[15 + i] = (unix >> (8 * i)) & 0xFF;
      }
      final bd = ByteData.sublistView(f);
      for (var i = 0; i < samples.length && i < 24; i++) {
        bd.setInt16(27 + i * 2, samples[i], Endian.little);
      }
      return f;
    }

    late AppDatabase db;
    late DriftStreamRepository repo;
    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = DriftStreamRepository(db);
    });
    tearDown(() async => db.close());

    test('the 24-sample waveform round-trips into ppgRawSample byte-identically', () async {
      const unix = 1780916200;
      // A signed waveform incl. negatives, to prove the i16 codec is lossless.
      final samples = List<int>.generate(24, (i) => (i.isEven ? 1 : -1) * (100 + i * 37));
      final st = extractHistoricalStreams(
          [v26Frame(unix, samples)], unix, unix, DeviceFamily.whoop5);

      expect(st.ppgRaw, hasLength(1));
      expect(st.ppgRaw.single.ts, unix);
      expect(st.ppgRaw.single.samples, samples);

      await repo.insert(st, 'my-whoop');

      final row = (await db.select(db.whoopPpgRawSamples).get()).single;
      expect((row.deviceId, row.ts, row.sampleCount), ('my-whoop', unix, 24));
      expect(PpgRawRow.unpackSamples(row.samples), samples);
    });

    test('re-inserting the same v26 second is idempotent (append-only IGNORE)', () async {
      const unix = 1780916300;
      final samples = List<int>.generate(24, (i) => i - 12);
      final st = extractHistoricalStreams(
          [v26Frame(unix, samples)], unix, unix, DeviceFamily.whoop5);
      await repo.insert(st, 'my-whoop');
      await repo.insert(st, 'my-whoop');
      expect(await db.select(db.whoopPpgRawSamples).get(), hasLength(1));
    });
  });
}
