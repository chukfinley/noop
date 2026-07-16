import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/baselines.dart';
import 'package:noop/core/analytics/noop_engine.dart';
import 'package:noop/core/analytics/raw_samples.dart';
import 'package:noop/core/data/models.dart';

/// Recovery must never claim to be CALIBRATING at or above the seed gate.
///
/// Recovery is HRV-baseline-dominant and does not score without a usable baseline AND a night that
/// produced HRV + RHR. Those are two independent failures, and the app used to collapse them into
/// one: every unscored night was flagged "calibrating" with a count of
/// `min(4, nValid + (hrv != null ? 1 : 0))`. So a fully-calibrated wearer (nValid = 30) whose night
/// gave sparse RR — RMSSD needs >= 20 clean beats, so this is routine — read "CALIBRATING 4/4"
/// behind an empty gauge. The `min` was not a tidy-up; it MASKED a 30-vs-4 over-statement. Upstream's
/// helper guards the same way (n >= seed -> nil).
///
/// The honest states are three, and 2a2eb326's intent ("no fake 58") binds all of them: a real
/// score, seeding progress, or nothing to show.

/// One synthetic day: a ~160-min asleep block (strap sleep_state = 2) + a daytime wake block. The
/// night clears the stager's 2-hour minimum so it is scored as sleep.
///
/// [withRr] false keeps the identical HR track but strips the beat-to-beat RR intervals, which is
/// precisely the sparse-RR night: resting HR still resolves, RMSSD cannot, so recovery has no HRV.
RawDay _day(DateTime date, {bool withRr = true, double Function(int s)? rrOf}) {
  final samples = <RawSample>[];
  final midnight = DateTime(date.year, date.month, date.day);

  final nightStart = midnight.add(const Duration(minutes: 20));
  for (var s = 0; s < 160 * 60; s++) {
    final ts = nightStart.add(Duration(seconds: s)).millisecondsSinceEpoch ~/ 1000;
    final rr = (rrOf ?? (int i) => 1200 + 45 * math.sin(2 * math.pi * 0.25 * i))(s);
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

  /// [nights] full nights, then one final night whose RR is stripped.
  List<DayRecord> _runThenSparseNight(int nights) {
    final days = <RawDay>[
      for (var d = 0; d < nights; d++) _day(start.add(Duration(days: d))),
      _day(start.add(Duration(days: nights)), withRr: false),
    ];
    return const NoopEngine()
        .analyze(days, profile)
        .where((d) => d.sleep != null)
        .toList();
  }

  group('the three recovery states are distinct', () {
    test('a seeding baseline is "calibrating N/4" and NOT "no data"', () {
      final nights = _runThenSparseNight(6);
      for (var i = 0; i < baselineProvisionalMinNights; i++) {
        expect(nights[i].chargeCalibrating, isTrue, reason: 'night $i is still seeding');
        expect(nights[i].chargeCalibrationNights, i + 1);
        expect(nights[i].chargeNoData, isFalse,
            reason: 'seeding is progress, not an absence of data');
        expect(nights[i].chargeScored, isFalse);
      }
    });

    test('once the baseline is seeded, recovery is a real score', () {
      final nights = _runThenSparseNight(6);
      final n = nights[baselineProvisionalMinNights];
      expect(n.chargeScored, isTrue);
      expect(n.chargeCalibrating, isFalse);
      expect(n.chargeCalibrationNights, isNull);
      expect(n.chargeNoData, isFalse);
      expect(n.charge, inInclusiveRange(0, 100));
    });

    test('a CALIBRATED wearer with a sparse-RR night gets no-data, never "Calibrating 4/4"', () {
      // The reported defect. The baseline seeded days ago and is untouched; only tonight is blank.
      final nights = _runThenSparseNight(6);
      final sparse = nights.last;

      expect(sparse.chargeCalibrating, isFalse,
          reason: 'nothing is calibrating — the baseline has been ready for nights');
      expect(sparse.chargeCalibrationNights, isNull,
          reason: 'the old code reported 4 here, and the UI read "CALIBRATING 4/4"');
      expect(sparse.chargeNoData, isTrue);
      expect(sparse.chargeScored, isFalse, reason: 'charge is a filler mean — never render it');
    });

    test('the sparse night is blank on recovery ONLY — the real metrics survive', () {
      // The no-data state is scoped to recovery. Resting HR and sleep come from the same night's HR
      // track and must still be real, exactly as the calibrating state already promises.
      final sparse = _runThenSparseNight(6).last;
      expect(sparse.hrv, 0, reason: 'no RR intervals -> no RMSSD, and none is invented');
      expect(sparse.rhr, greaterThan(0));
      expect(sparse.sleep, isNotNull);
      expect(sparse.rest, greaterThan(0));
    });
  });

  group('the reported count can never over-state the baseline', () {
    test('N is the authoritative post-fold nValid, never a prediction of a refused fold', () {
      // The old count added 1 for "tonight produced a number", PREDICTING a fold that the baseline's
      // bounds gate (HRV must be 5..250 ms) may refuse. A night can absolutely produce a clean,
      // in-range RMSSD that the gate still rejects — this RR track alternates 1900/1300 ms, which
      // survives BOTH the 300..2000 ms range filter and the 20% Malik ectopic filter, yet lands an
      // RMSSD near 600 ms. The baseline banks nothing; the old UI still counted the night.
      final days = <RawDay>[_day(start, rrOf: (s) => s.isEven ? 1900 : 1300)];
      final out = const NoopEngine().analyze(days, profile).where((d) => d.sleep != null).toList();
      expect(out, isNotEmpty);

      // Precondition — without this the test would pass vacuously via the hrv == null path.
      final hrv = out.first.hrv;
      expect(hrv, greaterThan(Baselines.configs['hrv']!.maxVal),
          reason: 'the night must yield a REAL RMSSD that the fold then refuses');

      // Replay the fold the pipeline performed, to recover the authoritative count.
      final oracle = BaselineState();
      Baselines.update(oracle, 'hrv', hrv);
      expect(oracle.nValid, 0, reason: 'the fold refused it — nothing was banked');

      expect(out.first.chargeCalibrationNights, 0,
          reason: 'the old code predicted 1 here, claiming a night the baseline never took');
      expect(out.first.chargeCalibrationNights, oracle.nValid,
          reason: 'N must equal the real post-fold nValid, never nValid + 1');
    });

    test('N never reaches the seed gate without the baseline reaching it too', () {
      // The invariant the removed `math.min` was hiding: "calibrating" and "N >= seed" are mutually
      // exclusive by construction, so no clamp is needed and none may be re-introduced.
      for (final nights in [1, 2, 3, 4, 5, 6, 7]) {
        for (final rec in _runThenSparseNight(nights)) {
          final n = rec.chargeCalibrationNights;
          if (n == null) continue;
          expect(n, lessThanOrEqualTo(baselineProvisionalMinNights),
              reason: 'a count above the gate is nonsense, not something to clamp away');
          expect(rec.chargeNoData, isFalse, reason: 'the two unscored reasons are exclusive');
        }
      }
    });

    test('exactly one of the three states holds, on every day of every run', () {
      for (final nights in [1, 3, 6]) {
        for (final rec in _runThenSparseNight(nights)) {
          final states = [rec.chargeCalibrating, rec.chargeNoData, rec.chargeScored]
              .where((x) => x)
              .length;
          expect(states, 1, reason: 'the states must partition, never overlap or leave a gap');
        }
      }
    });
  });
}
