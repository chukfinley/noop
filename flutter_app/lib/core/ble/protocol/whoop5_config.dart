import 'dart:convert';
import 'dart:typed_data';

import 'framing.dart';

/// Faithful Dart port of `Whoop5Config.kt`.
///
/// WHOOP 5.0 / MG "R22" feature-flag config (deep-stream unlock) — direct port of the macOS/iOS
/// `Whoop5Config` (Packages/WhoopProtocol/Sources/WhoopProtocol/Whoop5Config.swift).
///
/// WHOOP 5/MG straps withhold their deep biometric streams (the high-rate "R22" optical/HR/motion
/// packets, type 0x2F) from a freshly-connected client. The official app switches them on by writing
/// a short burst of persistent feature-flag config values right after the hello handshake — a sequence
/// independently documented by two third parties: judes.club's "Cracking the WHOOP 5 Bluetooth
/// Protocol" (whose interactive frame-builder is the byte-level ground truth this is validated against)
/// and Asherlc/dofek's docs/whoop-ble-protocol.md (Android APK decompilation), which corroborate the
/// key names, values and the SET_FF_VALUE (0x78) opcode.
///
/// Each flag is one SET_CONFIG (0x78) command whose 40-byte payload is the flag NAME as ASCII,
/// NUL-padded to 32 bytes, then a one-byte value (itself an ASCII digit: '1'=0x31 or '2'=0x32) at
/// offset 32, then 7 zero bytes. The inner b3 byte (0x01) is carried as the first payload byte ahead
/// of the body, exactly like CLIENT_HELLO. Reversible (only changes which data the strap emits), gated
/// behind an explicit opt-in, and writable only on real iOS/Android hardware. (#174)
class Whoop5Config {
  Whoop5Config._();

  /// SET_CONFIG / SET_FF_VALUE command opcode.
  static const int setConfigCmd = 0x78;

  /// SET_DEVICE_CONFIG opcode (0x77). Writes one persistent device-config value (vs the feature-flag
  /// SET_CONFIG/0x78). Used for the Broadcast-HR flag; validated on real hardware. Keep in lockstep
  /// with the Swift `Whoop5Config.setDeviceConfigCmd`. (#181)
  static const int setDeviceConfigCmd = 0x77;

  /// The confirmed Broadcast-HR device-config KEY: setting it makes the strap advertise its heart rate
  /// as a standard 0x180D BLE HR sensor (live HR in the manufacturer data), so a Garmin / Zwift / gym
  /// receiver can pair to the strap directly. Validated on real hardware (paired on a Garmin Edge 840,
  /// spec §4). Value byte is an ASCII digit: '1'(0x31)=on / '0'(0x30)=off.
  static const String broadcastHrKey = 'whoop_live_hr_in_adv_ind_pkt';

  /// The full SET_DEVICE_CONFIG (0x77) command PAYLOAD for one device-config write: the b3 lead byte
  /// (0x01, like CLIENT_HELLO) ahead of the 33-byte [deviceConfigBody]. Hand this to the puffin framer
  /// with cmd [setDeviceConfigCmd]. Mirrors the Kotlin `setBroadcastHr` body (WhoopBleClient.kt:3812).
  static Uint8List deviceConfigPayload(String name, int value) {
    final body = deviceConfigBody(name, value);
    final payload = Uint8List(1 + body.length);
    payload[0] = 0x01;
    payload.setRange(1, 1 + body.length, body);
    return payload;
  }

  /// The exact ordered enable sequence the official app sends, transcribed verbatim from
  /// judes.club's frame-builder FLAGS array. `enable_r22_packets` opens the type-0x2F biometric
  /// stream; the rest tune channel selection, wear detection and sleep behaviour. Keep in lockstep
  /// with the Swift `Whoop5Config.enableR22Sequence`.
  static const List<Flag> enableR22Sequence = <Flag>[
    Flag('enable_r22_packets', 0x32),
    Flag('enable_r22_v2_packets', 0x32),
    Flag('enable_r22_v3_packets', 0x32),
    Flag('enable_r22_v4_packets', 0x31),
    Flag('enable_r22_v5_packets', 0x32),
    Flag('enable_r22_v6_packets', 0x32),
    Flag('enable_r22_v8_packets', 0x32),
    Flag('make_hrfm_visible', 0x32),
    Flag('disable_pip_r26_packets', 0x32),
    Flag('wear_detect_bias', 0x32),
    Flag('hr_ch_switching', 0x32),
    Flag('ir_hw_switching', 0x32),
    Flag('enable_passive_strap_fit_gen5', 0x31),
    Flag('enable_sig11_during_sleep', 0x32),
    Flag('dorset_inhibit_wpt', 0x32),
  ];

  /// The 40-byte SET_CONFIG payload body: flag name as ASCII NUL-padded to 32 bytes, value byte at
  /// offset 32, then 7 zero bytes. (Mirrors judes.club `setConfigPayload(name, value)`.)
  static Uint8List payloadBody(String name, int value) {
    final p = Uint8List(40);
    final bytes = ascii.encode(name);
    final n = bytes.length < 32 ? bytes.length : 32;
    for (var i = 0; i < n; i++) {
      p[i] = bytes[i];
    }
    p[32] = value & 0xFF;
    return p;
  }

  /// The device-config write body: key name as ASCII NUL-padded to 32 bytes, then the value byte (an
  /// ASCII digit, e.g. '1'=0x31 / '0'=0x30). 33 bytes, no trailing padding (unlike the 40-byte
  /// feature-flag body). The caller prepends the b3 byte (0x01) before sending, like CLIENT_HELLO.
  /// Validated for whoop_live_hr_in_adv_ind_pkt on real hardware (paired on a Garmin Edge 840).
  /// Keep in lockstep with the Swift `Whoop5Config.deviceConfigBody`. (#181)
  static Uint8List deviceConfigBody(String name, int value) {
    final b = Uint8List(33);
    final bytes = ascii.encode(name);
    final n = bytes.length < 32 ? bytes.length : 32;
    for (var i = 0; i < n; i++) {
      b[i] = bytes[i];
    }
    b[32] = value & 0xFF;
    return b;
  }

  /// The full puffin command-frame bytes for one feature-flag write (b3=0x01 ahead of the body),
  /// ready to send to the 5/MG command characteristic. Byte-for-byte identical to the official
  /// app's captured writes and to the Swift `Whoop5Config.frame`.
  static Uint8List frame(Flag flag, int seq) {
    final body = payloadBody(flag.name, flag.value);
    final payload = Uint8List(1 + body.length);
    payload[0] = 0x01;
    payload.setRange(1, 1 + body.length, body);
    return Framing.puffinCommandFrame(
      cmd: setConfigCmd,
      seq: seq,
      payload: payload,
    );
  }
}

/// One persistent feature flag and the value the official app writes for it (ASCII '1'/'2').
class Flag {
  const Flag(this.name, this.value);

  final String name;
  final int value;

  @override
  bool operator ==(Object other) =>
      other is Flag && other.name == name && other.value == value;

  @override
  int get hashCode => Object.hash(name, value);

  @override
  String toString() => 'Flag(name: $name, value: $value)';
}
