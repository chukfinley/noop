import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/baselines.dart';

/// Boundary tests for `Baselines.deviceEraEpoch` (upstream #459 / #470): the recalibration epoch at
/// the latest device-era boundary in a source-tagged nightly history, so a baseline never mixes two
/// brands' incompatible HRV scales (Oura RMSSD ~120–155 ms vs WHOOP ~72–112 ms across a switch).
///
/// Mirrors the upstream Kotlin `DeviceEraEpochTest` / Swift `DeviceEraEpochTests` case-for-case so
/// all three platforms compute the SAME epoch for the same history. The primitive is dormant here
/// (no consumer wired — see the doc header on `deviceEraEpoch`), so these tests ARE the contract.
void main() {
  int epochOfDayUtc(String day) =>
      DateTime.parse('${day}T00:00:00Z').millisecondsSinceEpoch ~/ 1000;

  String d(String month, int day) => '2026-$month-${day.toString().padLeft(2, '0')}';

  group('single brand → no epoch', () {
    test('empty history is zero', () {
      expect(Baselines.deviceEraEpoch(const []), 0);
    });

    test('one WHOOP brand across many ids is zero', () {
      const days = [
        SourceDay('2026-01-01', 'my-whoop'),
        SourceDay('2026-01-02', 'my-whoop-noop'),
        SourceDay('2026-01-03', 'whoop-EA:DC:0C:67:20:04'),
        SourceDay('2026-01-04', 'my-whoop'),
      ];
      expect(Baselines.deviceEraEpoch(days), 0);
    });

    test('one wearable brand only is zero', () {
      final days = [for (var i = 1; i <= 28; i++) SourceDay(d('01', i), 'oura-import')];
      expect(Baselines.deviceEraEpoch(days), 0);
    });

    test('a strap-to-strap swap opens NO era (WHOOP 4 and 5 share a scale)', () {
      // The deliberate non-goal: brand bucketing is coarse, so swapping straps must not re-seed the
      // baseline. Only a genuine brand change does.
      const days = [
        SourceDay('2026-01-01', 'whoop-AA:AA:AA:AA:AA:AA'),
        SourceDay('2026-01-02', 'whoop-AA:AA:AA:AA:AA:AA'),
        SourceDay('2026-01-03', 'whoop-BB:BB:BB:BB:BB:BB'),
        SourceDay('2026-01-04', 'whoop-BB:BB:BB:BB:BB:BB'),
      ];
      expect(Baselines.deviceEraEpoch(days), 0);
    });
  });

  group('the reported case', () {
    test('oura then whoop returns the first WHOOP day', () {
      final days = [
        for (var i = 1; i <= 15; i++) SourceDay(d('01', i), 'oura-import'),
        for (var i = 16; i <= 31; i++) SourceDay(d('01', i), 'my-whoop'),
      ];
      expect(Baselines.deviceEraEpoch(days), epochOfDayUtc('2026-01-16'));
    });

    test('unsorted input is sorted internally', () {
      const days = [
        SourceDay('2026-01-16', 'my-whoop'),
        SourceDay('2026-01-02', 'oura-import'),
        SourceDay('2026-01-31', 'my-whoop'),
        SourceDay('2026-01-01', 'oura-import'),
        SourceDay('2026-01-20', 'my-whoop'),
      ];
      expect(Baselines.deviceEraEpoch(days), epochOfDayUtc('2026-01-16'));
    });

    test('whoop then oura returns the first Oura day', () {
      final days = [
        for (var i = 1; i <= 10; i++) SourceDay(d('02', i), 'my-whoop'),
        for (var i = 11; i <= 20; i++) SourceDay(d('02', i), 'oura-import'),
      ];
      expect(Baselines.deviceEraEpoch(days), epochOfDayUtc('2026-02-11'));
    });

    test('only the latest boundary matters', () {
      final days = [
        for (var i = 1; i <= 5; i++) SourceDay(d('03', i), 'oura-import'),
        for (var i = 6; i <= 10; i++) SourceDay(d('03', i), 'my-whoop'),
        for (var i = 11; i <= 15; i++) SourceDay(d('03', i), 'oura-import'),
      ];
      expect(Baselines.deviceEraEpoch(days), epochOfDayUtc('2026-03-11'));
    });

    test('fitbit and garmin are distinct brands', () {
      final days = [
        for (var i = 1; i <= 5; i++) SourceDay(d('04', i), 'garmin-import'),
        for (var i = 6; i <= 10; i++) SourceDay(d('04', i), 'fitbit-import'),
      ];
      expect(Baselines.deviceEraEpoch(days), epochOfDayUtc('2026-04-06'));
    });

    test('a lone off-brand day inside the current era truncates it (fail-safe)', () {
      // Dropping MORE history is always safe; mixing scales is not.
      const days = [
        SourceDay('2026-07-01', 'my-whoop'),
        SourceDay('2026-07-02', 'my-whoop'),
        SourceDay('2026-07-03', 'oura-import'), // stray import day
        SourceDay('2026-07-04', 'my-whoop'),
        SourceDay('2026-07-05', 'my-whoop'),
      ];
      expect(Baselines.deviceEraEpoch(days), epochOfDayUtc('2026-07-04'));
    });

    test('same-day mixed brand breaks the tie deterministically', () {
      // An overlap night carrying BOTH an Oura and a WHOOP row: the (day, sourceId) total order must
      // resolve the tie identically to the Kotlin/Swift twins so the epoch never diverges by platform.
      // 'my-whoop' < 'oura-import', so on 2026-06-03 the LAST row is oura-import; the current-brand
      // (whoop) suffix walk breaks there and the era opens at 2026-06-04.
      const days = [
        SourceDay('2026-06-01', 'oura-import'),
        SourceDay('2026-06-02', 'oura-import'),
        SourceDay('2026-06-03', 'my-whoop'), // overlap day: both brands present
        SourceDay('2026-06-03', 'oura-import'),
        SourceDay('2026-06-04', 'my-whoop'),
      ];
      expect(Baselines.deviceEraEpoch(days), epochOfDayUtc('2026-06-04'));
    });
  });

  group('brand bucketing', () {
    test('collapses WHOOP ids and separates wearables', () {
      expect(Baselines.brandBucket('my-whoop'), 'whoop');
      expect(Baselines.brandBucket('my-whoop-noop'), 'whoop');
      expect(Baselines.brandBucket('whoop-AA:BB:CC:DD:EE:FF'), 'whoop');
      expect(Baselines.brandBucket('apple-health'), 'whoop');
      expect(Baselines.brandBucket('health-connect'), 'whoop');
      expect(Baselines.brandBucket(''), 'whoop');
      expect(Baselines.brandBucket('oura-import'), 'oura');
      expect(Baselines.brandBucket('oura-api'), 'oura'); // cloud id == export id brand
      expect(Baselines.brandBucket('fitbit-import'), 'fitbit');
      expect(Baselines.brandBucket('garmin-import'), 'garmin');
    });
  });

  group('day-key parsing is strict', () {
    test('a real key resolves to its UTC midnight', () {
      expect(Baselines.dayStartEpochUtc('2026-01-16'), 1768521600);
      expect(Baselines.dayStartEpochUtc('1970-01-01'), 0);
    });

    test('a malformed or rolled-over key is rejected, never normalised', () {
      // DateTime.tryParse would silently make 2026-13-45 into 2027-02-14; the twins' strict
      // formatters return null → 0, so we must too.
      expect(Baselines.dayStartEpochUtc('2026-13-45'), 0);
      expect(Baselines.dayStartEpochUtc('2026-02-30'), 0);
      expect(Baselines.dayStartEpochUtc('2026-1-6'), 0); // not fixed-width
      expect(Baselines.dayStartEpochUtc('bogus'), 0);
      expect(Baselines.dayStartEpochUtc(''), 0);
    });

    test('an unparseable era-start day yields no epoch rather than a bogus one', () {
      const days = [
        SourceDay('2026-01-01', 'oura-import'),
        SourceDay('not-a-day', 'my-whoop'),
      ];
      // 'not-a-day' sorts after '2026-01-01' lexically, so it is the newest → opens the whoop era,
      // but its key can't be parsed, so the epoch degrades to 0 (fold everything) rather than lying.
      expect(Baselines.deviceEraEpoch(days), 0);
    });
  });
}
