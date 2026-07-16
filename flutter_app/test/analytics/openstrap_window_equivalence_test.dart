// Pins [OpenStrapEngine.analyze]'s per-night RR window as a PURE performance
// change: the engine used to find each night's beats by scanning the whole
// flattened RR stream (O(days x totalBeats) — 233 M iterations at 90 days), and
// now binary-searches the window's two ends. Same beats, same order, same scores.
//
// The technique is 19eb1b2a's: the OLD selection transcribed verbatim as an
// oracle, driven through the SAME vendored math, asserting byte-identical
// [DayRecord]s. Seeded with the shapes a windowed select could plausibly break —
// nights straddling midnight, a night with no beats at all, seconds carrying up to
// three beats (equal stamps), an RR-only day, and a NON-chronological input that
// must fall back to the scan rather than silently mis-window.
//
// Mutation-checked while writing: flipping the lower bound to an upper bound, or
// making the window inclusive at `endSec`, fails `identical scores` below.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/daily_pipeline.dart';
import 'package:noop/core/analytics/openstrap/openstrap_engine.dart';
import 'package:noop/core/analytics/openstrap/vendor/clinical/hrv_time.dart';
import 'package:noop/core/analytics/openstrap/vendor/clinical/readiness_lnrmssd.dart';
import 'package:noop/core/analytics/openstrap/vendor/foundations/rr_correction.dart';
import 'package:noop/core/analytics/openstrap/vendor/respiration/resp_rate.dart';
import 'package:noop/core/analytics/raw_samples.dart';
import 'package:noop/core/data/models.dart';
import 'package:noop/core/state/prefs.dart' show HrvWindow;

// ---------------------------------------------------------------------------
// Oracle — OpenStrapEngine.analyze as it stood before the binary search, copied
// verbatim. Only the class/level wrapper differs; the flatten + per-night linear
// select + every call into the vendored math are character-for-character the old
// code, so any divergence is the new window's fault, not a re-derivation's.
// ---------------------------------------------------------------------------
List<DayRecord> oracleAnalyze(
  List<RawDay> days,
  UserProfile profile, {
  HrvWindow hrvWindow = HrvWindow.wholeNight,
}) {
  final base = DailyPipeline(profile, hrvWindow: hrvWindow).run(days);
  if (base.isEmpty) return base;

  final rrTs = <double>[];
  final rrMsAll = <double>[];
  for (final d in days) {
    for (final s in d.samples) {
      for (final rr in s.rrIntervals) {
        rrTs.add(s.ts.toDouble());
        rrMsAll.add(rr);
      }
    }
  }

  final lnHistory = <double>[];
  final out = <DayRecord>[];
  for (final rec in base) {
    final sleep = rec.sleep;
    if (sleep == null) {
      out.add(rec);
      continue;
    }
    final startSec = sleep.bedtime.millisecondsSinceEpoch ~/ 1000;
    final endSec = sleep.wake.millisecondsSinceEpoch ~/ 1000;

    // THE loop under test: a full scan of every beat ever synced, per night.
    final rr = <double>[];
    for (var i = 0; i < rrTs.length; i++) {
      if (rrTs[i] >= startSec && rrTs[i] < endSec) rr.add(rrMsAll[i]);
    }
    if (rr.length < 20) {
      out.add(rec);
      continue;
    }

    final corr = correctRr(rr);
    if (corr.nn.length < 6) {
      out.add(rec);
      continue;
    }

    final hrvM = nocturnalRmssd(corr.nn, corr.nnTimesMs);
    final rmssd = hrvM.value;

    final respM = rsaRespRate(
      corr.nn,
      corr.nnTimesMs,
      artifactFraction: 1 - corr.cleanFraction,
    );
    final resp = respM.value?.brpm;

    double? charge;
    if (rmssd != null && rmssd > 0) {
      lnHistory.add(math.log(rmssd));
      final meanNn = corr.nn.reduce((a, b) => a + b) / corr.nn.length;
      final readyM = readinessLnRmssd(lnHistory, meanNnTodayMs: meanNn);
      final z = readyM.value?.z;
      if (z != null) charge = (50 + 22 * z).clamp(1.0, 99.0);
    }

    out.add(rec.copyWith(
      hrv: rmssd,
      respiratoryRate: resp,
      charge: charge,
    ));
  }
  return out;
}

/// Every field of a scored day, flattened — including the ones OpenStrap does not
/// touch, so a window bug that leaked into sleep or the HR thread cannot hide.
String sig(DayRecord d) {
  final s = d.sleep;
  return [
    'date=${d.date.toIso8601String()}',
    'charge=${d.charge}',
    'calNights=${d.chargeCalibrationNights}',
    'noData=${d.chargeNoData}',
    'effort=${d.effort}',
    'rest=${d.rest}',
    'stress=${d.stress}',
    'hrv=${d.hrv}',
    'rhr=${d.rhr}',
    'resp=${d.respiratoryRate}',
    'spo2=${d.spo2}',
    'vitality=${d.vitality}',
    'hr=${d.hr.map((h) => '${h.time.millisecondsSinceEpoch}/${h.bpm}').join(',')}',
    if (s == null)
      'sleep=null'
    else
      'sleep=[bed=${s.bedtime.toIso8601String()} wake=${s.wake.toIso8601String()} '
          'asleep=${s.asleep.inSeconds} deep=${s.deep.inSeconds} rem=${s.rem.inSeconds} '
          'light=${s.light.inSeconds} awake=${s.awake.inSeconds} eff=${s.efficiency} '
          'resp=${s.respiratoryRate} dist=${s.disturbances} '
          'hypno=${s.hypnogram.map((h) => '${h.start.millisecondsSinceEpoch}/'
              '${h.duration.inSeconds}/${h.stage}').join(',')}]',
  ].join(' ');
}

// ---------------------------------------------------------------------------
// Seeds
// ---------------------------------------------------------------------------

RawSample _s(int ts, List<int> rr, {required int hr, int? state, double? mv}) =>
    RawSample(
      ts: ts,
      hr: hr,
      spo2: 0,
      rrCount: rr.length > 3 ? 3 : rr.length,
      rr1: rr.isNotEmpty ? rr[0] : 0,
      rr2: rr.length > 1 ? rr[1] : 0,
      rr3: rr.length > 2 ? rr[2] : 0,
      movement: mv,
      sleepState: state,
    );

/// A day whose night STRADDLES MIDNIGHT — it opens at 22:40 the previous evening
/// and closes at 06:00 — which is the case the flattened cross-day stream exists
/// for, and the one a per-day window would get wrong. [beatsPerSecond] drives how
/// many equal stamps land in a row.
RawDay _night(
  DateTime midnight, {
  int beatsPerSecond = 1,
  bool withNight = true,
  bool withDay = true,
}) {
  final samples = <RawSample>[];
  if (withNight) {
    // 00:05 → 05:05 asleep. Five hours clears the stager's 2 h minimum with room
    // for the boundary seconds below to matter.
    final start = midnight.add(const Duration(minutes: 5));
    for (var i = 0; i < 5 * 3600; i++) {
      final ts = start.add(Duration(seconds: i)).millisecondsSinceEpoch ~/ 1000;
      final base = 1200 + 45 * math.sin(2 * math.pi * 0.25 * i);
      samples.add(_s(
        ts,
        [for (var b = 0; b < beatsPerSecond; b++) (base + b * 3).round()],
        hr: (60000 / base).round(),
        state: 2,
        mv: 1.0,
      ));
    }
  }
  if (withDay) {
    final start = midnight.add(const Duration(hours: 9));
    for (var m = 0; m < 5 * 60; m++) {
      final ts = start.add(Duration(minutes: m)).millisecondsSinceEpoch ~/ 1000;
      samples.add(_s(ts, const [], hr: 70 + (m % 7), state: 0, mv: 1.05));
    }
  }
  samples.sort((a, b) => a.ts.compareTo(b.ts));
  return RawDay(midnight, samples);
}

void main() {
  const profile = UserProfile();
  final start = DateTime(2026, 3, 1);

  test('identical scores — the binary-searched window selects the oracle\'s '
      'beats across every awkward shape', () {
    final days = <RawDay>[
      _night(start), // ordinary night
      _night(start.add(const Duration(days: 1)), beatsPerSecond: 3), // equal stamps
      _night(start.add(const Duration(days: 2)), withNight: false), // day only
      _night(start.add(const Duration(days: 3))),
      _night(start.add(const Duration(days: 4)), beatsPerSecond: 2),
      _night(start.add(const Duration(days: 5)), withDay: false), // night only
      _night(start.add(const Duration(days: 6))),
      _night(start.add(const Duration(days: 7))),
    ];

    final expected = oracleAnalyze(days, profile).map(sig).toList();
    final actual = const OpenStrapEngine().analyze(days, profile).map(sig).toList();

    expect(actual.length, expected.length);
    expect(expected.where((s) => !s.contains('sleep=null')), isNotEmpty,
        reason: 'the seed must actually reach the RR window, or this pins nothing');
    for (var i = 0; i < expected.length; i++) {
      expect(actual[i], expected[i], reason: 'scored day $i differs');
    }
  });

  test('identical scores under the non-wholeNight HRV window too', () {
    final days = [
      for (var d = 0; d < 6; d++) _night(start.add(Duration(days: d))),
    ];
    for (final w in HrvWindow.values) {
      final expected =
          oracleAnalyze(days, profile, hrvWindow: w).map(sig).toList();
      final actual = const OpenStrapEngine()
          .analyze(days, profile, hrvWindow: w)
          .map(sig)
          .toList();
      expect(actual, expected, reason: 'hrvWindow $w differs');
    }
  });

  test('DAYS out of order — the stream is non-chronological, the scan fallback '
      'takes over, and the scores still match the oracle exactly', () {
    // Where the ordering promise actually has a hole. WITHIN a day it is enforced
    // the hard way: [DailyPipeline._buildEpochs] sizes its bins from
    // `s.first.ts .. s.last.ts`, so a day whose samples run backwards throws
    // outright, long before any of this. ACROSS days nothing checks anything —
    // [AnalysisEngine.analyze] merely documents "oldest → newest", the pipeline
    // scores each day independently, and a caller who assembled the list in the
    // wrong order gets no complaint. That is a silent-wrong-answer case for a
    // binary search (the flattened stamps dip at the swapped boundary, the lower
    // bounds collapse to the same index, and the night selects ZERO beats — so it
    // would quietly lose its HRV, its respiratory rate and its Plews charge, and
    // report the shared pipeline's numbers instead of erroring).
    //
    // Mutation-checked: deleting the `chronological` guard (always binary-search)
    // fails this test; the two tests above still pass, which is exactly why this
    // one exists.
    final days = <RawDay>[
      _night(start.add(const Duration(days: 1))), // day 1 before day 0
      _night(start),
      _night(start.add(const Duration(days: 2))),
    ];

    final expected = oracleAnalyze(days, profile).map(sig).toList();
    final actual = const OpenStrapEngine().analyze(days, profile).map(sig).toList();
    expect(actual, expected);
    // Guard the guard: if the seed stopped producing scoreable nights this would
    // pass vacuously.
    expect(expected.where((s) => !s.contains('sleep=null')), isNotEmpty);
  });

  test('an empty history and a history with no beats at all are unchanged', () {
    expect(const OpenStrapEngine().analyze(const [], profile), isEmpty);
    // Days with HR but zero RR: every night falls under the 20-beat floor, so each
    // record must come back from the shared pipeline untouched.
    final noBeats = [
      for (var d = 0; d < 4; d++)
        _night(start.add(Duration(days: d)), withNight: false),
    ];
    final expected = oracleAnalyze(noBeats, profile).map(sig).toList();
    final actual =
        const OpenStrapEngine().analyze(noBeats, profile).map(sig).toList();
    expect(actual, expected);
  });
}
