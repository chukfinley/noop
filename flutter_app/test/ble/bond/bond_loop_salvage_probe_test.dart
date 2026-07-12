import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/transport/whoop_ble_client.dart';

/// Port of `BondLoopSalvageProbeTest.kt` (#78 hole-4). Pins the pure gate for the one bounded
/// app-foreground salvage attempt while the bond-loop pause is latched: it must fire past the floor
/// while paused (so a strap the user has since freed self-heals), but never re-enter the refusal
/// hammer (capped at one per floor window, suppressed when connected / user-torn-down / never tripped).
void main() {
  const floor = WhoopBleClient.bondLoopSalvageFloorMs;

  test('fires past the floor while paused', () {
    expect(
      WhoopBleClient.shouldSalvageProbe(
          pausedForBondLoop: true,
          connected: false,
          intentionalDisconnect: false,
          msSincePauseTripped: floor),
      isTrue,
    );
    expect(
      WhoopBleClient.shouldSalvageProbe(
          pausedForBondLoop: true,
          connected: false,
          intentionalDisconnect: false,
          msSincePauseTripped: floor + 3600000),
      isTrue,
    );
  });

  test('respects the floor', () {
    // Below the floor no probe fires — back-to-back foregrounds can't chain attempts.
    expect(
      WhoopBleClient.shouldSalvageProbe(
          pausedForBondLoop: true,
          connected: false,
          intentionalDisconnect: false,
          msSincePauseTripped: floor - 1),
      isFalse,
    );
    expect(
      WhoopBleClient.shouldSalvageProbe(
          pausedForBondLoop: true,
          connected: false,
          intentionalDisconnect: false,
          msSincePauseTripped: 0),
      isFalse,
    );
  });

  test('needs a trip timestamp', () {
    // null ms = the pause never tripped this run = never probe.
    expect(
      WhoopBleClient.shouldSalvageProbe(
          pausedForBondLoop: true,
          connected: false,
          intentionalDisconnect: false,
          msSincePauseTripped: null),
      isFalse,
    );
  });

  test('only while paused', () {
    // Not paused (the normal healthy path) never probes.
    expect(
      WhoopBleClient.shouldSalvageProbe(
          pausedForBondLoop: false,
          connected: false,
          intentionalDisconnect: false,
          msSincePauseTripped: floor),
      isFalse,
    );
  });

  test('suppressed when connected or user tore down', () {
    expect(
      WhoopBleClient.shouldSalvageProbe(
          pausedForBondLoop: true,
          connected: true,
          intentionalDisconnect: false,
          msSincePauseTripped: floor),
      isFalse,
    );
    expect(
      WhoopBleClient.shouldSalvageProbe(
          pausedForBondLoop: true,
          connected: false,
          intentionalDisconnect: true,
          msSincePauseTripped: floor),
      isFalse,
    );
  });
}
