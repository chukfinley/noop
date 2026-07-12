import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/alarm_payload.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/protocol/enums.dart';
import 'package:noop/core/ble/protocol/framing.dart';

/// Byte-golden tests for what `WhoopBleClient.setStrapAlarm` puts on the wire (smart-alarm spec §2/§4).
/// setStrapAlarm composes exactly these two layers — the [AlarmPayload] body + the family framer — so
/// pinning the payload bytes and the command-frame bytes proves the transport emits the spec's bytes,
/// with no device involved.
void main() {
  Uint8List bytes(List<int> b) => Uint8List.fromList(b.map((i) => i & 0xFF).toList());

  group('payload goldens', () {
    test('WHOOP4 SET_ALARM_TIME body is the confirmed 9-byte form', () {
      // [alarmId=0x01][u32 LE epoch seconds][0x00,0x00][0x00,0x00]. epoch 0x12345678 → LE 78 56 34 12.
      final body = AlarmPayload.buildWhoop4(0x12345678);
      expect(body, bytes(<int>[0x01, 0x78, 0x56, 0x34, 0x12, 0x00, 0x00, 0x00, 0x00]));
      expect(body.length, 9);
    });

    test('WHOOP5 SET_ALARM_TIME body is the 20-byte rev4 golden', () {
      // wake = 1_700_000_000_000 ms → 1_700_000_000 s = 0x6553F100 (LE 00 F1 53 65), subseconds 0.
      final body = AlarmPayload.build(1700000000000);
      expect(
        body,
        bytes(<int>[
          0x04, 0x01, // REVISION_4, alarmId 1
          0x00, 0xF1, 0x53, 0x65, // epoch seconds u32 LE
          0x00, 0x00, // subseconds u16 LE
          47, 152, 0, 0, 0, 0, 0, 0, // 8 waveform effects
          0x00, 0x00, // loopControl u16 LE
          7, 30, // overallLoop, durationSeconds
        ]),
      );
      expect(body.length, 20);
      expect(body.length % 4, 0, reason: 'rev4 payload must be 4-byte aligned for puffin framing');
    });

    test('DISABLE_ALARM body is the rev2 sentinel [0x02,0xFF]', () {
      expect(AlarmPayload.disableRev2(), bytes(<int>[0x02, 0xFF]));
    });
  });

  group('command-frame goldens', () {
    test('WHOOP4 SET_ALARM_TIME frames as [35][seq][66]+9-byte body, CRC valid', () {
      final body = AlarmPayload.buildWhoop4(0x12345678);
      final frame = Framing.buildCommand(CommandNumber.setAlarmTime, payload: body, seq: 7);
      expect(frame[0], 0xAA); // SOF
      expect(frame[4], PacketType.command.rawValue); // type 35
      expect(frame[5], 7); // seq
      expect(frame[6], 66); // SET_ALARM_TIME
      expect(Uint8List.sublistView(frame, 7, 7 + body.length), body);
      // Round-trips through the WHOOP4 decoder with a valid CRC32.
      expect(Framing.parseFrame(frame, DeviceFamily.whoop4).crcOk, isTrue);
    });

    test('WHOOP4 DISABLE_ALARM frames as [35][seq][69]+[0x02,0xFF]', () {
      final frame = Framing.buildCommand(CommandNumber.disableAlarm,
          payload: AlarmPayload.disableRev2(), seq: 3);
      expect(frame[4], PacketType.command.rawValue);
      expect(frame[6], 69); // DISABLE_ALARM
      expect(Uint8List.sublistView(frame, 7, 9), bytes(<int>[0x02, 0xFF]));
      expect(Framing.parseFrame(frame, DeviceFamily.whoop4).crcOk, isTrue);
    });

    test('WHOOP5 SET_ALARM_TIME puffin frame carries cmd 66 + the 20-byte rev4 body, CRC valid', () {
      final body = AlarmPayload.build(1700000000000);
      final frame = Framing.puffinCommandFrame(cmd: 66, seq: 0, payload: body);
      // Inner record starts at offset 8: [type=35][seq][cmd=66] then the payload at 11..31.
      expect(frame[8], PacketType.command.rawValue);
      expect(frame[9], 0); // seq
      expect(frame[10], 66); // SET_ALARM_TIME
      expect(Uint8List.sublistView(frame, 11, 11 + body.length), body);
      // The strap rejects a misaligned puffin payload ("error = 4"); a valid CRC proves 4-alignment.
      expect(Framing.parseFrame(frame, DeviceFamily.whoop5).crcOk, isTrue);
    });

    test('WHOOP5 GET_ALARM_TIME request payload is [0x04,0x01] (rev4, alarmId 1)', () {
      // Mirrors the readback request setStrapAlarm/getStrapAlarm send on 5/MG (spec §3.1).
      final frame = Framing.puffinCommandFrame(cmd: 67, seq: 0, payload: bytes(<int>[0x04, 0x01]));
      expect(frame[10], 67); // GET_ALARM_TIME
      expect(Uint8List.sublistView(frame, 11, 13), bytes(<int>[0x04, 0x01]));
      expect(Framing.parseFrame(frame, DeviceFamily.whoop5).crcOk, isTrue);
    });
  });
}
