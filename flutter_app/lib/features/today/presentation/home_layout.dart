import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/state/prefs.dart';

/// One item's configuration: its stable [id] and whether it is currently
/// [visible]. Plain value type so it maps to/from the raw JSON [Prefs] persists.
class HomeSectionCfg {
  final String id;
  final bool visible;
  const HomeSectionCfg(this.id, this.visible);

  HomeSectionCfg copyWith({bool? visible}) =>
      HomeSectionCfg(id, visible ?? this.visible);
}

/// Human labels for the top-level home sections.
const Map<String, String> kHomeSectionLabels = {
  'hero': 'Scores',
  'water': 'Water',
  'stress': 'Stress & Energy',
  'health': 'Health Monitor',
  'yourcards': 'Your cards',
};

/// The default home section order — all visible.
const List<HomeSectionCfg> kDefaultHomeLayout = [
  HomeSectionCfg('hero', true),
  HomeSectionCfg('water', true),
  HomeSectionCfg('stress', true),
  HomeSectionCfg('health', true),
  HomeSectionCfg('yourcards', true),
];

/// Human labels for the Health-Monitor tiles.
const Map<String, String> kHealthItemLabels = {
  'resp': 'Resp. Rate',
  'rhr': 'Resting HR',
  'hrv': 'HRV',
  'spo2': 'SpO₂',
  'temp': 'Temp',
  'sleep': 'Sleep',
};

/// The default Health-Monitor tile order — all visible, row-major in the grid.
const List<HomeSectionCfg> kDefaultHealthLayout = [
  HomeSectionCfg('rhr', true),
  HomeSectionCfg('hrv', true),
  HomeSectionCfg('sleep', true),
  HomeSectionCfg('resp', true),
  HomeSectionCfg('spo2', true),
  HomeSectionCfg('temp', true),
];

/// Labels for the score trio (the hero dials + the big cards).
const Map<String, String> kCardLabels = {
  'recovery': 'Recovery',
  'strain': 'Strain',
  'sleep': 'Sleep',
};

/// The default score-trio order — Recovery · Strain · Sleep. This single order
/// drives BOTH the hero dials and the "Your cards" list so they stay consistent.
const List<HomeSectionCfg> kDefaultCardsLayout = [
  HomeSectionCfg('recovery', true),
  HomeSectionCfg('strain', true),
  HomeSectionCfg('sleep', true),
];

/// Reconcile a persisted layout with the known [defaults]: keep stored
/// order/visibility for ids we still know, drop unknown ids, append missing
/// known ids (with their default visibility).
List<HomeSectionCfg> _reconcile(
    List<HomeSectionCfg> stored, List<HomeSectionCfg> defaults) {
  final known = {for (final c in defaults) c.id};
  final result = <HomeSectionCfg>[
    for (final c in stored)
      if (known.contains(c.id)) c,
  ];
  final present = {for (final c in result) c.id};
  for (final d in defaults) {
    if (!present.contains(d.id)) result.add(d);
  }
  return result;
}

/// Seed a layout from persisted raw maps, falling back to [defaults].
List<HomeSectionCfg> _seed(
    List<Map<String, dynamic>>? raw, List<HomeSectionCfg> defaults) {
  if (raw == null || raw.isEmpty) return List.of(defaults);
  final stored = <HomeSectionCfg>[
    for (final m in raw)
      if (m['id'] is String)
        HomeSectionCfg(m['id'] as String, m['visible'] == true),
  ];
  return _reconcile(stored, defaults);
}

/// Holds an ordered, show/hide configuration, seeded from [Prefs] and persisted
/// (via [save]) on every change. Generic — the score trio and the Health tiles
/// share one implementation.
class SectionLayoutNotifier extends StateNotifier<List<HomeSectionCfg>> {
  final void Function(List<Map<String, dynamic>>) save;
  SectionLayoutNotifier({
    required List<HomeSectionCfg> seed,
    required this.save,
  }) : super(seed);

  /// Reorder among the VISIBLE items only; hidden items keep their relative
  /// order and trail the list.
  void reorderVisible(int oldIndex, int newIndex) {
    var n = newIndex;
    if (n > oldIndex) n -= 1;
    final visible = [for (final c in state) if (c.visible) c];
    final hidden = [for (final c in state) if (!c.visible) c];
    if (oldIndex < 0 || oldIndex >= visible.length) return;
    final item = visible.removeAt(oldIndex);
    visible.insert(n.clamp(0, visible.length), item);
    state = [...visible, ...hidden];
    _persist();
  }

  /// Replace the VISIBLE order with [orderedVisibleIds] (what an in-place drag
  /// just produced), keeping hidden items trailing in their existing order.
  void setVisibleOrder(List<String> orderedVisibleIds) {
    final byId = {for (final c in state) c.id: c};
    final visible = <HomeSectionCfg>[
      for (final id in orderedVisibleIds)
        if (byId.containsKey(id) && byId[id]!.visible) byId[id]!,
    ];
    final seen = {for (final c in visible) c.id};
    final hidden = [for (final c in state) if (!seen.contains(c.id)) c];
    state = [...visible, ...hidden];
    _persist();
  }

  void setVisible(String id, bool v) {
    state = [
      for (final c in state) c.id == id ? c.copyWith(visible: v) : c,
    ];
    _persist();
  }

  void _persist() {
    save([for (final c in state) {'id': c.id, 'visible': c.visible}]);
  }
}

/// The home section order/visibility.
final homeLayoutProvider =
    StateNotifierProvider<SectionLayoutNotifier, List<HomeSectionCfg>>(
  (ref) => SectionLayoutNotifier(
    seed: _seed(Prefs.instance.homeLayout, kDefaultHomeLayout),
    save: Prefs.instance.setHomeLayout,
  ),
);

/// The Health-Monitor tile order/visibility.
final healthLayoutProvider =
    StateNotifierProvider<SectionLayoutNotifier, List<HomeSectionCfg>>(
  (ref) => SectionLayoutNotifier(
    seed: _seed(Prefs.instance.healthLayout, kDefaultHealthLayout),
    save: Prefs.instance.setHealthLayout,
  ),
);

/// The score-trio order — one order for Recovery/Strain/Sleep, shared by the
/// hero dials and the big cards.
final cardsLayoutProvider =
    StateNotifierProvider<SectionLayoutNotifier, List<HomeSectionCfg>>(
  (ref) => SectionLayoutNotifier(
    seed: _seed(Prefs.instance.cardsLayout, kDefaultCardsLayout),
    save: Prefs.instance.setCardsLayout,
  ),
);

/// Whether the home is in arrange mode. Enter by tapping the "Edit" pill; then
/// long-press a dial or health tile and drag it to reorder in place. Normal taps
/// are suppressed while arranging. Session-only; the arrangement persists via
/// the layout providers above.
final homeEditModeProvider = StateProvider<bool>((ref) => false);
