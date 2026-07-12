import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/db/database.dart' show AppDatabase;
import 'package:noop/core/state/log_store.dart';
import 'package:noop/core/state/providers.dart' show databaseProvider;

/// Which part of the day a logbook behaviour belongs to — drives the section
/// grouping on the logbook screen (STATUS / DAYTIME / NIGHTTIME).
enum JournalSection { status, daytime, nighttime }

extension JournalSectionLabel on JournalSection {
  String get label => switch (this) {
        JournalSection.status => 'STATUS',
        JournalSection.daytime => 'DAYTIME',
        JournalSection.nighttime => 'NIGHTTIME',
      };
}

/// A single trackable behaviour. [name] is the short title shown in the picker;
/// [question] is the yes/no prompt shown on the logbook. [group] is the picker
/// category tab it lives under.
class Behavior {
  final String id;
  final String name;
  final String question;
  final JournalSection section;
  final String group;
  const Behavior({
    required this.id,
    required this.name,
    required this.question,
    required this.section,
    required this.group,
  });
}

/// Picker category tabs. TEMP — the real WHOOP taxonomy lands later.
const kJournalGroups = <String>[
  'All',
  'Medication',
  'Recovery',
  'Sleep',
  'Nutrition',
  'Lifestyle',
];

/// TEMP behaviour catalogue (placeholder data — real WHOOP dump comes later).
const kBehaviorCatalog = <Behavior>[
  Behavior(id: 'sick', name: 'Illness', question: 'Felt sick?', section: JournalSection.status, group: 'Lifestyle'),
  Behavior(id: 'breathwork', name: 'Breathwork', question: 'Practised breathwork?', section: JournalSection.daytime, group: 'Recovery'),
  Behavior(id: 'icebath', name: 'Ice bath', question: 'Took an ice bath?', section: JournalSection.daytime, group: 'Recovery'),
  Behavior(id: 'coldshower', name: 'Cold shower', question: 'Took a cold shower?', section: JournalSection.daytime, group: 'Recovery'),
  Behavior(id: 'hydration', name: 'Hydration', question: 'Drank enough water?', section: JournalSection.daytime, group: 'Nutrition'),
  Behavior(id: 'meals', name: 'Meals', question: 'Ate all your meals during the day?', section: JournalSection.daytime, group: 'Nutrition'),
  Behavior(id: 'creatine', name: 'Creatine', question: 'Took creatine?', section: JournalSection.daytime, group: 'Medication'),
  Behavior(id: 'magnesium', name: 'Magnesium', question: 'Took magnesium?', section: JournalSection.daytime, group: 'Medication'),
  Behavior(id: 'masturbated', name: 'Masturbation', question: 'Masturbated?', section: JournalSection.daytime, group: 'Lifestyle'),
  Behavior(id: 'darkroom', name: 'Dark room', question: 'Slept in a dark room?', section: JournalSection.nighttime, group: 'Sleep'),
  Behavior(id: 'ownbed', name: 'Own bed', question: 'Slept in your usual bed?', section: JournalSection.nighttime, group: 'Sleep'),
  Behavior(id: 'latefood', name: 'Late meal', question: 'Ate shortly before bed?', section: JournalSection.nighttime, group: 'Nutrition'),
  Behavior(id: 'readbed', name: 'Read in bed', question: 'Read in bed (no screen)?', section: JournalSection.nighttime, group: 'Sleep'),
  Behavior(id: 'nightmare', name: 'Nightmare', question: 'Had a bad dream?', section: JournalSection.nighttime, group: 'Sleep'),
  Behavior(id: 'bluelight', name: 'Blue-light glasses', question: 'Wore blue-light glasses before bed?', section: JournalSection.nighttime, group: 'Sleep'),
];

/// Which behaviours the user has chosen to track. Defaults to the whole
/// catalogue. In-memory for now; persistence lands with the real data.
class SelectedBehaviors extends StateNotifier<Set<String>> {
  SelectedBehaviors() : super(kBehaviorCatalog.map((b) => b.id).toSet());

  void toggle(String id) {
    final next = {...state};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = next;
  }
}

final selectedBehaviorsProvider =
    StateNotifierProvider<SelectedBehaviors, Set<String>>((ref) => SelectedBehaviors());

/// Yes/no answers keyed by `yyyy-MM-dd|behaviorId`. true = ✓, false = ✕,
/// absent = unanswered. Drift-backed (seeded from [LogStore]).
class JournalAnswers extends StateNotifier<Map<String, bool>> {
  JournalAnswers(this._db) : super(Map.of(LogStore.instance.journal));

  final AppDatabase _db;

  void set(String key, bool yes) {
    state = {...state, key: yes};
    LogStore.instance.journal[key] = yes;
    final i = key.indexOf('|');
    if (i > 0) {
      _db.setJournalAnswer(key.substring(0, i), key.substring(i + 1), yes);
    }
  }
}

final journalAnswersProvider =
    StateNotifierProvider<JournalAnswers, Map<String, bool>>(
        (ref) => JournalAnswers(ref.watch(databaseProvider)));

/// The day the logbook is currently showing.
final journalDayProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
});

String journalKey(DateTime day, String id) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}|$id';
