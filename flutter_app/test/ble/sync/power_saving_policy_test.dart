import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/sync/power_saving_policy.dart';

/// Pins the battery-adaptive BLE policy (ryanbr/noop #478 / #482, closing #477). Keyed on the STRAP's
/// battery, off by default, never while charging: when the strap is low AND discharging, stretch the
/// background history sync 15 → 45 min and (as a sub-option) release the always-on continuous-HRV
/// stream. Pure value type → no BLE seam needed.
void main() {
  // A policy armed at the default 20% threshold, sync-stretch only.
  const armed = PowerSavingPolicy(enabled: true, thresholdPct: 20);
  // The same, with the continuous-HRV sub-option on.
  const armedWithHrv =
      PowerSavingPolicy(enabled: true, thresholdPct: 20, releaseContinuousHrv: true);

  group('off by default', () {
    test('a default policy is dormant', () {
      const p = PowerSavingPolicy();
      expect(p.enabled, isFalse);
      expect(p.releaseContinuousHrv, isFalse);
      expect(p.thresholdPct, PowerSavingPolicy.defaultThresholdPct);
    });

    test('a dormant policy never engages, even on a nearly-dead discharging strap', () {
      const p = PowerSavingPolicy();
      expect(p.engaged(batteryFraction: 0.01, charging: false), isFalse);
      // Byte-for-byte today's behaviour: normal cadence, stream untouched.
      expect(p.syncIntervalMs(batteryFraction: 0.01, charging: false),
          PowerSavingPolicy.normalSyncIntervalMs);
      expect(p.dropContinuousHrv(batteryFraction: 0.01, charging: false), isFalse);
    });

    test('the HRV sub-option alone does nothing while the master arm is off', () {
      const p = PowerSavingPolicy(releaseContinuousHrv: true); // enabled still false
      expect(p.dropContinuousHrv(batteryFraction: 0.05, charging: false), isFalse);
      expect(p.syncIntervalMs(batteryFraction: 0.05, charging: false),
          PowerSavingPolicy.normalSyncIntervalMs);
    });
  });

  group('never while charging', () {
    test('a low strap on the charger never engages', () {
      expect(armed.engaged(batteryFraction: 0.05, charging: true), isFalse);
      expect(armed.syncIntervalMs(batteryFraction: 0.05, charging: true),
          PowerSavingPolicy.normalSyncIntervalMs);
      expect(armedWithHrv.dropContinuousHrv(batteryFraction: 0.05, charging: true), isFalse);
    });

    test('charging wins even at 0%', () {
      expect(armed.engaged(batteryFraction: 0.0, charging: true), isFalse);
    });

    test('unplugging a low strap engages it', () {
      expect(armed.engaged(batteryFraction: 0.10, charging: true), isFalse);
      expect(armed.engaged(batteryFraction: 0.10, charging: false), isTrue);
    });
  });

  group('threshold boundary', () {
    test('at the threshold engages (at/below, not strictly below)', () {
      expect(armed.engaged(batteryFraction: 0.20, charging: false), isTrue);
    });

    test('one point above the threshold does not engage', () {
      expect(armed.engaged(batteryFraction: 0.21, charging: false), isFalse);
    });

    test('below the threshold engages', () {
      expect(armed.engaged(batteryFraction: 0.19, charging: false), isTrue);
      expect(armed.engaged(batteryFraction: 0.02, charging: false), isTrue);
      expect(armed.engaged(batteryFraction: 0.0, charging: false), isTrue);
    });

    test('a full strap never engages', () {
      expect(armed.engaged(batteryFraction: 1.0, charging: false), isFalse);
    });

    test('the fraction is rounded to whole percent before comparing', () {
      // 0.204 → 20% → at the threshold → engaged; 0.205 → 21% → above → not.
      expect(armed.engaged(batteryFraction: 0.204, charging: false), isTrue);
      expect(armed.engaged(batteryFraction: 0.205, charging: false), isFalse);
    });

    test('a custom in-range threshold is honoured', () {
      const p = PowerSavingPolicy(enabled: true, thresholdPct: 10);
      expect(p.engaged(batteryFraction: 0.10, charging: false), isTrue);
      expect(p.engaged(batteryFraction: 0.11, charging: false), isFalse);
      // The default-threshold policy WOULD have engaged at 15% — the picker really moves the line.
      expect(p.engaged(batteryFraction: 0.15, charging: false), isFalse);
      expect(armed.engaged(batteryFraction: 0.15, charging: false), isTrue);
    });
  });

  group('threshold clamping', () {
    test('the picker range is 10–30 with a 20 default', () {
      expect(PowerSavingPolicy.minThresholdPct, 10);
      expect(PowerSavingPolicy.maxThresholdPct, 30);
      expect(PowerSavingPolicy.defaultThresholdPct, 20);
    });

    test('a below-range threshold clamps up to the minimum', () {
      // A corrupt/legacy stored pref must never narrow the lever below the picker's range.
      const p = PowerSavingPolicy(enabled: true, thresholdPct: 0);
      expect(p.effectiveThresholdPct, PowerSavingPolicy.minThresholdPct);
      expect(p.engaged(batteryFraction: 0.10, charging: false), isTrue);
      expect(p.engaged(batteryFraction: 0.11, charging: false), isFalse);
    });

    test('a negative threshold clamps up to the minimum', () {
      const p = PowerSavingPolicy(enabled: true, thresholdPct: -5);
      expect(p.effectiveThresholdPct, PowerSavingPolicy.minThresholdPct);
    });

    test('an above-range threshold clamps down to the maximum', () {
      // ...and must never widen it beyond the picker's range either.
      const p = PowerSavingPolicy(enabled: true, thresholdPct: 90);
      expect(p.effectiveThresholdPct, PowerSavingPolicy.maxThresholdPct);
      expect(p.engaged(batteryFraction: 0.30, charging: false), isTrue);
      expect(p.engaged(batteryFraction: 0.31, charging: false), isFalse);
    });

    test('in-range thresholds pass through untouched', () {
      for (final t in [10, 15, 20, 25, 30]) {
        expect(PowerSavingPolicy(enabled: true, thresholdPct: t).effectiveThresholdPct, t);
      }
    });
  });

  group('unknown inputs fail safe', () {
    test('an unknown battery never engages', () {
      // Disconnected / not yet read: never throttle on a reading we do not have.
      expect(armed.engaged(batteryFraction: null, charging: false), isFalse);
      expect(armed.syncIntervalMs(batteryFraction: null, charging: false),
          PowerSavingPolicy.normalSyncIntervalMs);
      expect(armedWithHrv.dropContinuousHrv(batteryFraction: null, charging: false), isFalse);
    });

    test('an unknown battery never engages regardless of the charging flag', () {
      expect(armed.engaged(batteryFraction: null, charging: null), isFalse);
      expect(armed.engaged(batteryFraction: null, charging: true), isFalse);
    });

    test('a non-finite battery never engages', () {
      expect(armed.engaged(batteryFraction: double.nan, charging: false), isFalse);
      expect(armed.engaged(batteryFraction: double.infinity, charging: false), isFalse);
      expect(armed.engaged(batteryFraction: double.negativeInfinity, charging: false), isFalse);
    });

    test('an unknown charging flag counts as discharging', () {
      // Load-bearing: the standard 0x2A19 profile carries no charging bit, so a WHOOP 4 reports a
      // fraction with a null charging flag. Treating null as "charging" would silently disable the
      // whole feature on that strap. Both levers are benign, so engaging here costs nothing.
      expect(armed.engaged(batteryFraction: 0.10, charging: null), isTrue);
      expect(armed.syncIntervalMs(batteryFraction: 0.10, charging: null),
          PowerSavingPolicy.lowBatterySyncIntervalMs);
    });

    test('an unknown charging flag still respects the threshold', () {
      expect(armed.engaged(batteryFraction: 0.50, charging: null), isFalse);
    });
  });

  group('sync interval', () {
    test('15 min normally, 45 min while engaged', () {
      expect(PowerSavingPolicy.normalSyncIntervalMs, 15 * 60 * 1000);
      expect(PowerSavingPolicy.lowBatterySyncIntervalMs, 45 * 60 * 1000);
    });

    test('a healthy discharging strap syncs at the normal cadence', () {
      expect(armed.syncIntervalMs(batteryFraction: 0.80, charging: false),
          PowerSavingPolicy.normalSyncIntervalMs);
    });

    test('a low discharging strap stretches to 45 min', () {
      expect(armed.syncIntervalMs(batteryFraction: 0.15, charging: false),
          PowerSavingPolicy.lowBatterySyncIntervalMs);
    });

    test('the stretch applies without the HRV sub-option', () {
      // The sync stretch is the always-on-when-engaged lever; the HRV release is opt-in on top.
      expect(armed.releaseContinuousHrv, isFalse);
      expect(armed.syncIntervalMs(batteryFraction: 0.15, charging: false),
          PowerSavingPolicy.lowBatterySyncIntervalMs);
    });
  });

  group('continuous-HRV release', () {
    test('requires the sub-option: engaged alone does not drop the stream', () {
      expect(armed.engaged(batteryFraction: 0.15, charging: false), isTrue);
      expect(armed.dropContinuousHrv(batteryFraction: 0.15, charging: false), isFalse);
    });

    test('drops the stream when engaged with the sub-option on', () {
      expect(armedWithHrv.dropContinuousHrv(batteryFraction: 0.15, charging: false), isTrue);
    });

    test('does not drop the stream on a healthy strap', () {
      expect(armedWithHrv.dropContinuousHrv(batteryFraction: 0.80, charging: false), isFalse);
    });

    test('re-arms once the strap goes back on the charger', () {
      // The client re-derives this per reconcile, so charging alone restores the stream.
      expect(armedWithHrv.dropContinuousHrv(batteryFraction: 0.15, charging: false), isTrue);
      expect(armedWithHrv.dropContinuousHrv(batteryFraction: 0.15, charging: true), isFalse);
    });

    test('the sub-option leaves the sync stretch intact', () {
      expect(armedWithHrv.syncIntervalMs(batteryFraction: 0.15, charging: false),
          PowerSavingPolicy.lowBatterySyncIntervalMs);
    });
  });

  group('copyWith', () {
    test('overrides one field and preserves the rest', () {
      const base = PowerSavingPolicy();
      final on = base.copyWith(enabled: true);
      expect(on.enabled, isTrue);
      expect(on.thresholdPct, PowerSavingPolicy.defaultThresholdPct);
      expect(on.releaseContinuousHrv, isFalse);

      final picked = on.copyWith(thresholdPct: 30, releaseContinuousHrv: true);
      expect(picked.enabled, isTrue);
      expect(picked.thresholdPct, 30);
      expect(picked.releaseContinuousHrv, isTrue);
    });

    test('an empty copyWith changes nothing', () {
      const base = PowerSavingPolicy(
          enabled: true, thresholdPct: 25, releaseContinuousHrv: true);
      final same = base.copyWith();
      expect(same.enabled, base.enabled);
      expect(same.thresholdPct, base.thresholdPct);
      expect(same.releaseContinuousHrv, base.releaseContinuousHrv);
    });

    test('disabling via copyWith fully disarms both levers', () {
      final off = armedWithHrv.copyWith(enabled: false);
      expect(off.syncIntervalMs(batteryFraction: 0.05, charging: false),
          PowerSavingPolicy.normalSyncIntervalMs);
      expect(off.dropContinuousHrv(batteryFraction: 0.05, charging: false), isFalse);
    });
  });
}
