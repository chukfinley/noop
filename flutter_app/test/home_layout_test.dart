import 'package:flutter_test/flutter_test.dart';
import 'package:noop/features/today/presentation/home_layout.dart';

/// Guards the reorder / show-hide logic behind the in-place home arranger (the
/// score trio + the Health-Monitor tiles). The notifier is built with an
/// in-memory `save` sink so no Prefs/secure storage is touched — we assert both
/// the state transitions and what gets persisted.
void main() {
  (SectionLayoutNotifier, List<List<Map<String, dynamic>>>) make(
      List<HomeSectionCfg> seed) {
    final saved = <List<Map<String, dynamic>>>[];
    final n = SectionLayoutNotifier(seed: List.of(seed), save: saved.add);
    return (n, saved);
  }

  List<String> ids(List<HomeSectionCfg> s) => [for (final c in s) c.id];

  group('defaults', () {
    test('every score-trio id has a label', () {
      for (final c in kDefaultCardsLayout) {
        expect(kCardLabels.containsKey(c.id), isTrue);
      }
    });
    test('every health id has a label', () {
      for (final c in kDefaultHealthLayout) {
        expect(kHealthItemLabels.containsKey(c.id), isTrue);
      }
    });
  });

  group('reorderVisible', () {
    test('moves a visible item and persists', () {
      final (n, saved) = make(kDefaultCardsLayout);
      // recovery, strain, sleep → move recovery (0) to the end.
      n.reorderVisible(0, 3);
      expect(ids(n.state), ['strain', 'sleep', 'recovery']);
      expect([for (final m in saved.last) m['id']],
          ['strain', 'sleep', 'recovery']);
    });

    test('reorders among visible only; hidden trail in prior order', () {
      final seed = [
        const HomeSectionCfg('resp', false),
        const HomeSectionCfg('rhr', true),
        const HomeSectionCfg('hrv', true),
        const HomeSectionCfg('sleep', true),
      ];
      final (n, _) = make(seed);
      n.reorderVisible(1, 0); // visible [rhr,hrv,sleep] → move hrv to front
      expect(ids(n.state), ['hrv', 'rhr', 'sleep', 'resp']);
    });

    test('out-of-range index is a no-op', () {
      final (n, saved) = make(kDefaultCardsLayout);
      n.reorderVisible(9, 0);
      expect(ids(n.state), ['recovery', 'strain', 'sleep']);
      expect(saved, isEmpty);
    });
  });

  group('setVisibleOrder (in-place drag commit)', () {
    test('adopts the dragged visible order, hidden stay trailing', () {
      final seed = [
        const HomeSectionCfg('recovery', true),
        const HomeSectionCfg('strain', false),
        const HomeSectionCfg('sleep', true),
      ];
      final (n, _) = make(seed);
      // Visible are recovery, sleep; a drag swaps them.
      n.setVisibleOrder(['sleep', 'recovery']);
      expect(ids(n.state), ['sleep', 'recovery', 'strain']);
      expect(n.state.firstWhere((c) => c.id == 'strain').visible, isFalse);
    });
  });

  group('setVisible', () {
    test('hiding flips the flag and persists', () {
      final (n, saved) = make(kDefaultCardsLayout);
      n.setVisible('strain', false);
      expect(n.state.firstWhere((c) => c.id == 'strain').visible, isFalse);
      expect(saved.last.firstWhere((m) => m['id'] == 'strain')['visible'],
          isFalse);
    });
  });
}
