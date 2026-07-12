/// Faithful Dart port of `Backfiller.kt` (+ `ClockRef` / `TrimCursorStore` / `PrefsTrimCursorStore`).
///
/// Historical-offload state machine (idle / backfilling). It consumes the METADATA frames of an
/// offload — HISTORY_START / repeated HISTORY_END / HISTORY_COMPLETE — accumulating the type-47
/// records between them into chunks and committing each chunk durably.
///
/// Per-chunk local safe-trim invariant (unchanged from the Kotlin/Swift original):
///   decode known -> persist decoded (durable) -> persist the strap_trim cursor -> ack the trim to the
///   strap (link-layer confirmed write).
/// A chunk is forgotten by the strap only after its decoded rows are locally durable AND the trim
/// cursor is persisted AND the ack write is confirmed. The phone NEVER waits on a server.
///
/// CRITICAL behaviour preserved: a high-freq-sync offload sends ONE HISTORY_START then REPEATED
/// HISTORY_ENDs (a chunk-close every ~50 records). So we ack EVERY end and keep accumulating
/// afterwards — we snapshot+clear the accumulated frames on each END but leave the chunk OPEN so
/// subsequent records become the next chunk. An END with no accumulated records is still acked.
///
/// This whole file is PURE (no drift / dart:io): it depends only on the ported protocol layer and on
/// injected callbacks / a [BackfillRepository] / a [TrimCursorStore], so the state machine is fully
/// unit-testable. The drift-backed [BackfillRepository] + [TrimCursorStore] live in
/// `stream_persistence.dart` (the persistence layer).
library;

import 'dart:async';
import 'dart:typed_data';

import '../protocol/device_family.dart';
import '../protocol/framing.dart';
import '../protocol/historical_streams.dart';

/// Count of rows ACTUALLY inserted per stream (mirrors the Kotlin `InsertCounts` /
/// `WhoopStore.insert` return tuple). An already-present natural key is a no-op and does not count.
class InsertCounts {
  const InsertCounts({
    this.hr = 0,
    this.rr = 0,
    this.events = 0,
    this.battery = 0,
    this.spo2 = 0,
    this.skinTemp = 0,
    this.steps = 0,
    this.resp = 0,
    this.gravity = 0,
  });

  final int hr;
  final int rr;
  final int events;
  final int battery;
  final int spo2;
  final int skinTemp;
  final int steps;
  final int resp;
  final int gravity;
}

/// The sink one decoded [StreamBatch] is persisted through, stamped with a `deviceId`. The Dart analog
/// of the Kotlin `WhoopRepository.insert(StreamBatch, deviceId)`. Kept abstract so the Backfiller stays
/// pure and testable with a fake; the drift implementation lives in `stream_persistence.dart`.
abstract class BackfillRepository {
  Future<InsertCounts> insert(StreamBatch batch, String deviceId);
}

/// A (device-epoch, wall-clock) correlation in unix seconds. Analog of the Kotlin/Swift `ClockRef`.
/// type-47 historical records carry real unix timestamps, so the identity ref (device == wall) makes
/// the offset math a no-op while still decoding correct wall time — the same fallback the Backfiller
/// uses when GET_CLOCK is silent.
class ClockRef {
  const ClockRef(this.device, this.wall);

  final int device;
  final int wall;

  factory ClockRef.identityNow() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return ClockRef(now, now);
  }
}

/// Durable key/value cursor store for the `strap_trim` watermark. The Room schema has no cursor table,
/// so the native app persists it via SharedPreferences (`PrefsTrimCursorStore`); here it is backed by
/// a small drift KV (see `DriftTrimCursorStore` in `stream_persistence.dart`). The safe-trim ORDERING
/// is preserved (decoded rows durable before the cursor is written, cursor before the ack), so the
/// worst case is a redundant re-offload of an already-stored chunk after a crash — never data loss —
/// because the decoded inserts are idempotent by natural key.
abstract class TrimCursorStore {
  Future<void> set(String name, int value);
  Future<int?> get(String name);
}

/// A trivial in-memory [TrimCursorStore] (tests / the identity fallback).
class InMemoryTrimCursorStore implements TrimCursorStore {
  final Map<String, int> _m = {};

  @override
  Future<void> set(String name, int value) async => _m[name] = value;

  @override
  Future<int?> get(String name) async => _m[name];
}

typedef AckTrim = void Function(int trim, Uint8List endData);
typedef ChunkCommitted = void Function(StreamBatch batch);
typedef LogSink = void Function(String line);

/// Archive undecodable frames durably BEFORE the ack (#77 / #91). ASYNC because a
/// durable write (a drift insert + commit) is async and the ack MUST wait for it: the
/// invariant is durable rows → cursor → ack, never ack unarchived data. Returns true
/// when the frames are durable (the ack may proceed) or there was nothing to archive;
/// false on a write failure, which HOLDS the ack so the strap re-sends the chunk.
typedef RejectedSink = Future<bool> Function(
    List<Uint8List> frames, int trim, DeviceFamily family);

/// A tiny async mutex so overlapping `await ingest(...)` calls serialise their chunk assembly
/// (mirrors the Kotlin `Mutex` / the Swift serial-drain task).
class _Mutex {
  Future<void> _tail = Future<void>.value();

  Future<T> withLock<T>(Future<T> Function() action) {
    final done = Completer<void>();
    final prev = _tail;
    _tail = done.future;
    return prev.then((_) => action()).whenComplete(done.complete);
  }
}

class Backfiller {
  Backfiller({
    required this.repository,
    required this.deviceId,
    required TrimCursorStore cursorStore,
    required AckTrim ackTrim,
    ChunkCommitted onChunkCommitted = _noopChunk,
    void Function() onConsoleChunk = _noopVoid,
    LogSink log = _noopLog,
    RejectedSink rejectedSink = _defaultRejectedSink,
    ClockRef? clockRef,
    bool Function() connectionActive = _alwaysFalse,
    LogSink connectionLog = _noopLog,
  })  : _cursorStore = cursorStore,
        _ackTrim = ackTrim,
        _onChunkCommitted = onChunkCommitted,
        _onConsoleChunk = onConsoleChunk,
        _log = log,
        _rejectedSink = rejectedSink,
        clockRef = clockRef ?? ClockRef.identityNow(),
        _connectionActive = connectionActive,
        _connectionLog = connectionLog;

  final BackfillRepository repository;

  /// The device id every offloaded row is stamped with (read at finishChunk). Mutable so a
  /// WHOOP→WHOOP active-device switch re-points it; the single-WHOOP path never reassigns it.
  String deviceId;

  final TrimCursorStore _cursorStore;
  final AckTrim _ackTrim;
  final ChunkCommitted _onChunkCommitted;
  final void Function() _onConsoleChunk;
  final LogSink _log;
  final RejectedSink _rejectedSink;
  final bool Function() _connectionActive;
  final LogSink _connectionLog;

  /// The (device, wall) clock reference. Settable by the client if a real correlation lands.
  ClockRef clockRef;

  static void _noopChunk(StreamBatch _) {}
  static void _noopVoid() {}
  static void _noopLog(String _) {}
  static bool _alwaysFalse() => false;
  static Future<bool> _defaultRejectedSink(
          List<Uint8List> _, int __, DeviceFamily ___) async =>
      true;

  /// Emit one Connection & Sync test-mode line iff the mode is on. The cheap gate is checked BEFORE
  /// [build] runs, so the line string is never constructed when the mode is off. Diagnostic only.
  void _emitConnection(String Function() build) {
    if (!_connectionActive()) return;
    _connectionLog(build());
  }

  /// #547 SESSION-RELATIVE gate: the strap's own GET_DATA_RANGE oldest/newest banked-record markers for
  /// the CURRENT offload, set by the client when the range reply lands. null (both) until known.
  int? sessionOldestUnix;
  int? sessionNewestUnix;

  /// Strap family for the CURRENT offload, set at [begin] — drives the family-aware frame parse and the
  /// +4 end_data slice.
  DeviceFamily _family = DeviceFamily.whoop4;

  bool _isBackfilling = false;

  /// True while a historical offload session is active.
  bool get isBackfilling => _isBackfilling;

  final _Mutex _mutex = _Mutex();

  /// Buffered data frames for the current open chunk (between START and the next END).
  final List<Uint8List> _chunk = <Uint8List>[];

  /// Whether a START has been received and we're accumulating a chunk.
  bool _chunkOpen = false;

  int _sessionRowsPersisted = 0;
  int _sessionMotionRows = 0;
  int _sessionSkinTempRows = 0;
  final Set<int> _sessionNightKeys = <int>{};

  int get sessionRowsPersisted => _sessionRowsPersisted;
  int get sessionMotionRows => _sessionMotionRows;
  int get sessionSkinTempRows => _sessionSkinTempRows;
  int get sessionNights => _sessionNightKeys.length;

  bool _loggedNoCursor = false;
  bool _loggedFutureRtc = false;
  final Set<int> _loggedLayoutVersions = <int>{};
  bool _loggedImplausibleClock = false;

  int _sessionDroppedImplausible = 0;
  int get sessionDroppedImplausible => _sessionDroppedImplausible;

  /// The trim cursor of the LAST chunk this Backfiller acked. Survives across sessions on the same
  /// connection so the auto-continue gate can ask "did the offload actually advance the strap's trim?".
  /// null until the first ack. NOT reset in [begin].
  int? _lastAckedTrim;
  int? get lastAckedTrim => _lastAckedTrim;

  /// Called when the strap signals a historical offload is beginning. chunkOpen starts TRUE: the
  /// biometric replay streams records immediately and sends one HISTORY_START then repeated
  /// HISTORY_ENDs, so we must accumulate from the outset. Port of `begin()`.
  void begin([DeviceFamily family = DeviceFamily.whoop4]) {
    _family = family;
    _isBackfilling = true;
    _sessionRowsPersisted = 0;
    _sessionMotionRows = 0;
    _sessionSkinTempRows = 0;
    _sessionNightKeys.clear();
    _loggedNoCursor = false;
    _loggedFutureRtc = false;
    _loggedLayoutVersions.clear();
    _loggedImplausibleClock = false;
    _sessionDroppedImplausible = 0;
    sessionOldestUnix = null;
    sessionNewestUnix = null;
    _chunk.clear();
    _chunkOpen = true;
  }

  /// Feed one complete (reassembled) BLE frame into the state machine. Awaits while a chunk is
  /// persisted so chunk boundaries are never crossed concurrently. Port of `ingest(_:)`.
  Future<void> ingest(Uint8List frame) {
    return _mutex.withLock(() async {
      final meta = classifyHistoricalMeta(Framing.parseFrame(frame, _family));
      if (meta is HistoricalMetaStart) {
        _isBackfilling = true;
        _chunk.clear();
        _chunkOpen = true;
      } else if (meta is HistoricalMetaEnd) {
        await _finishChunk(meta.unix, meta.trim, frame);
      } else if (meta is HistoricalMetaComplete) {
        _isBackfilling = false;
        _chunk.clear();
        _chunkOpen = false;
      } else {
        // HistoricalMetaOther — a data / non-metadata frame.
        if (_chunkOpen) _chunk.add(frame);
      }
    });
  }

  /// Commit one HISTORY_END chunk: persist decoded -> persist strap_trim cursor -> ack the trim.
  /// Early-returns on any failure to preserve the safe-trim invariant (never ack data we failed to
  /// store). Port of `finishChunk(unix:trim:endFrame:)`.
  Future<void> _finishChunk(int unix, int trim, Uint8List endFrame) async {
    final endData = Backfiller.endData(endFrame, _family);
    if (endData == null) return;

    // #773: corrupt future-RTC detection. A genuine offload is always PAST-dated, so an end dated days
    // into the future can only be a corrupt strap RTC. Surface it ONCE per session. Observability only.
    if (trim != 0xFFFFFFFF && !_loggedFutureRtc) {
      final wallNow = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (Backfiller.isCorruptFutureRtc(unix, wallNow)) {
        _loggedFutureRtc = true;
        _log(Backfiller.futureRtcLine(unix, wallNow));
      }
    }

    // Snapshot + clear the accumulated frames but leave [_chunkOpen] TRUE so the records following this
    // END become the next chunk.
    final frames = List<Uint8List>.from(_chunk);
    _chunk.clear();

    StreamBatch? committed;
    if (frames.isNotEmpty) {
      final ref = clockRef;
      final decoded = extractHistoricalStreams(
        frames,
        ref.device,
        ref.wall,
        _family,
        null, // wallNow — default fallback, matches the Kotlin call
        sessionOldestUnix,
        sessionNewestUnix,
      );

      // Observability: which historical layout does this strap emit? Log each distinct layout once.
      int? firstVersion;
      for (final f in frames) {
        final v = decodeHistorical(f, _family)?['hist_version'];
        if (v is int) {
          firstVersion = v;
          break;
        }
      }
      if (firstVersion != null && _loggedLayoutVersions.add(firstVersion)) {
        _log('Backfill: historical records use layout v$firstVersion');
        final v = firstVersion;
        _emitConnection(() {
          final decodable = frames.any((f) {
            final d = decodeHistorical(f, _family);
            return d != null &&
                (d.containsKey('heart_rate') ||
                    d.containsKey('gravity_x') ||
                    d.containsKey('ppg_waveform'));
          });
          return 'firmware layout v$v decodable=$decodable';
        });
      }

      // #547: surface a bad-clock strap ONCE per session.
      _sessionDroppedImplausible += decoded.droppedImplausibleTs;
      if (decoded.droppedImplausibleTs > 0 && !_loggedImplausibleClock) {
        _loggedImplausibleClock = true;
        _log(
          'Backfill: WARNING dropped ${decoded.droppedImplausibleTs} record(s) with an '
          'implausible timestamp (bad strap clock — far-past or future-dated); they are '
          'excluded so they can\'t misdate history.',
        );
      }

      // #77 / #91: HISTORICAL_DATA record frames that fail decode used to be acked anyway — the strap
      // trims acked history, so the user's ONLY copy was destroyed. Classify PER FRAME, archive the
      // rejects durably FIRST, and only then allow the ack below.
      final rejected = rejectedHistoricalRecords(frames, _family);
      if (decoded.isEmpty && rejected.isEmpty) _onConsoleChunk();
      if (rejected.isNotEmpty) {
        _log(
          'Backfill: WARNING ${rejected.length} record frame(s) decoded to 0 rows '
          '(trim=$trim) — archiving raw bytes before ack (CRC/unmapped layout)',
        );
        // A hex sample in the strap log so an unmapped firmware's record layout can be mapped.
        final take = rejected.length < 8 ? rejected.length : 8;
        for (var i = 0; i < take; i++) {
          final f = rejected[i];
          final hex =
              f.map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0')).join();
          _log('Backfill: rejected frame[$i] ${f.length}B: $hex');
        }
        // Archive must be durable BEFORE the ack. A false return is a genuine write failure — hold the
        // cursor/ack so the strap re-sends the chunk on the next offload. No data loss either way.
        // Awaited: the durable write (drift insert + commit) must complete before we advance the trim.
        if (!await _rejectedSink(rejected, trim, _family)) {
          return;
        }
      }

      try {
        final counts = await repository.insert(decoded, deviceId); // DECODED FIRST (durable)
        committed = decoded;
        final tally = Backfiller.chunkTally(
          counts,
          <int>[
            ...decoded.gravity.map((g) => g.ts),
            ...decoded.hr.map((h) => h.ts),
          ],
        );
        _sessionRowsPersisted += tally.rows;
        _sessionMotionRows += tally.motion;
        _sessionSkinTempRows += counts.skinTemp;
        _sessionNightKeys.addAll(tally.nights);
        _emitConnection(() =>
            'offload progress trim=$trim chunkRows=${tally.rows} '
            'sessionRows=$_sessionRowsPersisted sessionMotion=$_sessionMotionRows nights=$sessionNights');
      } catch (t) {
        // Diag: the decoded rows couldn't be written. We return WITHOUT acking so the strap keeps this
        // chunk and re-sends it next session (no data loss).
        _log(
          'Backfill: failed to persist decoded rows (trim=$trim): $t, holding ack so the strap '
          're-sends this chunk; history won\'t advance until the write succeeds.',
        );
        return; // do NOT advance/ack, chunk was never durably committed
      }
    }

    // #150 / #783 / #1: trim=0xFFFFFFFF is the strap's "no valid flash cursor" sentinel. Gate on
    // sessionRowsPersisted (which now already includes THIS end's own rows): rows > 0 → neutral
    // caught-up line; 0 rows → the genuine no-history guidance. Logs once per session.
    if (trim == 0xFFFFFFFF && !_loggedNoCursor) {
      _loggedNoCursor = true;
      _log(Backfiller.noCursorLine(_sessionRowsPersisted));
      _emitConnection(() => 'no-cursor sentinel (trim=0xFFFFFFFF)');
    }

    // Persist the trim cursor BEFORE acking (so a crash between persist and ack still resumes from the
    // right place). trim is a u32 carried as int (unsigned-safe).
    try {
      await _cursorStore.set(strapTrimCursor, trim);
    } catch (t) {
      _log(
        'Backfill: failed to write strap_trim cursor (trim=$trim): $t, holding ack so the strap '
        're-sends this chunk; history won\'t advance until the cursor write succeeds.',
      );
      return;
    }

    _ackTrim(trim, endData);
    _lastAckedTrim = trim; // record the advanced cursor for the auto-continue spin-detector
    if (committed != null && !committed.isEmpty) _onChunkCommitted(committed);
  }

  /// Called when a backfill watchdog timer fires (strap went silent mid-offload). Clears state WITHOUT
  /// acking — the open chunk was never durably committed. Port of `timeoutFired()`.
  void timeoutFired() {
    _isBackfilling = false;
    _chunk.clear();
    _chunkOpen = false;
  }

  // ── companion (pure static helpers) ─────────────────────────────────────────

  /// Cursor name for the strap's safe-trim watermark. Matches `setCursor("strap_trim", ...)`.
  static const String strapTrimCursor = 'strap_trim';

  /// The 8-byte `end_data` the high-freq-sync ack requires: metadata.data[10:18]. The inner record
  /// begins at frame[7] on WHOOP4 (end_data = frame[17:25]) and at frame[11] on WHOOP5/MG (the +4
  /// puffin envelope → end_data = frame[21:29]). The trim cursor is the first u32 of end_data. Returns
  /// null if the frame is too short. Port of `Backfiller.endData(from:family:)`. (#78)
  static Uint8List? endData(Uint8List frame, DeviceFamily family) {
    final start = family == DeviceFamily.whoop5 ? 21 : 17;
    if (frame.length < start + 8) return null;
    return Uint8List.sublistView(frame, start, start + 8);
  }

  /// Pure per-chunk persistence tally (#150). rows = biometric rows inserted (HR, R-R, SpO2, skin-temp,
  /// resp, gravity — battery/events/steps are housekeeping, NOT biometric history). motion = gravity
  /// rows. nights = distinct day-keys (ts / 86400).
  static ({int rows, int motion, Set<int> nights}) chunkTally(
    InsertCounts counts,
    List<int> timestamps,
  ) {
    final rows = counts.hr +
        counts.rr +
        counts.spo2 +
        counts.skinTemp +
        counts.resp +
        counts.gravity;
    return (
      rows: rows,
      motion: counts.gravity,
      nights: timestamps.map((t) => t ~/ 86400).toSet(),
    );
  }

  /// The one-line session success summary (#150). Null when nothing persisted, so a console-only /
  /// caught-up session stays quiet.
  static String? sessionSummaryLine(int rows, int motion, int skinTemp, int nights) {
    if (rows <= 0) return null;
    return 'Backfill: session persisted $rows rows ($motion with motion, $skinTemp skin-temp) '
        'across $nights night(s).';
  }

  /// The trim=0xFFFFFFFF sentinel line (#783). rows > 0 → neutral caught-up line; 0 → genuine
  /// no-history guidance. Pure so a fixture pins both branches.
  static String noCursorLine(int rowsPersisted) {
    if (rowsPersisted > 0) {
      return 'Backfill: reached the end of available history (trim=0xFFFFFFFF) - caught up after '
          'persisting $rowsPersisted row(s) this run. Nothing more to offload.';
    }
    return 'Backfill: strap reported no flash cursor (trim=0xFFFFFFFF) - it has no banked history to '
        'offload. This is a clock/charge state on the strap, not a decode problem; fully charge '
        'it and reconnect so it starts banking.';
  }

  /// #773: how far ahead of the wall clock a HISTORY_END's own timestamp may sit before we call the
  /// strap RTC corrupt. Generous (1 day) so ordinary skew or a timezone confusion never trips it.
  static const int futureRtcToleranceSeconds = 86400;

  /// #773: is this HISTORY_END timestamp an implausible FUTURE date (a corrupt strap RTC)?
  static bool isCorruptFutureRtc(int endUnix, int wallNowUnix) =>
      endUnix > wallNowUnix + futureRtcToleranceSeconds;

  /// #773: the recovery-hint line for a corrupt future-dated strap RTC. No em-dash (project rule).
  static String futureRtcLine(int endUnix, int wallNowUnix) {
    final ahead = (endUnix - wallNowUnix) < 0 ? 0 : (endUnix - wallNowUnix);
    final aheadDays = ahead ~/ 86400;
    return 'Backfill: the strap reported a record dated about $aheadDays day(s) in the FUTURE - '
        'its clock (RTC) is corrupt, not a NOOP problem. Those records can\'t be filed onto the '
        'right day. Fully charge the strap to 100% and reconnect so it re-syncs its clock; if it '
        'persists, forget and re-pair the strap.';
  }
}
