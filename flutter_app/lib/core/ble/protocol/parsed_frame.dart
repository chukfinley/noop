/// Faithful Dart port of `ParsedFrame.kt`.
///
/// Result of decoding a single complete frame.
///
/// Mirrors the Swift reference `ParsedFrame` reduced to the fields the app consumes:
///  - [ok]: the envelope was well-formed (SOF present, minimum length). `false` for fragments.
///  - [crcOk]: payload CRC32 outcome — `true`/`false` when verifiable, `null` when not enough bytes
///    were present to check (mirrors Swift's optional `crcOK`). A non-`false` value is the integrity
///    gate downstream code uses before trusting a frame.
///  - [typeName]: canonical packet-type name (e.g. "REALTIME_DATA", "EVENT", "COMMAND_RESPONSE",
///    "METADATA"), or "type{N}" / "INVALID/FRAGMENT" when unmapped/invalid.
///  - [parsed]: a flat map of decoded fields. Values are plain Dart types (int, double, String,
///    bool, or `List<int>` for `rr_intervals`). Keys match the Swift parsed-dict keys exactly so
///    higher layers (Streams, HistoricalMeta) port without renames.
class ParsedFrame {
  final bool ok;
  final bool? crcOk;
  final String typeName;
  final Map<String, Object?> parsed;

  const ParsedFrame({
    required this.ok,
    required this.crcOk,
    required this.typeName,
    required this.parsed,
  });

  /// A frame that could not be decoded (too short, wrong SOF, or a mid-stream fragment).
  factory ParsedFrame.invalid() => const ParsedFrame(
        ok: false,
        crcOk: null,
        typeName: 'INVALID/FRAGMENT',
        parsed: <String, Object?>{},
      );

  @override
  bool operator ==(Object other) =>
      other is ParsedFrame &&
      other.ok == ok &&
      other.crcOk == crcOk &&
      other.typeName == typeName &&
      _mapEquals(other.parsed, parsed);

  @override
  int get hashCode => Object.hash(ok, crcOk, typeName, _mapHash(parsed));

  @override
  String toString() =>
      'ParsedFrame(ok: $ok, crcOk: $crcOk, typeName: $typeName, parsed: $parsed)';

  static bool _valueEquals(Object? a, Object? b) {
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_valueEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  static bool _mapEquals(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (!_valueEquals(entry.value, b[entry.key])) return false;
    }
    return true;
  }

  static int _mapHash(Map<String, Object?> m) {
    var h = 0;
    for (final entry in m.entries) {
      final v = entry.value;
      final vh = v is List ? Object.hashAll(v) : v.hashCode;
      h ^= entry.key.hashCode ^ vh;
    }
    return h;
  }
}
