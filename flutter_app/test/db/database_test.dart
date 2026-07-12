import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/data/db/database.dart';

/// Headless drift tests — an in-memory `NativeDatabase` is injected, so no
/// platform channels, no path_provider, no app launch. Proves the schema opens
/// and the nutrition domain round-trips + rolls up correctly.
void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('schema opens and all tables are empty', () async {
    expect(await db.select(db.dailyMetrics).get(), isEmpty);
    expect(await db.select(db.foodItems).get(), isEmpty);
    expect((await db.dayNutrition('2026-07-11')).kcal, 0);
  });

  test('food item upsert replaces on conflict', () async {
    await db.upsertFoodItem(const FoodItemsCompanion(
      id: Value('40822938'),
      name: Value('Cola Zero'),
      kcal100: Value(0.2),
      source: Value('off'),
    ));
    await db.upsertFoodItem(const FoodItemsCompanion(
      id: Value('40822938'),
      name: Value('Coca-Cola Zero'),
      kcal100: Value(0.3),
      source: Value('off'),
    ));
    final items = await db.select(db.foodItems).get();
    expect(items, hasLength(1));
    expect(items.single.name, 'Coca-Cola Zero');
  });

  test('meal + entries roll up into day totals', () async {
    const day = '2026-07-11';
    await db.insertMeal(const MealsCompanion(
      id: Value('m1'),
      day: Value(day),
      type: Value('lunch'),
      createdTs: Value(1000),
    ));
    await db.insertFoodEntry(const FoodEntriesCompanion(
      id: Value('e1'),
      mealId: Value('m1'),
      name: Value('Rice'),
      grams: Value(150),
      kcal: Value(195),
      protein: Value(4),
      carbs: Value(42),
      fat: Value(0.5),
    ));
    await db.insertFoodEntry(const FoodEntriesCompanion(
      id: Value('e2'),
      mealId: Value('m1'),
      name: Value('Chicken'),
      grams: Value(120),
      kcal: Value(198),
      protein: Value(36),
      carbs: Value(0),
      fat: Value(4),
    ));

    final totals = await db.dayNutrition(day);
    expect(totals.entries, 2);
    expect(totals.kcal, closeTo(393, 1e-9));
    expect(totals.protein, closeTo(40, 1e-9));
    expect(totals.carbs, closeTo(42, 1e-9));
    expect(totals.fat, closeTo(4.5, 1e-9));

    // A different day is unaffected.
    expect((await db.dayNutrition('2026-07-10')).kcal, 0);
  });

  test('weight + water logs round-trip and delete', () async {
    await db.setWeight('2026-07-11', 81.5);
    await db.setWeight('2026-07-11', 80.9); // upsert overwrites
    await db.setWater('2026-07-11', 500);
    expect(await db.allWeights(), {'2026-07-11': 80.9});
    expect(await db.allWater(), {'2026-07-11': 500});
    await db.deleteWeight('2026-07-11');
    expect(await db.allWeights(), isEmpty);
  });

  test('journal answers key as day|questionId', () async {
    await db.setJournalAnswer('2026-07-11', 'icebath', true);
    await db.setJournalAnswer('2026-07-11', 'creatine', false);
    await db.setJournalAnswer('2026-07-11', 'icebath', false); // upsert
    final map = await db.allJournalAnswers();
    expect(map['2026-07-11|icebath'], false);
    expect(map['2026-07-11|creatine'], false);
  });

  test('alarms upsert, list ordered by time, and delete', () async {
    await db.upsertAlarm(const AlarmsCompanion(
      id: Value('a1'),
      hour: Value(7),
      minute: Value(30),
      enabled: Value(true),
      status: Value('queued'),
    ));
    await db.upsertAlarm(const AlarmsCompanion(
      id: Value('a2'),
      hour: Value(6),
      minute: Value(0),
      status: Value('idle'),
    ));
    final list = await db.allAlarms();
    expect(list.map((a) => a.id), ['a2', 'a1']); // ordered by hour
    await db.deleteAlarm('a2');
    expect((await db.allAlarms()).single.id, 'a1');
  });

  test('deleting a meal cascades to its entries', () async {
    const day = '2026-07-11';
    await db.insertMeal(const MealsCompanion(
      id: Value('m1'),
      day: Value(day),
      type: Value('dinner'),
      createdTs: Value(2000),
    ));
    await db.insertFoodEntry(const FoodEntriesCompanion(
      id: Value('e1'),
      mealId: Value('m1'),
      name: Value('Pasta'),
      grams: Value(200),
      kcal: Value(300),
    ));
    await (db.delete(db.meals)..where((m) => m.id.equals('m1'))).go();
    expect(await db.select(db.foodEntries).get(), isEmpty,
        reason: 'FK cascade removes orphaned entries');
  });
}
