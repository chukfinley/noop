import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

/// A single logged body-weight reading.
class WeightEntry {
  final DateTime day; // date-only (local midnight)
  final double kg;
  const WeightEntry(this.day, this.kg);

  String get key =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}

/// Owns the body-weight log: a list of entries sorted oldest → newest, seeded
/// from [Prefs] and written through on every change.
class WeightLog extends StateNotifier<List<WeightEntry>> {
  WeightLog() : super(_seed());

  static List<WeightEntry> _seed() {
    final entries = Prefs.instance.weightLog.entries
        .map((e) => WeightEntry(DateTime.parse(e.key), e.value))
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    return entries;
  }

  /// Latest logged weight, or null if the log is empty.
  WeightEntry? get latest => state.isEmpty ? null : state.last;

  /// Log [kg] for [day] (date-only). Overwrites an existing entry for that day.
  void log(double kg, {DateTime? day}) {
    final d = _dateOnly(day ?? _todayLocal());
    final key = WeightEntry(d, kg).key;
    final map = {for (final e in state) e.key: e.kg}..[key] = kg;
    Prefs.instance.setWeightLog(map);
    final next = map.entries
        .map((e) => WeightEntry(DateTime.parse(e.key), e.value))
        .toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    state = next;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // Isolated so the forbidden argless DateTime.now() stays in one guarded spot.
  static DateTime _todayLocal() => DateTime.now();
}

final weightLogProvider =
    StateNotifierProvider<WeightLog, List<WeightEntry>>((ref) => WeightLog());
