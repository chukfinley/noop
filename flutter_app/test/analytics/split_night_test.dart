import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/sleep_stager.dart';

/// Split-night coverage (upstream #345: "split nights report the whole night's Asleep total and
/// hypnogram").
///
/// The bug this pins: a real mid-night waking of 12–20 min used to BREAK the bout, leaving two
/// fragments, and `_longestBout` reported only the longer one. An 8 h night with a 12-minute
/// bathroom break scored 4 h — Asleep-Total halved on a night the wearer slept through. The bridge
/// tolerance was 20 EPOCHS (10 min) where upstream's `maxGapMin` is 20 MINUTES; the unit slip WAS
/// the bug.
///
/// The invariant: while the interruption stays within the bridge tolerance, the reported window,
/// the Asleep total and the hypnogram axis all span onset → final wake — never one fragment.

const _epoch = SleepStager.epochSec;
const _t0 = 1750000000; // fixed epoch base — deterministic, no clock reads

/// An 8 h night (960 epochs) broken by ONE real waking of [seamMin] minutes at [seamAtEpoch]:
/// the wearer is up — HR at 75 bpm, the wrist moving, the strap reporting awake.
///
/// Movement carries no fixed unit by contract, so this uses the production producer's scale
/// (`DailyPipeline._buildEpochs`: gravity removed, quiet level subtracted ⇒ still wrist ≈ 0). The
/// still-wrist wobble keeps the night's MAD non-degenerate so the motion tiers have a real scale.
({List<int> ts, List<double?> hr, List<double> mv, List<bool> asleep}) _night({
  required int seamMin,
  int seamAtEpoch = 480,
  int n = 960,
}) {
  final seamEpochs = seamMin * 2; // 2 epochs per minute at 30 s
  final ts = <int>[];
  final hr = <double?>[];
  final mv = <double>[];
  final asleep = <bool>[];
  for (var i = 0; i < n; i++) {
    ts.add(_t0 + i * _epoch);
    final up = i >= seamAtEpoch && i < seamAtEpoch + seamEpochs;
    hr.add(up ? 75.0 : 50.0);
    mv.add(up ? 0.3 : 0.002 * (i % 5));
    asleep.add(!up);
  }
  return (ts: ts, hr: hr, mv: mv, asleep: asleep);
}

SleepResult? _detect(({List<int> ts, List<double?> hr, List<double> mv, List<bool> asleep}) n) =>
    SleepStager.detect(
      epochTs: n.ts,
      epochHr: n.hr,
      epochMovement: n.mv,
      dayHrMin: 50,
      epochAsleep: n.asleep,
    );

/// Every second of the window is covered by exactly one contiguous segment.
void _expectGapless(SleepResult r) {
  expect(r.hypnogram.first.startTs, r.startTs);
  var cursor = r.startTs;
  for (final s in r.hypnogram) {
    expect(s.startTs, cursor, reason: 'segments must be contiguous');
    cursor += s.durationSec;
  }
  expect(cursor, r.endTs, reason: 'the hypnogram must close at the window end');
  expect(r.lightSec + r.deepSec + r.remSec + r.awakeSec, r.inBedSec);
}

void main() {
  group('a bridged waking keeps the whole night (#345)', () {
    // 12 min is the exact regression: it sits between the old 10-min bridge and upstream's 20-min
    // one, so it used to halve the night and now must not.
    for (final seamMin in <int>[2, 5, 10, 12, 15, 20]) {
      test('a $seamMin-min waking still reports all 8 h', () {
        final r = _detect(_night(seamMin: seamMin));
        expect(r, isNotNull, reason: 'an 8 h night with a $seamMin-min waking is still a night');

        // The window spans onset → final wake, not the winning fragment.
        expect(r!.startTs, _t0);
        expect(r.endTs, _t0 + 960 * _epoch);
        expect(r.inBedSec, 8 * 3600);
        _expectGapless(r);

        // Asleep-Total is the WHOLE night minus the seam — never one fragment (which would be
        // ~4 h). This is the number #345 is about.
        expect(r.asleepSec, 8 * 3600 - seamMin * 60);

        // The seam itself is scored awake — bridging decides where the night ENDS, it never
        // launders a real waking into sleep.
        expect(r.awakeSec, seamMin * 60);
        expect(r.efficiency, lessThan(1.0));

        // Real sleep is banked on BOTH sides of the seam.
        final seamTs = _t0 + 480 * _epoch;
        expect(r.hypnogram.any((s) => s.startTs < seamTs && s.stage != SleepStageK.awake), isTrue,
            reason: 'sleep before the seam counts');
        expect(r.hypnogram.any((s) => s.startTs >= seamTs && s.stage != SleepStageK.awake), isTrue,
            reason: 'sleep after the seam counts');
      });
    }

    test('the 12-min waking specifically does not halve the night (the #345 regression)', () {
      // Locked separately and explicitly: this is the exact input that reported 4 h of an 8 h night.
      final r = _detect(_night(seamMin: 12))!;
      expect(r.inBedSec, 8 * 3600);
      expect(r.asleepSec, greaterThan(7 * 3600), reason: 'must not collapse to a ~4 h fragment');
    });

    test('an off-centre waking spans the whole night too', () {
      // The fragments are lopsided (1 h then ~6.8 h). Reporting "the longest fragment" would drop
      // the first hour silently; spanning the bridged night keeps it.
      final r = _detect(_night(seamMin: 15, seamAtEpoch: 120))!;
      expect(r.startTs, _t0, reason: 'the short leading fragment is still part of the night');
      expect(r.endTs, _t0 + 960 * _epoch);
      expect(r.asleepSec, 8 * 3600 - 15 * 60);
      _expectGapless(r);
    });
  });

  group('a genuinely separate block is still separate', () {
    // The bridge must not become a blanket merge: past the tolerance the night really did end.
    test('a waking beyond the bridge tolerance breaks the night', () {
      // 40 min up — well past 20 min. The two blocks are separate sleeps, so the reported window
      // must be ONE of them, not a 8 h span papering over a 40-min hole.
      final r = _detect(_night(seamMin: 40))!;
      expect(r.inBedSec, lessThan(8 * 3600));
      expect(r.awakeSec, 0, reason: 'the seam is outside the window entirely, not inside it');
      _expectGapless(r);
    });

    test('the bridge tolerance is 20 min, matching upstream maxGapMin', () {
      // The boundary, pinned from both sides so the unit can never silently slip back to epochs.
      expect(_detect(_night(seamMin: 20))!.inBedSec, 8 * 3600, reason: '20 min bridges');
      expect(_detect(_night(seamMin: 25))!.inBedSec, lessThan(8 * 3600), reason: '25 min breaks');
    });
  });

  group('an unbroken night is unchanged by the wider bridge', () {
    test('a clean 8 h night still reports 8 h asleep', () {
      // Widening the bridge must not perturb a night that never had a gap.
      final r = _detect(_night(seamMin: 0))!;
      expect(r.inBedSec, 8 * 3600);
      expect(r.asleepSec, 8 * 3600);
      expect(r.awakeSec, 0);
      expect(r.efficiency, 1.0);
      _expectGapless(r);
    });
  });
}
