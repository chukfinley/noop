import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/alarm_payload.dart';
import 'package:noop/core/ble/protocol/crc.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/protocol/enums.dart';
import 'package:noop/core/ble/protocol/framing.dart';
import 'package:noop/core/ble/protocol/parsed_frame.dart';
import 'package:noop/core/ble/protocol/streams.dart';

/// Faithful Dart port of `FramingTest.kt`.
///
/// Frame round-trip + decode tests against concrete byte vectors.
///
/// All vectors were generated independently (Python: zlib CRC-32, table CRC-8, CRC16-Modbus) from
/// the same envelope spec the code implements, so a passing test confirms cross-checked agreement
/// rather than the code merely agreeing with itself.

String _hex(Uint8List bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write((b & 0xFF).toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

Uint8List _bytes(List<int> ints) => Uint8List.fromList(ints);

Uint8List _fromHex(String s) {
  final out = Uint8List(s.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

/// Build a CRC-valid WHOOP4 COMMAND_RESPONSE (type 0x24) frame for a given resp_cmd + payload,
/// computing crc8(length) and crc32(inner) exactly as the strap would, so the decode vector
/// cross-checks the decoder instead of agreeing with a hand-typed checksum.
Uint8List _whoop4CommandResponse(int cmd, Uint8List payload) {
  final inner = Uint8List(3 + payload.length); // type, seq, resp_cmd, payload
  inner[0] = 0x24;
  inner[1] = 0x00;
  inner[2] = cmd & 0xFF;
  inner.setRange(3, 3 + payload.length, payload);
  final length = 4 + inner.length; // crc32 sits at offset = length
  final out = Uint8List(length + 4);
  out[0] = 0xAA;
  out[1] = length & 0xFF;
  out[2] = (length >> 8) & 0xFF;
  out[3] = Crc.crc8(Uint8List.fromList(<int>[out[1], out[2]])) & 0xFF;
  out.setRange(4, 4 + inner.length, inner);
  final crc32 = Crc.crc32(inner);
  for (var i = 0; i < 4; i++) {
    out[length + i] = (crc32 >> (8 * i)) & 0xFF;
  }
  return out;
}

void main() {
  // MARK: - buildCommand round-trips

  test('buildCommand_getBatteryLevel_exactBytes', () {
    // GET_BATTERY_LEVEL(26), payload [0], seq 0.
    final frame = Framing.buildCommand(CommandNumber.getBatteryLevel,
        payload: _bytes(<int>[0]), seq: 0);
    expect(_hex(frame), 'aa0800a823001a001725ee23');
  });

  test('buildCommand_toggleRealtimeHr_exactBytes', () {
    // TOGGLE_REALTIME_HR(3), payload [1], seq 7.
    final frame = Framing.buildCommand(CommandNumber.toggleRealtimeHr,
        payload: _bytes(<int>[1]), seq: 7);
    expect(_hex(frame), 'aa0800a8230703011caaa6ca');
  });

  test('buildCommand_oneShotBuzzSequence_exactBytes', () {
    // #921 one-shot buzz: RUN_HAPTICS_PATTERN(79) [patternId=2, loops=3, 0, 0, 0] immediately
    // followed by RUN_ALARM(68) [0x01], on consecutive seq bytes.
    final haptics = Framing.buildCommand(CommandNumber.runHapticsPattern,
        payload: _bytes(<int>[2, 3, 0, 0, 0]), seq: 1);
    expect(_hex(haptics), 'aa0c00fc23014f02030000005ff5d722');
    final runAlarm = Framing.buildCommand(CommandNumber.runAlarm,
        payload: _bytes(<int>[0x01]), seq: 2);
    expect(_hex(runAlarm), 'aa0800a82302440135b15573');
    // The payload bytes themselves, pinned once more without the envelope: patternId=2, 3 loops.
    expect(haptics.sublist(7, 12), equals(_bytes(<int>[2, 3, 0, 0, 0])));
    expect(runAlarm[6] & 0xFF, CommandNumber.runAlarm.rawValue);
  });

  test('buildCommand_envelopeShapeIsCorrect', () {
    final frame = Framing.buildCommand(CommandNumber.getClock,
        payload: _bytes(<int>[0]), seq: 0);
    expect(frame[0], 0xAA); // SOF
    final length = (frame[1] & 0xFF) | ((frame[2] & 0xFF) << 8);
    expect(frame.length, length + 4); // total = length + 4
    expect(frame[4] & 0xFF, PacketType.command.rawValue); // type 35
    expect(frame[5] & 0xFF, 0); // seq
    expect(frame[6] & 0xFF, CommandNumber.getClock.rawValue); // cmd
  });

  test('buildCommand_parsesBackAsValidCommandResponseSibling', () {
    // Building a COMMAND frame and re-validating its CRCs proves the envelope is self-consistent.
    final frame = Framing.buildCommand(CommandNumber.getBatteryLevel,
        payload: _bytes(<int>[0]), seq: 0);
    // Manually re-check CRC8 over the two length bytes.
    final wantCrc8 = Crc.crc8(Uint8List.fromList(<int>[frame[1], frame[2]]));
    expect(wantCrc8, frame[3] & 0xFF);
    // Manually re-check CRC32 over the inner record frame[4 until length].
    final length = (frame[1] & 0xFF) | ((frame[2] & 0xFF) << 8);
    final inner = frame.sublist(4, length);
    final wantCrc32 = Crc.crc32(inner);
    final gotCrc32 = (frame[length] & 0xFF) |
        ((frame[length + 1] & 0xFF) << 8) |
        ((frame[length + 2] & 0xFF) << 16) |
        ((frame[length + 3] & 0xFF) << 24);
    expect(wantCrc32, gotCrc32);
  });

  // MARK: - puffinCommandFrame (EXPERIMENTAL WHOOP 5.0/MG)

  test('puffinCommandFrame_roundTripsThroughWhoop5Parse', () {
    // EXPERIMENTAL: a puffin TOGGLE_REALTIME_HR(3) probe, payload [1], seq 7.
    final frame = Framing.puffinCommandFrame(
      cmd: CommandNumber.toggleRealtimeHr.rawValue,
      seq: 7,
      payload: _bytes(<int>[1]),
    );
    final r = Framing.parseFrame(frame, DeviceFamily.whoop5);
    expect(r.ok, true);
    expect(r.crcOk, true);
    // Inner record starts at offset 8: [type=35][seq=7][cmd=3][payload=1].
    expect(frame[8] & 0xFF, PacketType.command.rawValue);
    expect(frame[9] & 0xFF, 7);
    expect(frame[10] & 0xFF, CommandNumber.toggleRealtimeHr.rawValue);
    expect(frame[11] & 0xFF, 1);
  });

  test('puffinCommandFrame_envelopeShapeAndCrcsAreSelfConsistent', () {
    final frame = Framing.puffinCommandFrame(
      cmd: CommandNumber.toggleRealtimeHr.rawValue,
      seq: 1,
      payload: _bytes(<int>[1]),
    );
    // SOF 0xAA, format byte 0x01.
    expect(frame[0], 0xAA);
    expect(frame[1], 0x01);
    // declaredLength = inner(3+1=4) + 4 = 8; total frame = declaredLength + 8.
    final declLen = (frame[2] & 0xFF) | ((frame[3] & 0xFF) << 8);
    expect(declLen, 8);
    expect(declLen + 8, frame.length);
    // CRC16-Modbus over frame[0..6) is stored LE at frame[6..8).
    final wantHeader = Crc.crc16Modbus(frame.sublist(0, 6));
    final gotHeader = (frame[6] & 0xFF) | ((frame[7] & 0xFF) << 8);
    expect(wantHeader, gotHeader);
    // CRC32 over the inner record frame[8 until total-4) is stored LE in the last 4 bytes.
    final payloadEnd = frame.length - 4;
    final inner = frame.sublist(8, payloadEnd);
    final wantCrc32 = Crc.crc32(inner);
    final gotCrc32 = (frame[payloadEnd] & 0xFF) |
        ((frame[payloadEnd + 1] & 0xFF) << 8) |
        ((frame[payloadEnd + 2] & 0xFF) << 16) |
        ((frame[payloadEnd + 3] & 0xFF) << 24);
    expect(wantCrc32, gotCrc32);
  });

  test('puffinCommandFrame_hapticsMatchesMaverickGolden', () {
    // WHOOP 5/MG buzz (#48): haptic inner is 15 bytes ([35, seq, 0x13] + 12-byte payload), which
    // pad4 must extend to 16 before length/CRC — like the strap's maverick framing.
    final payload =
        _bytes(<int>[0x01, 47, 152, 0, 0, 0, 0, 0, 0, 0, 0, 0]); // 0x01+effects(8)+loopCtl(2)+overall
    expect(payload.length, 12);
    final frame = Framing.puffinCommandFrame(cmd: 0x13, seq: 1, payload: payload);
    expect(_hex(frame),
        'aa0114000001e1e1230113012f980000000000000000000098cb83a5');
    expect(frame.length, 28); // 8 header + 16 padded inner + 4 crc32
    expect(Framing.parseFrame(frame, DeviceFamily.whoop5).ok, true);
    // pad4 is a NO-OP for already-4-aligned commands: HR toggle inner ([35,seq,3,1]) stays 16 bytes.
    expect(
        Framing.puffinCommandFrame(
                cmd: CommandNumber.toggleRealtimeHr.rawValue,
                seq: 7,
                payload: _bytes(<int>[1]))
            .length,
        16);
  });

  test('puffinCommandFrame_alarmFramesMatchSwiftParityGoldens', () {
    // Cross-platform parity pins: the macOS port asserts these SAME three full-frame hexes.
    final alarm = Framing.puffinCommandFrame(
        cmd: 66, seq: 1, payload: AlarmPayload.build(1700000000123));
    expect(_hex(alarm),
        'aa011c000001e381230142040100f15365be0f2f980000000000000000071e00392f2ac9');
    expect(
        _hex(Framing.puffinCommandFrame(
            cmd: 69, seq: 1, payload: AlarmPayload.disableRev2())),
        'aa010c000001e74123014502ff000000267ffc4f');
    expect(
        _hex(Framing.puffinCommandFrame(
            cmd: 68, seq: 1, payload: _bytes(<int>[0x02, 0x01]))),
        'aa010c000001e741230144020100000017cd19e2');
  });

  // MARK: - parseFrame decode vectors

  test('parse_realtimeData_heartRateAndRr', () {
    // type40 seq0, ts=1700000000, hr=62, rr=[850,870].
    final frame = _bytes(<int>[
      0xaa, 0x12, 0x00, 0x7d, 0x28, 0x00, 0x00, 0xf1, 0x53, 0x65, 0x00, 0x00,
      0x3e, 0x02, 0x52, 0x03, 0x66, 0x03, 0x73, 0x8f, 0x40, 0xae,
    ]);
    final r = Framing.parseFrame(frame);
    expect(r.ok, true);
    expect(r.crcOk, true);
    expect(r.typeName, 'REALTIME_DATA');
    expect(r.parsed['timestamp'], 1700000000);
    expect(r.parsed['heart_rate'], 62);
    expect(r.parsed['rr_intervals'], equals(<int>[850, 870]));
  });

  test('parse_eventBatteryLevel_socMvCharging', () {
    // EVENT BATTERY_LEVEL(3): ev_ts=1700000050, soc_raw=875(->87.5), mv=4012, charge=1.
    final frame = _bytes(<int>[
      0xaa, 0x1b, 0x00, 0xc0, 0x30, 0x00, 0x03, 0x00, 0x32, 0xf1, 0x53, 0x65,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x6b, 0x03, 0x00, 0x00, 0xac, 0x0f, 0x00,
      0x00, 0x00, 0x01, 0xb8, 0xe1, 0x9c, 0x12,
    ]);
    final r = Framing.parseFrame(frame);
    expect(r.ok, true);
    expect(r.crcOk, true);
    expect(r.typeName, 'EVENT');
    expect(r.parsed['event'], 'BATTERY_LEVEL(3)');
    expect(r.parsed['event_timestamp'], 1700000050);
    expect(r.parsed['battery_pct'] as double, closeTo(87.5, 1e-9));
    expect(r.parsed['battery_mV'], 4012);
    expect(r.parsed['battery_charging'], 1);
  });

  test('parse_eventBatteryLevel_notCharging', () {
    // Same synthetic BATTERY_LEVEL vector with the charge byte @26 = 0.
    final frame = _bytes(<int>[
      0xaa, 0x1b, 0x00, 0xc0, 0x30, 0x00, 0x03, 0x00, 0x32, 0xf1, 0x53, 0x65,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x6b, 0x03, 0x00, 0x00, 0xac, 0x0f, 0x00,
      0x00, 0x00, 0x00, 0x2e, 0xd1, 0x9b, 0x65,
    ]);
    final r = Framing.parseFrame(frame);
    expect(r.ok, true);
    expect(r.crcOk, true);
    expect(r.parsed['event'], 'BATTERY_LEVEL(3)');
    expect(r.parsed['battery_charging'], 0);
  });

  test('parse_metadata_historyEnd', () {
    // METADATA HISTORY_END(2): unix=1699999999, trim=123456.
    final frame = _bytes(<int>[
      0xaa, 0x15, 0x00, 0x16, 0x31, 0x00, 0x02, 0xff, 0xf0, 0x53, 0x65, 0x05,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0xe2, 0x01, 0x00, 0x5a, 0x85, 0x0d,
      0x5e,
    ]);
    final r = Framing.parseFrame(frame);
    expect(r.ok, true);
    expect(r.crcOk, true);
    expect(r.typeName, 'METADATA');
    expect(r.parsed['meta_type'], 'HISTORY_END(2)');
    expect(r.parsed['unix'], 1699999999);
    expect(r.parsed['trim_cursor'], 123456);
  });

  test('parse_commandResponse_getBatteryLevel', () {
    // COMMAND_RESPONSE GET_BATTERY_LEVEL(26): soc=912 -> 91.2%.
    final frame = _bytes(<int>[
      0xaa, 0x0b, 0x00, 0x97, 0x24, 0x00, 0x1a, 0x00, 0x00, 0x90, 0x03, 0x72,
      0x96, 0x86, 0x64,
    ]);
    final r = Framing.parseFrame(frame);
    expect(r.ok, true);
    expect(r.crcOk, true);
    expect(r.typeName, 'COMMAND_RESPONSE');
    expect(r.parsed['resp_cmd'], 'GET_BATTERY_LEVEL(26)');
    expect(r.parsed['battery_pct'] as double, closeTo(91.2, 1e-9));
  });

  test('parse_commandResponse_reportVersionInfo_fwHarvard', () {
    // COMMAND_RESPONSE REPORT_VERSION_INFO(7): fw_harvard = four LE u32 at payload[3,7,11,15].
    // payload[0..2] are status bytes (ignored); the four versions spell 41.16.6.0.
    final payload = Uint8List(19);
    void le32(int at, int v) {
      for (var i = 0; i < 4; i++) {
        payload[at + i] = (v >> (8 * i)) & 0xFF;
      }
    }

    le32(3, 41);
    le32(7, 16);
    le32(11, 6);
    le32(15, 0);
    final r = Framing.parseFrame(
        _whoop4CommandResponse(CommandNumber.reportVersionInfo.rawValue, payload));
    expect(r.ok, true);
    expect(r.crcOk, true);
    expect(r.typeName, 'COMMAND_RESPONSE');
    expect(r.parsed['fw_harvard'], '41.16.6.0');
  });

  test('parse_corruptedCrc_reportsCrcFalse', () {
    // Flip a payload byte so the CRC32 no longer matches; the frame is still well-formed (ok),
    // but crcOk must be false so downstream code rejects it.
    final frame = _bytes(<int>[
      0xaa, 0x12, 0x00, 0x7d, 0x28, 0x00, 0x00, 0xf1, 0x53, 0x65, 0x00, 0x00,
      0x3e, 0x02, 0x52, 0x03, 0x66, 0x03, 0x73, 0x8f, 0x40, 0xae,
    ]);
    frame[12] = (frame[12] + 1) & 0xFF; // mutate heart_rate byte
    final r = Framing.parseFrame(frame);
    expect(r.ok, true);
    expect(r.crcOk, false);
  });

  test('parse_fragmentIsInvalid', () {
    final r = Framing.parseFrame(_bytes(<int>[0xaa, 0x12, 0x00]));
    expect(r.ok, false);
    expect(r.typeName, 'INVALID/FRAGMENT');
    expect(r.crcOk, isNull);
  });

  // MARK: - Reassembler

  test('reassembler_splitFrameAcrossFragments', () {
    final frame = Framing.buildCommand(CommandNumber.getBatteryLevel,
        payload: _bytes(<int>[0]), seq: 0);
    final r = Reassembler();
    // Split mid-frame.
    final cut = frame.length ~/ 2;
    expect(r.feed(frame.sublist(0, cut)), isEmpty);
    final done = r.feed(frame.sublist(cut, frame.length));
    expect(done.length, 1);
    expect(done[0], equals(frame));
  });

  test('reassembler_twoFramesInOneFragment', () {
    final a = Framing.buildCommand(CommandNumber.getBatteryLevel,
        payload: _bytes(<int>[0]), seq: 0);
    final b = Framing.buildCommand(CommandNumber.getClock,
        payload: _bytes(<int>[0]), seq: 1);
    final r = Reassembler();
    final out = r.feed(_bytes(<int>[...a, ...b]));
    expect(out.length, 2);
    expect(out[0], equals(a));
    expect(out[1], equals(b));
  });

  test('reassembler_dropsLeadingGarbageBeforeSof', () {
    final frame = Framing.buildCommand(CommandNumber.getBatteryLevel,
        payload: _bytes(<int>[0]), seq: 0);
    final r = Reassembler();
    final out = r.feed(_bytes(<int>[0x00, 0x11, 0x22, ...frame]));
    expect(out.length, 1);
    expect(out[0], equals(frame));
  });

  test('reassembler_garbageLengthDoesNotStall_resyncsToNextFrame', () {
    // A misaligned/corrupt SOF with an impossibly large declared length (0xFFFF -> 65539 bytes)
    // must NOT wedge the stream. The reassembler should drop the bad SOF and recover the real frame.
    final good = Framing.buildCommand(CommandNumber.getBatteryLevel,
        payload: _bytes(<int>[0]), seq: 0);
    final garbage = _bytes(<int>[0xAA, 0xFF, 0xFF, 0x00]);
    final r = Reassembler();
    final out = r.feed(_bytes(<int>[...garbage, ...good]));
    expect(out.length, 1);
    expect(out[0], equals(good));
  });

  test('reassembler_reassemblesWhenFedOneByteAtATime', () {
    // Two back-to-back frames, fed a single byte per fragment.
    final first = Framing.buildCommand(CommandNumber.getBatteryLevel,
        payload: _bytes(<int>[0]), seq: 0);
    final second = Framing.buildCommand(CommandNumber.getClock,
        payload: _bytes(<int>[0]), seq: 1);
    final r = Reassembler();
    final out = <Uint8List>[];
    for (final b in <int>[...first, ...second]) {
      out.addAll(r.feed(_bytes(<int>[b])));
    }
    expect(out.length, 2);
    expect(out[0], equals(first));
    expect(out[1], equals(second));
  });

  test('reassembler_resetDropsPartialFrame', () {
    // reset() (called on every reconnect) must discard a buffered half-frame.
    final frame = Framing.buildCommand(CommandNumber.getBatteryLevel,
        payload: _bytes(<int>[0]), seq: 0);
    final r = Reassembler();
    final cut = frame.length ~/ 2;
    expect(r.feed(frame.sublist(0, cut)), isEmpty);
    r.reset();
    final out = r.feed(frame);
    expect(out.length, 1);
    expect(out[0], equals(frame));
  });

  // MARK: - enum fromRaw

  test('enums_fromRawRoundTrip', () {
    expect(PacketType.fromRaw(40), PacketType.realtimeData);
    expect(EventNumber.fromRaw(3), EventNumber.batteryLevel);
    expect(MetadataType.fromRaw(2), MetadataType.historyEnd);
    expect(CommandNumber.fromRaw(79), CommandNumber.runHapticsPattern);
    // #769: STOP_HAPTICS is cmd 122, the documented WHOOP 4.0 clear the Breathe teardown fires.
    expect(CommandNumber.fromRaw(122), CommandNumber.stopHaptics);
    expect(CommandNumber.stopHaptics.rawValue, 122);
    expect(PacketType.fromRaw(999), isNull);
    expect(CommandNumber.fromRaw(26), isNotNull);
  });

  // MARK: - extractStreams

  test('extractStreams_hrAndRrFromRealtime', () {
    final frame = _bytes(<int>[
      0xaa, 0x12, 0x00, 0x7d, 0x28, 0x00, 0x00, 0xf1, 0x53, 0x65, 0x00, 0x00,
      0x3e, 0x02, 0x52, 0x03, 0x66, 0x03, 0x73, 0x8f, 0x40, 0xae,
    ]);
    final parsed = Framing.parseFrame(frame);
    // deviceClockRef == wallClockRef so ts passes through unchanged.
    final streams = extractStreams(<ParsedFrame>[parsed], 1700000000, 1700000000);
    expect(streams.hr.length, 1);
    expect(streams.hr[0], const HrSample(1700000000, 62));
    expect(streams.rr.length, 2);
    expect(streams.rr[0], const RrInterval(1700000000, 850));
    expect(streams.rr[1], const RrInterval(1700000000, 870));
  });

  // MARK: - WHOOP 5.0/MG REALTIME_DATA (+4) + family-aware reassembly

  // A real type-40 REALTIME_DATA frame from a worn WHOOP 5 (same vector as the Swift
  // Whoop5RealtimeTests): hr=98, rr=[603,587] ms, ts=1780916382. HR matched the 0x2A37 profile.
  const whoop5RealtimeHex =
      'aa011800010022e128029ea0266aae4762025b024b020000000001005ed515dc';

  test('whoop5_realtimeData_decodesHrRrAtPlus4', () {
    final f = Framing.parseFrame(_fromHex(whoop5RealtimeHex), DeviceFamily.whoop5);
    expect(f.ok, true);
    expect(f.typeName, 'REALTIME_DATA');
    expect(f.crcOk, true);
    expect(f.parsed['heart_rate'], 98); // 4.0 @12 -> 5.0 @16
    expect(f.parsed['timestamp'], 1780916382); // 4.0 @6 -> 5.0 @10
    expect(f.parsed['rr_intervals'], equals(<int>[603, 587]));
  });

  test('whoop5_reassembler_isFamilyAware', () {
    // The WHOOP4 length rule decodes a bogus ~6 KB length for a 5/MG frame and never emits; the
    // family-aware reassembler frames it correctly (declLen @[2..4], total + 8).
    final frame = _fromHex(whoop5RealtimeHex);
    final out = Reassembler(DeviceFamily.whoop5).feed(frame);
    expect(out.length, 1);
    expect(out[0], equals(frame));
    expect(Reassembler(DeviceFamily.whoop4).feed(frame), isEmpty);
  });

  // MARK: - WHOOP 5/MG command + decode vectors (real-hardware captures, #78 fork)

  test('puffinCommandFrame_historicalCommandsMatchGooseBytes', () {
    // CRC-pinned against frames a real WHOOP 5 acked (Goose-compatible). Our [0x00] default
    // payload pads identically to an empty payload (pad4), so both forms produce these bytes.
    final getRange = Framing.puffinCommandFrame(
      cmd: CommandNumber.getDataRange.rawValue,
      seq: 1,
      payload: _bytes(<int>[]),
    );
    final sendHistorical = Framing.puffinCommandFrame(
      cmd: CommandNumber.sendHistoricalData.rawValue,
      seq: 2,
      payload: _bytes(<int>[]),
    );
    expect(_hex(getRange), 'aa0108000001e67123012200dbf3b335');
    expect(_hex(sendHistorical), 'aa0108000001e6712302160075bedf8c');
  });

  test('whoop5_commandResponse_decodesAtPuffinOffsets', () {
    // Synthetic puffin COMMAND_RESPONSE round-trip: GET_DATA_RANGE, resp_seq=7, result=SUCCESS.
    final frame = Framing.puffinCommandFrame(
      cmd: CommandNumber.getDataRange.rawValue,
      seq: 0,
      payload: _bytes(<int>[7, 1]),
      type: PacketType.commandResponse.rawValue,
    );
    final parsed = Framing.parseFrame(frame, DeviceFamily.whoop5);
    expect(parsed.typeName, 'COMMAND_RESPONSE');
    expect(parsed.parsed['resp_cmd'], 'GET_DATA_RANGE(34)');
    expect(parsed.parsed['resp_seq'], 7);
    expect(parsed.parsed['result'], 'SUCCESS(1)');
  });

  test('whoop5_event_decodesAtPlus4AndPreservesPayload', () {
    // Real 5/MG capture: uncatalogued event 0x1D(29) with a 16-byte payload — kept as hex so
    // protocol research can classify it later.
    final frame = _fromHex(
        'aa011c00010023d130c61d00e61ab7698a390c000e0000000000e8020b000100d2803585');
    final parsed = Framing.parseFrame(frame, DeviceFamily.whoop5);
    expect(parsed.typeName, 'EVENT');
    expect(parsed.crcOk, true);
    expect(parsed.parsed['event'], '0x1D(29)');
    expect(parsed.parsed['event_timestamp'], 1773607654);
    expect(parsed.parsed['event_payload_hex'], '8a390c000e0000000000e8020b000100');
  });

  test('whoop5_consoleLogs_extractsText', () {
    // Real 5/MG capture: the strap narrating its own history transfer. NUL-trimmed.
    final frame = _fromHex(
      'aa014400010030b1329f02005319b769a93e340001486973746f726963616c20446174610a20'
      '35352c20323538313935393a20424c453a2068697374207472616e7366657220730039d91fe2',
    );
    final parsed = Framing.parseFrame(frame, DeviceFamily.whoop5);
    expect(parsed.typeName, 'CONSOLE_LOGS');
    expect(parsed.crcOk, true);
    expect(parsed.parsed['console'],
        'Historical Data\n 55, 2581959: BLE: hist transfer s');
  });
}
