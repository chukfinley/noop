import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/db/database.dart';
import 'package:noop/core/data/nutrition/ai_food_client.dart';
import 'package:noop/core/data/nutrition/off_client.dart';
import 'package:noop/core/state/providers.dart';

/// The meal slots a food entry can be logged under.
enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeLabel on MealType {
  String get label => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snack',
      };
  String get id => name;
}

/// The ISO `yyyy-MM-dd` key for the currently-selected day (drives the reads).
/// Falls back to today when there are no synced days yet (empty live state).
final selectedIsoDayProvider = Provider<String>((ref) =>
    isoDay(ref.watch(selectedDayProvider)?.date ?? DateTime.now()));

/// Rolled-up nutrition totals for the selected day.
final dayNutritionProvider = StreamProvider<DayNutrition>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchDayNutrition(ref.watch(selectedIsoDayProvider));
});

/// The selected day's meals.
final dayMealsProvider = StreamProvider<List<Meal>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchMealsForDay(ref.watch(selectedIsoDayProvider));
});

/// The selected day's food entries (flat, across all meals).
final dayEntriesProvider = StreamProvider<List<FoodEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchEntriesForDay(ref.watch(selectedIsoDayProvider));
});

/// Write-side service for the nutrition domain. Deterministic ids keep one meal
/// per (day, type); entries snapshot their macros at log time so later OFF/AI
/// changes never rewrite history.
class NutritionService {
  NutritionService(this._db);
  final AppDatabase _db;

  /// A monotonic-ish suffix for entry ids without a clock dependency in the
  /// hot path — the caller passes `nowMicros` (DateTime.now in the app).
  static String _mealId(String day, MealType type) => '$day|${type.id}';

  Future<void> _ensureMeal(String day, MealType type, int nowMicros) async {
    // Idempotent — insertMeal ignores a conflict, so one meal per (day, type).
    await _db.insertMeal(MealsCompanion.insert(
      id: _mealId(day, type),
      day: day,
      type: type.id,
      createdTs: nowMicros ~/ 1000000,
    ));
  }

  Future<void> _addEntry(FoodEntriesCompanion entry) =>
      _db.insertFoodEntry(entry);

  /// Log an OFF product at [grams] grams into [type] on [day]. Macros are scaled
  /// from the product's per-100 g values and snapshotted.
  Future<void> logProduct(
    String day,
    MealType type,
    OffProduct p,
    double grams, {
    required int nowMicros,
  }) async {
    // Cache the product for reuse / later reference.
    await _db.upsertFoodItem(FoodItemsCompanion.insert(
      id: p.barcode.isEmpty ? 'manual-$nowMicros' : p.barcode,
      name: p.name,
      brand: Value(p.brand),
      imageUrl: Value(p.imageUrl),
      servingSizeRaw: Value(p.servingSizeRaw),
      servingGrams: Value(p.servingGrams),
      kcal100: Value(p.kcal100),
      carbs100: Value(p.carbs100),
      protein100: Value(p.protein100),
      fat100: Value(p.fat100),
      sugar100: Value(p.sugar100),
      fiber100: Value(p.fiber100),
      salt100: Value(p.salt100),
      source: const Value('off'),
    ));
    final f = grams / 100.0;
    await _ensureMeal(day, type, nowMicros);
    await _addEntry(FoodEntriesCompanion.insert(
      id: '${_mealId(day, type)}|$nowMicros',
      mealId: _mealId(day, type),
      name: p.name,
      grams: grams,
      kcal: (p.kcal100 ?? 0) * f,
      carbs: Value((p.carbs100 ?? 0) * f),
      protein: Value((p.protein100 ?? 0) * f),
      fat: Value((p.fat100 ?? 0) * f),
      foodItemId: Value(p.barcode.isEmpty ? null : p.barcode),
    ));
  }

  /// Log a free-text manual entry with directly-entered macros.
  Future<void> logManual(
    String day,
    MealType type, {
    required String name,
    required double grams,
    required double kcal,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    required int nowMicros,
  }) async {
    await _ensureMeal(day, type, nowMicros);
    await _addEntry(FoodEntriesCompanion.insert(
      id: '${_mealId(day, type)}|$nowMicros',
      mealId: _mealId(day, type),
      name: name,
      grams: grams,
      kcal: kcal,
      carbs: Value(carbs),
      protein: Value(protein),
      fat: Value(fat),
    ));
  }

  /// Log every item the AI identified in a photo as its own entry.
  Future<void> logAiEstimate(
    String day,
    MealType type,
    AiFoodEstimate est, {
    required int nowMicros,
  }) async {
    await _ensureMeal(day, type, nowMicros);
    var i = 0;
    for (final item in est.items) {
      await _addEntry(FoodEntriesCompanion.insert(
        id: '${_mealId(day, type)}|$nowMicros|${i++}',
        mealId: _mealId(day, type),
        name: item.name.isEmpty ? est.dish : item.name,
        grams: item.grams,
        kcal: item.kcal,
        carbs: Value(item.carbs),
        protein: Value(item.protein),
        fat: Value(item.fat),
      ));
    }
  }

  Future<void> deleteEntry(String id) => _db.deleteFoodEntry(id);
}

final nutritionServiceProvider = Provider<NutritionService>(
    (ref) => NutritionService(ref.watch(databaseProvider)));
