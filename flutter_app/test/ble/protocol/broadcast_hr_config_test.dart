import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/whoop5_config.dart';

/// Faithful Dart port of `BroadcastHrConfigTest.kt`.
///
/// Golden test for the "Broadcast HR" device-config write — the strap is made to advertise its heart
/// rate as a standard BLE HR sensor (0x180D + live HR in the advertisement) by setting the device
/// config whoop_live_hr_in_adv_ind_pkt via SET_DEVICE_CONFIG (0x77). The body is the key name ASCII
/// NUL-padded to 32 bytes, then the value byte (ASCII digit) — 33 bytes, no trailing padding.
/// Validated on real hardware (paired on a Garmin Edge 840). Mirrors the Swift
/// Whoop5ConfigTests.testDeviceConfigBodyIsNameNullPaddedThenAsciiValue. (#181)
void main() {
  test('deviceConfigBodyIsNameNullPaddedThenAsciiValue', () {
    final body =
        Whoop5Config.deviceConfigBody('whoop_live_hr_in_adv_ind_pkt', 0x31);
    expect(body.length, 33);
    expect(
      String.fromCharCodes(body.sublist(0, 28)),
      'whoop_live_hr_in_adv_ind_pkt',
    );
    for (var i = 28; i < 32; i++) {
      expect(body[i], 0, reason: 'null pad @$i');
    }
    expect(body[32], '1'.codeUnitAt(0), reason: "ASCII '1' value @32");
  });

  test('disableUsesAsciiZero', () {
    expect(
      Whoop5Config.deviceConfigBody('whoop_live_hr_in_adv_ind_pkt', 0x30)[32],
      '0'.codeUnitAt(0),
    );
  });
}
