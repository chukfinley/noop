/// Faithful Dart port of `HistoricalStreams.kt`.
///
/// Historical (offload) decode for the WHOOP 4.0/5.0 — the type-47 HISTORICAL_DATA path.
///
/// Faithful port of three macOS Swift pieces:
///   - the `postHooks["historical_data"]` decoder (Packages/WhoopProtocol/.../PostHooks.swift),
///     which decodes a type-47 record's biometric block using the per-version field table baked
///     into whoop_protocol.json (V24/V12 = full DSP block; V5/V7/V9 = generic HR/RR only),
///   - `classifyHistoricalMeta` (Packages/WhoopProtocol/.../HistoricalMeta.swift), the METADATA
///     classifier the offload state machine uses, and
///   - `extractHistoricalStreams` (Packages/WhoopProtocol/.../HistoricalStreams.swift), which turns
///     a batch of parsed offload frames into datastore rows.
///
/// WHY this lives here and not in [Framing.parseFrame]: the live [Framing] decoder deliberately
/// does NOT decode type-47 (it only handles REALTIME_DATA / EVENT / COMMAND_RESPONSE / METADATA),
/// exactly like the Swift live path. Historical records are decoded only during a backfill, so the
/// type-47 decoder is kept on the offload path to mirror the Swift split precisely.
///
/// The frame envelope is identical to Framing.kt's: [0]=0xAA, [1..2]=len u16 LE, [3]=crc8(len),
/// [4]=packet type (47 here), [5]=record VERSION (NOT a sequence byte for type-47 — the schema
/// note says "Version = seq byte (frame[5])"), [6..]=record. Field offsets in the version table
/// are FRAME-ABSOLUTE (= openwhoop data offset + 7). All multi-byte values are little-endian.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'device_family.dart';
import 'enums.dart';
import 'framing.dart';
import 'parsed_frame.dart';
import 'ppg_hr.dart';
import 'streams.dart';

// MARK: - plausible-timestamp bounds (#547)

/// Lowest unix-second a real WHOOP record can carry (2023-11). A bad strap clock/flash (pikapik, #547)
/// emits records whose `unix` decodes to scattered garbage — far-past (year 2024/2019/…), a year-2027
/// spike (1_827_642_881), and even a FUTURE date. Those land in the DB verbatim and pollute the
/// day-windowed analytics. Reuses the same 1.7 B floor already used to validate GET_DATA_RANGE words.
/// Below this → drop the record.
const int minPlausibleUnix = 1700000000;

/// How far past the offload wall-clock a record may be stamped (#547). A historical record can NEVER
/// post-date its own capture, so anything more than one day ahead of "now" is a bad-clock artefact.
const int futureMargin = 86400;

/// SESSION-RELATIVE slack (#547): how far OUTSIDE the strap's own GET_DATA_RANGE oldest/newest markers a
/// record may still be stamped before it's treated as wandering-clock pollution. 7 days absorbs marker
/// jitter / a still-banking newest edge / DST while still catching months-off garbage. Kept in lockstep
/// with Swift `HistoricalStreams.swift` SESSION_RANGE_MARGIN.
const int sessionRangeMargin = 7 * 86400;

// MARK: - little-endian readers (null when out of range; mirror PostHooks.swift u8/u16/u32/f32)

int? _histU8(Uint8List d, int off) => off + 1 <= d.length ? d[off] & 0xFF : null;

int? _histU16(Uint8List d, int off) =>
    off + 2 <= d.length ? (d[off] & 0xFF) | ((d[off + 1] & 0xFF) << 8) : null;

/// Signed little-endian i16 (two's complement). null when out of range. Mirrors Swift `readI16`.
int? _histI16(Uint8List d, int off) {
  if (off + 2 > d.length) return null;
  final u = (d[off] & 0xFF) | ((d[off + 1] & 0xFF) << 8);
  return u >= 0x8000 ? u - 0x10000 : u;
}

/// Unsigned little-endian u32 (0..0xFFFFFFFF). null when out of range.
int? _histU32(Uint8List d, int off) {
  if (off + 4 > d.length) return null;
  return (d[off] & 0xFF) |
      ((d[off + 1] & 0xFF) << 8) |
      ((d[off + 2] & 0xFF) << 16) |
      ((d[off + 3] & 0xFF) << 24);
}

/// IEEE-754 float32 LE -> double (exact, NO rounding). null when out of range.
/// Port of PostHooks.swift `f32`: read 4 bytes as a float32 bit-pattern, widen to double — the exact
/// analog of Kotlin `Float.fromBits(Int).toDouble()` / Swift `Float(bitPattern:)`.
double? _histF32(Uint8List d, int off) {
  if (off + 4 > d.length) return null;
  return ByteData.sublistView(d, off, off + 4).getFloat32(0, Endian.little);
}

/// One decoded type-47 field-layout VERSION. Frame-absolute offsets, lifted verbatim from the
/// `HISTORICAL_DATA.versions` table in whoop_protocol.json. `rrFirstOff` is where the (up to 4)
/// u16 R-R intervals begin. A null DSP-block offset means that field is absent for the version.
class _HistVersion {
  const _HistVersion({
    required this.unixOff,
    required this.hrOff,
    required this.rrCountOff,
    required this.rrFirstOff,
    this.spo2RedOff,
    this.spo2IrOff,
    this.skinTempRawOff,
    this.respRateRawOff,
    this.gravityXOff,
    this.gravityYOff,
    this.gravityZOff,
  });

  final int unixOff;
  final int hrOff;
  final int rrCountOff;
  final int rrFirstOff;
  // Full DSP biometric block (V24 / V12 only); null on the generic V5/V7/V9 records.
  final int? spo2RedOff;
  final int? spo2IrOff;
  final int? skinTempRawOff;
  final int? respRateRawOff;
  final int? gravityXOff;
  final int? gravityYOff;
  final int? gravityZOff;
}

/// V24 layout (this WHOOP 4.0; verified on 762 device records per the schema note). V12 shares the
/// exact same DSP layout ("ref":"24"). Offsets are FRAME-ABSOLUTE, copied from whoop_protocol.json.
const _HistVersion _histV24 = _HistVersion(
  unixOff: 11,
  hrOff: 21,
  rrCountOff: 22,
  rrFirstOff: 23,
  spo2RedOff: 68,
  spo2IrOff: 70,
  skinTempRawOff: 72,
  respRateRawOff: 80,
  gravityXOff: 40,
  gravityYOff: 44,
  gravityZOff: 48,
);

/// Generic HR/RR-only record (V5; V7/V9 share it via "ref":"5"). No DSP sensor block.
const _HistVersion _histV5 = _HistVersion(
  unixOff: 11,
  hrOff: 21,
  rrCountOff: 22,
  rrFirstOff: 23,
);

/// Resolve a record version (frame[5]) to its field layout, or null if the layout is unmapped.
_HistVersion? _histVersionLayout(int version) {
  switch (version) {
    case 24:
    case 12:
      return _histV24;
    case 5:
    case 7:
    case 9:
      return _histV5;
    default:
      return null;
  }
}

/// Decode a single type-47 HISTORICAL_DATA frame into the same flat parsed-map keys the Swift
/// `postHooks["historical_data"]` produces. Returns null when the frame is not a valid type-47
/// record (wrong SOF/too short/failed CRC/unmapped version) — callers skip those, matching the
/// Swift `if !r.ok || r.crcOK == false { continue }` + unmapped-layout guard.
///
/// Keys emitted (only when present in the frame): `hist_version`, `unix`, `heart_rate`, `rr_count`,
/// `rr_intervals` (`List<int>`), `spo2_red`, `spo2_ir`, `skin_temp_raw`, `resp_rate_raw`, `gravity_x`,
/// `gravity_y`, `gravity_z`. These match the keys [extractHistoricalStreams] reads.
Map<String, Object?>? decodeHistorical(
  Uint8List frame, [
  DeviceFamily family = DeviceFamily.whoop4,
]) {
  if (frame.length < 8 || frame[0] != 0xAA) return null;

  // Integrity gate: validate the envelope + CRC32 via the shared Framing parser. We reuse its
  // crcOk so a garbled/forged offload frame can never inject rows. parseFrame leaves type-47's
  // `parsed` empty (the live decoder skips type-47), so we decode the record ourselves below.
  final checked = Framing.parseFrame(frame, family);
  if (!checked.ok || checked.crcOk == false) return null;

  // WHOOP 5.0/MG has the longer puffin envelope (record @8), so its v18 layout is decoded separately
  // at its own absolute offsets (port of Swift decodeWhoop5Historical). WHOOP 4 below is unchanged.
  if (family == DeviceFamily.whoop5) return _decodeWhoop5Historical(frame);
  if (family != DeviceFamily.whoop4) return null;
  if ((frame[4] & 0xFF) != PacketType.historicalData.rawValue) return null;

  final version = frame[5] & 0xFF;

  // WHOOP 4.0 **v25** historical layout (issue #30). RE'd from 45 real records on v1.92+ full dumps:
  // an 84-byte record with `unix` @11 (u32 LE) and the DSP gravity vector @73/75/77 as 3×i16 LE /
  // 16384 — |gravity| ≈ 1 g on 45/45 records. Bytes 23-72 are the optical PPG waveform; per-second HR
  // is NOT stored in v25 (PPG-derived), so this yields motion + timestamp — exactly what the sleep
  // stager gates on. Additive + version-gated; v18/v24/v26 untouched. Mirrors Swift PostHooks v25 case.
  if (version == 25 && frame.length >= 79) {
    final out = <String, Object?>{};
    out['hist_version'] = version;
    final u = _histU32(frame, 11);
    if (u != null) out['unix'] = u.toSigned(32);
    double? grav(int off) {
      final v = _histU16(frame, off);
      if (v == null) return null;
      return (v >= 32768 ? v - 65536 : v) / 16384.0; // i16 LE, ±2 g full-scale
    }

    final gx = grav(73);
    final gy = grav(75);
    final gz = grav(77);
    if (gx != null && gy != null && gz != null) {
      final mag = sqrt(gx * gx + gy * gy + gz * gz);
      if (mag >= 0.5 && mag <= 1.5) {
        // a real DSP orientation vector is ~1 g; reject garbage
        out['gravity_x'] = gx;
        out['gravity_y'] = gy;
        out['gravity_z'] = gz;
      }
    }
    out['rr_intervals'] = <int>[];
    return out;
  }

  // Unmapped firmware version: instead of dropping the whole record, fall back to the canonical v24
  // DSP layout. Firmware versions overwhelmingly share it (V12 == V24). We accept the fallback ONLY if
  // it decodes to physically-real data (validated at the end) so a wrong layout can never store
  // garbage. Mapped versions are unaffected. Mirrors Swift PostHooks "historical_data". (#30 / #77)
  final mapped = _histVersionLayout(version);
  final usingFallback = mapped == null;
  final layout = mapped ?? _histV24;

  final out = <String, Object?>{};
  out['hist_version'] = version;

  // unix is the record's REAL unix seconds (no clock offset needed for type-47).
  final unix = _histU32(frame, layout.unixOff);
  if (unix != null) out['unix'] = unix.toSigned(32);
  final hr = _histU8(frame, layout.hrOff);
  if (hr != null) out['heart_rate'] = hr;
  final rrn = _histU8(frame, layout.rrCountOff) ?? 0;
  out['rr_count'] = rrn;

  // Up to 4 R-R intervals (u16, ms). Drop 0 ms placeholders, matching PostHooks (`v != 0`).
  final rrVals = <int>[];
  for (var i = 0; i < min(rrn, 4); i++) {
    final v = _histU16(frame, layout.rrFirstOff + i * 2);
    if (v != null && v != 0) rrVals.add(v);
  }
  out['rr_intervals'] = rrVals;

  // Full DSP block (V24/V12 only). Each read is guarded; absent fields are simply not emitted.
  if (layout.spo2RedOff != null) {
    final v = _histU16(frame, layout.spo2RedOff!);
    if (v != null) out['spo2_red'] = v;
  }
  if (layout.spo2IrOff != null) {
    final v = _histU16(frame, layout.spo2IrOff!);
    if (v != null) out['spo2_ir'] = v;
  }
  if (layout.skinTempRawOff != null) {
    final v = _histU16(frame, layout.skinTempRawOff!);
    if (v != null) out['skin_temp_raw'] = v;
  }
  if (layout.respRateRawOff != null) {
    final v = _histU16(frame, layout.respRateRawOff!);
    if (v != null) out['resp_rate_raw'] = v;
  }
  if (layout.gravityXOff != null) {
    final v = _histF32(frame, layout.gravityXOff!);
    if (v != null) out['gravity_x'] = v;
  }
  if (layout.gravityYOff != null) {
    final v = _histF32(frame, layout.gravityYOff!);
    if (v != null) out['gravity_y'] = v;
  }
  if (layout.gravityZOff != null) {
    final v = _histF32(frame, layout.gravityZOff!);
    if (v != null) out['gravity_z'] = v;
  }

  // Validate the v24-layout guess for an unmapped version: gravity is the DSP-separated orientation
  // vector, so |gravity| ≈ 1 g on a real record regardless of motion, and HR is physiological. If the
  // guess doesn't fit this firmware the decoded values are random — drop the record rather than store
  // garbage. Mapped versions skip this entirely. (#30 / #77)
  if (usingFallback) {
    final gx = (out['gravity_x'] as double?) ?? double.nan;
    final gy = (out['gravity_y'] as double?) ?? double.nan;
    final gz = (out['gravity_z'] as double?) ?? double.nan;
    final mag = sqrt(gx * gx + gy * gy + gz * gz);
    final h = (out['heart_rate'] as int?) ?? 0;
    if (!(mag >= 0.8 && mag <= 1.2 && h >= 25 && h <= 230)) return null;
  }

  return out;
}

/// WHOOP 5.0/MG type-47 "v18" historical decode. The puffin envelope is longer, so the record starts
/// at byte 8 (type@8, version@9) and fields sit at their WHOOP5-ABSOLUTE offsets — NOT the WHOOP4 V24
/// layout shifted by +4. Offsets verified against real worn/off-wrist frames: unix@15, hr@22, rr@24+,
/// gravity@45/49/53, and per-second fields each gated to a physical range so a wrong offset on
/// unmapped firmware stores nothing. Mirrors Swift `decodeWhoop5Historical`, and emits the same keys
/// [extractHistoricalStreams] reads. v26 (PPG) and other versions aren't stored, so they return null.
Map<String, Object?>? _decodeWhoop5Historical(Uint8List frame) {
  if (_histU8(frame, 8) != PacketType.historicalData.rawValue) return null;
  final version = _histU8(frame, 9);
  if (version == null) return null;
  if (version != 18) return null;

  final out = <String, Object?>{};
  out['hist_version'] = version;
  // @11 a per-record counter: +1 every record, independent of unix (advances across gaps). @11 is
  // only the low byte — read the full u32 LE.
  final recordIndex = _histU32(frame, 11);
  if (recordIndex != null) out['record_index'] = recordIndex.toSigned(32);
  final unix = _histU32(frame, 15);
  if (unix != null) out['unix'] = unix.toSigned(32);
  final hr = _histU8(frame, 22);
  if (hr != null) out['heart_rate'] = hr;
  final rrn = _histU8(frame, 23) ?? 0;
  out['rr_count'] = rrn;
  final rrVals = <int>[];
  for (var i = 0; i < min(rrn, 4); i++) {
    final v = _histU16(frame, 24 + i * 2);
    if (v != null && v != 0) rrVals.add(v);
  }
  out['rr_intervals'] = rrVals;
  // Bytes adjacent to the HR/R-R fields. @36/256 tracks hr@22 to sub-bpm (corr 0.989) — a
  // higher-precision heart rate; the others are carried raw (meaning not pinned).
  final cardiacFlags = _histU8(frame, 33);
  if (cardiacFlags != null) out['cardiac_flags'] = cardiacFlags;
  final hrFixed = _histU16(frame, 36);
  if (hrFixed != null) out['hr_fixed_8_8'] = hrFixed; // bpm = value / 256
  final rrPacked = _histU16(frame, 38);
  if (rrPacked != null) out['rr_packed'] = rrPacked;
  final cardiacStatus = _histU8(frame, 40);
  if (cardiacStatus != null) out['cardiac_status'] = cardiacStatus;
  final gravX = _histF32(frame, 45);
  if (gravX != null) out['gravity_x'] = gravX;
  final gravY = _histF32(frame, 49);
  if (gravY != null) out['gravity_y'] = gravY;
  final gravZ = _histF32(frame, 53);
  if (gravZ != null) out['gravity_z'] = gravZ;

  // Per-second fields beyond HR/gravity, each gated to a physically-real range (cross-validated
  // worn vs off-wrist). Optical/perfusion @69/71 still doesn't decode consistently and is left raw.
  final dynAccel = _histF32(frame, 41);
  if (dynAccel != null && dynAccel.isFinite && dynAccel >= 0.0 && dynAccel <= 8.0) {
    out['dynamic_acceleration'] = dynAccel;
  }
  final stepCounter = _histU16(frame, 57);
  if (stepCounter != null) out['step_motion_counter'] = stepCounter;
  // @59 a per-step cadence-like byte (never 0; lower when moving faster). Raw — no unit asserted.
  final stepCadence = _histU8(frame, 59);
  if (stepCadence != null) out['step_cadence'] = stepCadence;
  final wearQuality = _histU8(frame, 63);
  if (wearQuality != null && wearQuality >= 0 && wearQuality <= 2) {
    out['motion_wear_quality'] = wearQuality;
  }
  // @63 also reads as a small validated ACTIVITY-CLASS enum (community finding, #316): 0=still, 1=walk,
  // 2=run, 0xFF=invalid. Only the known codes are surfaced — anything else stores nothing.
  final activityClass = _histU8(frame, 63);
  if (activityClass != null &&
      (activityClass == 0 || activityClass == 1 || activityClass == 2)) {
    out['activity_class'] = activityClass;
  }
  // Auxiliary thermal readings adjacent to the main skin-temperature register. Carried raw; °C =
  // raw/10. Signed i16, gated to a plausible thermal range.
  final tempAux1 = _histI16(frame, 69);
  if (tempAux1 != null && (tempAux1 / 10.0) >= 0.0 && (tempAux1 / 10.0) <= 60.0) {
    out['temp_aux_1_raw'] = tempAux1;
  }
  final tempAux2 = _histI16(frame, 71);
  if (tempAux2 != null && (tempAux2 / 10.0) >= 0.0 && (tempAux2 / 10.0) <= 60.0) {
    out['temp_aux_2_raw'] = tempAux2;
  }
  // skin temp: raw u16 (the store keeps it raw, /100 at display). Gate on a plausible thermal range:
  // °C = raw/100. The gate is only a garbage filter; the absolute scale lives in the consumer.
  final skinTemp = _histU16(frame, 73);
  if (skinTemp != null && (skinTemp / 100.0) >= 5.0 && (skinTemp / 100.0) <= 45.0) {
    out['skin_temp_raw'] = skinTemp;
  }
  // @75 a 16-bit status word; NOT a deep-sleep marker.
  final statusWord = _histU16(frame, 75);
  if (statusWord != null) out['status_word'] = statusWord;
  // @77 / @79 two further 16-bit status words adjacent to @75; carried raw, meaning not pinned.
  final statusWord1 = _histU16(frame, 77);
  if (statusWord1 != null) out['status_word_1'] = statusWord1;
  final statusWord2 = _histU16(frame, 79);
  if (statusWord2 != null) out['status_word_2'] = statusWord2;
  // @81 packs several band flags into one byte. High nibble (bits 4-5) tracks a scored night:
  // 0 wake / 1 still / 2 asleep / 3 up. bits 2-3 a wake-quality field; bits 0-1 an on-wrist flag.
  final band81 = _histU8(frame, 81);
  if (band81 != null) {
    out['sleep_state'] = (band81 >> 4) & 3;
    out['wake_quality'] = (band81 >> 2) & 3;
    out['onwrist'] = band81 & 3;
  }
  // @82 a single raw byte adjacent to the flag byte; carried raw, meaning not pinned.
  final aux82 = _histU8(frame, 82);
  if (aux82 != null) out['aux_byte_82'] = aux82;
  // @113 a float32 (observed range ~ -5.3..0, 0 = unset); purpose unknown, carried raw. EMPIRICAL.
  final unknown113 = _histF32(frame, 113);
  if (unknown113 != null && unknown113.isFinite) out['unknown_f32_113'] = unknown113;
  return out;
}

/// WHOOP 5.0/MG type-47 **layout v26** PPG-waveform record (#156). Mirror of Swift
/// `decodeWhoop5HistoricalV26`. v26 is a 24 Hz optical PPG buffer: **24 little-endian i16 samples at
/// frame bytes [27:75]**, one record per second, with the record's own unix u32 LE @15 (the v18 slot).
class _V26Record {
  const _V26Record({required this.unix, required this.samples});
  final int unix;
  final List<int> samples;
}

_V26Record? _decodeWhoop5HistoricalV26(Uint8List frame) {
  if (_histU8(frame, 8) != PacketType.historicalData.rawValue) return null;
  if (_histU8(frame, 9) != 26) return null;
  final unix = _histU32(frame, 15);
  if (unix == null) return null;
  final samples = <int>[];
  var off = 27;
  while (off < 75) {
    final v = _histI16(frame, off);
    if (v == null) break;
    samples.add(v);
    off += 2;
  }
  if (samples.isEmpty) return null;
  return _V26Record(unix: unix.toSigned(32), samples: samples);
}

/// The HISTORICAL_DATA (type-47) record frames in [rawFrames] that genuinely FAIL to decode — a CRC
/// failure, or an unmapped firmware layout whose v24 plausibility gate (see [decodeHistorical]) also
/// rejects it. These are exactly the record frames [extractHistoricalStreams] silently drops.
///
/// EXCLUDED (decode to zero rows BY DESIGN, never "lost" data — must NOT be counted):
///   - CONSOLE_LOGS (type-50) frames — the strap's own diagnostics text channel.
///   - WHOOP 5/MG v26 (raw PPG) records — deliberately unstored, known and skipped by design.
///   - Non-record frames (METADATA, EVENT, etc.) — not type-47, so never returned.
///
/// Pure function (no I/O) so it is unit-testable against captured frames.
List<Uint8List> rejectedHistoricalRecords(
  List<Uint8List> rawFrames, [
  DeviceFamily family = DeviceFamily.whoop4,
]) {
  // Inner packet-type byte: WHOOP 5/MG's longer puffin envelope puts it at frame[8]; WHOOP 4 at [4].
  final typeIndex = family == DeviceFamily.whoop5 ? 8 : 4;
  return rawFrames.where((frame) {
    final t = _histU8(frame, typeIndex);
    if (t == null) return false;
    if (t != PacketType.historicalData.rawValue) return false; // console / metadata / etc.
    // WHOOP 5/MG v26 = raw PPG block, deliberately not stored — known-skipped, not lost data.
    if (family == DeviceFamily.whoop5 && _histU8(frame, 9) == 26) return false;
    // A type-47 record that [decodeHistorical] cannot turn into usable biometrics — CRC failure or
    // an unmapped layout the v24-fallback plausibility gate rejected.
    return decodeHistorical(frame, family) == null;
  }).toList();
}

// MARK: - METADATA classification (port of HistoricalMeta.swift)

/// Classification of a METADATA frame (type 49) for the historical-offload state machine.
sealed class HistoricalMeta {
  const HistoricalMeta();
}

/// HISTORY_START.
class HistoricalMetaStart extends HistoricalMeta {
  const HistoricalMetaStart();
}

/// HISTORY_END: [unix] = record unix seconds, [trim] = the trim cursor to ack/advance.
class HistoricalMetaEnd extends HistoricalMeta {
  const HistoricalMetaEnd({required this.unix, required this.trim});
  final int unix;
  final int trim;

  @override
  bool operator ==(Object other) =>
      other is HistoricalMetaEnd && other.unix == unix && other.trim == trim;

  @override
  int get hashCode => Object.hash(unix, trim);

  @override
  String toString() => 'HistoricalMetaEnd(unix: $unix, trim: $trim)';
}

/// HISTORY_COMPLETE.
class HistoricalMetaComplete extends HistoricalMeta {
  const HistoricalMetaComplete();
}

/// Any other / non-classifiable METADATA frame.
class HistoricalMetaOther extends HistoricalMeta {
  const HistoricalMetaOther();
}

/// Classify a parsed METADATA frame into the four cases the offload state machine needs.
/// Direct port of Swift `classifyHistoricalMeta`.
///
/// Integrity gate (kept from Swift): only act on a checksum-valid frame — without it a garbled or
/// forged BLE peer could forge HISTORY_END / HISTORY_COMPLETE and advance/ack the trim cursor for
/// data we never durably stored.
HistoricalMeta classifyHistoricalMeta(ParsedFrame p) {
  if (!p.ok || p.crcOk == false) return const HistoricalMetaOther();
  if (p.typeName != 'METADATA') return const HistoricalMetaOther();
  final metaName = p.parsed['meta_type'];
  if (metaName is! String) return const HistoricalMetaOther();
  if (metaName.startsWith('HISTORY_START')) return const HistoricalMetaStart();
  if (metaName.startsWith('HISTORY_COMPLETE')) return const HistoricalMetaComplete();
  if (metaName.startsWith('HISTORY_END')) {
    final unix = p.parsed.intOrNull('unix');
    final trim = p.parsed.intOrNull('trim_cursor');
    if (unix == null || trim == null) return const HistoricalMetaOther();
    // u32-on-the-wire; the int values were already truncated to 32 bits on decode. Carry as unsigned
    // so a value past 2^31 doesn't surface as negative downstream.
    return HistoricalMetaEnd(unix: unix & 0xFFFFFFFF, trim: trim & 0xFFFFFFFF);
  }
  return const HistoricalMetaOther();
}

// MARK: - decoded datastore rows + batch (mirror com.noop.data shapes)

/// A heart-rate sample at wall-clock unix seconds [ts]. Device-agnostic decoded row.
/// [hrFixed88] (WHOOP5 v18 sub-bpm HR, 8.8 fixed; bpm = value/256) and [onwrist]
/// (v18 on-wrist flag) are optional additive fields — null on the live path and on
/// families/versions that don't carry them. They are stored so a future engine can
/// use the higher-precision HR + wear gating; they don't affect this row's identity.
class HrRow {
  const HrRow(this.ts, this.bpm, {this.hrFixed88, this.onwrist});
  final int ts;
  final int bpm;
  final int? hrFixed88;
  final int? onwrist;

  @override
  bool operator ==(Object other) =>
      other is HrRow &&
      other.ts == ts &&
      other.bpm == bpm &&
      other.hrFixed88 == hrFixed88 &&
      other.onwrist == onwrist;
  @override
  int get hashCode => Object.hash(ts, bpm, hrFixed88, onwrist);
  @override
  String toString() =>
      'HrRow(ts: $ts, bpm: $bpm, hrFixed88: $hrFixed88, onwrist: $onwrist)';
}

/// A single beat-to-beat R-R interval (ms) at wall-clock unix seconds [ts].
class RrRow {
  const RrRow(this.ts, this.rrMs);
  final int ts;
  final int rrMs;

  @override
  bool operator ==(Object other) =>
      other is RrRow && other.ts == ts && other.rrMs == rrMs;
  @override
  int get hashCode => Object.hash(ts, rrMs);
  @override
  String toString() => 'RrRow(ts: $ts, rrMs: $rrMs)';
}

/// A device event. [payloadJSON] is the deterministic sorted-keys JSON for the remaining fields.
class EventEntry {
  const EventEntry(this.ts, this.kind, this.payloadJSON);
  final int ts;
  final String kind;
  final String payloadJSON;

  @override
  bool operator ==(Object other) =>
      other is EventEntry &&
      other.ts == ts &&
      other.kind == kind &&
      other.payloadJSON == payloadJSON;
  @override
  int get hashCode => Object.hash(ts, kind, payloadJSON);
  @override
  String toString() => 'EventEntry(ts: $ts, kind: $kind, payloadJSON: $payloadJSON)';
}

/// A battery reading. [charging] is a real Boolean only when the frame reported it, else null.
class BatteryRow {
  const BatteryRow({required this.ts, this.soc, this.mv, this.charging});
  final int ts;
  final double? soc;
  final int? mv;
  final bool? charging;

  @override
  bool operator ==(Object other) =>
      other is BatteryRow &&
      other.ts == ts &&
      other.soc == soc &&
      other.mv == mv &&
      other.charging == charging;
  @override
  int get hashCode => Object.hash(ts, soc, mv, charging);
  @override
  String toString() =>
      'BatteryRow(ts: $ts, soc: $soc, mv: $mv, charging: $charging)';
}

/// A raw-ADC SpO2 sample (red/ir) at wall-clock unix seconds [ts].
class Spo2Row {
  const Spo2Row(this.ts, this.red, this.ir);
  final int ts;
  final int red;
  final int ir;

  @override
  bool operator ==(Object other) =>
      other is Spo2Row && other.ts == ts && other.red == red && other.ir == ir;
  @override
  int get hashCode => Object.hash(ts, red, ir);
  @override
  String toString() => 'Spo2Row(ts: $ts, red: $red, ir: $ir)';
}

/// A skin-temperature raw register sample at wall-clock unix seconds [ts].
class SkinTempRow {
  const SkinTempRow(this.ts, this.raw);
  final int ts;
  final int raw;

  @override
  bool operator ==(Object other) =>
      other is SkinTempRow && other.ts == ts && other.raw == raw;
  @override
  int get hashCode => Object.hash(ts, raw);
  @override
  String toString() => 'SkinTempRow(ts: $ts, raw: $raw)';
}

/// Cumulative u16 step/motion counter at [ts] (WHOOP5 step_motion_counter@57). (#78)
/// [activityClass] is the per-record activity-class enum from @63 (0=still, 1=walk, 2=run); null when
/// the byte was 0xFF/invalid or absent.
class StepRow {
  const StepRow(this.ts, this.counter, {this.activityClass});
  final int ts;
  final int counter;
  final int? activityClass;

  @override
  bool operator ==(Object other) =>
      other is StepRow &&
      other.ts == ts &&
      other.counter == counter &&
      other.activityClass == activityClass;
  @override
  int get hashCode => Object.hash(ts, counter, activityClass);
  @override
  String toString() =>
      'StepRow(ts: $ts, counter: $counter, activityClass: $activityClass)';
}

/// The strap's OWN @81 high-nibble band sleep_state at [ts] (0 wake/1 still/2 asleep/3 up). (#175)
class SleepStateRow {
  const SleepStateRow(this.ts, this.state);
  final int ts;
  final int state;

  @override
  bool operator ==(Object other) =>
      other is SleepStateRow && other.ts == ts && other.state == state;
  @override
  int get hashCode => Object.hash(ts, state);
  @override
  String toString() => 'SleepStateRow(ts: $ts, state: $state)';
}

/// A respiratory-rate raw register sample at wall-clock unix seconds [ts].
class RespRow {
  const RespRow(this.ts, this.raw);
  final int ts;
  final int raw;

  @override
  bool operator ==(Object other) =>
      other is RespRow && other.ts == ts && other.raw == raw;
  @override
  int get hashCode => Object.hash(ts, raw);
  @override
  String toString() => 'RespRow(ts: $ts, raw: $raw)';
}

/// A DSP-separated gravity/orientation vector at wall-clock unix seconds [ts].
/// [dynamicAccel] is the WHOOP5 v18 per-second motion scalar (0–8 g), independent of
/// the gravity vector — optional additive field, null when absent/off-range.
class GravityRow {
  const GravityRow(this.ts,
      {required this.x, required this.y, required this.z, this.dynamicAccel});
  final int ts;
  final double x;
  final double y;
  final double z;
  final double? dynamicAccel;

  @override
  bool operator ==(Object other) =>
      other is GravityRow &&
      other.ts == ts &&
      other.x == x &&
      other.y == y &&
      other.z == z &&
      other.dynamicAccel == dynamicAccel;
  @override
  int get hashCode => Object.hash(ts, x, y, z, dynamicAccel);
  @override
  String toString() =>
      'GravityRow(ts: $ts, x: $x, y: $y, z: $z, dynamicAccel: $dynamicAccel)';
}

/// The raw WHOOP 5/MG v26 optical PPG waveform for one strap-second: [ts] is the
/// record's own unix second, [samples] the 24 raw i16 values (24 Hz buffer). Stored
/// losslessly so a future optical algorithm can re-run over the exact waveform, not
/// only the derived HR. [packSamples]/[unpackSamples] are the little-endian i16
/// codec used by the drift blob column.
class PpgRawRow {
  const PpgRawRow(this.ts, this.samples);
  final int ts;
  final List<int> samples;

  /// Pack [samples] into a little-endian i16 byte buffer (`samples.length*2` bytes).
  Uint8List packSamples() => packSamplesOf(samples);

  /// Pack an i16 sample list into a little-endian byte buffer.
  static Uint8List packSamplesOf(List<int> samples) {
    final out = Uint8List(samples.length * 2);
    final bd = ByteData.sublistView(out);
    for (var i = 0; i < samples.length; i++) {
      bd.setInt16(i * 2, samples[i], Endian.little);
    }
    return out;
  }

  /// Unpack a little-endian i16 byte buffer back into the sample list.
  static List<int> unpackSamples(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    return <int>[
      for (var i = 0; i + 2 <= bytes.length; i += 2) bd.getInt16(i, Endian.little)
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is PpgRawRow &&
      other.ts == ts &&
      _listEq(other.samples, samples);
  @override
  int get hashCode => Object.hash(ts, Object.hashAll(samples));
  @override
  String toString() => 'PpgRawRow(ts: $ts, samples: ${samples.length})';

  static bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// HR derived from the v26 PPG waveform: [ts] window-centre sec, [bpm], [conf] in 0…1. (#156)
class PpgHrRow {
  const PpgHrRow({required this.ts, required this.bpm, required this.conf});
  final int ts;
  final int bpm;
  final double conf;

  @override
  bool operator ==(Object other) =>
      other is PpgHrRow && other.ts == ts && other.bpm == bpm && other.conf == conf;
  @override
  int get hashCode => Object.hash(ts, bpm, conf);
  @override
  String toString() => 'PpgHrRow(ts: $ts, bpm: $bpm, conf: $conf)';
}

/// Decoded streams to persist in one transaction. Mirror of the Kotlin `StreamBatch`. All `ts`
/// values are wall-clock unix seconds.
class StreamBatch {
  StreamBatch({
    List<HrRow>? hr,
    List<RrRow>? rr,
    List<EventEntry>? events,
    List<BatteryRow>? battery,
    List<Spo2Row>? spo2,
    List<SkinTempRow>? skinTemp,
    List<RespRow>? resp,
    List<GravityRow>? gravity,
    List<StepRow>? steps,
    List<SleepStateRow>? sleepState,
    List<PpgHrRow>? ppgHr,
    List<PpgRawRow>? ppgRaw,
    this.droppedImplausibleTs = 0,
  })  : hr = hr ?? <HrRow>[],
        rr = rr ?? <RrRow>[],
        events = events ?? <EventEntry>[],
        battery = battery ?? <BatteryRow>[],
        spo2 = spo2 ?? <Spo2Row>[],
        skinTemp = skinTemp ?? <SkinTempRow>[],
        resp = resp ?? <RespRow>[],
        gravity = gravity ?? <GravityRow>[],
        steps = steps ?? <StepRow>[],
        sleepState = sleepState ?? <SleepStateRow>[],
        ppgHr = ppgHr ?? <PpgHrRow>[],
        ppgRaw = ppgRaw ?? <PpgRawRow>[];

  final List<HrRow> hr;
  final List<RrRow> rr;
  final List<EventEntry> events;
  final List<BatteryRow> battery;
  final List<Spo2Row> spo2;
  final List<SkinTempRow> skinTemp;
  final List<RespRow> resp;
  final List<GravityRow> gravity;
  final List<StepRow> steps;
  final List<SleepStateRow> sleepState;
  final List<PpgHrRow> ppgHr;

  /// Raw v26 optical PPG waveform, one entry per strap-second (24 raw i16 samples
  /// each). Populated only on the historical WHOOP5 v26 path; empty on the live path
  /// and on WHOOP4. Persisted losslessly so a future optical algorithm can re-run.
  final List<PpgRawRow> ppgRaw;

  /// #547: how many historical records this batch DROPPED because their timestamp was implausible.
  /// A diagnostic counter only, deliberately excluded from [isEmpty].
  final int droppedImplausibleTs;

  bool get isEmpty =>
      hr.isEmpty &&
      rr.isEmpty &&
      events.isEmpty &&
      battery.isEmpty &&
      spo2.isEmpty &&
      skinTemp.isEmpty &&
      resp.isEmpty &&
      gravity.isEmpty &&
      steps.isEmpty &&
      sleepState.isEmpty &&
      ppgHr.isEmpty &&
      ppgRaw.isEmpty;
}

// MARK: - Historical extraction (port of HistoricalStreams.swift extractHistoricalStreams)

/// Turn a batch of parsed offload frames into a [StreamBatch] of datastore rows. Direct port of
/// Swift `extractHistoricalStreams`.
///
/// HR/R-R/SpO2/skinTemp/resp/gravity come from type-47 HISTORICAL_DATA records, each of which
/// carries its OWN real unix timestamp — so NO wall-clock offset is applied to them. EVENT timestamps
/// are real RTC unix seconds. CRC-failed / non-ok frames are skipped.
///
/// [rawFrames] are the verbatim BLE frames for this chunk; [decodeHistorical] re-validates + decodes
/// each. [wallNow] is the #547 ingest-gate "now" used ONLY to reject future-dated records; when null
/// it falls back to max(wallClockRef, real clock). [sessionOldestUnix]/[sessionNewestUnix] are the
/// strap's GET_DATA_RANGE markers for THIS sync (null on replay/import paths).
StreamBatch extractHistoricalStreams(
  List<Uint8List> rawFrames,
  int deviceClockRef,
  int wallClockRef, [
  DeviceFamily family = DeviceFamily.whoop4,
  int? wallNow,
  int? sessionOldestUnix,
  int? sessionNewestUnix,
]) {
  // #547 gate "now": take the LATER of the supplied correlation wall and the real clock so a test that
  // passes a recent wallClockRef still has a sane upper bound, and the replay path's wallClockRef=0
  // falls back to the real clock. Mirrors the Swift wallNow seam.
  final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final resolvedWallNow = wallNow ?? (wallClockRef > nowSec ? wallClockRef : nowSec);

  // Count of records dropped by the #547 plausibility gate this batch.
  var droppedImplausible = 0;

  // The plausible-timestamp window for this batch (#547): the absolute floor [minPlausibleUnix,
  // resolvedWallNow + futureMargin] PLUS, when the strap's GET_DATA_RANGE markers are known AND
  // well-formed, the strap's OWN banked window padded by sessionRangeMargin. Mirrors Swift
  // `isPlausibleHistoricalUnix`.
  bool plausible(int ts) {
    if (ts < minPlausibleUnix || ts > resolvedWallNow + futureMargin) return false;
    final oldest = sessionOldestUnix;
    final newest = sessionNewestUnix;
    if (oldest == null || newest == null || oldest < minPlausibleUnix || newest < oldest) {
      return true;
    }
    return ts >= oldest - sessionRangeMargin && ts <= newest + sessionRangeMargin;
  }

  int? wall(int? deviceTs) =>
      deviceTs == null ? null : wallClockRef + (deviceTs - deviceClockRef);

  // FIX #72: type-47 `unix` and EVENT `event_timestamp` are the strap RTC's own real-unix seconds.
  // When the strap RTC is grossly stale those land far in the past. Correct them by the
  // (wall - device) clock offset, but ONLY when grossly stale, and SNAPPED to a 5-min grid so the
  // SAME record re-syncs to the SAME corrected ts. A normal/identity clockRef has offset ~0 (<
  // threshold) → rawTs unchanged.
  const staleThreshold = 86400; // 1 day
  const snapGranularity = 300; // 5 min
  final clockOffset = wallClockRef - deviceClockRef;
  // #547: returns null for an implausible (far-past / future-dated) record so every call site skips
  // it. Counts each drop. Mirrors the Swift correctedWall returning nil.
  int? correctedWall(int rawTs) {
    int candidate;
    if (clockOffset.abs() <= staleThreshold) {
      candidate = rawTs;
    } else {
      final snapped = (clockOffset >= 0
              ? clockOffset + snapGranularity ~/ 2
              : clockOffset - snapGranularity ~/ 2) ~/
          snapGranularity *
          snapGranularity;
      final corrected = rawTs + snapped;
      // A fully-drained strap whose RTC reset to ~epoch reports a near-zero deviceClockRef while its
      // frames still carry the true-unix rawTs; clockOffset is then ~decades and this "correction"
      // hurls every sample into the future. A record can't post-date its own capture, so when
      // corrected overshoots wall time the offset was bogus — keep the raw ts. (PR #471)
      candidate = corrected > wallClockRef + snapGranularity ? rawTs : corrected;
    }
    if (!plausible(candidate)) {
      droppedImplausible++;
      return null;
    }
    return candidate;
  }

  final hr = <HrRow>[];
  final rr = <RrRow>[];
  final spo2 = <Spo2Row>[];
  final skinTemp = <SkinTempRow>[];
  final steps = <StepRow>[];
  final sleepState = <SleepStateRow>[];
  final resp = <RespRow>[];
  final gravity = <GravityRow>[];
  final events = <EventEntry>[];
  final battery = <BatteryRow>[];
  // v26 PPG samples accumulate across the chunk, then get turned into HR after the loop (#156).
  final ppgSamples = <PpgSample>[];
  // The RAW v26 waveform, one row per strap-second, preserved losslessly alongside the derived HR.
  final ppgRaw = <PpgRawRow>[];

  for (final frame in rawFrames) {
    // Packet type byte: WHOOP 5/MG's longer puffin envelope puts it at frame[8]; WHOOP 4 at frame[4].
    final int t;
    if (family == DeviceFamily.whoop5) {
      t = _histU8(frame, 8) ?? -1;
    } else {
      t = frame.length > 4 ? frame[4] & 0xFF : -1;
    }

    if (t == PacketType.historicalData.rawValue) {
      // WHOOP 5/MG layout v26 = the 24 Hz optical PPG buffer. It carries no per-second HR, so
      // [decodeHistorical] returns null for it; instead we accumulate its waveform samples here and
      // derive HR after the loop via [PpgHr] (#156).
      if (family == DeviceFamily.whoop5) {
        final rec = _decodeWhoop5HistoricalV26(frame);
        if (rec != null) {
          // #547: skip a v26 PPG buffer whose unix is implausible (correctedWall → null).
          final baseTs = correctedWall(rec.unix & 0xFFFFFFFF);
          if (baseTs != null) {
            for (final v in rec.samples) {
              ppgSamples.add(PpgSample(ts: baseTs, value: v));
            }
            // Preserve the RAW waveform verbatim (lossless), not only the derived HR.
            ppgRaw.add(PpgRawRow(baseTs, rec.samples));
          }
        }
      }
      // type-47 carries the strap RTC's real-unix seconds. Correct for a grossly-stale RTC (FIX #72).
      final p = decodeHistorical(frame, family);
      if (p == null) continue;
      // #547: correctedWall is nullable — it returns null for an implausible record, so this skips a
      // bad-clock record entirely instead of letting its garbage `unix` enter the DB.
      final rawUnix = p.intOrNull('unix');
      if (rawUnix == null) continue;
      final ts = correctedWall(rawUnix);
      if (ts == null) continue;

      // skip startup hr=0 (matches Swift `bpm != 0`). Carry the WHOOP5 v18 sub-bpm HR
      // (@36) and on-wrist flag (@81) alongside so they land in hrSample instead of
      // being dropped; both are absent (null) on WHOOP4 / non-v18 records.
      final bpm = p.intOrNull('heart_rate');
      if (bpm != null && bpm != 0) {
        hr.add(HrRow(ts, bpm,
            hrFixed88: p.intOrNull('hr_fixed_8_8'),
            onwrist: p.intOrNull('onwrist')));
      }

      final rrs = p['rr_intervals'];
      if (rrs is List<int>) {
        for (final rrMs in rrs) {
          rr.add(RrRow(ts, rrMs));
        }
      }

      final red = p.intOrNull('spo2_red');
      if (red != null) {
        spo2.add(Spo2Row(ts, red, p.intOrNull('spo2_ir') ?? 0));
      }
      final skinRaw = p.intOrNull('skin_temp_raw');
      if (skinRaw != null) skinTemp.add(SkinTempRow(ts, skinRaw));
      // step_motion_counter@57 is the WHOOP5 CUMULATIVE u16 counter; stored raw. activity_class@63
      // rides on the same record — null when invalid/absent. (#78)
      final counter = p.intOrNull('step_motion_counter');
      if (counter != null) {
        steps.add(StepRow(ts, counter, activityClass: p.intOrNull('activity_class')));
      }
      // Band sleep_state (#175): carried VERBATIM including 0 (a real wake reading, not "absent").
      final st = p.intOrNull('sleep_state');
      if (st != null) sleepState.add(SleepStateRow(ts, st));
      final respRaw = p.intOrNull('resp_rate_raw');
      if (respRaw != null) resp.add(RespRow(ts, respRaw));
      final gx = p.doubleOrNull('gravity_x');
      if (gx != null) {
        gravity.add(GravityRow(
          ts,
          x: gx,
          y: p.doubleOrNull('gravity_y') ?? 0.0,
          z: p.doubleOrNull('gravity_z') ?? 0.0,
          // WHOOP5 v18 per-second motion scalar (@41), independent of the vector.
          dynamicAccel: p.doubleOrNull('dynamic_acceleration'),
        ));
      }
    } else if (t == PacketType.realtimeRawData.rawValue) {
      // Fallback (rare during a plain type-47 offload): HR/RR off the type-43 header. Its timestamp is
      // a device-epoch value, so it DOES get the wall-clock offset.
      final parsed = Framing.parseFrame(frame, family);
      if (!parsed.ok || parsed.crcOk == false) continue;
      final ts = wall(parsed.parsed.intOrNull('timestamp'));
      if (ts == null) continue;
      // #547: gate the wall()-corrected ts on the same plausibility window.
      if (!plausible(ts)) {
        droppedImplausible++;
        continue;
      }
      final bpm = parsed.parsed.intOrNull('heart_rate');
      if (bpm != null) hr.add(HrRow(ts, bpm));
      final rrs = parsed.parsed['rr_intervals'];
      if (rrs is List<int>) {
        for (final rrMs in rrs) {
          rr.add(RrRow(ts, rrMs));
        }
      }
    } else if (t == PacketType.event.rawValue) {
      // EVENT carries the strap RTC's real-unix seconds. Correct for a grossly-stale RTC (FIX #72).
      final parsed = Framing.parseFrame(frame, family);
      if (!parsed.ok || parsed.crcOk == false) continue;
      // #547: correctedWall now nullable — an EVENT with an implausible event_timestamp is skipped.
      final rawTs = parsed.parsed.intOrNull('event_timestamp');
      if (rawTs == null) continue;
      final ts = correctedWall(rawTs);
      if (ts == null) continue;
      final kind = parsed.parsed.stringOrNull('event') ?? '';
      if (kind.startsWith('BATTERY_LEVEL')) _appendHistBattery(battery, ts, parsed.parsed);
      final payload = Map<String, Object?>.of(parsed.parsed);
      payload.remove('event');
      payload.remove('event_timestamp');
      events.add(EventEntry(ts, kind, _encodePayload(payload)));
    } else if (t == PacketType.commandResponse.rawValue) {
      // No device timestamp on COMMAND_RESPONSE → stamp battery at wallClockRef (Swift parity).
      final parsed = Framing.parseFrame(frame, family);
      if (!parsed.ok || parsed.crcOk == false) continue;
      _appendHistBattery(battery, wallClockRef, parsed.parsed);
    }
  }

  // Derive HR from the accumulated v26 PPG waveform (8 s / 24 Hz autocorrelation, conf>=0.3) (#156).
  final ppgHr = PpgHr.estimate(ppgSamples)
      .map((e) => PpgHrRow(ts: e.ts, bpm: e.bpm, conf: e.conf))
      .toList();

  return StreamBatch(
    hr: hr,
    rr: rr,
    events: events,
    battery: battery,
    spo2: spo2,
    skinTemp: skinTemp,
    resp: resp,
    gravity: gravity,
    steps: steps,
    sleepState: sleepState,
    ppgHr: ppgHr,
    ppgRaw: ppgRaw,
    droppedImplausibleTs: droppedImplausible,
  );
}

/// Append a [BatteryRow] from a parsed frame's `battery_pct`/`battery_mV`/`battery_charging` fields
/// (no-op when neither soc nor mv is present). Mirrors the live-path `appendBattery` in Streams.
void _appendHistBattery(List<BatteryRow> out, int ts, Map<String, Object?> p) {
  final soc = p.doubleOrNull('battery_pct');
  final mv = p.intOrNull('battery_mV');
  if (soc == null && mv == null) return;
  final chargingRaw = p.intOrNull('battery_charging');
  final charging = chargingRaw == null ? null : chargingRaw != 0;
  out.add(BatteryRow(ts: ts, soc: soc, mv: mv, charging: charging));
}

/// Deterministic sorted-keys JSON for an event payload. Port of `StreamPersistence.encodePayload`
/// (which mirrors Swift `WhoopStore.encodePayload`). Keys sorted ascending; values quoted by type.
/// Empty payloads encode to `{}`.
String _encodePayload(Map<String, Object?> payload) {
  if (payload.isEmpty) return '{}';
  final keys = payload.keys.toList()..sort();
  final sb = StringBuffer('{');
  for (var i = 0; i < keys.length; i++) {
    if (i > 0) sb.write(',');
    sb.write(json.encode(keys[i]));
    sb.write(':');
    sb.write(_encodeValue(payload[keys[i]]));
  }
  sb.write('}');
  return sb.toString();
}

String _encodeValue(Object? v) {
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
  if (v is String) return json.encode(v);
  return json.encode(v.toString());
}
