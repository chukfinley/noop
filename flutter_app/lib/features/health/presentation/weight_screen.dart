import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/state/format.dart';
import 'package:noop/core/state/providers.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/health_charts.dart';
import 'package:noop/shared/widgets/scaffold.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

/// The body-weight tracker screen — the real, user-logged weight (no sensor
/// source). Log today's weight with one tap, or scroll back and tap ANY day to
/// enter/adjust that day's weight retroactively. Every entry persists through
/// [weightLogProvider]; nothing is fabricated.
class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key});

  static Color get _accent => Palette.metricCyan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(daysProvider);
    final log = ref.watch(weightLogProvider);
    final profile = ref.watch(profileProvider);

    // Newest → oldest, each day paired with its logged weight (or null).
    final rows = <(DateTime, double?)>[
      for (var i = days.length - 1; i >= 0; i--)
        (days[i].date, log[isoDay(days[i].date)]),
    ];

    // Carry the last known weight forward for the chart so gaps read flat, not
    // as drops to zero.
    double? lastW;
    final series = <double>[];
    for (final d in days) {
      final v = log[isoDay(d.date)];
      if (v != null) lastW = v;
      series.add(lastW ?? profile.weightKg);
    }
    final window = series.length <= 30 ? series : series.sublist(series.length - 30);

    // Latest logged reading + change since the previous logged reading.
    final logged = [
      for (var i = 0; i < days.length; i++)
        if (log[isoDay(days[i].date)] != null) log[isoDay(days[i].date)]!,
    ];
    final latest = logged.isNotEmpty ? logged.last : null;
    final prev = logged.length >= 2 ? logged[logged.length - 2] : null;
    final today = days.isEmpty ? null : days.last.date;

    return ScreenScaffold(
      title: 'Weight',
      glow: _accent,
      leadingHeader: const CenteredHeader(title: 'Weight'),
      children: [
        _hero(context, ref, latest, prev, profile.weightKg, today),
        if (logged.isNotEmpty)
          NoopCard(
            squircle: true,
            radius: Metrics.cornerHero,
            bordered: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LAST 30 DAYS',
                    style: NoopType.overline.copyWith(
                        color: Palette.textTertiary, letterSpacing: 1.6)),
                const SizedBox(height: Metrics.space16),
                HealthMiniLine(
                  values: window,
                  labels: const [],
                  color: _accent,
                  height: 72,
                ),
              ],
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Every day',
                style: NoopType.title2.copyWith(color: Palette.textPrimary)),
            const SizedBox(height: 2),
            Text('Tap any day to add or edit its weight.',
                style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
            const SizedBox(height: Metrics.space12),
            _DayList(rows: rows),
          ],
        ),
      ],
    );
  }

  Widget _hero(
    BuildContext context,
    WidgetRef ref,
    double? latest,
    double? prev,
    double fallback,
    DateTime? today,
  ) {
    final shown = latest ?? fallback;
    final delta = (latest != null && prev != null) ? latest - prev : null;
    final deltaColor = delta == null
        ? Palette.textTertiary
        : (delta > 0 ? Palette.statusWarning : Palette.statusPositive);
    return NoopCard(
      squircle: true,
      radius: Metrics.cornerHero,
      bordered: false,
      padding: const EdgeInsets.all(Metrics.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(latest != null ? 'CURRENT' : 'NOT LOGGED YET',
              style: NoopType.overline
                  .copyWith(color: Palette.textTertiary, letterSpacing: 1.6)),
          const SizedBox(height: Metrics.space8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(shown.toStringAsFixed(1),
                  style:
                      NoopType.display(52).copyWith(color: Palette.textPrimary)),
              const SizedBox(width: 6),
              Text('kg',
                  style:
                      NoopType.subhead.copyWith(color: Palette.textSecondary)),
              if (delta != null) ...[
                const Spacer(),
                Icon(
                    delta > 0
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 16,
                    color: deltaColor),
                Text('${delta.abs().toStringAsFixed(1)} kg',
                    style: NoopType.subhead.copyWith(
                        color: deltaColor, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          const SizedBox(height: Metrics.space16),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: _accent,
              borderRadius: BorderRadius.circular(Metrics.cornerLarge),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: today == null
                    ? null
                    : () => editWeightForDay(context, ref, today),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                      const SizedBox(width: Metrics.space8),
                      Text("Log today's weight",
                          style: NoopType.subhead.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The scrollable connected list of every day + its weight, newest first — the
/// same tonal-tile grammar as the Settings and metric-detail lists.
class _DayList extends ConsumerWidget {
  final List<(DateTime, double?)> rows;
  const _DayList({required this.rows});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const outer = Radius.circular(Metrics.cornerLarge);
    const inner = Radius.circular(Metrics.cornerBadge);
    final n = rows.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < n; i++) ...[
          _DayRow(
            date: rows[i].$1,
            kg: rows[i].$2,
            label: i == 0
                ? 'Today'
                : (i == 1 ? 'Yesterday' : Fmt.shortDate(rows[i].$1)),
            radius: BorderRadius.vertical(
              top: i == 0 ? outer : inner,
              bottom: i == n - 1 ? outer : inner,
            ),
          ),
          if (i != n - 1) const SizedBox(height: 3),
        ],
      ],
    );
  }
}

class _DayRow extends ConsumerWidget {
  final DateTime date;
  final double? kg;
  final String label;
  final BorderRadius radius;
  const _DayRow({
    required this.date,
    required this.kg,
    required this.label,
    required this.radius,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final has = kg != null;
    return Material(
      color: Palette.fillRaised,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => editWeightForDay(context, ref, date),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Metrics.space16, vertical: Metrics.space14),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: NoopType.body.copyWith(
                        color: has
                            ? Palette.textSecondary
                            : Palette.textTertiary)),
              ),
              if (has)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(kg!.toStringAsFixed(1),
                        style: NoopType.number(22)
                            .copyWith(color: Palette.textPrimary)),
                    const SizedBox(width: 3),
                    Text('kg',
                        style: NoopType.caption
                            .copyWith(color: Palette.textTertiary)),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: Palette.accent),
                    const SizedBox(width: 4),
                    Text('Add',
                        style: NoopType.caption.copyWith(color: Palette.accent)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Open the frosted weight-entry sheet for [day] and persist the result: a
/// value saves to that day, "Remove" clears it. Prefilled with the day's own
/// value when present, else the latest logged weight, else the profile weight.
Future<void> editWeightForDay(
    BuildContext context, WidgetRef ref, DateTime day) async {
  final log = ref.read(weightLogProvider);
  final existing = log[isoDay(day)];
  final initial =
      existing ?? ref.read(weightLogProvider.notifier).latest ??
          ref.read(profileProvider).weightKg;
  final result = await showModalBottomSheet<_WeightResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.14),
    builder: (_) => _WeightEntrySheet(
      day: day,
      initial: initial,
      canRemove: existing != null,
    ),
  );
  if (result == null) return;
  final notifier = ref.read(weightLogProvider.notifier);
  if (result.remove) {
    notifier.clearDay(day);
  } else if (result.kg != null) {
    notifier.setForDay(day, result.kg!);
  }
}

/// The outcome of the entry sheet: a [kg] value to save, or [remove] to clear.
class _WeightResult {
  final double? kg;
  final bool remove;
  const _WeightResult(this.kg, {this.remove = false});
}

/// A frosted, translucent weight-entry sheet for a specific [day] — a big
/// editable value flanked by ± steppers, Save, and (when the day already has a
/// value) a Remove action.
class _WeightEntrySheet extends StatefulWidget {
  final DateTime day;
  final double initial;
  final bool canRemove;
  const _WeightEntrySheet({
    required this.day,
    required this.initial,
    required this.canRemove,
  });

  @override
  State<_WeightEntrySheet> createState() => _WeightEntrySheetState();
}

class _WeightEntrySheetState extends State<_WeightEntrySheet> {
  late double _kg = widget.initial.clamp(20.0, 400.0);
  late final TextEditingController _ctrl =
      TextEditingController(text: _fmt(_kg));

  static String _fmt(double v) => v.toStringAsFixed(1);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _bump(double d) {
    final v = double.tryParse(_ctrl.text.trim().replaceAll(',', '.')) ?? _kg;
    setState(() {
      _kg = (v + d).clamp(20.0, 400.0);
      _ctrl.text = _fmt(_kg);
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    });
  }

  void _save() {
    final v = double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    if (v != null && v >= 20 && v <= 400) {
      Navigator.pop(context, _WeightResult(v));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onGlass = Palette.isLight ? Palette.textPrimary : Colors.white;
    final title = 'Weight · ${Fmt.dayTitle(widget.day)}';
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Metrics.cornerSheet),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(Metrics.cornerSheet),
            ),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: NoopType.headline.copyWith(color: onGlass)),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepBtn(
                        icon: Icons.remove_rounded,
                        onTap: () => _bump(-0.1),
                        onGlass: onGlass),
                    SizedBox(
                      width: 128,
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: NoopType.number(36).copyWith(color: onGlass),
                        cursorColor: Palette.accent,
                        onSubmitted: (_) => _save(),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text('kg',
                          style: NoopType.body
                              .copyWith(color: onGlass.withValues(alpha: 0.6))),
                    ),
                    _StepBtn(
                        icon: Icons.add_rounded,
                        onTap: () => _bump(0.1),
                        onGlass: onGlass),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Palette.accent,
                    borderRadius: BorderRadius.circular(Metrics.cornerLarge),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _save,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text('Save',
                              style: NoopType.subhead.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.canRemove) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(
                        context, const _WeightResult(null, remove: true)),
                    child: Text('Remove this day',
                        style: NoopType.footnote.copyWith(
                            color: onGlass.withValues(alpha: 0.7))),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A round translucent ± stepper (glass-on-glass, no border).
class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color onGlass;
  const _StepBtn(
      {required this.icon, required this.onTap, required this.onGlass});

  @override
  Widget build(BuildContext context) => Material(
        color: onGlass.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: onGlass),
          ),
        ),
      );
}
