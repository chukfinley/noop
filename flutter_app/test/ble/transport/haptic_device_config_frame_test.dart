import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/protocol/enums.dart';
import 'package:noop/core/ble/protocol/framing.dart';
import 'package:noop/core/ble/protocol/haptic_clock.dart';
import 'package:noop/core/ble/protocol/whoop5_config.dart';

/// Byte-golden tests for what `WhoopBleClient.runHaptic` / `setDeviceConfig` put on the wire
/// (device-config-and-haptics spec §4/§6). Both methods compose exactly these two layers — a
/// spec-pinned payload body + the family framer — so pinning the payload bytes AND the command-frame
/// bytes proves the transport emits the spec's bytes, with no device involved (the transport device
/// paths stay inert in tests, mirroring strap_alarm_frame_test).
void main() {
  Uint8List bytes(List<int> b) =>
      Uint8List.fromList(b.map((i) => i & 0xFF).toList());

  group('haptic payload goldens', () {
    test('WHOOP 5/MG maverick notify body is the confirmed 12-byte DRV2625 form', () {
      // [0x01 lead][8×waveFormEffect: 47,152,0..][u16 LE loopControl=0][overallLoop=0].
      final body = HapticPattern.maverickNotifyBody();
      expect(body,
          bytes(<int>[0x01, 47, 152, 0, 0, 0, 0, 0, 0, 0, 0, 0]));
      expect(body.length, 12);
    });

    test('WHOOP 4.0 legacy buzz body is [patternId 2, loops, 0,0,0]', () {
      expect(HapticPattern.whoop4BuzzBody(loops: 3),
          bytes(<int>[2, 3, 0, 0, 0]));
      // patternId + loops are configurable; loops clamps to a byte.
      expect(HapticPattern.whoop4BuzzBody(patternId: 5, loops: 300),
          bytes(<int>[5, 255, 0, 0, 0]));
      expect(HapticPattern.whoop4BuzzBody().length, 5);
    });
  });

  group('haptic command-frame goldens', () {
    test('WHOOP 5/MG buzz frames as puffin cmd 0x13 + the 12-byte notify body, CRC valid', () {
      // 0x13 = 19 = RUN_HAPTIC_PATTERN_MAVERICK; a raw legacy 79 is rejected on real MG (spec §6.2).
      final body = HapticPattern.maverickNotifyBody();
      final frame = Framing.puffinCommandFrame(
          cmd: CommandNumber.runHapticPatternMaverick.rawValue,
          seq: 1,
          payload: body);
      expect(CommandNumber.runHapticPatternMaverick.rawValue, 0x13);
      // Inner record starts at offset 8: [type=35][seq][cmd=0x13] then the payload at 11..22.
      expect(frame[8], PacketType.command.rawValue);
      expect(frame[9], 1); // seq
      expect(frame[10], 0x13); // RUN_HAPTIC_PATTERN_MAVERICK
      expect(Uint8List.sublistView(frame, 11, 11 + body.length), body);
      // The 12-byte payload makes the inner record 15 bytes → padded to 16 for puffin framing; a valid
      // CRC proves the pad4 + declLen + CRC32 all cover the right byte count (the strap else rejects it).
      expect(Framing.parseFrame(frame, DeviceFamily.whoop5).crcOk, isTrue);
    });

    test('WHOOP 4.0 buzz frames as [35][seq][79] + [2,loops,0,0,0], CRC valid', () {
      final body = HapticPattern.whoop4BuzzBody(loops: 3);
      final frame = Framing.buildCommand(CommandNumber.runHapticsPattern,
          payload: body, seq: 4);
      expect(CommandNumber.runHapticsPattern.rawValue, 0x4F);
      expect(frame[0], 0xAA); // SOF
      expect(frame[4], PacketType.command.rawValue); // type 35
      expect(frame[5], 4); // seq
      expect(frame[6], 79); // RUN_HAPTICS_PATTERN
      expect(Uint8List.sublistView(frame, 7, 7 + body.length), body);
      expect(Framing.parseFrame(frame, DeviceFamily.whoop4).crcOk, isTrue);
    });
  });

  group('device-config (Broadcast-HR) goldens', () {
    test('deviceConfigPayload is the b3 lead byte then the 33-byte key body', () {
      final payload = Whoop5Config.deviceConfigPayload(
          Whoop5Config.broadcastHrKey, 0x31);
      expect(payload.length, 34); // 1 (b3=0x01) + 33 (key body)
      expect(payload[0], 0x01);
      expect(Uint8List.sublistView(payload, 1),
          Whoop5Config.deviceConfigBody(Whoop5Config.broadcastHrKey, 0x31));
      expect(Whoop5Config.broadcastHrKey, 'whoop_live_hr_in_adv_ind_pkt');
    });

    test('Broadcast-HR ON frames as puffin cmd 0x77 + payload, CRC valid', () {
      final payload = Whoop5Config.deviceConfigPayload(
          Whoop5Config.broadcastHrKey, 0x31); // '1' = on
      final frame = Framing.puffinCommandFrame(
          cmd: CommandNumber.setDeviceConfig.rawValue, seq: 0, payload: payload);
      expect(CommandNumber.setDeviceConfig.rawValue, 0x77);
      expect(frame[8], PacketType.command.rawValue);
      expect(frame[10], 0x77); // SET_DEVICE_CONFIG
      expect(Uint8List.sublistView(frame, 11, 11 + payload.length), payload);
      // Key value byte at inner payload offset [1 + 32] must be ASCII '1'.
      expect(frame[11 + 1 + 32], '1'.codeUnitAt(0));
      expect(Framing.parseFrame(frame, DeviceFamily.whoop5).crcOk, isTrue);
    });

    test('Broadcast-HR OFF uses ASCII 0 and still frames with a valid CRC', () {
      final payload = Whoop5Config.deviceConfigPayload(
          Whoop5Config.broadcastHrKey, 0x30); // '0' = off
      final frame = Framing.puffinCommandFrame(
          cmd: CommandNumber.setDeviceConfig.rawValue, seq: 2, payload: payload);
      expect(frame[11 + 1 + 32], '0'.codeUnitAt(0));
      expect(Framing.parseFrame(frame, DeviceFamily.whoop5).crcOk, isTrue);
    });
  });
}
