import 'dart:convert';
import 'dart:typed_data';

import 'crc.dart';
import 'device_family.dart';
import 'enums.dart';
import 'parsed_frame.dart';

/// Faithful Dart port of `Framing.kt`.
///
/// Frame envelope handling: reassembly of BLE fragments, validation, decode, and command building.
///
/// Ported from the hardware-verified Swift reference (Framing.swift / Interpreter.swift /
/// PostHooks.swift). The Whoop 4.0 envelope is:
///
///   [0]      SOF 0xAA
///   [1..2]   length u16 LE
///   [3]      CRC8 over the two length bytes
///   [4]      packet type
///   [5]      seq
///   [6]      cmd / event / meta-type (type-dependent)
///   [7..]    payload
///   [len..]  CRC32 (zlib, LE) over frame[4..<length], 4 bytes;  total frame = length + 4
///
/// The Whoop 5.0 ("puffin") envelope differs (CRC16-Modbus header, inner record at offset 8); it is
/// validated/decoded here for completeness, with biometric field offsets deferred (the inner record
/// is exposed but HR/RR/battery decoding for WHOOP5 is a later milestone, matching the Swift port).

// MARK: - little-endian readers (null when out of range; mirror interpreter._read)

int? _u8(Uint8List d, int off) => off + 1 <= d.length ? d[off] & 0xFF : null;

int? _u16(Uint8List d, int off) =>
    off + 2 <= d.length ? (d[off] & 0xFF) | ((d[off + 1] & 0xFF) << 8) : null;

int? _u32(Uint8List d, int off) {
  if (off + 4 > d.length) return null;
  return (d[off] & 0xFF) |
      ((d[off + 1] & 0xFF) << 8) |
      ((d[off + 2] & 0xFF) << 16) |
      ((d[off + 3] & 0xFF) << 24);
}

/// The Kotlin enums carry UPPER_SNAKE constant names (`REALTIME_DATA`, `BATTERY_LEVEL`) and
/// `Framing` surfaces them verbatim via `enum.name`. Dart enum `.name` is camelCase, so this rebuilds
/// the on-wire name faithfully: insert `_` before each uppercase letter, then upper-case the whole
/// string (digits stay attached to the preceding segment, e.g. `sendR10R11Realtime` ->
/// `SEND_R10_R11_REALTIME`). Keeps parsed labels byte-for-byte with the Kotlin/Swift reference.
String _wireName(Enum e) {
  final n = e.name;
  final sb = StringBuffer();
  for (var i = 0; i < n.length; i++) {
    final c = n[i];
    final isUpper = c.toUpperCase() == c && c.toLowerCase() != c;
    if (i > 0 && isUpper) sb.write('_');
    sb.write(c.toUpperCase());
  }
  return sb.toString();
}

/// Accumulate BLE notification fragments into complete frames.
///
/// A complete frame is `length + 4` bytes where `length` = u16 LE at buf[1..3]. Leading bytes before
/// the 0xAA SOF are discarded. Mirrors framing.py / Swift `Reassembler`.
class Reassembler {
  Reassembler([this._family = DeviceFamily.whoop4]);

  final DeviceFamily _family;

  // The backing store is a plain byte buffer plus a read cursor, not a growable list of boxed bytes.
  // The old form drained a completed frame with repeated removeAt(0) calls, every one of which shifts
  // the whole tail down by one slot. Draining a single frame was therefore O(n^2), and the historical
  // offload pushes thousands of ~1.9 KB records across a multi-night sync, so that cost dominated. Here
  // fragments are appended into [_data], [_head] simply advances past consumed bytes, and the leftover
  // tail is slid back to the front once per feed(). The emitted frames are identical in bytes and
  // order; FramingTest's reassembler vectors hold that contract.
  Uint8List _data = Uint8List(0);
  int _head = 0; // index of the first byte not yet consumed
  int _tail = 0; // index one past the last valid byte

  /// ~4x the largest observed WHOOP frame (~1920 B raw/historical); above this is a bad length.
  static const int maxFrameBytes = 8192;

  /// Drop any partial-frame remnant. Called on (re)connect so a stalled or garbage frame from one
  /// session can't wedge the live stream in the next. The macOS BLEManager achieves the same by
  /// reassigning a fresh `Reassembler` on every connect (BLEManager.swift:183).
  void reset() {
    _head = 0;
    _tail = 0;
  }

  /// Feed one fragment; return zero or more complete frames now available, in order.
  List<Uint8List> feed(Uint8List fragment) {
    _append(fragment);
    final out = <Uint8List>[];
    while (true) {
      final sof = _indexOfSof();
      if (sof < 0) {
        // No SOF left in the window: nothing here is salvageable, so drop it all.
        _head = 0;
        _tail = 0;
        break;
      }
      // Skip any leading bytes ahead of the SOF instead of physically removing them.
      if (sof > _head) _head = sof;
      final avail = _tail - _head;
      if (avail < 4) break;
      // Frame length is encoded differently per family: WHOOP4 = u16 @[1..3], total = length + 4;
      // WHOOP5/MG ("puffin") = declaredLength u16 @[2..4], total = declaredLength + 8 (it counts
      // the payload + the 4-byte CRC32 trailer, and has 2 extra header bytes). Using the WHOOP4
      // formula on a 5/MG frame decodes a bogus 6 KB length and the live stream never emits.
      final int total;
      if (_family == DeviceFamily.whoop5) {
        total = ((_data[_head + 2] & 0xFF) | ((_data[_head + 3] & 0xFF) << 8)) + 8;
      } else {
        total = ((_data[_head + 1] & 0xFF) | ((_data[_head + 2] & 0xFF) << 8)) + 4;
      }
      if (total > maxFrameBytes) {
        // A corrupt or misaligned SOF decodes an impossibly large length and we'd wait forever
        // for bytes that can never arrive over BLE — the live stream would freeze until a
        // reconnect. The largest real WHOOP frame is ~1920 B, so anything past the 8 KB ceiling
        // is garbage: drop this 0xAA and resync to the next one.
        _head += 1;
        continue;
      }
      if (avail < total) break;
      out.add(Uint8List.fromList(_data.sublist(_head, _head + total)));
      _head += total;
    }
    _compact();
    return out;
  }

  /// Index of the first 0xAA at or after [_head] in the live window, or -1 if none remain.
  int _indexOfSof() {
    var i = _head;
    while (i < _tail) {
      if (_data[i] == 0xAA) return i;
      i++;
    }
    return -1;
  }

  /// Append a fragment, doubling the backing array when it would otherwise overflow.
  void _append(Uint8List fragment) {
    if (fragment.isEmpty) return;
    if (_tail + fragment.length > _data.length) {
      var cap = _data.isEmpty ? 256 : _data.length;
      while (cap < _tail + fragment.length) {
        cap = cap << 1;
      }
      final grown = Uint8List(cap);
      grown.setRange(0, _tail, _data);
      _data = grown;
    }
    _data.setRange(_tail, _tail + fragment.length, fragment);
    _tail += fragment.length;
  }

  /// Slide the unconsumed tail back to offset 0 so [_head] can't drift forever and the array stays
  /// small. compact() runs at the end of every feed(), so [_head] is always 0 when the next append()
  /// lands. The leftover is at most one in-progress frame (< maxFrameBytes), so the move is bounded.
  void _compact() {
    if (_head == 0) return;
    final remaining = _tail - _head;
    if (remaining > 0) _data.setRange(0, remaining, _data, _head);
    _head = 0;
    _tail = remaining;
  }
}

/// Outcome of validating a frame envelope and its CRCs.
class _FrameCheck {
  const _FrameCheck({
    required this.ok,
    this.length,
    this.headerCrcOk,
    this.crc32Ok,
  });

  final bool ok;
  final int? length;
  final bool? headerCrcOk;
  final bool? crc32Ok;
}

/// Frame envelope validation, decode, and command building. Mirrors the Kotlin `object Framing`.
class Framing {
  Framing._();

  // MARK: - validation

  /// Validate a complete Whoop 4.0 frame envelope and both CRCs.
  /// Frame: [0xAA][len u16 LE][crc8(len)][...inner...][crc32 u32 LE], total = len + 4.
  static _FrameCheck _verifyWhoop4(Uint8List frame) {
    if (frame.length < 8 || frame[0] != 0xAA) return const _FrameCheck(ok: false);
    final length = (frame[1] & 0xFF) | ((frame[2] & 0xFF) << 8);
    // Ranged CRC checksums the two length bytes in place, with no per-frame allocation.
    final headerOk = Crc.crc8(frame, from: 1, to: 3) == (frame[3] & 0xFF);
    bool? crc32Ok;
    // length must cover at least the envelope's inner bytes (mirrors framing.py).
    if (length >= 7 && length <= frame.length - 4) {
      // inner record = frame[4 until length], checksummed in place.
      final want = Crc.crc32(frame, from: 4, to: length);
      final got = _u32(frame, length) ?? 0;
      crc32Ok = want == got;
    }
    return _FrameCheck(
      ok: headerOk && (crc32Ok == true),
      length: length,
      headerCrcOk: headerOk,
      crc32Ok: crc32Ok,
    );
  }

  /// Validate a Whoop 5.0 frame:
  ///   [0] 0xAA [1] format [2..3] declaredLength u16 LE [4..5] header
  ///   [6..7] CRC16-Modbus over frame[0..<6] LE  [8..] payload   tail CRC32 LE over payload
  ///   total = declaredLength + 8 (declaredLength counts payload + the 4-byte CRC32 trailer).
  static _FrameCheck _verifyWhoop5(Uint8List frame) {
    if (frame.length < 12 || frame[0] != 0xAA) return const _FrameCheck(ok: false);
    final declaredLength = (frame[2] & 0xFF) | ((frame[3] & 0xFF) << 8);
    if (declaredLength < 4) return _FrameCheck(ok: false, length: declaredLength);
    final total = declaredLength + 8;

    // Ranged CRC over the first 6 header bytes in place, with no copyOfRange.
    final wantHeader = Crc.crc16Modbus(frame, from: 0, to: 6);
    final gotHeader = (frame[6] & 0xFF) | ((frame[7] & 0xFF) << 8);
    final headerOk = wantHeader == gotHeader;

    bool? crc32Ok;
    if (frame.length >= total) {
      final payloadEnd = total - 4;
      // payload = frame[8 until payloadEnd], checksummed in place.
      final want = Crc.crc32(frame, from: 8, to: payloadEnd);
      final got = _u32(frame, payloadEnd) ?? 0;
      crc32Ok = want == got;
    }
    return _FrameCheck(
      ok: headerOk && (crc32Ok == true),
      length: declaredLength,
      headerCrcOk: headerOk,
      crc32Ok: crc32Ok,
    );
  }

  // MARK: - type / enum naming

  /// Canonical packet-type name, aliasing the Whoop 5.0 "puffin" types onto their base names.
  static String _typeName(int t) {
    if (t == PuffinPacketType.puffinCommandResponse) return 'COMMAND_RESPONSE';
    if (t == PuffinPacketType.puffinMetadata) return 'METADATA';
    final pt = PacketType.fromRaw(t);
    return pt != null ? _wireName(pt) : 'type$t';
  }

  /// "NAME(raw)" for a known enum value, else "0xHH(raw)" — matches Swift `Schema.enumName`.
  static String _eventLabel(int v) {
    final e = EventNumber.fromRaw(v);
    return e != null ? '${_wireName(e)}($v)' : _hexLabel(v);
  }

  static String _metaLabel(int v) {
    final m = MetadataType.fromRaw(v);
    return m != null ? '${_wireName(m)}($v)' : _hexLabel(v);
  }

  static String _commandLabel(int v) {
    final c = CommandNumber.fromRaw(v);
    return c != null ? '${_wireName(c)}($v)' : _hexLabel(v);
  }

  /// 5/MG COMMAND_RESPONSE result codes. 3=UNSUPPORTED matches our own MG haptics-rejection
  /// capture (#48); 2=PENDING precedes SUCCESS on GET_DATA_RANGE (hardware-confirmed, #78 fork).
  static String _commandResultLabel(int v) {
    switch (v) {
      case 0:
        return 'FAILURE(0)';
      case 1:
        return 'SUCCESS(1)';
      case 2:
        return 'PENDING(2)';
      case 3:
        return 'UNSUPPORTED(3)';
      default:
        return _hexLabel(v);
    }
  }

  static String _hexLabel(int v) =>
      '0x${v.toRadixString(16).toUpperCase().padLeft(2, '0')}($v)';

  // MARK: - parse

  /// Decode a complete frame for the given [family]. Returns [ParsedFrame] with `ok`/`crcOk`,
  /// the canonical `typeName`, and a flat `parsed` map of decoded fields.
  static ParsedFrame parseFrame(Uint8List frame,
      [DeviceFamily family = DeviceFamily.whoop4]) {
    switch (family) {
      case DeviceFamily.whoop4:
        return _parseWhoop4(frame);
      case DeviceFamily.whoop5:
        return _parseWhoop5(frame);
    }
  }

  static ParsedFrame _parseWhoop4(Uint8List frame) {
    if (frame.length < 8 || frame[0] != 0xAA) return ParsedFrame.invalid();

    final check = _verifyWhoop4(frame);
    final length = check.length;
    final crcOk = check.crc32Ok;

    final t = frame[4] & 0xFF;
    final name = _typeName(t);
    final parsed = <String, Object?>{};

    switch (name) {
      case 'REALTIME_DATA':
        _decodeRealtime(frame, parsed);
        break;
      case 'EVENT':
        _decodeEvent(frame, length, parsed);
        break;
      case 'COMMAND_RESPONSE':
        _decodeCommandResponse(frame, length, parsed);
        break;
      case 'METADATA':
        _decodeMetadata(frame, length, parsed);
        break;
    }

    return ParsedFrame(ok: true, crcOk: crcOk, typeName: name, parsed: parsed);
  }

  static ParsedFrame _parseWhoop5(Uint8List frame) {
    // Minimum whoop5 frame: 8 header bytes + 1 inner (type) + 4 CRC32 trailer.
    if (frame.length < 12 || frame[0] != 0xAA) return ParsedFrame.invalid();
    final check = _verifyWhoop5(frame);
    const innerStart = 8;
    final t = frame[innerStart] & 0xFF;
    final name = _typeName(t);
    final parsed = <String, Object?>{};
    // WHOOP 5.0 field offsets are the 4.0 layout shifted by +4 (inner record starts at byte 8 vs 4).
    // REALTIME_DATA is hardware-verified at +4 (HR matched the 0x2A37 profile to ~0.4 bpm over 96
    // worn frames; see the Swift Whoop5RealtimeTests vector). Other types stay envelope-only until
    // their per-type 5.0 offsets are confirmed on hardware — we don't invent offsets.
    switch (name) {
      case 'REALTIME_DATA':
        _decodeRealtimeWhoop5(frame, parsed);
        break;
      case 'METADATA':
        _decodeMetadataWhoop5(frame, parsed);
        break;
      case 'EVENT':
        _decodeEventWhoop5(frame, parsed);
        break;
      case 'COMMAND_RESPONSE':
        _decodeCommandResponseWhoop5(frame, parsed);
        break;
      case 'CONSOLE_LOGS':
        _decodeConsoleLogsWhoop5(frame, parsed);
        break;
    }
    return ParsedFrame(
        ok: true, crcOk: check.crc32Ok, typeName: name, parsed: parsed);
  }

  /// EVENT (type 48) for WHOOP 5.0/MG — the 4.0 layout + 4: event@10 (u8, EventNumber),
  /// event_timestamp@12 (u32), opaque payload bytes @16..size-4 (kept as hex for protocol research —
  /// real captures show uncatalogued events, e.g. 0x1D(29) with a 16-byte payload). For
  /// BATTERY_LEVEL the 4.0 payload decode shifts with it: soc%=u16@21/10, mV=u16@25, charging@30
  /// bit0 (mirrors Swift Interpreter's whoop5 event decode; all gated, fail closed). (#78 fork)
  static void _decodeEventWhoop5(Uint8List frame, Map<String, Object?> parsed) {
    final evVal = _u8(frame, 10);
    if (evVal == null) return;
    parsed['event'] = _eventLabel(evVal);
    final ts = _u32(frame, 12);
    if (ts != null) parsed['event_timestamp'] = ts.toSigned(32);
    final payEnd = frame.length - 4;
    if (payEnd > 16) {
      parsed['event_payload_hex'] = _hex(frame, 16, payEnd);
    }
    if (EventNumber.fromRaw(evVal) == EventNumber.batteryLevel) {
      final raw = _u16(frame, 21);
      if (raw != null && raw <= 1100) parsed['battery_pct'] = raw / 10.0;
      final mv = _u16(frame, 25);
      if (mv != null && mv >= 3000 && mv <= 4300) parsed['battery_mV'] = mv;
      final ch = _u8(frame, 30);
      if (ch != null && ch <= 1) parsed['battery_charging'] = ch & 1;
    }
  }

  /// COMMAND_RESPONSE (puffin type 36 alias) for WHOOP 5.0/MG: resp_cmd@10 (u8, CommandNumber),
  /// resp_seq@11 (u8), result@12 (u8 → FAILURE/SUCCESS/PENDING/UNSUPPORTED). GET_DATA_RANGE
  /// typically answers PENDING then SUCCESS; the result codes are hardware-confirmed (#78 fork,
  /// and 3=UNSUPPORTED matches our own MG haptics rejection, #48). GET_BATTERY_LEVEL carries a
  /// direct percent at @13 (gated ≤100, fail closed; Swift parity — unused until the 5/MG
  /// allowlist grows).
  static void _decodeCommandResponseWhoop5(
      Uint8List frame, Map<String, Object?> parsed) {
    final cmd = _u8(frame, 10);
    if (cmd == null) return;
    parsed['resp_cmd'] = _commandLabel(cmd);
    final seq = _u8(frame, 11);
    if (seq != null) parsed['resp_seq'] = seq;
    final result = _u8(frame, 12);
    if (result != null) parsed['result'] = _commandResultLabel(result);
    if (CommandNumber.fromRaw(cmd) == CommandNumber.getBatteryLevel) {
      final pct = _u8(frame, 13);
      if (pct != null && pct <= 100) parsed['battery_pct'] = pct.toDouble();
    }
    // GET_HELLO (145): device name + firmware version. Mirrors the Swift Interpreter decode of the
    // same 50.38.1.0 capture: payload base is frame[11]; the name is printable ASCII at pay[16],
    // the firmware is 4 bytes at pay[93] gated on pay[93]==50 (the "5.x" generation). The session
    // token in the same block is deliberately never read. Surfaced on the Devices card.
    if (cmd == 145) {
      final payEnd = frame.length - 4; // drop the trailing CRC32
      if (payEnd > 11) {
        final pay = frame.sublist(11, payEnd);
        final name = StringBuffer();
        var i = 16;
        while (i < pay.length &&
            pay[i] != 0 &&
            (pay[i] & 0xFF) >= 32 &&
            (pay[i] & 0xFF) <= 126 &&
            name.length < 24) {
          name.writeCharCode(pay[i] & 0xFF);
          i++;
        }
        if (name.length >= 6) parsed['device_name'] = name.toString();
        if (pay.length >= 97 && (pay[93] & 0xFF) == 50) {
          parsed['fw_version'] = '${pay[93] & 0xFF}.${pay[94] & 0xFF}.'
              '${pay[95] & 0xFF}.${pay[96] & 0xFF}';
        }
      }
    }
  }

  /// CONSOLE_LOGS (type 50) for WHOOP 5.0/MG: 13-byte record header after the inner type byte,
  /// then UTF-8 console text @21..size-4 with an optional NUL terminator. The strap's own
  /// diagnostics channel — it narrates history syncs ("BLE: PullStats: Data: N, Events: N…",
  /// "RTC timestamp … is invalid; not saving data to flash"), which is how the clock-before-history
  /// requirement was discovered. Capped at 2 KB (matches the Swift PostHooks console hardening).
  /// (#78 fork, real-frame verified)
  static void _decodeConsoleLogsWhoop5(
      Uint8List frame, Map<String, Object?> parsed) {
    final payEnd = frame.length - 4;
    if (payEnd <= 21) return;
    final text = _trimEndNul(utf8.decode(frame.sublist(21, payEnd), allowMalformed: true));
    if (text.isNotEmpty) {
      parsed['console'] = text.length > 2048 ? text.substring(0, 2048) : text;
    }
  }

  /// METADATA (PUFFIN_METADATA, type 56) for WHOOP 5.0/MG — the 4.0 METADATA layout + 4 (the inner
  /// record starts at byte 8 vs 4): meta_type@10 (u8), and for a HISTORY_END additionally unix@11
  /// (u32), subsec@15 (u16), trim_cursor@21 (u32). Without this, parseWhoop5 left every 5/MG METADATA
  /// frame field-less, so classifyHistoricalMeta could never recognise HISTORY_END/COMPLETE → the
  /// Backfiller never acked/trimmed → 5/MG offload never completed. Offsets verified against real
  /// WHOOP 5 HISTORY_END frames (Swift decodeWhoop5Metadata, Interpreter.swift:407). (#78)
  static void _decodeMetadataWhoop5(
      Uint8List frame, Map<String, Object?> parsed) {
    final mt = _u8(frame, 10);
    if (mt == null) return;
    parsed['meta_type'] = _metaLabel(mt);
    // Only a HISTORY_END carries unix/subsec/trim; the u-reads null out on the shorter
    // START/COMPLETE frames, so classifyHistoricalMeta keys those off meta_type alone.
    final unix = _u32(frame, 11);
    if (unix != null) parsed['unix'] = unix.toSigned(32);
    final subsec = _u16(frame, 15);
    if (subsec != null) parsed['subsec'] = subsec;
    final trim = _u32(frame, 21);
    if (trim != null) parsed['trim_cursor'] = trim.toSigned(32);
  }

  /// REALTIME_DATA (type 40) for WHOOP 5.0 — the 4.0 layout + 4: timestamp@10 (u32),
  /// subseconds@14 (u16), heart_rate@16 (u8), rr_count@17, rr@18.. (u16). Mirrors the Swift
  /// parseFrameWhoop5 realtime decode and is covered by the same real-frame test vector.
  static void _decodeRealtimeWhoop5(
      Uint8List frame, Map<String, Object?> parsed) {
    final ts = _u32(frame, 10);
    if (ts != null) parsed['timestamp'] = ts.toSigned(32);
    final subseconds = _u16(frame, 14);
    if (subseconds != null) parsed['subseconds'] = subseconds;
    final hr = _u8(frame, 16);
    if (hr != null) parsed['heart_rate'] = hr;
    final rrn = _u8(frame, 17) ?? 0;
    parsed['rr_count'] = rrn;
    final rrs = <int>[];
    for (var i = 0; i < rrn; i++) {
      final v = _u16(frame, 18 + i * 2);
      if (v != null && v > 0) rrs.add(v); // drop 0 ms placeholders, matching 4.0 / Swift
    }
    parsed['rr_intervals'] = rrs;
  }

  // MARK: - per-type decoders (Whoop 4.0). Ported from PostHooks.swift + the static field specs.

  /// REALTIME_DATA (type 40): timestamp@6 (u32), heart_rate@12 (u8), rr_count@13, rr@14.. (u16).
  static void _decodeRealtime(Uint8List frame, Map<String, Object?> parsed) {
    final ts = _u32(frame, 6);
    if (ts != null) parsed['timestamp'] = ts.toSigned(32);
    final subseconds = _u16(frame, 10);
    if (subseconds != null) parsed['subseconds'] = subseconds;
    final hr = _u8(frame, 12);
    if (hr != null) parsed['heart_rate'] = hr;
    final rrn = _u8(frame, 13) ?? 0;
    parsed['rr_count'] = rrn;
    final rrs = <int>[];
    for (var i = 0; i < rrn; i++) {
      // Drop 0 ms intervals (placeholders, not beat-to-beat intervals), matching Swift.
      final v = _u16(frame, 14 + i * 2);
      if (v != null && v > 0) rrs.add(v);
    }
    parsed['rr_intervals'] = rrs;
  }

  /// EVENT (type 48): event@6 (u8, EventNumber), event_timestamp@8 (u32).
  /// For BATTERY_LEVEL, additionally decode soc@17(/10), mV@21, charging@26 bit0.
  static void _decodeEvent(
      Uint8List frame, int? length, Map<String, Object?> parsed) {
    final evVal = _u8(frame, 6);
    if (evVal == null) return;
    parsed['event'] = _eventLabel(evVal);
    final ts = _u32(frame, 8);
    if (ts != null) parsed['event_timestamp'] = ts.toSigned(32);

    if (EventNumber.fromRaw(evVal) == EventNumber.batteryLevel && length != null) {
      // Fixed layout, empirically verified against captured frames:
      //   soc% = u16@17/10 · mV = u16@21 · charging = u8@26 bit0
      final raw = _u16(frame, 17);
      if (raw != null && raw <= 1100) parsed['battery_pct'] = raw / 10.0;
      final mv = _u16(frame, 21);
      if (mv != null && mv >= 3000 && mv <= 4300) parsed['battery_mV'] = mv;
      final ch = _u8(frame, 26);
      if (ch != null && ch <= 1) parsed['battery_charging'] = ch & 1;
    }
  }

  /// COMMAND_RESPONSE (type 36): resp_cmd@6 (u8, CommandNumber). Decodes the battery level reply.
  /// Payload begins at offset 7; GET_BATTERY_LEVEL stores soc% = u16(payload[2..4]) / 10.
  static void _decodeCommandResponse(
      Uint8List frame, int? length, Map<String, Object?> parsed) {
    if (length == null) return;
    final payEnd = length < frame.length ? length : frame.length;
    if (payEnd < 7) return;
    final pay = frame.sublist(7, payEnd);
    final cmd = _u8(frame, 6);
    if (cmd == null) return;
    parsed['resp_cmd'] = _commandLabel(cmd);
    switch (CommandNumber.fromRaw(cmd)) {
      case CommandNumber.getBatteryLevel:
        if (pay.length >= 4) {
          final v = (pay[2] & 0xFF) | ((pay[3] & 0xFF) << 8);
          parsed['battery_pct'] = v / 10.0;
        }
        break;
      case CommandNumber.getClock:
        if (pay.length >= 6) {
          final v = (pay[2] & 0xFF) |
              ((pay[3] & 0xFF) << 8) |
              ((pay[4] & 0xFF) << 16) |
              ((pay[5] & 0xFF) << 24);
          parsed['clock'] = v.toSigned(32);
        }
        break;
      case CommandNumber.reportVersionInfo:
        // WHOOP 4.0 firmware version (the main "Harvard" MCU): four little-endian u32 at
        // pay[3,7,11,15]. Same base/offsets as the Swift PostHooks fw_harvard decode (pay also
        // starts at frame[7] there). Surfaced on the Devices card.
        if (pay.length >= 19) {
          int le32(int at) =>
              (pay[at] & 0xFF) |
              ((pay[at + 1] & 0xFF) << 8) |
              ((pay[at + 2] & 0xFF) << 16) |
              ((pay[at + 3] & 0xFF) << 24);
          parsed['fw_harvard'] = '${le32(3)}.${le32(7)}.${le32(11)}.${le32(15)}';
        }
        break;
      default:
        break;
    }
  }

  /// METADATA (type 49): meta_type@6 (u8, MetadataType). For a 14-byte payload ('<LHLL'):
  /// unix@7 (u32), subsec@11 (u16), unk0@13 (u32), trim_cursor@17 (u32).
  static void _decodeMetadata(
      Uint8List frame, int? length, Map<String, Object?> parsed) {
    final mt = _u8(frame, 6);
    if (mt == null) return;
    parsed['meta_type'] = _metaLabel(mt);
    if (length == null) return;
    final payEnd = length < frame.length ? length : frame.length;
    if (payEnd <= 7) return;
    final pay = frame.sublist(7, payEnd);
    if (pay.length >= 14) {
      final unix = (pay[0] & 0xFF) |
          ((pay[1] & 0xFF) << 8) |
          ((pay[2] & 0xFF) << 16) |
          ((pay[3] & 0xFF) << 24);
      final ss = (pay[4] & 0xFF) | ((pay[5] & 0xFF) << 8);
      final trim = (pay[10] & 0xFF) |
          ((pay[11] & 0xFF) << 8) |
          ((pay[12] & 0xFF) << 16) |
          ((pay[13] & 0xFF) << 24);
      parsed['unix'] = unix.toSigned(32);
      parsed['subsec'] = ss;
      parsed['trim_cursor'] = trim.toSigned(32);
    }
  }

  // MARK: - command building

  /// Build a complete, framed COMMAND packet ready to write to the command characteristic.
  ///
  /// Layout (verified against the device): `[0xAA][len u16 LE][crc8(len)][type=35][seq][cmd][payload][crc32 LE]`
  ///  - `len`  = (3 + payload.size) + 4  (inner type+seq+cmd+payload, plus the 4 envelope bytes)
  ///  - `crc8` is over the two length bytes only
  ///  - `crc32` (zlib) is over the inner `[type][seq][cmd][payload]`, stored little-endian
  static Uint8List buildCommand(CommandNumber cmd,
      {Uint8List? payload, int seq = 0}) {
    final pay = payload ?? Uint8List.fromList(<int>[0]);
    final inner = Uint8List(3 + pay.length);
    inner[0] = PacketType.command.rawValue & 0xFF; // type = 35
    inner[1] = seq & 0xFF;
    inner[2] = cmd.rawValue & 0xFF;
    inner.setRange(3, 3 + pay.length, pay);

    final length = inner.length + 4;
    final lenLo = length & 0xFF;
    final lenHi = (length >> 8) & 0xFF;
    final headerCrc = Crc.crc8(Uint8List.fromList(<int>[lenLo, lenHi])) & 0xFF;
    final trailer = Crc.crc32(inner);

    final frame = Uint8List(1 + 2 + 1 + inner.length + 4);
    var i = 0;
    frame[i++] = 0xAA;
    frame[i++] = lenLo;
    frame[i++] = lenHi;
    frame[i++] = headerCrc;
    frame.setRange(i, i + inner.length, inner);
    i += inner.length;
    frame[i++] = trailer & 0xFF;
    frame[i++] = (trailer >> 8) & 0xFF;
    frame[i++] = (trailer >> 16) & 0xFF;
    frame[i] = (trailer >> 24) & 0xFF;
    return frame;
  }

  /// EXPERIMENTAL: build a WHOOP 5.0/MG ("puffin") command frame in the CRC16 envelope.
  ///
  /// Direct port of the Swift `puffinCommandFrame` (WhoopProtocol/Framing.swift). The inner record
  /// is `[type][seq][cmd] + payload`; `declLen = inner.size + 4` (the CRC32 tail); the CRC16-Modbus
  /// covers the first six header bytes. `type` defaults to 35 (COMMAND) and `header` to `[0x00,
  /// 0x01]`, mirroring the structure of the only puffin frame we know a real strap accepts (the
  /// static CLIENT_HELLO). The returned frame round-trips through `parseFrame(frame, WHOOP5)`.
  ///
  /// Layout (LE = little-endian):
  ///   inner  = [type][seq][cmd] + payload
  ///   declLen = inner.size + 4
  ///   frame  = [0xAA, 0x01, declLen LE(2), header[0], header[1]]
  ///          + crc16Modbus(frame[0..6)) LE(2)
  ///          + inner
  ///          + crc32(inner) LE(4)
  static Uint8List puffinCommandFrame({
    required int cmd,
    required int seq,
    Uint8List? payload,
    int? type,
    Uint8List? header,
  }) {
    final pay = payload ?? Uint8List.fromList(<int>[0x00]);
    final typeByte = type ?? PacketType.command.rawValue; // 35
    final hdr = header ?? Uint8List.fromList(<int>[0x00, 0x01]);

    final inner0 = Uint8List(3 + pay.length);
    inner0[0] = typeByte & 0xFF;
    inner0[1] = seq & 0xFF;
    inner0[2] = cmd & 0xFF;
    inner0.setRange(3, 3 + pay.length, pay);
    // Pad the inner record to a 4-byte boundary before length/CRC, exactly as the strap's maverick
    // framing does (pad4). No-op for the 4-aligned commands shipped so far (toggle HR, historical),
    // but REQUIRED for the 12-byte haptics payload (inner 15 -> 16) — otherwise the declared length
    // and CRC32 cover the wrong byte count and the strap rejects the frame (#48).
    final pad = (4 - inner0.length % 4) % 4;
    final Uint8List inner;
    if (pad == 0) {
      inner = inner0;
    } else {
      inner = Uint8List(inner0.length + pad);
      inner.setRange(0, inner0.length, inner0);
    }

    final declLen = inner.length + 4;

    // Six-byte header: SOF, format byte, declLen LE(2), header(2). CRC16-Modbus is over these.
    final head = Uint8List(6);
    head[0] = 0xAA;
    head[1] = 0x01;
    head[2] = declLen & 0xFF;
    head[3] = (declLen >> 8) & 0xFF;
    head[4] = hdr[0];
    head[5] = hdr[1];
    final c16 = Crc.crc16Modbus(head);
    final c32 = Crc.crc32(inner);

    final frame = Uint8List(6 + 2 + inner.length + 4);
    var i = 0;
    frame.setRange(i, i + 6, head);
    i += 6;
    frame[i++] = c16 & 0xFF;
    frame[i++] = (c16 >> 8) & 0xFF;
    frame.setRange(i, i + inner.length, inner);
    i += inner.length;
    frame[i++] = c32 & 0xFF;
    frame[i++] = (c32 >> 8) & 0xFF;
    frame[i++] = (c32 >> 16) & 0xFF;
    frame[i] = (c32 >> 24) & 0xFF;
    return frame;
  }

  // MARK: - small helpers

  /// Lowercase hex of `d[from until to]` with no separators (mirrors Kotlin joinToString("%02x")).
  static String _hex(Uint8List d, int from, int to) {
    final sb = StringBuffer();
    for (var i = from; i < to; i++) {
      sb.write((d[i] & 0xFF).toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  /// Strip trailing NUL code units (mirrors Kotlin `trimEnd(' ')`).
  static String _trimEndNul(String s) {
    var end = s.length;
    while (end > 0 && s.codeUnitAt(end - 1) == 0) {
      end--;
    }
    return s.substring(0, end);
  }
}
