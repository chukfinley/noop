import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/engine.dart';
import 'package:noop/core/analytics/engine_registry.dart';
import 'package:noop/core/analytics/noop_engine.dart';
import 'package:noop/core/analytics/openstrap/openstrap_engine.dart';
import 'package:noop/core/analytics/raw_samples.dart';
import 'package:noop/core/data/models.dart';

/// One synthetic day: a ~160-min asleep block (strap sleep_state = 2) carrying
/// one RR interval per second, modulated at 0.25 Hz (= 15 breaths/min) so the RSA
/// respiratory estimator has a real peak to lock onto, plus a daytime wake block.
/// The night must clear the stager's 2-hour minimum window to be scored as sleep.
RawDay _day(DateTime date) {
  final samples = <RawSample>[];
  final midnight = DateTime(date.year, date.month, date.day);

  // Night: 00:20 → 03:00 asleep, HR ~50 bpm (RR ~1200 ms) + RSA modulation.
  final nightStart = midnight.add(const Duration(minutes: 20));
  final nightSecs = 160 * 60;
  for (var s = 0; s < nightSecs; s++) {
    final ts = nightStart.add(Duration(seconds: s)).millisecondsSinceEpoch ~/ 1000;
    // 0.25 Hz sinusoidal RSA on a 1200 ms base (respiration at 15 br/min).
    final rr = 1200 + 45 * math.sin(2 * math.pi * 0.25 * s);
    samples.add(RawSample(
      ts: ts,
      hr: (60000 / rr).round(),
      spo2: 0,
      rrCount: 1,
      rr1: rr.round(),
      rr2: 0,
      rr3: 0,
      movement: 1.0,
      sleepState: 2, // asleep
    ));
  }

  // Day: 08:00 → 12:00 awake, HR ~70 bpm, no sleep state.
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
      sleepState: 0, // awake
    ));
  }

  samples.sort((a, b) => a.ts.compareTo(b.ts));
  return RawDay(midnight, samples);
}

List<RawDay> _week() {
  final start = DateTime(2026, 6, 1);
  return [for (var d = 0; d < 6; d++) _day(start.add(Duration(days: d)))];
}

void main() {
  const profile = UserProfile();

  test('registry exposes NOOP (default) + OpenStrap, ids unique', () {
    expect(engineRegistry.length, greaterThanOrEqualTo(2));
    expect(engineRegistry.first, isA<NoopEngine>());
    expect(defaultEngineId, 'noop');
    final ids = engineRegistry.map((e) => e.id).toList();
    expect(ids, containsAll(['noop', 'openstrap']));
    expect(ids.toSet().length, ids.length, reason: 'ids must be unique');
  });

  test('engineById falls back to the default engine for an unknown id', () {
    expect(engineById('openstrap'), isA<OpenStrapEngine>());
    expect(engineById('does-not-exist').id, defaultEngineId);
    expect(engineById(null).id, defaultEngineId);
  });

  test('both engines score the same raw days into the same day count', () {
    final days = _week();
    final noop = const NoopEngine().analyze(days, profile);
    final os = const OpenStrapEngine().analyze(days, profile);
    expect(noop, isNotEmpty);
    expect(os.length, noop.length,
        reason: 'switching engines must not change which days exist');
    // Dates line up one-to-one.
    for (var i = 0; i < os.length; i++) {
      expect(os[i].date, noop[i].date);
    }
  });

  test('OpenStrap resolves a respiratory rate near the injected 15 br/min', () {
    final os = const OpenStrapEngine().analyze(_week(), profile);
    final withResp = os.where((d) => d.respiratoryRate > 0).toList();
    expect(withResp, isNotEmpty,
        reason: 'RSA estimator should lock the 0.25 Hz modulation');
    for (final d in withResp) {
      expect(d.respiratoryRate, closeTo(15, 3));
    }
  });

  test('OpenStrap HRV is finite/positive and its charge diverges once warm', () {
    final days = _week();
    final noop = const NoopEngine().analyze(days, profile);
    final os = const OpenStrapEngine().analyze(days, profile);
    for (final d in os.where((d) => d.sleep != null)) {
      expect(d.hrv, greaterThan(0));
      expect(d.hrv.isFinite, isTrue);
    }
    // After the lnRMSSD baseline warms up (≥4 nights), OpenStrap's Plews charge
    // should differ from our recovery model on at least one late day.
    var diverged = false;
    for (var i = 4; i < os.length; i++) {
      if ((os[i].charge - noop[i].charge).abs() > 0.5) diverged = true;
    }
    expect(diverged, isTrue,
        reason: 'OpenStrap charge (Plews lnRMSSD) should differ from NOOP once '
            'the baseline is established');
  });
}
