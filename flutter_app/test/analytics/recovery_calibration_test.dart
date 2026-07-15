import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/analytics/baselines.dart';

/// Oracle for the recovery cold-start "Calibrating N/4 nights" affordance (upstream #393 / #449,
/// "Bug B"). Recovery is nil until the HRV baseline crosses the seed gate
/// ([baselineProvisionalMinNights] valid nights); the app surfaces honest progress instead of a bare
/// empty state or a fabricated score.
///
/// Upstream's bug was that N was re-derived as a SEPARATE per-night bounds count over the raw
/// history, which could drift ABOVE the baseline's real `nValid` and tip past the seed gate — the UI
/// then read "Was your strap worn?" while the baseline was genuinely still seeding. This port has no
/// such re-derivation (`DailyPipeline` reads `_hrvBase.nValid` off the very BaselineState the scorer
/// rides) and no manual-recalibration epoch, so Bug B cannot occur here.
///
/// These tests pin the invariant that makes that true: `nValid` is the authoritative post-fold count,
/// and any looser "count the nights that had a number" predicate over-states it. If someone ever
/// re-introduces a parallel count, the divergence pinned below is what will bite them.
void main() {
  group('nValid is the authoritative seed count', () {
    test('a night with no HRV does not advance the count', () {
      final s = BaselineState();
      Baselines.update(s, 'hrv', null);
      Baselines.update(s, 'hrv', null);
      expect(s.nValid, 0);
      expect(s.status, BaselineStatus.calibrating);
    });

    test('each in-bounds night advances the count by exactly one', () {
      final s = BaselineState();
      for (var i = 1; i <= 3; i++) {
        Baselines.update(s, 'hrv', 55 + i.toDouble());
        expect(s.nValid, i);
      }
    });

    test('an out-of-bounds night does NOT advance the count — a bounds-blind count would', () {
      // The HRV config is 5..250 ms. A physiologically implausible RMSSD is refused by the fold, so
      // it must not advance the seed either. This is the exact divergence upstream's Bug B rode: a
      // caller counting "nights that produced a number" reads 3 here, while the real baseline has 1.
      final s = BaselineState();
      Baselines.update(s, 'hrv', 55); // in bounds  → folds
      Baselines.update(s, 'hrv', 4); // below minVal → refused
      Baselines.update(s, 'hrv', 999); // above maxVal → refused
      expect(s.nValid, 1, reason: 'only the in-bounds night seeds the baseline');

      const boundsBlindCount = 3; // what "it had a value" would have said
      expect(boundsBlindCount, greaterThan(s.nValid),
          reason: 'a parallel per-night count over-states the real baseline — never display it');
    });

    test('an in-bounds outlier is SEEN by the seed even though it is not folded', () {
      // The 5σ outlier gate skips the fold but still counts the night (`nValid++; // seen, not
      // folded`). N must track that, which reading nValid does for free.
      final s = BaselineState();
      for (var i = 0; i < 10; i++) {
        Baselines.update(s, 'hrv', 60);
      }
      final before = s.nValid;
      final baselineBefore = s.baseline;
      Baselines.update(s, 'hrv', 240); // in bounds, but way outside 5×spread
      expect(s.nValid, before + 1, reason: 'seen');
      expect(s.baseline, baselineBefore, reason: 'not folded');
    });
  });

  group('the seed gate', () {
    test('the baseline is unusable below the gate and usable at it', () {
      final s = BaselineState();
      for (var i = 1; i < baselineProvisionalMinNights; i++) {
        Baselines.update(s, 'hrv', 55 + i.toDouble());
        expect(s.usable, isFalse, reason: 'still calibrating at nValid=${s.nValid}');
        expect(s.status, BaselineStatus.calibrating);
      }
      Baselines.update(s, 'hrv', 60);
      expect(s.nValid, baselineProvisionalMinNights);
      expect(s.usable, isTrue, reason: 'the gate is crossed exactly at the seed count');
      expect(s.status, BaselineStatus.provisional);
    });

    test('out-of-bounds nights cannot tip a calibrating baseline past the gate', () {
      // The shape of Bug B: enough nights "with a number" to clear the gate, but only two that the
      // baseline actually accepted. The real state must still read calibrating.
      final s = BaselineState();
      Baselines.update(s, 'hrv', 55);
      Baselines.update(s, 'hrv', 58);
      for (var i = 0; i < 4; i++) {
        Baselines.update(s, 'hrv', 999); // implausible nights, refused
      }
      expect(s.nValid, 2);
      expect(s.usable, isFalse);
      expect(s.status, BaselineStatus.calibrating,
          reason: 'the UI must read "Calibrating 2/4", never fall through to a strap-worn prompt');
    });
  });
}
