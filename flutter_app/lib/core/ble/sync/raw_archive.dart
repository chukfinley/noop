/// Durable, append-only archive of CRC-ok-but-undecodable HISTORICAL frames.
///
/// Dart analog of the Kotlin `RawHistoryArchive.kt` (#77 / #91): the strap FREES its
/// flash copy of a chunk once the phone acks the trim cursor, so after that ack the
/// phone's SQLite file is the ONLY copy. If a chunk's records can't be decoded (a CRC
/// edge, or an unmapped firmware layout the v24 plausibility gate rejects), acking
/// anyway destroys the user's only copy while the UI says "History synced".
///
/// So the Backfiller archives the raw bytes HERE — durably — BEFORE the ack. A later
/// release that maps the layout can then recover them (and this archive is itself the
/// corpus that mapping needs). Frames carry sensor payloads, not identifiers.
///
/// Invariant (mirrors the Kotlin `AppendResult`/throw contract, collapsed to a bool):
///   [append] returns TRUE  → the frames are durably persisted (the caller may ack), or
///                            there was nothing to archive.
///   [append] returns FALSE → a genuine write failure. The caller must NOT ack, so the
///                            strap keeps the records and re-sends them next offload.
/// Never ack unarchived data — durable rows first, then cursor, then ack.
library;

import 'package:drift/drift.dart';

import '../../data/db/database.dart';
import '../protocol/device_family.dart';

/// The seam the Backfiller archives rejected frames through, before it acks the trim.
/// Kept abstract so the transport can inject a fake in a test and the drift-backed
/// implementation ([DriftRejectedFrameArchive]) stays out of the pure sync layer.
abstract class RejectedFrameArchive {
  /// Durably persist each undecodable [frames] entry (tagged with the HISTORY_END
  /// [trim] cursor and strap [family]). Returns true once the rows are durable (or the
  /// list is empty), false on a write failure so the caller HOLDS the ack.
  Future<bool> append(List<Uint8List> frames, int trim, DeviceFamily family);
}

/// [RejectedFrameArchive] backed by the drift `RawSensorArchive` table (append-only,
/// autoincrement id, no updates/deletes). Each frame becomes one immutable row:
/// `capturedAtMs`, `trimCursor`, `family` tag, and the verbatim `rawHex`.
class DriftRejectedFrameArchive implements RejectedFrameArchive {
  DriftRejectedFrameArchive(this._db);

  final AppDatabase _db;

  @override
  Future<bool> append(
      List<Uint8List> frames, int trim, DeviceFamily family) async {
    if (frames.isEmpty) return true; // nothing to archive → ack may proceed
    final now = DateTime.now().millisecondsSinceEpoch;
    final tag = family == DeviceFamily.whoop5 ? 'whoop5' : 'whoop4';
    final rows = <RawSensorArchiveCompanion>[
      for (final f in frames)
        RawSensorArchiveCompanion.insert(
          capturedAtMs: now,
          rawHex: _hex(f),
          trimCursor: Value(trim),
          family: Value(tag),
        ),
    ];
    try {
      await _db.insertRawArchive(rows);
      return true; // durable → the caller may ack the trim
    } catch (_) {
      // A genuine write failure: hold the ack so the strap re-sends the chunk. No data
      // loss either way (the strap still holds the records; inserts are append-only).
      return false;
    }
  }

  /// Lowercase hex of a frame's bytes (matches the Kotlin `ByteArray.toHex`).
  static String _hex(Uint8List f) =>
      f.map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0')).join();
}
