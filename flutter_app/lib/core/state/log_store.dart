import 'package:noop/core/data/db/database.dart';
import 'package:noop/core/state/prefs.dart';

/// Synchronous in-memory mirror of the DB-backed user logs (weight / water /
/// journal), so screens can read them synchronously while the drift store is
/// the durable source of truth. Populated once at startup by [loadFrom]; the
/// log notifiers seed from here and write through to both this cache and the DB.
class LogStore {
  LogStore._();
  static final LogStore instance = LogStore._();

  Map<String, double> weights = {};
  Map<String, double> water = {};
  Map<String, bool> journal = {};

  /// Load the logs from [db] into memory, importing any pre-existing
  /// secure-storage logs (from [Prefs]) into the DB once, on first run.
  Future<void> loadFrom(AppDatabase db) async {
    // One-time migration: seed the DB from the old Prefs blobs if it's empty.
    if ((await db.allWeights()).isEmpty && Prefs.instance.weightLog.isNotEmpty) {
      for (final e in Prefs.instance.weightLog.entries) {
        await db.setWeight(e.key, e.value);
      }
    }
    if ((await db.allWater()).isEmpty && Prefs.instance.waterLog.isNotEmpty) {
      for (final e in Prefs.instance.waterLog.entries) {
        await db.setWater(e.key, e.value);
      }
    }
    weights = await db.allWeights();
    water = await db.allWater();
    journal = await db.allJournalAnswers();
  }
}
