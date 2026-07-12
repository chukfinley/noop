/// Faithful Dart port of `StreamPersistence.kt` + the drift insert wiring (`WhoopRepository.insert`)
/// and the `PrefsTrimCursorStore`.
///
/// [StreamPersistence.toBatch] bridges the live protocol-layer decode ([Streams]) to the offload
/// insert shape ([StreamBatch]) — including the deterministic sorted-keys JSON encoding of each event's
/// residual payload (the exact analog of `WhoopStore.encodePayload`), so the same payload always
/// serialises byte-identically. [DriftStreamRepository] then persists a [StreamBatch] into the drift
/// [AppDatabase] with idempotent (natural-key) inserts, mirroring `WhoopRepository.insert`.
library;

import 'package:drift/drift.dart';

import '../../data/db/database.dart';
import '../protocol/historical_streams.dart';
import '../protocol/streams.dart';
import 'backfiller.dart';
import 'raw_archive.dart';

class StreamPersistence {
  StreamPersistence._();

  /// Convert a decoded protocol [Streams] batch into the [StreamBatch] insert shape. `ts` widens int
  /// (protocol, wall-clock unix seconds) — no change in Dart, both are int. The WHOOP REALTIME_DATA
  /// stream carries no SpO2/skinTemp (those are type-47-only, via the historical-offload path), so for
  /// a WHOOP batch those stay empty; a live source that DOES decode them (the Oura ring) widens 1:1.
  static StreamBatch toBatch(Streams streams) => StreamBatch(
        hr: streams.hr.map((it) => HrRow(it.ts, it.bpm)).toList(),
        rr: streams.rr.map((it) => RrRow(it.ts, it.rrMs)).toList(),
        events: streams.events
            .map((it) => EventEntry(it.ts, it.kind, encodePayload(it.payload)))
            .toList(),
        battery: streams.battery
            .map((it) => BatteryRow(
                ts: it.ts, soc: it.soc, mv: it.mv, charging: it.charging))
            .toList(),
        spo2: streams.spo2.map((it) => Spo2Row(it.ts, it.red, it.ir)).toList(),
        skinTemp:
            streams.skinTemp.map((it) => SkinTempRow(it.ts, it.raw)).toList(),
        // resp/gravity/steps/ppgHr remain type-47-only (historical offload), unchanged.
      );

  /// Deterministic sorted-keys JSON for an event payload. Port of `WhoopStore.encodePayload`
  /// (JSONEncoder with `.sortedKeys`). Keys sorted ascending, quoted; values by type. Empty → `{}`.
  static String encodePayload(Map<String, Object?> payload) {
    if (payload.isEmpty) return '{}';
    final keys = payload.keys.toList()..sort();
    final sb = StringBuffer('{');
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) sb.write(',');
      sb.write(_quote(keys[i]));
      sb.write(':');
      sb.write(_encodeValue(payload[keys[i]]));
    }
    sb.write('}');
    return sb.toString();
  }

  /// Encode one JSON value by type (numbers bare, strings/bools/null literal, lists as arrays).
  static String _encodeValue(Object? v) {
    if (v == null) return 'null';
    if (v is bool) return v.toString();
    if (v is int) return v.toString();
    if (v is double) return v.isFinite ? v.toString() : 'null';
    if (v is List) {
      final sb = StringBuffer('[');
      for (var i = 0; i < v.length; i++) {
        if (i > 0) sb.write(',');
        sb.write(_encodeValue(v[i]));
      }
      sb.write(']');
      return sb.toString();
    }
    if (v is String) return _quote(v);
    return _quote(v.toString());
  }

  /// JSON string quoting, matching `JSONObject.quote` / Dart `json.encode(String)`.
  static String _quote(String s) {
    final sb = StringBuffer('"');
    for (final rune in s.runes) {
      switch (rune) {
        case 0x22:
          sb.write('\\"');
          break;
        case 0x5C:
          sb.write('\\\\');
          break;
        case 0x08:
          sb.write('\\b');
          break;
        case 0x0C:
          sb.write('\\f');
          break;
        case 0x0A:
          sb.write('\\n');
          break;
        case 0x0D:
          sb.write('\\r');
          break;
        case 0x09:
          sb.write('\\t');
          break;
        default:
          if (rune < 0x20) {
            sb.write('\\u');
            sb.write(rune.toRadixString(16).padLeft(4, '0'));
          } else {
            sb.writeCharCode(rune);
          }
      }
    }
    sb.write('"');
    return sb.toString();
  }
}

/// Persists a decoded [StreamBatch] into the drift [AppDatabase], stamping every row with `deviceId`
/// and using idempotent (natural-key) inserts. Port of `WhoopRepository.insert(StreamBatch, deviceId)`:
/// returns the number of rows ACTUALLY inserted per stream (0 for rows that already existed). v26
/// PPG-derived HR is counted into [InsertCounts.hr]; band sleep_state is persist-only (not counted).
class DriftStreamRepository implements BackfillRepository {
  DriftStreamRepository(this._db);

  final AppDatabase _db;

  /// The durable rejected-frame archive backed by the SAME drift database, so the
  /// transport can wire the Backfiller's `rejectedSink` without reaching for the db
  /// directly (it only holds a [BackfillRepository]). Undecodable frames land here
  /// BEFORE the strap trim is acked.
  late final RejectedFrameArchive rejectedArchive =
      DriftRejectedFrameArchive(_db);

  @override
  Future<InsertCounts> insert(StreamBatch streams, String deviceId) async {
    if (streams.isEmpty) return const InsertCounts();

    return _db.transaction(() async {
      final hr = await _db.insertWhoopHr(streams.hr
          .map((it) => WhoopHrSamplesCompanion.insert(
              deviceId: deviceId,
              ts: it.ts,
              bpm: it.bpm,
              hrFixed88: Value(it.hrFixed88),
              onwrist: Value(it.onwrist)))
          .toList());
      final ppgHr = await _db.insertWhoopPpgHr(streams.ppgHr
          .map((it) => WhoopPpgHrSamplesCompanion.insert(
              deviceId: deviceId, ts: it.ts, bpm: it.bpm, conf: it.conf))
          .toList());
      final rr = await _db.insertWhoopRr(streams.rr
          .map((it) => WhoopRrIntervalsCompanion.insert(
              deviceId: deviceId, ts: it.ts, rrMs: it.rrMs))
          .toList());
      final events = await _db.insertWhoopEvents(streams.events
          .map((it) => WhoopEventsCompanion.insert(
              deviceId: deviceId,
              ts: it.ts,
              kind: it.kind,
              payloadJson: it.payloadJSON))
          .toList());
      final battery = await _db.insertWhoopBattery(streams.battery
          .map((it) => WhoopBatteryCompanion.insert(
              deviceId: deviceId,
              ts: it.ts,
              soc: Value(it.soc),
              mv: Value(it.mv),
              charging: Value(it.charging)))
          .toList());
      final spo2 = await _db.insertWhoopSpo2(streams.spo2
          .map((it) => WhoopSpo2SamplesCompanion.insert(
              deviceId: deviceId, ts: it.ts, red: it.red, ir: it.ir))
          .toList());
      final skinTemp = await _db.insertWhoopSkinTemp(streams.skinTemp
          .map((it) => WhoopSkinTempSamplesCompanion.insert(
              deviceId: deviceId, ts: it.ts, raw: it.raw))
          .toList());
      final steps = await _db.insertWhoopSteps(streams.steps
          .map((it) => WhoopStepSamplesCompanion.insert(
              deviceId: deviceId,
              ts: it.ts,
              counter: it.counter,
              activityClass: Value(it.activityClass)))
          .toList());
      // Band sleep_state (#175): persist-only, NOT counted (mirrors WhoopRepository.insert).
      await _db.insertWhoopSleepState(streams.sleepState
          .map((it) => WhoopSleepStateSamplesCompanion.insert(
              deviceId: deviceId, ts: it.ts, state: it.state))
          .toList());
      final resp = await _db.insertWhoopResp(streams.resp
          .map((it) => WhoopRespSamplesCompanion.insert(
              deviceId: deviceId, ts: it.ts, raw: it.raw))
          .toList());
      final gravity = await _db.insertWhoopGravity(streams.gravity
          .map((it) => WhoopGravitySamplesCompanion.insert(
              deviceId: deviceId,
              ts: it.ts,
              x: it.x,
              y: it.y,
              z: it.z,
              dynamicAccel: Value(it.dynamicAccel)))
          .toList());
      // Raw v26 PPG waveform: persist-only (lossless), NOT counted — a future optical
      // algorithm re-runs over these exact samples. Idempotent on (deviceId, ts).
      await _db.insertWhoopPpgRaw(streams.ppgRaw
          .map((it) => WhoopPpgRawSamplesCompanion.insert(
              deviceId: deviceId,
              ts: it.ts,
              sampleCount: it.samples.length,
              samples: it.packSamples()))
          .toList());
      // Decoded-but-uncolumned v18 fields (long-format): persist-only (lossless), NOT
      // counted. Idempotent on (deviceId, ts, key) so a re-offload is a no-op.
      await _db.insertWhoopRawFields(streams.rawFields
          .map((it) => WhoopRawFieldSamplesCompanion.insert(
              deviceId: deviceId,
              ts: it.ts,
              key: it.key,
              intValue: Value(it.intValue),
              realValue: Value(it.realValue)))
          .toList());

      // ppgHr folds into the hr count so the "persisted N" summary reflects HR recovered from the
      // optical waveform too, exactly like WhoopRepository.insert.
      return InsertCounts(
        hr: hr + ppgHr,
        rr: rr,
        events: events,
        battery: battery,
        spo2: spo2,
        skinTemp: skinTemp,
        steps: steps,
        resp: resp,
        gravity: gravity,
      );
    });
  }
}

/// Durable [TrimCursorStore] backed by the drift `syncCursor` KV. The equivalent of the native
/// `PrefsTrimCursorStore`: the cursor lives beside the sensor rows in the same SQLite file, so the
/// safe-trim ORDERING (decoded rows durable → cursor written → ack) is preserved.
class DriftTrimCursorStore implements TrimCursorStore {
  DriftTrimCursorStore(this._db);

  final AppDatabase _db;

  @override
  Future<void> set(String name, int value) => _db.setSyncCursor(name, value);

  @override
  Future<int?> get(String name) => _db.getSyncCursor(name);
}
