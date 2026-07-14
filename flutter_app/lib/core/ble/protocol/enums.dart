/// Faithful Dart port of `Enums.kt`.
///
/// On-wire enums for the WHOOP protocol. Each constant carries its raw (on-wire) int value and
/// every enum offers a `fromRaw(int)` lookup that returns null for unknown codes.
///
/// Values mirror the canonical schema (whoop_protocol.json) and the project SHARED CONTRACT.
/// These are deliberately a curated subset of the full device enum tables — only the codes the
/// offline companion app reads or sends. Unknown codes are surfaced by name elsewhere (see
/// `Framing.enumLabel`); they are not added here so the enums stay small and intentional.
library;

/// Frame packet type (envelope byte at offset 4 for Whoop 4.0).
enum PacketType {
  command(35),
  commandResponse(36),
  puffinCommand(37),
  puffinCommandResponse(38),
  realtimeData(40),
  realtimeRawData(43),
  historicalData(47),
  event(48),
  metadata(49),
  consoleLogs(50),
  realtimeImuDataStream(51),
  historicalImuDataStream(52);

  const PacketType(this.rawValue);

  final int rawValue;

  static PacketType? fromRaw(int raw) {
    for (final e in values) {
      if (e.rawValue == raw) return e;
    }
    return null;
  }
}

/// METADATA frame sub-type (historical-offload state machine).
enum MetadataType {
  historyStart(1),
  historyEnd(2),
  historyComplete(3);

  const MetadataType(this.rawValue);

  final int rawValue;

  static MetadataType? fromRaw(int raw) {
    for (final e in values) {
      if (e.rawValue == raw) return e;
    }
    return null;
  }
}

/// EVENT frame event code (offset 6 in an EVENT frame).
enum EventNumber {
  batteryLevel(3),
  chargingOn(7),
  chargingOff(8),
  wristOn(9),
  wristOff(10),
  doubleTap(14),
  temperatureLevel(17),
  bleBonded(23),
  bleRealtimeHrOn(33),
  bleRealtimeHrOff(34),
  strapDrivenAlarmExecuted(57),
  appDrivenAlarmExecuted(58),
  hapticsFired(60);

  const EventNumber(this.rawValue);

  final int rawValue;

  static EventNumber? fromRaw(int raw) {
    for (final e in values) {
      if (e.rawValue == raw) return e;
    }
    return null;
  }
}

/// Curated, SAFE command codes for *sending* to the strap. Destructive commands
/// (reboot / firmware load / force-trim / ship-mode / power-cycle / fuel-gauge reset / BLE DFU)
/// are deliberately excluded so the in-app sender can never brick or wipe the device.
enum CommandNumber {
  toggleRealtimeHr(3),
  // ABORT_HISTORICAL_TRANSMITS (0x14) — tell the strap to stop any in-flight historical dump. This
  // is NON-destructive (it only cancels the current offload stream; it never trims/wipes flash), and
  // it is central to the official app's sync: the WHOOP app sends it (1) once on connect to clear a
  // dump left running by a previously-crashed session, and (2) on any error / 5 s inactivity /
  // cancel to unwedge the transfer. Mirrors Kotlin `WhoopProtocol.abortHistoricalTransmits` and
  // official `com.whoop.straphistorysync.sync` (opcode verified in `vp0/e.smali`).
  abortHistoricalTransmits(20),
  // REPORT_VERSION_INFO (7): WHOOP 4.0 firmware/version read. The strap answers with the bundled
  // component versions (`fw_harvard` a.b.c.d, `fw_boylston` a.b.c.d). A documented READ command,
  // separate from the firmware-LOAD opcodes. Mirrors Swift `WhoopCommand.reportVersionInfo`.
  reportVersionInfo(7),
  setClock(10),
  getClock(11),
  sendHistoricalData(22),
  // The historical-offload trim/ack command. Sent (with response) to confirm one HISTORY_END
  // chunk so the strap may trim it; payload = [0x01] + the verbatim 8-byte HISTORY_END end_data.
  // Port of Swift `WhoopCommand.historicalDataResult` (whoop_protocol.json: 23 HISTORICAL_DATA_RESULT).
  historicalDataResult(23),
  getBatteryLevel(26),
  getDataRange(34),
  getHelloHarvard(35),
  // GET_HELLO (145): WHOOP 5.0/MG hello. The response carries the device name plus `fw_version`
  // a.b.c.d. Older 4.0 firmware replies "unsupported" (0a03) and is ignored. Mirrors Swift
  // `WhoopCommand.getHello`.
  getHello(145),
  sendR10R11Realtime(63),
  // WHOOP 5.0/MG (device family GOOSE/MAVERICK) one-shot buzz. Gen-4 straps use the legacy
  // RUN_HAPTICS_PATTERN(79) below; a 5/MG strap only honors this command.
  runHapticPatternMaverick(19),
  setAlarmTime(66),
  getAlarmTime(67),
  runAlarm(68),
  disableAlarm(69),
  // SET_ADVERTISING_NAME_HARVARD (77) — rename the WHOOP 4.0's BLE advertising name on the strap
  // firmware (the name the OS shows in Bluetooth). Payload: [0x00,0x00] + UTF-8 name + [0x00]; the
  // strap reboots to apply. WHOOP 4.0 only (a 5/MG uses puffin framing + a different config path).
  // Port of Swift WhoopCommand.setAdvertisingNameHarvard.
  setAdvertisingName(77),
  runHapticsPattern(79),
  getAllHapticsPattern(80),
  // SET_CONFIG / SET_FF_VALUE (0x78) — write one persistent feature flag. The 5/MG "enable R22
  // packets" sequence (Whoop5Config) sends 15 of these to switch on the deep biometric streams.
  // Reversible; gated behind the deep-data opt-in; iOS/Android only. (#174)
  setConfig(120),
  // SET_DEVICE_CONFIG (0x77) — write one persistent DEVICE-config value (distinct from the
  // feature-flag SET_CONFIG/0x78). Used for the "Broadcast HR" flag whoop_live_hr_in_adv_ind_pkt,
  // which makes the strap advertise its HR as a standard 0x180D BLE sensor. Validated on real
  // hardware (paired on a Garmin Edge 840). Reversible; gated behind the broadcast-HR opt-in. (#181)
  setDeviceConfig(119),
  startRawData(81),
  stopRawData(82),
  stopHaptics(122),
  selectWrist(123);

  const CommandNumber(this.rawValue);

  final int rawValue;

  static CommandNumber? fromRaw(int raw) {
    for (final e in values) {
      if (e.rawValue == raw) return e;
    }
    return null;
  }
}
