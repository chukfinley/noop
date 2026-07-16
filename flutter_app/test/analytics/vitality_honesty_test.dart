import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/baselines.dart';
import 'package:noop/core/analytics/engines.dart' as engines;
import 'package:noop/core/analytics/noop_engine.dart';
import 'package:noop/core/analytics/raw_samples.dart';
import 'package:noop/core/data/models.dart';

/// Vitality ("Energy") is [DayRecord.charge] re-expressed, so it inherits charge's
/// contract exactly — including the part that bites: on a calibrating or no-data
/// night `charge` is the `recoveryPopulationMean` FILLER (58), kept only so the
/// numeric fields stay finite. `vitality: charge.clamp(0, 100).round()` therefore
/// hands the UI a 58 that is not a reading, and the Today screen rendered it as
/// "58%" behind a 58%-full energy bar with no gate — the same fake-58 defect
/// 2a2eb326 removed for Charge itself, still live for Vitality.
///
/// These pin the ENGINE half of the contract: the filler is identifiable from the
/// record alone, so `chargeScored` is a sufficient gate for any renderer. Setting
/// vitality to 0 would NOT be a fix — "0%" is a false reading where 58 was a fake
/// one — so the number stays and the gate carries the honesty.

/// One synthetic day: a ~160-min asleep block (strap sleep_state = 2) plus a
/// daytime wake block. [withRr] false strips the beat-to-beat intervals — the
/// sparse-RR night: resting HR still resolves, RMSSD cannot, so recovery has no
/// HRV to score and `charge` falls back to the filler.
RawDay _day(DateTime date, {bool withRr = true}) {
  final samples = <RawSample>[];
  final midnight = DateTime(date.year, date.month, date.day);

  final nightStart = midnight.add(const Duration(minutes: 20));
  for (var s = 0; s < 160 * 60; s++) {
    final ts = nightStart.add(Duration(seconds: s)).millisecondsSinceEpoch ~/ 1000;
    final rr = 1200 + 45 * math.sin(2 * math.pi * 0.25 * s);
    samples.add(RawSample(
      ts: ts,
      hr: (60000 / rr).round(),
      spo2: 0,
      rrCount: withRr ? 1 : 0,
      rr1: withRr ? rr.round() : 0,
      rr2: 0,
      rr3: 0,
      movement: 1.0,
      sleepState: 2,
    ));
  }

  final dayStart = midnight.add(const Duration(hours: 8));
  for (var m = 0; m < 4 * 60; m++) {
    final ts = dayStart.add(Duration(minutes: m)).millisecondsSinceEpoch ~/ 1000;
    samples.add(RawSample(
      ts: ts,
      hr: 70 + (m % 7),
      spo2: 0,
      rrCount: 0,
      rr1: 0,
      rr2: 0,
      rr3: 0,
      movement: 1.05,
      sleepState: 0,
    ));
  }

  samples.sort((a, b) => a.ts.compareTo(b.ts));
  return RawDay(midnight, samples);
}

void main() {
  const profile = UserProfile();
  final start = DateTime(2026, 6, 1);

  List<DayRecord> runThenSparseNight(int nights) {
    final days = <RawDay>[
      for (var d = 0; d < nights; d++) _day(start.add(Duration(days: d))),
      _day(start.add(Duration(days: nights)), withRr: false),
    ];
    return const NoopEngine()
        .analyze(days, profile)
        .where((d) => d.sleep != null)
        .toList();
  }

  /// The filler Vitality would show if rendered ungated — the exact "fake 58".
  final fillerVitality = engines.recoveryPopulationMean.clamp(0, 100).round();

  group('vitality never presents the population-mean filler as a reading', () {
    test('the filler really is 58 — the number the UI used to render', () {
      // Pins the premise. If the population anchor ever moves, this test says so
      // rather than letting the defect reappear under a different number.
      expect(fillerVitality, 58);
    });

    test('a seeding night carries the filler and is NOT scored', () {
      final nights = runThenSparseNight(6);
      for (var i = 0; i < baselineProvisionalMinNights; i++) {
        final n = nights[i];
        expect(n.chargeScored, isFalse, reason: 'night $i is still seeding');
        expect(n.vitality, fillerVitality,
            reason: 'night $i carries the filler, so `chargeScored` is exactly '
                'the gate a renderer needs — vitality is not independently honest');
        expect(n.chargeCalibrating, isTrue,
            reason: 'a seeding night must read as calibration progress, not "no data"');
      }
    });

    test('a no-data night carries the filler and is NOT scored', () {
      final nights = runThenSparseNight(6);
      final n = nights.last; // baseline ready, but this night has no usable HRV
      expect(n.chargeNoData, isTrue);
      expect(n.chargeScored, isFalse);
      expect(n.vitality, fillerVitality,
          reason: 'the fake 58: a calibrated wearer whose night produced no HRV '
              'still gets the population mean in vitality');
    });

    test('a scored night carries a real vitality that tracks charge', () {
      final nights = runThenSparseNight(6);
      final n = nights[baselineProvisionalMinNights];
      expect(n.chargeScored, isTrue);
      expect(n.vitality, n.charge.clamp(0, 100).round(),
          reason: 'on a scored night vitality is charge re-expressed');
    });

    test('vitality is never 0 on an unscored night', () {
      // The wrong fix, pinned shut. Zeroing the field would render "0%" — a
      // FALSE reading traded for a fake one, and a worse one: 0% energy is a
      // claim about the wearer, while the gate says nothing at all.
      final nights = runThenSparseNight(6);
      for (final n in nights.where((d) => !d.chargeScored)) {
        expect(n.vitality, isNot(0),
            reason: 'an unscored night must stay gated, not be zeroed');
      }
    });
  });
}
