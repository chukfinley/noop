import 'dart:typed_data';

/// Faithful Dart port of `DeviceFamily.kt`.

/// Which checksum guards the frame header for a given device family.
enum HeaderCRCKind {
  /// CRC8 (poly 0x07) over the two declared-length bytes — Whoop 4.0.
  crc8,

  /// CRC16-Modbus (poly 0xA001, init 0xFFFF, reflected) over the header prefix — Whoop 5.0.
  crc16Modbus,
}

/// Which WHOOP hardware generation a connection / capture belongs to.
///
/// This module is platform-pure: it never imports Bluetooth types. The BLE layer is responsible
/// for turning the UUID *strings* exposed here into UUID values. Keeping platform UUID types out of
/// this module lets the protocol code run on a plain VM (and in tests).
enum DeviceFamily {
  /// Whoop 4.0 — 0x07 CRC8 header check.
  whoop4,

  /// Whoop 5.0 / MG — CRC16-Modbus header check, "puffin" packet types.
  whoop5;

  /// Whoop 5.0 CLIENT_HELLO bytes (16 bytes). Exposed as a named constant for test/debug use.
  static final Uint8List whoop5ClientHello = Uint8List.fromList(<int>[
    0xAA, 0x01, 0x08, 0x00, 0x00, 0x01, 0xE6, 0x71, //
    0x23, 0x01, 0x91, 0x01, 0x36, 0x3E, 0x5C, 0x8D,
  ]);

  /// The header-CRC algorithm this family uses; the payload CRC32 is identical for both.
  HeaderCRCKind get headerCRCKind {
    switch (this) {
      case DeviceFamily.whoop4:
        return HeaderCRCKind.crc8;
      case DeviceFamily.whoop5:
        return HeaderCRCKind.crc16Modbus;
    }
  }

  /// Primary GATT service UUID *string* for this family (lowercase, as advertised).
  String get serviceUuidString {
    switch (this) {
      case DeviceFamily.whoop4:
        return '61080001-8d6d-82b8-614a-1c8cb0f8dcc6';
      case DeviceFamily.whoop5:
        return 'fd4b0001-cce1-4033-93ce-002d5875f58a';
    }
  }

  /// Characteristic UUID *strings* this family uses, in stable ascending order.
  List<String> get characteristicUuidStrings {
    switch (this) {
      case DeviceFamily.whoop4:
        return const <String>[
          '61080002-8d6d-82b8-614a-1c8cb0f8dcc6',
          '61080003-8d6d-82b8-614a-1c8cb0f8dcc6',
          '61080004-8d6d-82b8-614a-1c8cb0f8dcc6',
          '61080005-8d6d-82b8-614a-1c8cb0f8dcc6',
        ];
      case DeviceFamily.whoop5:
        return const <String>[
          'fd4b0002-cce1-4033-93ce-002d5875f58a',
          'fd4b0003-cce1-4033-93ce-002d5875f58a',
          'fd4b0004-cce1-4033-93ce-002d5875f58a',
          'fd4b0005-cce1-4033-93ce-002d5875f58a',
          'fd4b0007-cce1-4033-93ce-002d5875f58a',
        ];
    }
  }

  /// The command/write characteristic UUID *string* for this family (the …0002 endpoint that
  /// CLIENT_HELLO and command frames are written to). A single confirmed write here is the bond.
  String get commandCharacteristicUuidString {
    switch (this) {
      case DeviceFamily.whoop4:
        return '61080002-8d6d-82b8-614a-1c8cb0f8dcc6';
      case DeviceFamily.whoop5:
        return 'fd4b0002-cce1-4033-93ce-002d5875f58a';
    }
  }

  /// Static CLIENT_HELLO frame this family writes immediately after GATT discovery to start a
  /// session, or `null` for families that do not use a fixed hello.
  ///
  /// The Whoop 5.0 hello is a fully-formed type-35 (COMMAND) frame with CRC16-Modbus header and
  /// CRC32 payload trailer. Transcribed verbatim from the Goose reverse-engineering
  /// (`GooseHello.clientHelloFrameHex` = "aa0108000001e67123019101363e5c8d").
  Uint8List? get clientHello {
    switch (this) {
      case DeviceFamily.whoop4:
        return null;
      case DeviceFamily.whoop5:
        return Uint8List.fromList(whoop5ClientHello);
    }
  }
}

/// Whoop 5.0 "puffin" packet types mirror existing 4.0 types on the new transport. These map onto
/// the canonical base type names so they decode like their 4.0 counterparts instead of falling
/// through to an "unknown" label.
class PuffinPacketType {
  PuffinPacketType._();

  /// Puffin command response — behaves like COMMAND_RESPONSE (type 36).
  static const int puffinCommandResponse = 38;

  /// Puffin metadata — behaves like METADATA (type 49).
  static const int puffinMetadata = 56;
}
