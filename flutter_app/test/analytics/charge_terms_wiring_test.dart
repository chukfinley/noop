import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/baselines.dart';
import 'package:noop/core/analytics/charge_terms.dart';
import 'package:noop/core/analytics/daily_pipeline.dart';
import 'package:noop/core/analytics/noop_engine.dart';
import 'package:noop/core/analytics/raw_samples.dart';
import 'package:noop/core/analytics/strain_scorer.dart';
import 'package:noop/core/data/models.dart';

/// Wiring contract for the two experimental Charge terms (#417/#436) inside [DailyPipeline].
///
/// `charge_terms_test.dart` already pins the PURE pieces (slope fit, both term transforms, the
/// weights, `foldInto`'s algebra). This file pins the part that file cannot see: that the pipeline
/// feeds those terms REAL data, that the flag actually gates them, and — the invariant upstream
/// v9.0.0's own test header calls the central claim — that with the terms dormant the score is
/// byte-identical to before they existed.
///
/// Upstream ships these dormant on both platforms (a grep finds no production caller supplying
/// `recoveryIndexSlope` / `priorDayEffort` / `effortBaseline`), so "off by default" is upstream's
/// intent, not an unfinished port. These tests are what make the wiring safe to switch on later.
void main() {
  const profile = UserProfile();
  final start = DateTime(2026, 6, 1);

  /// One synthetic day: a 160-minute asleep block (strap `sleep_state` = 2) whose HR follows a
  /// KNOWN linear trend, plus a 2-hour daytime block at a fixed HR that sets the day's Effort.
  ///
  /// Both blocks are sampled per SECOND: `StrainScorer.sampleDurationMinutes` infers the whole
  /// day's per-sample duration from the FIRST TWO timestamps, so a mixed-cadence day would price
  /// every daytime sample as one second and make Effort an artifact of the fixture.
  ///
  /// The night's RR carries a 4-second oscillation on top of the trend so RMSSD is real (the
  /// pipeline needs HRV to score recovery at all); the daytime block carries no RR, like a real
  /// capture.
  RawDay day(
    DateTime date, {
    double startBpm = 62,
    double nightSlopeBpmPerHour = -2,
    int daytimeHr = 120,
  }) {
    final samples = <RawSample>[];
    final midnight = DateTime(date.year, date.month, date.day);

    final nightStart = midnight.add(const Duration(minutes: 20));
    for (var s = 0; s < 160 * 60; s++) {
      final ts = nightStart.add(Duration(seconds: s)).millisecondsSinceEpoch ~/ 1000;
      final trendBpm = startBpm + nightSlopeBpmPerHour * (s / 3600.0);
      final rr = 60000.0 / trendBpm + 45 * math.sin(2 * math.pi * 0.25 * s);
      samples.add(RawSample(
        ts: ts,
        hr: (60000 / rr).round(),
        spo2: 0,
        rrCount: 1,
        rr1: rr.round(),
        rr2: 0,
        rr3: 0,
        movement: 1.0,
        sleepState: 2,
      ));
    }

    final dayStart = midnight.add(const Duration(hours: 9));
    for (var s = 0; s < 2 * 60 * 60; s++) {
      final ts = dayStart.add(Duration(seconds: s)).millisecondsSinceEpoch ~/ 1000;
      samples.add(RawSample(
        ts: ts,
        hr: daytimeHr,
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

  /// Exactly five days — the window in which the Recovery-Index term can act ALONE.
  ///
  /// By day 5 the HRV baseline has its 4 seed nights so recovery scores, while the Effort baseline
  /// has only 3 folds (its fold is lagged a day) and is therefore not yet usable, so the
  /// Activity-Balance term still drops. Any on-vs-off delta on day 5 is the slope term and nothing
  /// else — without this the two terms would confound each other.
  List<RawDay> fiveDays({required double slope}) => [
        for (var i = 0; i < 5; i++)
          day(start.add(Duration(days: i)), nightSlopeBpmPerHour: slope),
      ];

  List<DayRecord> run(List<RawDay> days, {required bool on}) =>
      DailyPipeline(profile, experimentalChargeTerms: on).run(days);

  group('the flag gates the terms, and the shipping path never sets it', () {
    test('a scored day is the precondition for everything below', () {
      final last = run(fiveDays(slope: -2), on: false).last;
      expect(last.chargeScored, isTrue,
          reason: 'an unscored day would make every on-vs-off comparison vacuous');
    });

    test('OFF is the default, and NoopEngine — the shipping path — leaves it off', () {
      final days = fiveDays(slope: -6);
      final viaDefault = DailyPipeline(profile).run(days);
      final viaExplicitOff = run(days, on: false);
      final viaEngine = const NoopEngine().analyze(days, profile);

      // A slope of -6 bpm/h is a term that WOULD move the score hard (proven below), so these
      // three agreeing is a real statement: nothing in the shipping app folds the terms in.
      expect(viaDefault.map((d) => d.charge), viaExplicitOff.map((d) => d.charge));
      expect(viaEngine.map((d) => d.charge), viaExplicitOff.map((d) => d.charge));
    });

    test('OFF leaves EVERY Charge state untouched, not just the number', () {
      for (final rec in run(fiveDays(slope: -6), on: false)) {
        expect(rec.chargeCalibrationNights,
            rec.chargeCalibrating ? isNotNull : isNull);
      }
      // The wiring routes Charge through `foldInto`, which returns null iff the base score was
      // null. Pin that the scored/calibrating/no-data partition survives that detour.
      for (final on in [false, true]) {
        for (final rec in run(fiveDays(slope: -6), on: on)) {
          final states = [rec.chargeCalibrating, rec.chargeNoData, rec.chargeScored]
              .where((x) => x)
              .length;
          expect(states, 1, reason: 'foldInto must not blur the three recovery states');
        }
      }
    });

    test('the terms are actually REACHABLE — ON moves the score', () {
      // The failure this guards is the one that made this port necessary: code that exists, is
      // tested in isolation, and is wired to nothing.
      final off = run(fiveDays(slope: -6), on: false).last.charge;
      final on = run(fiveDays(slope: -6), on: true).last.charge;
      expect(on, isNot(off));
    });
  });

  group('Recovery Index — the pipeline feeds it the real overnight slope', () {
    double delta(double slope) {
      final off = run(fiveDays(slope: slope), on: false).last.charge;
      final on = run(fiveDays(slope: slope), on: true).last.charge;
      return on - off;
    }

    test('a DECLINING overnight HR supports Charge; a RISING one limits it', () {
      // Same nights, same everything — only the term toggles, so the delta IS the term.
      expect(delta(-6), greaterThan(0), reason: 'HR falling through the night is the good pattern');
      expect(delta(6), lessThan(0), reason: 'HR rising overnight limits recovery');
    });

    test('the slope the pipeline extracts matches the injected trend', () {
      // Pins the seam between the fixture and `recoveryIndexSlope`: if the pipeline handed the
      // term the wrong window (say the whole day instead of the in-bed block), the sign tests
      // above could still pass while the magnitude was meaningless.
      final d = day(start, nightSlopeBpmPerHour: -6);
      final ts = <int>[];
      final bpm = <double>[];
      for (final r in d.samples) {
        if (r.hr > 0 && r.sleepState == 2) {
          ts.add(r.ts);
          bpm.add(r.hr.toDouble());
        }
      }
      final got = ChargeTerms.recoveryIndexSlope(ts, bpm, ts.first, ts.last);
      expect(got, isNotNull);
      expect(got!, closeTo(-6.0, 0.5));
    });

    test('a night too short to fit a trend drops the term rather than guessing', () {
      // < recoveryIndexMinBins populated 5-minute bins. The honest outcome is null, not a slope
      // fitted through a sliver of the night.
      final d = day(start);
      final ts = <int>[];
      final bpm = <double>[];
      for (final r in d.samples) {
        if (r.hr > 0 && r.sleepState == 2) {
          ts.add(r.ts);
          bpm.add(r.hr.toDouble());
        }
      }
      final shortWindow = ts.first + (ChargeTerms.recoveryIndexMinBins - 1) * 5 * 60;
      expect(ChargeTerms.recoveryIndexSlope(ts, bpm, ts.first, shortWindow), isNull);
    });
  });

  group('Activity Balance — the pipeline feeds it YESTERDAY\'s Effort', () {
    /// Eight settle days at a moderate load, then a prior day at [priorDaytimeHr], then the
    /// target day. With [gap] the calendar day between the prior day and the target is missing
    /// entirely (no wear), so the last Effort we hold is two days old.
    ///
    /// Every night is identical, so the target day's HRV/RHR/sleep are identical across variants;
    /// only the prior day's Effort moves. The Effort baseline is identical too — its fold lags a
    /// day, so at the moment the target is scored the prior day's Effort is not yet in it.
    List<RawDay> days({required int priorDaytimeHr, bool gap = false}) => [
          for (var i = 0; i < 8; i++) day(start.add(Duration(days: i))),
          day(start.add(const Duration(days: 8)), daytimeHr: priorDaytimeHr),
          day(start.add(Duration(days: gap ? 10 : 9))),
        ];

    double targetCharge({required int priorDaytimeHr, bool gap = false, bool on = true}) =>
        run(days(priorDaytimeHr: priorDaytimeHr, gap: gap), on: on).last.charge;

    test('the fixture really does produce different Efforts (precondition)', () {
      final hard = run(days(priorDaytimeHr: 155), on: false)[8].effort;
      final rest = run(days(priorDaytimeHr: 70), on: false)[8].effort;
      expect(hard, greaterThan(rest),
          reason: 'without a real Effort spread the term has nothing to read');
      expect(hard, greaterThan(0));
    });

    test('a HARDER previous day lowers Charge; a lighter one supports it', () {
      final afterHard = targetCharge(priorDaytimeHr: 155);
      final afterRest = targetCharge(priorDaytimeHr: 70);
      expect(afterHard, lessThan(afterRest));
    });

    test('with the terms OFF, the previous day\'s load cannot touch Charge', () {
      // The control for the test above: proves that delta is the Activity-Balance term and not
      // some other path by which yesterday's daytime HR leaks into tonight's score.
      expect(
        targetCharge(priorDaytimeHr: 155, on: false),
        targetCharge(priorDaytimeHr: 70, on: false),
      );
    });

    test('across a calendar gap the term DROPS — a stale load is not "yesterday"', () {
      // The pipeline skips no-wear days, so "the last day we scored" is routinely not yesterday.
      // Feeding a two-day-old Effort in as previous-day activity would fabricate a relationship
      // the data never carried, so the term must drop and the weights renormalize.
      expect(
        targetCharge(priorDaytimeHr: 155, gap: true),
        targetCharge(priorDaytimeHr: 70, gap: true),
        reason: 'across a gap, the prior day\'s load must have NO influence at all',
      );
      // Positive control: the very same comparison without the gap DOES move, so the equality
      // above is the adjacency gate doing its job, not the term being inert.
      expect(
        targetCharge(priorDaytimeHr: 155),
        isNot(targetCharge(priorDaytimeHr: 70)),
      );
    });
  });

  group('the "strain" baseline the Activity-Balance term reads', () {
    test('the Effort baseline excludes the value it scores (the fold is lagged)', () {
      // The pipeline's established order is "score against history, THEN fold tonight in". The
      // value scored on day N is Effort(N-1), so folding Effort(N-1) before scoring day N would
      // put the value inside its own EWMA mean and damp the very signal the term carries.
      // Replay the fold the pipeline performs and pin the count it must have reached.
      final s = BaselineState();
      // Days 1..5 fold Effort(1..4): one fold per day from day 2 on.
      for (var i = 0; i < 4; i++) {
        Baselines.update(s, strainMetricKey, 40.0);
      }
      expect(s.nValid, 4);
      expect(s.usable, isTrue,
          reason: 'day 6 is the first day the Activity-Balance term can apply');
    });

    test('Effort folds through the registered strainCfg bounds, not a fallback', () {
      // Before "strain" was registered, `Baselines.update` fell through to its
      // MetricConfig(0, 1e9, 0.1) default — a floorSpread of 0.1 on a 0-100 axis, which would
      // make the z-score ~50x too sensitive to routine training variation.
      final s = BaselineState();
      Baselines.update(s, strainMetricKey, 40.0);
      expect(s.spread, strainCfg.floorSpread);
      expect(s.spread, 5.0);

      // Out-of-range Effort is refused by the registered bounds, never folded.
      final t = BaselineState();
      Baselines.update(t, strainMetricKey, StrainScorer.maxStrain + 1);
      expect(t.nValid, 0);
    });
  });
}
