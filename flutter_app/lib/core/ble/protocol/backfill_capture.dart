/// Faithful Dart port of `BackfillCaptureJsonl.kt` + `BackfillCaptureSummary.kt` (merged).
///
/// Research/diagnostics helpers for the historical-offload backfill:
///   - [BackfillCaptureRecord] + [BackfillCaptureJsonl]: encode one captured frame as a STABLE JSON
///     line (sorted `parsed` keys, deterministic escaping) for the raw-capture JSONL export.
///   - [BackfillCaptureSummary]: tally packet-type counts and retain a bounded sample of the
///     unknown (`type<N>`) frames so an unmapped firmware surfaces in a shared log.
library;

/// One captured frame's metadata + verbatim hex, ready to serialise as a JSONL line.
class BackfillCaptureRecord {
  const BackfillCaptureRecord({
    required this.capturedAtMs,
    required this.sessionId,
    required this.characteristic,
    required this.typeName,
    required this.crcOk,
    required this.offload,
    required this.size,
    required this.parsed,
    required this.hex,
  });

  final int capturedAtMs;
  final String sessionId;
  final String characteristic;
  final String typeName;
  final bool? crcOk;
  final bool offload;
  final int size;
  final Map<String, Object?> parsed;
  final String hex;
}

/// Stable JSON-line encoder for a [BackfillCaptureRecord]. Field order is fixed; `parsed` map keys are
/// sorted ascending so the same record always serialises byte-identically. Mirrors the Kotlin `object
/// BackfillCaptureJsonl`.
class BackfillCaptureJsonl {
  BackfillCaptureJsonl._();

  static String encode(BackfillCaptureRecord record) {
    final sb = StringBuffer();
    sb.write('{');
    _appendField(sb, 'captured_at_ms', record.capturedAtMs);
    sb.write(',');
    _appendField(sb, 'session_id', record.sessionId);
    sb.write(',');
    _appendField(sb, 'characteristic', record.characteristic);
    sb.write(',');
    _appendField(sb, 'type_name', record.typeName);
    sb.write(',');
    _appendField(sb, 'crc_ok', record.crcOk);
    sb.write(',');
    _appendField(sb, 'offload', record.offload);
    sb.write(',');
    _appendField(sb, 'size', record.size);
    sb.write(',');
    _appendQuoted(sb, 'parsed');
    sb.write(':');
    _appendJsonValue(sb, record.parsed);
    sb.write(',');
    _appendField(sb, 'hex', record.hex);
    sb.write('}');
    return sb.toString();
  }

  static void _appendField(StringBuffer sb, String name, Object? value) {
    _appendQuoted(sb, name);
    sb.write(':');
    _appendJsonValue(sb, value);
  }

  static void _appendJsonValue(StringBuffer sb, Object? value) {
    if (value == null) {
      sb.write('null');
    } else if (value is bool) {
      sb.write(value);
    } else if (value is num) {
      sb.write(value);
    } else if (value is Map) {
      sb.write('{');
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      for (var i = 0; i < entries.length; i++) {
        if (i > 0) sb.write(',');
        _appendQuoted(sb, entries[i].key.toString());
        sb.write(':');
        _appendJsonValue(sb, entries[i].value);
      }
      sb.write('}');
    } else if (value is Iterable) {
      sb.write('[');
      var i = 0;
      for (final item in value) {
        if (i > 0) sb.write(',');
        _appendJsonValue(sb, item);
        i++;
      }
      sb.write(']');
    } else {
      _appendQuoted(sb, value.toString());
    }
  }

  static void _appendQuoted(StringBuffer sb, String value) {
    sb.write('"');
    for (final ch in value.codeUnits) {
      switch (ch) {
        case 0x5C: // '\'
          sb.write('\\\\');
          break;
        case 0x22: // '"'
          sb.write('\\"');
          break;
        case 0x0A: // '\n'
          sb.write('\\n');
          break;
        case 0x0D: // '\r'
          sb.write('\\r');
          break;
        case 0x09: // '\t'
          sb.write('\\t');
          break;
        default:
          if (ch < 0x20) {
            sb.write('\\u');
            sb.write(ch.toRadixString(16).padLeft(4, '0'));
          } else {
            sb.writeCharCode(ch);
          }
      }
    }
    sb.write('"');
  }
}

class _UnknownSample {
  const _UnknownSample({
    required this.typeName,
    required this.crcOk,
    required this.size,
    required this.characteristic,
    required this.hex,
  });

  final String typeName;
  final bool? crcOk;
  final int size;
  final String characteristic;
  final String hex;
}

/// Tally packet-type counts over a backfill and keep a bounded sample of the unknown (`type<N>`)
/// frames. Mirrors the Kotlin `BackfillCaptureSummary`.
class BackfillCaptureSummary {
  BackfillCaptureSummary({this.maxUnknownSamples = 20});

  final int maxUnknownSamples;

  // A Dart map literal preserves insertion order (LinkedHashMap), matching Kotlin's linkedMapOf.
  final Map<String, int> _counts = <String, int>{};
  final List<_UnknownSample> _unknownSamples = <_UnknownSample>[];

  void record(String typeName, bool? crcOk, int size, String characteristic, String hex) {
    _counts[typeName] = (_counts[typeName] ?? 0) + 1;
    if (_unknownSamples.length < maxUnknownSamples && _isUnknownType(typeName)) {
      _unknownSamples.add(_UnknownSample(
        typeName: typeName,
        crcOk: crcOk,
        size: size,
        characteristic: characteristic,
        hex: hex,
      ));
    }
  }

  String countsText() {
    if (_counts.isEmpty) return 'none';
    final entries = _counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => '${e.key}=${e.value}').join(', ');
  }

  String unknownSamplesText() {
    if (_unknownSamples.isEmpty) return 'none';
    return _unknownSamples
        .map((s) =>
            '${s.typeName}(size=${s.size},char=${s.characteristic},crc=${s.crcOk},hex=${s.hex})')
        .join('; ');
  }

  void reset() {
    _counts.clear();
    _unknownSamples.clear();
  }

  bool _isUnknownType(String typeName) => typeName.startsWith('type');
}
