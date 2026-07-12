/// Faithful Dart port of `Streams.kt`.
///
/// Decoded stream rows — the durable, compact local record produced from parsed frames.
///
/// Ported from the Swift reference (Streams.swift). `ts` is wall-clock unix seconds throughout.
/// These are pure data carriers with no platform dependency; the data layer maps them onto
/// storage entities (HrSample, RrInterval, EventRow, BatterySample) as needed.
library;

import 'device_family.dart';
import 'parsed_frame.dart';

/// A heart-rate sample at wall-clock unix seconds [ts].
class HrSample {
  final int ts;
  final int bpm;

  const HrSample(this.ts, this.bpm);

  @override
  bool operator ==(Object other) =>
      other is HrSample && other.ts == ts && other.bpm == bpm;

  @override
  int get hashCode => Object.hash(ts, bpm);

  @override
  String toString() => 'HrSample(ts: $ts, bpm: $bpm)';
}

/// A single beat-to-beat R-R interval (ms) at wall-clock unix seconds [ts].
class RrInterval {
  final int ts;
  final int rrMs;

  const RrInterval(this.ts, this.rrMs);

  @override
  bool operator ==(Object other) =>
      other is RrInterval && other.ts == ts && other.rrMs == rrMs;

  @override
  int get hashCode => Object.hash(ts, rrMs);

  @override
  String toString() => 'RrInterval(ts: $ts, rrMs: $rrMs)';
}

/// A raw-ADC SpO2 sample at wall-clock unix seconds [ts]. Mirrors the storage `Spo2Sample`
/// (red/ir) and the Swift `SpO2Sample(red:ir:unit:)` shape so [Streams] is a 1:1 widen.
/// Historically only the type-47 historical-offload path produced these; the live carrier now also
/// carries them so a single-value optical source (the Oura ring exposes ONE combined SpO2 reading,
/// not separate red/ir channels) can flow live. Such a source puts its raw value in [red] and
/// leaves [ir] at 0 (an unread channel, never a fabricated second reading).
///
/// [unit] preserves the decoder's own scale tag (e.g. "raw_adc"/"raw"/"dc_raw") so a downstream
/// reader never assumes a percentage.
class Spo2Sample {
  final int ts;
  final int red;
  final int ir;
  final String unit;

  const Spo2Sample(this.ts, this.red, this.ir, {this.unit = 'raw_adc'});

  @override
  bool operator ==(Object other) =>
      other is Spo2Sample &&
      other.ts == ts &&
      other.red == red &&
      other.ir == ir &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(ts, red, ir, unit);

  @override
  String toString() => 'Spo2Sample(ts: $ts, red: $red, ir: $ir, unit: $unit)';
}

/// A skin-temperature sample at wall-clock unix seconds [ts]. Mirrors the storage `SkinTempSample`
/// and the Swift `SkinTempSample(raw:unit:)` shape.
///
/// UNIT CONVENTION: [raw] is a device-native register value whose °C scale is FAMILY-SPECIFIC (#938) —
/// the 5/MG v18 @73 field is CENTI-degrees C (°C = raw / 100), but the WHOOP 4.0 v24 @72 field is a RAW
/// ADC on a different scale. The analytics reader converts via [skinTempCelsius], which branches on
/// [DeviceFamily]; running the 4.0 raw through /100 read every worn night ~8 °C, below the 28 °C worn
/// gate (issue #938). [unit] carries a scale tag ("raw_adc") so the scale is never silently assumed.
class SkinTempSample {
  final int ts;
  final int raw;
  final String unit;

  const SkinTempSample(this.ts, this.raw, {this.unit = 'raw_adc'});

  @override
  bool operator ==(Object other) =>
      other is SkinTempSample &&
      other.ts == ts &&
      other.raw == raw &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(ts, raw, unit);

  @override
  String toString() => 'SkinTempSample(ts: $ts, raw: $raw, unit: $unit)';
}

/// WHOOP 4.0 (v24) skin-temp mapping constants (#938). The single provisional slope + anchor live in
/// ONE place so the two-point-calibration TODO has an obvious home. Kept in lockstep with the Swift
/// `Whoop4SkinTemp`.
class Whoop4SkinTemp {
  Whoop4SkinTemp._();

  /// Worn resting raw register value the anchor pins (reporter's steady worn baseline, ~826).
  static const double anchorRaw = 826.0;

  /// Physiological nocturnal wrist skin temperature the anchor raw maps to (°C).
  static const double anchorCelsius = 33.0;

  /// PROVISIONAL °C-per-raw-unit slope. TODO(#938): replace with the two-point anchor slope.
  static const double provisionalSlopeCPerRaw = 0.05;
}

/// Convert a raw `skin_temp_raw` register value to °C, DEVICE-FAMILY-AWARE (#938).
///
/// The two families bank skin temp on DIFFERENT scales, and applying one family's scale to the other
/// is a real decode bug: the historical `skin_temp_raw` field is a RAW ADC on the WHOOP 4.0 (v24 @72)
/// but a CENTIDEGREE register on the 5/MG (v18 @73). A single family-blind `raw/100` sent every 4.0
/// night ~8 °C low, below the 28 °C worn gate, so skin temp + the illness signal vanished (issue #938).
///
/// - [DeviceFamily.whoop5]: `raw / 100`. PROVEN on real 5/MG captures (worn 3057 = 30.6 °C, off-wrist
///   2247 = 22.5 °C). Unchanged.
/// - [DeviceFamily.whoop4]: a single-anchor affine map. The 4.0 firmware banks byte-72 at 1 Hz
///   ON-WRIST ONLY, so there is ONE solid anchor. We anchor the worn value at a defensible nocturnal
///   wrist skin temperature (33.0 °C ↔ raw 826) and carry a PROVISIONAL slope until a second
///   calibration point exists. All 4.0 values APPROXIMATE. Kept in lockstep with the Swift
///   `skinTempCelsius(raw:family:)`.
double skinTempCelsius(int raw, DeviceFamily family) {
  switch (family) {
    case DeviceFamily.whoop5:
      return raw / 100.0;
    case DeviceFamily.whoop4:
      return Whoop4SkinTemp.anchorCelsius +
          (raw - Whoop4SkinTemp.anchorRaw) * Whoop4SkinTemp.provisionalSlopeCPerRaw;
  }
}

/// A device event. [ts] is real RTC unix seconds (already wall-clock, never offset). [kind] is the
/// event label (e.g. "BATTERY_LEVEL(3)", "WRIST_OFF(10)"); [payload] carries any extra decoded
/// fields with `event`/`event_timestamp` removed.
class WhoopEvent {
  final int ts;
  final String kind;
  final Map<String, Object?> payload;

  const WhoopEvent(this.ts, this.kind, this.payload);

  @override
  String toString() => 'WhoopEvent(ts: $ts, kind: $kind, payload: $payload)';
}

/// A battery reading. [ts] is event RTC for BATTERY_LEVEL events, else the wall-clock reference.
/// [charging] is a real Boolean only when the frame reported it (BATTERY_LEVEL events); `null`
/// otherwise (command responses).
class BatterySample {
  final int ts;
  final double? soc;
  final int? mv;
  final bool? charging;

  const BatterySample({
    required this.ts,
    required this.soc,
    required this.mv,
    this.charging,
  });

  @override
  bool operator ==(Object other) =>
      other is BatterySample &&
      other.ts == ts &&
      other.soc == soc &&
      other.mv == mv &&
      other.charging == charging;

  @override
  int get hashCode => Object.hash(ts, soc, mv, charging);

  @override
  String toString() =>
      'BatterySample(ts: $ts, soc: $soc, mv: $mv, charging: $charging)';
}

/// The bundle of decoded series extracted from a batch of parsed frames.
class Streams {
  final List<HrSample> hr;
  final List<RrInterval> rr;
  final List<WhoopEvent> events;
  final List<BatterySample> battery;
  // spo2/skinTemp default empty so every existing WHOOP-path call site is unchanged; only a source
  // that decodes these biometric signals live (the Oura ring) populates them.
  final List<Spo2Sample> spo2;
  final List<SkinTempSample> skinTemp;

  Streams({
    List<HrSample>? hr,
    List<RrInterval>? rr,
    List<WhoopEvent>? events,
    List<BatterySample>? battery,
    List<Spo2Sample>? spo2,
    List<SkinTempSample>? skinTemp,
  })  : hr = hr ?? <HrSample>[],
        rr = rr ?? <RrInterval>[],
        events = events ?? <WhoopEvent>[],
        battery = battery ?? <BatterySample>[],
        spo2 = spo2 ?? <Spo2Sample>[],
        skinTemp = skinTemp ?? <SkinTempSample>[];

  static Streams get empty => Streams();
}

/// Map a device-epoch timestamp to wall-clock unix seconds via a pure linear offset.
/// Assumes strap clock and wall clock tick at the same rate (no skew/drift). Port of `_to_wall`.
int? _toWall(int? deviceTs, int deviceClockRef, int wallClockRef) {
  if (deviceTs == null) return null;
  return wallClockRef + (deviceTs - deviceClockRef);
}

/// Turn parsed frames into datastore rows. Port of `interpreter.extract_streams`.
///
/// HR/R-R are taken ONLY from REALTIME_DATA (type 40). REALTIME_RAW_DATA (type 43) also carries an
/// HR byte but streams alongside type-40 during raw collection, so routing both would double-count
/// HR for the same instants. CRC-failed and non-ok frames are skipped.
Streams extractStreams(
  List<ParsedFrame> parsed,
  int deviceClockRef,
  int wallClockRef,
) {
  final out = Streams();
  for (final r in parsed) {
    if (!r.ok || r.crcOk == false) continue;
    final p = r.parsed;
    switch (r.typeName) {
      case 'REALTIME_DATA':
        final ts = _toWall(p.intOrNull('timestamp'), deviceClockRef, wallClockRef);
        if (ts != null) {
          final bpm = p.intOrNull('heart_rate');
          if (bpm != null) out.hr.add(HrSample(ts, bpm));
          // Drop RR rows when timestamp is absent (a ts-less RR row is unstorable).
          final rrs = p.intArrayOrNull('rr_intervals');
          if (rrs != null) {
            for (final rr in rrs) {
              out.rr.add(RrInterval(ts, rr));
            }
          }
        }
        break;

      case 'EVENT':
        // EVENT timestamps are real RTC unix seconds — already wall-clock, NOT offset.
        final ts = p.intOrNull('event_timestamp');
        if (ts == null) continue;
        final kind = p.stringOrNull('event') ?? '';
        // BATTERY_LEVEL events (~every 8 min) carry SoC/mV/charging → the DENSE series.
        if (kind.startsWith('BATTERY_LEVEL')) _appendBattery(out, ts, p);
        final payload = Map<String, Object?>.of(p);
        payload.remove('event');
        payload.remove('event_timestamp');
        out.events.add(WhoopEvent(ts, kind, payload));
        break;

      case 'COMMAND_RESPONSE':
        // No device timestamp on COMMAND_RESPONSE → stamp battery at wallClockRef.
        _appendBattery(out, wallClockRef, p);
        break;

      default:
        break;
    }
  }
  return out;
}

/// Append a [BatterySample] from a parsed frame's `battery_pct`/`battery_mV`/`battery_charging`
/// fields (no-op when neither soc nor mv is present). `charging` is a real Boolean only when the
/// frame reported it (BATTERY_LEVEL events); command responses leave it null.
void _appendBattery(Streams out, int ts, Map<String, Object?> p) {
  final soc = p.doubleOrNull('battery_pct');
  final mv = p.intOrNull('battery_mV');
  if (soc == null && mv == null) return;
  final chargingRaw = p.intOrNull('battery_charging');
  final charging = chargingRaw == null ? null : chargingRaw != 0;
  out.battery.add(BatterySample(ts: ts, soc: soc, mv: mv, charging: charging));
}

/// Heterogeneous parsed-map accessors (mirror Swift's ParsedValue.intValue/etc. and the Kotlin
/// `Map<String, Any?>` extensions). Exposed so callers can compute e.g. the newest realtime
/// timestamp when anchoring a live batch (#126), exactly like the Kotlin `intOrNull`.
extension ParsedMapAccessors on Map<String, Object?> {
  int? intOrNull(String key) {
    final v = this[key];
    if (v is int) return v;
    return null;
  }

  double? doubleOrNull(String key) {
    final v = this[key];
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return null;
  }

  String? stringOrNull(String key) {
    final v = this[key];
    return v is String ? v : null;
  }

  List<int>? intArrayOrNull(String key) {
    final v = this[key];
    return v is List<int> ? v : null;
  }
}
