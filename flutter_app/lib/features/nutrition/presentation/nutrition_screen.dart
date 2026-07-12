import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/db/database.dart';
import 'package:noop/core/state/format.dart';
import 'package:noop/features/nutrition/presentation/add_food_screen.dart';
import 'package:noop/features/nutrition/state/nutrition.dart';
import 'package:noop/shared/widgets/behavior.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/common.dart';
import 'package:noop/shared/widgets/scaffold.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

/// The Nutrition day screen — a calorie + macro summary for the selected day and
/// the day's logged meals, with an entry point to add food (OFF search / manual
/// / AI photo). All data lives in the local drift store.
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(dayNutritionProvider);
    final entries = ref.watch(dayEntriesProvider).valueOrNull ?? const [];

    return ScreenScaffold(
      title: 'Nutrition',
      glow: Palette.effortColor,
      children: [
        _SummaryCard(totals: totals.valueOrNull ?? DayNutrition.empty),
        const SizedBox(height: Metrics.space16),
        for (final type in MealType.values) ...[
          _MealSection(
            type: type,
            entries: entries
                .where((e) => e.mealId.endsWith('|${type.id}'))
                .toList(),
          ),
          const SizedBox(height: Metrics.space12),
        ],
        const SizedBox(height: Metrics.space8),
        NoopButton(
          'Add food',
          icon: Icons.add_rounded,
          onPressed: () =>
              Navigator.of(context).push(noopRoute(const AddFoodScreen())),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final DayNutrition totals;
  const _SummaryCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    return NoopCard(
      accent: Palette.effortColor,
      padding: const EdgeInsets.all(Metrics.space20),
      child: Column(
        children: [
          Text(totals.kcal.round().toString(),
              style: NoopType.number(44).copyWith(color: Palette.textPrimary)),
          Text('kcal today',
              style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
          const SizedBox(height: Metrics.space16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Macro('Protein', totals.protein, Palette.metricRose),
              _Macro('Carbs', totals.carbs, Palette.metricCyan),
              _Macro('Fat', totals.fat, Palette.metricPurple),
            ],
          ),
        ],
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  final String label;
  final double grams;
  final Color color;
  const _Macro(this.label, this.grams, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('${grams.round()} g',
            style: NoopType.number(20).copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: NoopType.caption.copyWith(color: Palette.textTertiary)),
      ],
    );
  }
}

class _MealSection extends ConsumerWidget {
  final MealType type;
  final List<FoodEntry> entries;
  const _MealSection({required this.type, required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kcal = entries.fold<double>(0, (a, e) => a + e.kcal);
    return SectionCard(
      title: type.label,
      accent: Palette.effortColor,
      trailing: Text('${kcal.round()} kcal',
          style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
      child: entries.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: Metrics.space8),
              child: Text('Nothing logged',
                  style:
                      NoopType.body.copyWith(color: Palette.textTertiary)),
            )
          : Column(
              children: [
                for (final e in entries)
                  _EntryRow(
                    entry: e,
                    onDelete: () => ref
                        .read(nutritionServiceProvider)
                        .deleteEntry(e.id),
                  ),
              ],
            ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final FoodEntry entry;
  final VoidCallback onDelete;
  const _EntryRow({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Metrics.space8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        NoopType.body.copyWith(color: Palette.textPrimary)),
                Text('${entry.grams.round()} g · ${Fmt.intComma(entry.kcal.round())} kcal',
                    style: NoopType.caption
                        .copyWith(color: Palette.textTertiary)),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded,
                size: 18, color: Palette.textTertiary),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
