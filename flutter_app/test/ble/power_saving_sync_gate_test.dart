import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/background/background_sync_worker.dart';
import 'package:noop/core/ble/sync/power_saving_policy.dart';

/// Unit-pins the WIRING half of the power-saving sync stretch — the pure
/// [powerSavingShouldSkipTick] predicate that turns the policy's `syncIntervalMs` into a
/// keep/skip decision for one headless WorkManager tick. (The policy's own decision table is
/// pinned by `test/ble/sync/power_saving_policy_test.dart`; this covers what the worker does
/// with it.)
///
/// The stretch is implemented as a tick GATE, not a re-registered WorkManager frequency: the
/// job keeps one stable 15-min tick (Android's periodic minimum, which IS the normal cadence)
/// and this drops 2 of every 3 while engaged. The cases below therefore care most about the
/// fail-open edges — every ambiguity must SYNC, because the lever's whole contract is that it
/// delays data without ever losing any.
///
/// No DB, no radio, no real clock — project rule: never launch the app.
void main() {
  // A fixed "now"; last-sync stamps are expressed relative to it.
  const nowMs = 1800000000000;
  const min = 60 * 1000;

  const normalMs = PowerSavingPolicy.normalSyncIntervalMs; // 15 min
  const lowMs = PowerSavingPolicy.lowBatterySyncIntervalMs; // 45 min

  /// Armed at the default 20% threshold.
  const armed = PowerSavingPolicy(enabled: true, thresholdPct: 20);
  const off = PowerSavingPolicy();

  bool skip({
    PowerSavingPolicy policy = armed,
    double? battery = 0.10,
    bool? charging = false,
    int? lastSyncAtMs = nowMs - 5 * min,
  }) =>
      powerSavingShouldSkipTick(
        policy: policy,
        batteryFraction: battery,
        charging: charging,
        lastSyncAtMs: lastSyncAtMs,
        nowMs: nowMs,
      );

  group('the constants this gate is built on', () {
    test('the normal cadence IS the WorkManager tick period, so an un-engaged gate is inert', () {
      expect(normalMs, 15 * min);
      expect(lowMs, 45 * min);
      expect(lowMs ~/ normalMs, 3, reason: 'engaged = skip 2 of every 3 ticks');
    });
  });

  group('not engaged → never gate (today\'s behaviour, byte-for-byte)', () {
    test('power saving OFF → never skips, however low the strap is', () {
      expect(skip(policy: off, battery: 0.01, lastSyncAtMs: nowMs), isFalse);
    });

    test('strap battery ABOVE the threshold → never skips', () {
      expect(skip(battery: 0.50, lastSyncAtMs: nowMs), isFalse);
    });

    test('strap CHARGING → never skips (a charging strap has nothing to conserve)', () {
      expect(skip(battery: 0.05, charging: true, lastSyncAtMs: nowMs), isFalse);
    });

    test('strap battery UNKNOWN → never skips (fails safe — never throttle on a reading we lack)',
        () {
      expect(skip(battery: null, lastSyncAtMs: nowMs), isFalse);
    });

    test('a tick a few seconds early can never accidentally halve an un-engaged cadence', () {
      // The gate is not in play at all when the interval is the normal one, so the tick's own
      // jitter cannot turn a 15-min cadence into an accidental 30.
      expect(skip(policy: off, lastSyncAtMs: nowMs - (15 * min - 3000)), isFalse);
      expect(skip(battery: 0.90, lastSyncAtMs: nowMs - (15 * min - 3000)), isFalse);
    });
  });

  group('engaged → stretch 15 min to 45', () {
    test('5 min since the last sync → SKIP', () {
      expect(skip(lastSyncAtMs: nowMs - 5 * min), isTrue);
    });

    test('the 15-min tick → SKIP (1 of 3)', () {
      expect(skip(lastSyncAtMs: nowMs - 15 * min), isTrue);
    });

    test('the 30-min tick → SKIP (2 of 3)', () {
      expect(skip(lastSyncAtMs: nowMs - 30 * min), isTrue);
    });

    test('the 45-min tick → SYNC (the stretched interval has elapsed)', () {
      expect(skip(lastSyncAtMs: nowMs - 45 * min), isFalse);
    });

    test('1 ms under 45 min → still SKIP; exactly 45 min → SYNC', () {
      expect(skip(lastSyncAtMs: nowMs - lowMs + 1), isTrue);
      expect(skip(lastSyncAtMs: nowMs - lowMs), isFalse);
    });

    test('long past the stretched interval → SYNC', () {
      expect(skip(lastSyncAtMs: nowMs - 6 * 60 * min), isFalse);
    });

    test('exactly AT the threshold engages (<=, not <)', () {
      expect(skip(battery: 0.20, lastSyncAtMs: nowMs - 5 * min), isTrue);
    });

    test('charging UNKNOWN is treated as discharging → engages', () {
      // The standard 0x2A19 battery profile carries no charging bit, so a WHOOP 4 reports a
      // fraction with a null flag; treating null as "charging" would silently disable the
      // whole feature on that strap.
      expect(skip(charging: null, lastSyncAtMs: nowMs - 5 * min), isTrue);
    });
  });

  group('fail-open edges — every ambiguity syncs', () {
    test('never synced (null stamp) → never hold back the FIRST sync', () {
      expect(skip(lastSyncAtMs: null), isFalse);
    });

    test('a FUTURE last-sync stamp (clock skew / DST) → cannot prove → SYNC', () {
      expect(skip(lastSyncAtMs: nowMs + 60 * min), isFalse);
    });

    test('a last-sync stamp exactly now but engaged → skip (the only non-ambiguous hold)', () {
      expect(skip(lastSyncAtMs: nowMs), isTrue);
    });

    test('a stale-but-real snapshot still gates — failed offloads never advance lastSyncAt', () {
      // lastSyncAt only moves on a COMPLETED offload, so a run of failures leaves it old →
      // elapsed grows → the gate opens. The lever can never wedge sync off permanently.
      expect(skip(lastSyncAtMs: nowMs - 3 * 60 * min), isFalse);
    });
  });

  group('the threshold picker range is enforced through the policy clamp', () {
    test('a corrupt/legacy stored threshold above the picker cannot widen the lever', () {
      // 90 clamps to the policy's 30% max, so a strap at 50% is still above it.
      const corrupt = PowerSavingPolicy(enabled: true, thresholdPct: 90);
      expect(corrupt.effectiveThresholdPct, PowerSavingPolicy.maxThresholdPct);
      expect(skip(policy: corrupt, battery: 0.50, lastSyncAtMs: nowMs), isFalse);
      expect(skip(policy: corrupt, battery: 0.30, lastSyncAtMs: nowMs), isTrue);
    });

    test('a threshold below the picker floor clamps up to 10%', () {
      const corrupt = PowerSavingPolicy(enabled: true, thresholdPct: 0);
      expect(corrupt.effectiveThresholdPct, PowerSavingPolicy.minThresholdPct);
      // Still ARMED (enabled is the master switch, not the threshold value) at <= 10%.
      expect(skip(policy: corrupt, battery: 0.10, lastSyncAtMs: nowMs), isTrue);
      expect(skip(policy: corrupt, battery: 0.15, lastSyncAtMs: nowMs), isFalse);
    });

    test('every picker position the Settings UI offers behaves', () {
      for (final pct in [10, 15, 20, 25, 30]) {
        final p = PowerSavingPolicy(enabled: true, thresholdPct: pct);
        expect(p.effectiveThresholdPct, pct, reason: '$pct% must survive the clamp untouched');
        expect(skip(policy: p, battery: pct / 100, lastSyncAtMs: nowMs), isTrue,
            reason: 'at $pct% the lever engages');
        expect(skip(policy: p, battery: (pct + 1) / 100, lastSyncAtMs: nowMs), isFalse,
            reason: 'just above $pct% it does not');
      }
    });
  });
}
