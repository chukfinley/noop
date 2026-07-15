import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/workout_type_classifier.dart';

/// Synthetic-fixture tests for the coarse [WorkoutTypeClassifier] (#414 / #439).
///
/// Per the repo's derived-signal validation rule, each class is exercised with MULTIPLE distinct
/// injected patterns rather than one lucky example, plus an ambiguous window that must NOT get a
/// confident specific label. Real-world validation against labeled workouts is an explicit,
/// separate follow-up — these fixtures only prove the heuristic recovers the shapes it was designed
/// around, and that the advisory contract holds.
void main() {
  /// Feature-vector builder (keeps test cases terse and readable).
  WorkoutClassFeatures features({
    double durationMin = 30.0,
    double meanHR = 120,
    int peakHR = 150,
    double? meanHRRPct,
    double hrCV = 0.05,
    double stillFraction = 0.0,
    double walkFraction = 0.0,
    double runFraction = 0.0,
    double tickCoverage = 0.0,
    double motionVariance = 0.0,
    double motionCV = 0.0,
    double? kcalPerMin,
  }) =>
      WorkoutClassFeatures(
        durationSec: durationMin * 60.0,
        meanHR: meanHR,
        peakHR: peakHR,
        meanHRRPct: meanHRRPct,
        hrCV: hrCV,
        stillFraction: stillFraction,
        walkFraction: walkFraction,
        runFraction: runFraction,
        tickCoverage: tickCoverage,
        motionVariance: motionVariance,
        motionCV: motionCV,
        kcalPerMin: kcalPerMin,
      );

  group('WorkoutTypeClassifier — ramp helpers', () {
    test('rampUp clamps and interpolates', () {
      expect(WorkoutTypeClassifier.rampUp(0, 10, 20), 0.0);
      expect(WorkoutTypeClassifier.rampUp(10, 10, 20), 0.0);
      expect(WorkoutTypeClassifier.rampUp(15, 10, 20), closeTo(0.5, 1e-9));
      expect(WorkoutTypeClassifier.rampUp(20, 10, 20), 1.0);
      expect(WorkoutTypeClassifier.rampUp(99, 10, 20), 1.0);
    });

    test('rampUp degenerates to a step when hi <= lo', () {
      expect(WorkoutTypeClassifier.rampUp(9, 20, 10), 0.0);
      expect(WorkoutTypeClassifier.rampUp(10, 20, 10), 1.0);
      expect(WorkoutTypeClassifier.rampUp(11, 20, 10), 1.0);
    });

    test('rampDown mirrors rampUp', () {
      expect(WorkoutTypeClassifier.rampDown(5, 10, 20), 1.0);
      expect(WorkoutTypeClassifier.rampDown(15, 10, 20), closeTo(0.5, 1e-9));
      expect(WorkoutTypeClassifier.rampDown(25, 10, 20), 0.0);
    });

    test('plateau is a trapezoid', () {
      expect(WorkoutTypeClassifier.plateau(0, 10, 20, 30, 40), 0.0);
      expect(WorkoutTypeClassifier.plateau(15, 10, 20, 30, 40), closeTo(0.5, 1e-9));
      expect(WorkoutTypeClassifier.plateau(25, 10, 20, 30, 40), 1.0);
      expect(WorkoutTypeClassifier.plateau(35, 10, 20, 30, 40), closeTo(0.5, 1e-9));
      expect(WorkoutTypeClassifier.plateau(45, 10, 20, 30, 40), 0.0);
    });

    test('gait absence is NEUTRAL (0.5), not a penalty, when ticks are too sparse', () {
      // A WHOOP 4.0 window carries no @63 activity class at all — an absent signal must never read
      // as evidence AGAINST the non-foot classes.
      final noTicks = features(tickCoverage: 0.0, stillFraction: 0.0);
      expect(WorkoutTypeClassifier.gaitAbsenceScore(noTicks), 0.5);

      final belowFloor = features(tickCoverage: 0.14, stillFraction: 0.0);
      expect(WorkoutTypeClassifier.gaitAbsenceScore(belowFloor), 0.5);

      // Once ticks ARE trustworthy, "mostly still" becomes real evidence.
      final stillTicks = features(tickCoverage: 0.9, stillFraction: 0.9);
      expect(WorkoutTypeClassifier.gaitAbsenceScore(stillTicks), 1.0);
    });
  });

  group('WorkoutTypeClassifier — per-class recovery (two distinct patterns each)', () {
    test('RUN: tick-led and HR+motion fallback', () {
      final tickLed = features(
        meanHRRPct: 72,
        hrCV: 0.05,
        runFraction: 0.85,
        walkFraction: 0.10,
        stillFraction: 0.05,
        tickCoverage: 0.9,
        motionVariance: 0.20,
      );
      expect(WorkoutTypeClassifier.classify(tickLed).predictedClass,
          CoarseWorkoutClass.run);

      // No step stream at all (WHOOP 4.0): high %HRR + high impact + smooth HR.
      final fallback = features(
        meanHRRPct: 80,
        hrCV: 0.04,
        tickCoverage: 0.0,
        motionVariance: 0.25,
      );
      expect(WorkoutTypeClassifier.classify(fallback).predictedClass,
          CoarseWorkoutClass.run);
    });

    test('WALK: tick-led and HR+motion fallback', () {
      final tickLed = features(
        meanHR: 95,
        peakHR: 110,
        meanHRRPct: 25,
        hrCV: 0.05,
        walkFraction: 0.80,
        stillFraction: 0.15,
        runFraction: 0.05,
        tickCoverage: 0.9,
        motionVariance: 0.04,
      );
      expect(WorkoutTypeClassifier.classify(tickLed).predictedClass,
          CoarseWorkoutClass.walk);

      final fallback = features(
        meanHR: 90,
        peakHR: 105,
        meanHRRPct: 22,
        hrCV: 0.05,
        tickCoverage: 0.0,
        motionVariance: 0.045,
      );
      expect(WorkoutTypeClassifier.classify(fallback).predictedClass,
          CoarseWorkoutClass.walk);
    });

    test('STRENGTH: bursty HR, low motion — with and without ticks', () {
      final withTicks = features(
        meanHRRPct: 50,
        hrCV: 0.22, // sets-then-rest sawtooth
        stillFraction: 0.85,
        tickCoverage: 0.9,
        motionVariance: 0.02,
        kcalPerMin: 5.0,
      );
      expect(WorkoutTypeClassifier.classify(withTicks).predictedClass,
          CoarseWorkoutClass.strength);

      final noTicks = features(
        meanHRRPct: 45,
        hrCV: 0.30,
        tickCoverage: 0.0,
        motionVariance: 0.01,
        kcalPerMin: 4.0,
      );
      expect(WorkoutTypeClassifier.classify(noTicks).predictedClass,
          CoarseWorkoutClass.strength);
    });

    test('CYCLE: smooth elevated HR, stable posture — with and without ticks', () {
      final withTicks = features(
        meanHRRPct: 68,
        hrCV: 0.03, // steady spin
        stillFraction: 0.90,
        tickCoverage: 0.9,
        motionVariance: 0.005,
      );
      expect(WorkoutTypeClassifier.classify(withTicks).predictedClass,
          CoarseWorkoutClass.cycle);

      final noTicks = features(
        meanHRRPct: 70,
        hrCV: 0.02,
        tickCoverage: 0.0,
        motionVariance: 0.004,
      );
      expect(WorkoutTypeClassifier.classify(noTicks).predictedClass,
          CoarseWorkoutClass.cycle);
    });

    test('SKI: variable posture + intermittent HR — with and without ticks', () {
      final withTicks = features(
        meanHRRPct: 55,
        hrCV: 0.14, // runs broken up by lift rides
        stillFraction: 0.80,
        tickCoverage: 0.9,
        motionVariance: 0.25,
      );
      expect(WorkoutTypeClassifier.classify(withTicks).predictedClass,
          CoarseWorkoutClass.ski);

      final noTicks = features(
        meanHRRPct: 60,
        hrCV: 0.13,
        tickCoverage: 0.0,
        motionVariance: 0.30,
      );
      expect(WorkoutTypeClassifier.classify(noTicks).predictedClass,
          CoarseWorkoutClass.ski);
    });

    test('a SMOOTH window never scores as strength on plausible HR/motion alone', () {
      // The `bursty` weight is deliberately dominant — see strengthScore's comment.
      final smooth = features(meanHRRPct: 50, hrCV: 0.0, tickCoverage: 0.0, motionVariance: 0.02);
      final scores = WorkoutTypeClassifier.allScores(smooth);
      expect(scores[CoarseWorkoutClass.strength]!,
          lessThan(scores[CoarseWorkoutClass.cycle]!));
    });
  });

  group('WorkoutTypeClassifier — OTHER and confidence', () {
    /// (top score, margin over the runner-up) for a window — lets each OTHER path be pinned to the
    /// specific bar it is meant to fail.
    (double, double) topAndMargin(WorkoutClassFeatures f) {
      final sorted = WorkoutTypeClassifier.classify(f).scores.values.toList()..sort();
      return (sorted.last, sorted.last - sorted[sorted.length - 2]);
    }

    test('nothing plausible → OTHER (the minPlausibleScore bar, in isolation)', () {
      // Very low %HRR with wild motion: no class's prototype matches, but the winner still beats the
      // runner-up comfortably — so ONLY the plausibility bar can be what forces OTHER here.
      final implausible = features(
        meanHR: 70,
        peakHR: 80,
        meanHRRPct: 5,
        hrCV: 0.09,
        tickCoverage: 0.0,
        motionVariance: 2.0,
      );
      final (top, margin) = topAndMargin(implausible);
      expect(top, lessThan(WorkoutTypeClassifier.minPlausibleScore));
      expect(margin, greaterThanOrEqualTo(WorkoutTypeClassifier.minMargin),
          reason: 'fixture must isolate the plausibility bar, not also trip the margin bar');
      expect(WorkoutTypeClassifier.classify(implausible).predictedClass, CoarseWorkoutClass.other);
    });

    test('too close to call → OTHER, never an arbitrary tie-break (the minMargin bar, in isolation)',
        () {
      // A plausible-looking window whose top two classes are nearly tied: the winner CLEARS the
      // plausibility bar, so ONLY the margin bar can be what forces OTHER here.
      final tooClose = features(
        meanHRRPct: 42,
        hrCV: 0.095,
        tickCoverage: 0.0,
        motionVariance: 0.085,
      );
      final (top, margin) = topAndMargin(tooClose);
      expect(top, greaterThanOrEqualTo(WorkoutTypeClassifier.minPlausibleScore),
          reason: 'fixture must isolate the margin bar, not also trip the plausibility bar');
      expect(margin, lessThan(WorkoutTypeClassifier.minMargin));
      expect(WorkoutTypeClassifier.classify(tooClose).predictedClass, CoarseWorkoutClass.other);
    });

    test('thin data damps confidence vs the same shape with complete inputs', () {
      final complete = features(
        meanHRRPct: 72,
        hrCV: 0.05,
        runFraction: 0.85,
        stillFraction: 0.05,
        walkFraction: 0.10,
        tickCoverage: 0.9,
        motionVariance: 0.20,
      );
      final thin = features(
        meanHRRPct: null, // no %HRR resolvable
        hrCV: 0.05,
        tickCoverage: 0.0, // no ticks
        motionVariance: 0.20,
      );
      expect(WorkoutTypeClassifier.classify(thin).confidence,
          lessThan(WorkoutTypeClassifier.classify(complete).confidence));
    });

    test('confidence stays within [0, 1] across wildly different windows', () {
      for (final f in [
        features(meanHRRPct: 100, hrCV: 0.0, tickCoverage: 1.0, runFraction: 1.0),
        features(meanHRRPct: null, hrCV: 5.0, tickCoverage: 0.0, motionVariance: 99.0),
        features(meanHRRPct: 0, hrCV: 0.0, tickCoverage: 0.0),
      ]) {
        final c = WorkoutTypeClassifier.classify(f).confidence;
        expect(c, inInclusiveRange(0.0, 1.0));
      }
    });

    test('scores map invariant: always the 5 concrete classes, never OTHER', () {
      final p = WorkoutTypeClassifier.classify(features(meanHRRPct: 50));
      expect(p.scores.keys.toSet(), {
        CoarseWorkoutClass.walk,
        CoarseWorkoutClass.run,
        CoarseWorkoutClass.strength,
        CoarseWorkoutClass.cycle,
        CoarseWorkoutClass.ski,
      });
      expect(p.scores.containsKey(CoarseWorkoutClass.other), isFalse);
      for (final v in p.scores.values) {
        expect(v, inInclusiveRange(0.0, 1.0));
      }
    });

    test('an OTHER verdict still carries its full scores map for later validation', () {
      final p = WorkoutTypeClassifier.classify(
          features(meanHRRPct: 42, hrCV: 0.095, motionVariance: 0.085));
      expect(p.predictedClass, CoarseWorkoutClass.other);
      expect(p.scores.length, 5); // the losers are kept, not discarded
    });

    test('the interface adapter matches the direct call', () {
      const adapter = HeuristicWorkoutClassifier();
      final f = features(meanHRRPct: 72, hrCV: 0.05, runFraction: 0.85, tickCoverage: 0.9);
      final a = adapter.classify(f);
      final b = WorkoutTypeClassifier.classify(f);
      expect(a.predictedClass, b.predictedClass);
      expect(a.confidence, b.confidence);
      expect(a.scores, b.scores);
    });

    test('wire strings match the Swift/Kotlin rawValues', () {
      expect(CoarseWorkoutClass.values.map((c) => c.raw).toList(),
          ['walk', 'run', 'strength', 'cycle', 'ski', 'other']);
    });
  });

  group('advisory contract — MUST NEVER override the user (#414)', () {
    final confidentRun = WorkoutTypeClassifier.classify(WorkoutClassFeatures(
      durationSec: 1800,
      meanHR: 150,
      peakHR: 175,
      meanHRRPct: 72,
      hrCV: 0.05,
      runFraction: 0.85,
      walkFraction: 0.10,
      stillFraction: 0.05,
      tickCoverage: 0.9,
      motionVariance: 0.20,
    ));

    test('sanity: the fixture IS a confident run', () {
      expect(confidentRun.predictedClass, CoarseWorkoutClass.run);
      expect(confidentRun.confidence, greaterThan(0.0));
    });

    test('every prediction is permanently marked advisory', () {
      expect(confidentRun.isAdvisory, isTrue);
      expect(
        WorkoutTypeClassifier.classify(
                WorkoutClassFeatures(durationSec: 60, meanHR: 0, peakHR: 0, meanHRRPct: null, hrCV: 0))
            .isAdvisory,
        isTrue,
      );
    });

    test('a user-set sport ALWAYS wins — no matter how confident the heuristic is', () {
      // The whole point of the feature: this must be null for ANY user selection.
      for (final userSport in ['cycling', 'tennis', 'run', 'Basketball', '  yoga  ']) {
        expect(
          suggestionFor(confidentRun, userSport: userSport, optedIn: true),
          isNull,
          reason: 'must never override the user-set sport "$userSport"',
        );
      }
    });

    test('opt-in is required — no suggestion by default', () {
      expect(suggestionFor(confidentRun), isNull);
      expect(suggestionFor(confidentRun, optedIn: false), isNull);
    });

    test('suggests only when opted in AND the user has set nothing', () {
      expect(suggestionFor(confidentRun, optedIn: true), CoarseWorkoutClass.run);
      expect(suggestionFor(confidentRun, userSport: null, optedIn: true), CoarseWorkoutClass.run);
      // An empty/whitespace sport is "unset", not a user choice.
      expect(suggestionFor(confidentRun, userSport: '', optedIn: true), CoarseWorkoutClass.run);
      expect(suggestionFor(confidentRun, userSport: '   ', optedIn: true), CoarseWorkoutClass.run);
    });

    test('OTHER is never offered as a suggestion', () {
      const other = WorkoutClassPrediction(CoarseWorkoutClass.other, 0.9, {});
      expect(suggestionFor(other, optedIn: true), isNull);
    });
  });

  group('WorkoutTypeFeatureExtractor', () {
    // A synthetic run: 20 min at 1 Hz, HR ~155, run-classified ticks, moving gravity vector.
    List<int> ts(int n, {int from = 1000}) => [for (var i = 0; i < n; i++) from + i];

    test('run window round-trips through the extractor to a RUN verdict', () {
      const n = 1200;
      final hrTs = ts(n);
      final hrBpm = [for (var i = 0; i < n; i++) 155.0 + math.sin(i / 30.0) * 4];
      final gTs = ts(n);
      // Impactful, varying gravity vector.
      final gx = [for (var i = 0; i < n; i++) math.sin(i / 2.0) * 0.5];
      final gy = [for (var i = 0; i < n; i++) math.cos(i / 2.0) * 0.5];
      final gz = [for (var i = 0; i < n; i++) 0.8 + math.sin(i / 5.0) * 0.1];
      final sTs = ts(n);
      final sCls = [for (var i = 0; i < n; i++) 2]; // all "run"

      final f = WorkoutTypeFeatureExtractor.extract(
        hrTsSec: hrTs,
        hrBpm: hrBpm,
        gravityTsSec: gTs,
        gravityX: gx,
        gravityY: gy,
        gravityZ: gz,
        stepTsSec: sTs,
        stepActivityClass: sCls,
        start: 1000,
        end: 1000 + n - 1,
        restingHR: 55,
        maxHR: 190,
      )!;

      expect(f.durationSec, (n - 1).toDouble());
      expect(f.runFraction, 1.0);
      expect(f.stillFraction, 0.0);
      expect(f.tickCoverage, closeTo(1.0, 1e-9));
      expect(f.meanHRRPct, isNotNull);
      expect(f.meanHR, closeTo(155.0, 1.0));
      expect(f.peakHR, greaterThan(155));
      expect(WorkoutTypeClassifier.classify(f).predictedClass, CoarseWorkoutClass.run);
    });

    test('walk window round-trips to a WALK verdict', () {
      const n = 1200;
      final hrBpm = [for (var i = 0; i < n; i++) 95.0 + math.sin(i / 40.0) * 3];
      final f = WorkoutTypeFeatureExtractor.extract(
        hrTsSec: ts(n),
        hrBpm: hrBpm,
        gravityTsSec: ts(n),
        gravityX: [for (var i = 0; i < n; i++) math.sin(i / 4.0) * 0.12],
        gravityY: [for (var i = 0; i < n; i++) math.cos(i / 4.0) * 0.12],
        gravityZ: [for (var i = 0; i < n; i++) 0.95],
        stepTsSec: ts(n),
        stepActivityClass: [for (var i = 0; i < n; i++) 1], // all "walk"
        start: 1000,
        end: 1000 + n - 1,
        restingHR: 55,
        maxHR: 190,
      )!;
      expect(f.walkFraction, 1.0);
      expect(WorkoutTypeClassifier.classify(f).predictedClass, CoarseWorkoutClass.walk);
    });

    test('no step stream → zero tick coverage, no NaNs', () {
      final f = WorkoutTypeFeatureExtractor.extract(
        hrTsSec: ts(600),
        hrBpm: [for (var i = 0; i < 600; i++) 140.0],
        start: 1000,
        end: 1599,
        restingHR: 55,
        maxHR: 190,
      )!;
      expect(f.tickCoverage, 0.0);
      expect(f.stillFraction, 0.0);
      expect(f.walkFraction, 0.0);
      expect(f.runFraction, 0.0);
      expect(f.motionVariance, 0.0);
      expect(f.motionCV, 0.0);
      expect(f.hrCV.isNaN, isFalse);
      expect(f.meanHR, 140.0);
    });

    test('null activity classes are ignored, not counted as "still"', () {
      final f = WorkoutTypeFeatureExtractor.extract(
        hrTsSec: ts(100),
        hrBpm: [for (var i = 0; i < 100; i++) 140.0],
        stepTsSec: ts(100),
        stepActivityClass: [for (var i = 0; i < 100; i++) i < 50 ? 2 : null],
        start: 1000,
        end: 1099,
        restingHR: 55,
        maxHR: 190,
      )!;
      expect(f.runFraction, 1.0); // 50 valid ticks, all "run"
      expect(f.stillFraction, 0.0);
      expect(f.tickCoverage, closeTo(50 / 99, 1e-9));
    });

    test('no HR in window → null (never fabricates a vector)', () {
      expect(
        WorkoutTypeFeatureExtractor.extract(
          hrTsSec: ts(10, from: 50000),
          hrBpm: [for (var i = 0; i < 10; i++) 140.0],
          start: 1000,
          end: 2000,
        ),
        isNull,
      );
      expect(
        WorkoutTypeFeatureExtractor.extract(hrTsSec: const [], hrBpm: const [], start: 1000, end: 2000),
        isNull,
      );
    });

    test('degenerate window → null', () {
      expect(
        WorkoutTypeFeatureExtractor.extract(
            hrTsSec: ts(10), hrBpm: [for (var i = 0; i < 10; i++) 140.0], start: 2000, end: 2000),
        isNull,
      );
      expect(
        WorkoutTypeFeatureExtractor.extract(
            hrTsSec: ts(10), hrBpm: [for (var i = 0; i < 10; i++) 140.0], start: 2000, end: 1000),
        isNull,
      );
    });

    test('no calories → null kcal/min; calories → per-minute rate', () {
      final base = {
        'hrTsSec': ts(600),
        'hrBpm': [for (var i = 0; i < 600; i++) 140.0],
      };
      final noCals = WorkoutTypeFeatureExtractor.extract(
        hrTsSec: base['hrTsSec'] as List<int>,
        hrBpm: base['hrBpm'] as List<double>,
        start: 1000,
        end: 1600, // 600 s = 10 min
      )!;
      expect(noCals.kcalPerMin, isNull);

      final withCals = WorkoutTypeFeatureExtractor.extract(
        hrTsSec: base['hrTsSec'] as List<int>,
        hrBpm: base['hrBpm'] as List<double>,
        start: 1000,
        end: 1600,
        caloriesKcal: 100,
      )!;
      expect(withCals.kcalPerMin, closeTo(10.0, 1e-9)); // 100 kcal / 10 min
    });

    test('%HRR is null when HRmax cannot be resolved', () {
      // 10 samples, no age, no maxHR → estimateHRmax returns "unknown" (0).
      final f = WorkoutTypeFeatureExtractor.extract(
        hrTsSec: ts(10),
        hrBpm: [for (var i = 0; i < 10; i++) 140.0],
        start: 1000,
        end: 1009,
      )!;
      expect(f.meanHRRPct, isNull);
    });

    test('gravityActivitySeries: first record is 0, then |Δ| L2', () {
      final s = WorkoutTypeFeatureExtractor.gravityActivitySeries(
        [1, 2, 3],
        [0.0, 3.0, 3.0],
        [0.0, 4.0, 4.0],
        [0.0, 0.0, 0.0],
      );
      expect(s.length, 3);
      expect(s[0].intensity, 0.0); // no predecessor
      expect(s[1].intensity, closeTo(5.0, 1e-9)); // 3-4-5
      expect(s[2].intensity, 0.0); // no change
      expect(s.map((e) => e.ts).toList(), [1, 2, 3]);
    });

    test('deriveRestingHR is the 10th percentile of the window', () {
      final bpm = [for (var i = 0; i < 101; i++) 50.0 + i]; // 50..150
      expect(WorkoutTypeFeatureExtractor.deriveRestingHR(bpm), closeTo(60.0, 1e-9));
      expect(WorkoutTypeFeatureExtractor.deriveRestingHR([]), 0.0);
    });

    test('unsorted input is ordered internally (same vector either way)', () {
      final hrTs = ts(600);
      final hrBpm = [for (var i = 0; i < 600; i++) 100.0 + i % 20];
      final ordered = WorkoutTypeFeatureExtractor.extract(
          hrTsSec: hrTs, hrBpm: hrBpm, start: 1000, end: 1599, restingHR: 55, maxHR: 190)!;
      final pairs = [for (var i = 0; i < 600; i++) (hrTs[i], hrBpm[i])].reversed.toList();
      final shuffled = WorkoutTypeFeatureExtractor.extract(
        hrTsSec: [for (final p in pairs) p.$1],
        hrBpm: [for (final p in pairs) p.$2],
        start: 1000,
        end: 1599,
        restingHR: 55,
        maxHR: 190,
      )!;
      expect(shuffled.meanHR, closeTo(ordered.meanHR, 1e-9));
      expect(shuffled.hrCV, closeTo(ordered.hrCV, 1e-9));
      expect(shuffled.meanHRRPct!, closeTo(ordered.meanHRRPct!, 1e-9));
    });
  });

  group('WorkoutTypeFeatureExtractor — stats helpers', () {
    test('mean/variance/stddev are population statistics', () {
      expect(WorkoutTypeFeatureExtractor.mean([2, 4, 6]), closeTo(4.0, 1e-9));
      expect(WorkoutTypeFeatureExtractor.variance([2, 4, 6]), closeTo(8.0 / 3.0, 1e-9));
      expect(WorkoutTypeFeatureExtractor.stddev([2, 4, 6]), closeTo(math.sqrt(8.0 / 3.0), 1e-9));
    });

    test('degenerate inputs return 0, never NaN', () {
      expect(WorkoutTypeFeatureExtractor.mean([]), 0.0);
      expect(WorkoutTypeFeatureExtractor.variance([]), 0.0);
      expect(WorkoutTypeFeatureExtractor.variance([5]), 0.0);
      expect(WorkoutTypeFeatureExtractor.stddev([]), 0.0);
    });
  });
}
