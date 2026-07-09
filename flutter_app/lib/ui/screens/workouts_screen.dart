import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../state/format.dart';
import '../../state/providers.dart';
import '../components/scaffold.dart';
import '../components/cards.dart';
import '../components/common.dart';
import '../components/gauge.dart';
import '../components/tiles.dart';
import '../theme/metrics.dart';
import '../theme/palette.dart';

/// Workouts screen — an effort hero ring, summary metrics, a per-sport
/// breakdown, aggregate time-in-zones, and the full session log. Each session
/// opens a detail bottom sheet. Mirrors TodayScreen in style.
class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider);

    if (workouts.isEmpty) {
      return ScreenScaffold(
        title: 'Workouts',
        subtitle: 'No sessions yet',
        children: [
          NoopCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Metrics.space24),
              child: Center(
                child: Text('No workouts yet',
                    style: NoopType.body
                        .copyWith(color: Palette.textTertiary)),
              ),
            ),
          ),
        ],
      );
    }

    final totalDuration = workouts.fold<Duration>(
        Duration.zero, (sum, w) => sum + w.duration);
    final totalCalories = workouts.fold<int>(0, (sum, w) => sum + w.calories);
    final avgEffort =
        workouts.fold<double>(0, (sum, w) => sum + w.effort) / workouts.length;

    return ScreenScaffold(
      title: 'Workouts',
      subtitle: '${workouts.length} sessions',
      children: [
        _EffortHero(
          workouts: workouts,
          avgEffort: avgEffort,
          totalDuration: totalDuration,
          totalCalories: totalCalories,
        ),
        SectionHeader('Summary'),
        _Summary(
          count: workouts.length,
          totalDuration: totalDuration,
          avgEffort: avgEffort,
          totalCalories: totalCalories,
        ),
        SectionHeader('By sport'),
        _BySport(workouts: workouts),
        _ZonesCard(workouts: workouts),
        SectionHeader('All sessions'),
        for (final w in workouts) _SessionRow(workout: w),
      ],
    );
  }
}

// ── Sport icon mapping ──────────────────────────────────────────────────────

IconData _sportIcon(String sport) {
  switch (sport.toLowerCase()) {
    case 'running':
      return Icons.directions_run;
    case 'cycling':
      return Icons.pedal_bike;
    case 'strength':
      return Icons.fitness_center;
    case 'hiit':
      return Icons.bolt;
    case 'yoga':
      return Icons.self_improvement;
    case 'swimming':
      return Icons.pool;
    case 'walking':
      return Icons.directions_walk;
    default:
      return Icons.sports;
  }
}

// ── Effort hero ─────────────────────────────────────────────────────────────

class _EffortHero extends StatelessWidget {
  final List<Workout> workouts;
  final double avgEffort;
  final Duration totalDuration;
  final int totalCalories;
  const _EffortHero({
    required this.workouts,
    required this.avgEffort,
    required this.totalDuration,
    required this.totalCalories,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Typical effort',
      accent: Palette.effortColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RingGauge(
            fraction: avgEffort / 100,
            stops: DomainTheme.effort.gradientStops,
            size: 120,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(avgEffort.round().toString(),
                    style: NoopType.display(38)
                        .copyWith(color: Palette.textPrimary)),
                Text('effort',
                    style: NoopType.overline
                        .copyWith(color: Palette.effortColor)),
              ],
            ),
          ),
          const SizedBox(width: Metrics.space20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroStat('Sessions', workouts.length.toString(),
                    Palette.effortColor),
                const SizedBox(height: Metrics.space12),
                _heroStat('Total time', Fmt.hm(totalDuration),
                    Palette.metricCyan),
                const SizedBox(height: Metrics.space12),
                _heroStat('Calories', Fmt.intComma(totalCalories),
                    Palette.stressColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(label,
              style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
        ),
        Text(value, style: NoopType.number(20).copyWith(color: color)),
      ],
    );
  }
}

// ── Summary grid ────────────────────────────────────────────────────────────

class _Summary extends StatelessWidget {
  final int count;
  final Duration totalDuration;
  final double avgEffort;
  final int totalCalories;
  const _Summary({
    required this.count,
    required this.totalDuration,
    required this.avgEffort,
    required this.totalCalories,
  });

  @override
  Widget build(BuildContext context) {
    return MetricGrid([
      MetricTile(
        label: 'Sessions',
        value: count.toString(),
        accent: Palette.effortColor,
      ),
      MetricTile(
        label: 'Total time',
        value: Fmt.hm(totalDuration),
        accent: Palette.metricCyan,
      ),
      MetricTile(
        label: 'Avg effort',
        value: avgEffort.toStringAsFixed(1),
        accent: Palette.statusWarning,
      ),
      MetricTile(
        label: 'Calories',
        value: Fmt.intComma(totalCalories),
        unit: 'kcal',
        accent: Palette.stressColor,
      ),
    ]);
  }
}

// ── By sport ────────────────────────────────────────────────────────────────

class _BySport extends StatelessWidget {
  final List<Workout> workouts;
  const _BySport({required this.workouts});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Workout>>{};
    for (final w in workouts) {
      groups.putIfAbsent(w.sport, () => <Workout>[]).add(w);
    }
    final sports = groups.keys.toList();

    return Column(
      children: [
        for (var i = 0; i < sports.length; i++) ...[
          _sportRow(sports[i], groups[sports[i]]!),
          if (i != sports.length - 1) const SizedBox(height: Metrics.gap),
        ],
      ],
    );
  }

  Widget _sportRow(String sport, List<Workout> group) {
    final total = group.fold<Duration>(Duration.zero, (s, w) => s + w.duration);
    final avgEffort =
        group.fold<double>(0, (s, w) => s + w.effort) / group.length;
    return NoopCard(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Palette.effortColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Metrics.cornerSm),
            ),
            child: Icon(_sportIcon(sport),
                size: 18, color: Palette.effortColor),
          ),
          const SizedBox(width: Metrics.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sport,
                    style: NoopType.headline
                        .copyWith(color: Palette.textPrimary)),
                Text('${group.length} · ${Fmt.hm(total)}',
                    style: NoopType.caption
                        .copyWith(color: Palette.textTertiary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(avgEffort.toStringAsFixed(1),
                  style:
                      NoopType.number(18).copyWith(color: Palette.effortColor)),
              Text('avg effort',
                  style:
                      NoopType.footnote.copyWith(color: Palette.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Time in zones ───────────────────────────────────────────────────────────

List<Duration> _aggregateZones(List<Workout> workouts) {
  final totals = List<Duration>.filled(5, Duration.zero);
  for (final w in workouts) {
    for (var z = 0; z < 5 && z < w.zoneDurations.length; z++) {
      totals[z] += w.zoneDurations[z];
    }
  }
  return totals;
}

class _ZonesCard extends StatelessWidget {
  final List<Workout> workouts;
  const _ZonesCard({required this.workouts});

  @override
  Widget build(BuildContext context) {
    final zones = _aggregateZones(workouts);
    return SectionCard(
      title: 'Time in zones',
      accent: Palette.effortColor,
      child: _ZoneBars(zones: zones),
    );
  }
}

class _ZoneBars extends StatelessWidget {
  final List<Duration> zones;
  const _ZoneBars({required this.zones});

  @override
  Widget build(BuildContext context) {
    final maxMinutes = zones
        .map((d) => d.inMinutes)
        .fold<int>(0, (m, v) => v > m ? v : m);
    return Column(
      children: [
        for (var i = 0; i < 5; i++) ...[
          _ZoneRow(
            zone: i + 1,
            duration: zones[i],
            maxMinutes: maxMinutes,
          ),
          if (i != 4) const SizedBox(height: Metrics.space12),
        ],
      ],
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final int zone;
  final Duration duration;
  final int maxMinutes;
  const _ZoneRow({
    required this.zone,
    required this.duration,
    required this.maxMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final color = Palette.hrZoneColor(zone);
    final minutes = duration.inMinutes;
    final fraction = maxMinutes == 0 ? 0.0 : minutes / maxMinutes;
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text('Z$zone',
              style: NoopType.captionNumber.copyWith(color: color)),
        ),
        const SizedBox(width: Metrics.space8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Metrics.cornerPill),
            child: Container(
              height: Metrics.segmentBarHeight,
              color: Palette.surfaceInset,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(Metrics.cornerPill),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Metrics.space12),
        SizedBox(
          width: 52,
          child: Text('${minutes}m',
              textAlign: TextAlign.right,
              style: NoopType.captionNumber
                  .copyWith(color: Palette.textSecondary)),
        ),
      ],
    );
  }
}

// ── Session row ─────────────────────────────────────────────────────────────

class _SessionRow extends StatelessWidget {
  final Workout workout;
  const _SessionRow({required this.workout});

  @override
  Widget build(BuildContext context) {
    final w = workout;
    return Padding(
      padding: const EdgeInsets.only(top: Metrics.gap),
      child: NoopCard(
        accent: Palette.effortColor,
        onTap: () => _showDetail(context, w),
        child: Row(
          children: [
            Icon(_sportIcon(w.sport), color: Palette.effortColor, size: 22),
            const SizedBox(width: Metrics.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.sport,
                      style: NoopType.headline
                          .copyWith(color: Palette.textPrimary)),
                  Text(
                      '${Fmt.shortDate(w.start)} · ${Fmt.hm(w.duration)} · '
                      '${w.calories} kcal · ${w.avgHr.round()} bpm',
                      style: NoopType.caption
                          .copyWith(color: Palette.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: Metrics.space8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(w.effort.round().toString(),
                    style: NoopType.number(20)
                        .copyWith(color: Palette.effortColor)),
                Text('effort',
                    style: NoopType.footnote
                        .copyWith(color: Palette.textTertiary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showDetail(BuildContext context, Workout w) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Palette.surfaceRaised,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Metrics.cardRadius)),
    ),
    builder: (context) => _WorkoutDetailSheet(workout: w),
  );
}

class _WorkoutDetailSheet extends StatelessWidget {
  final Workout workout;
  const _WorkoutDetailSheet({required this.workout});

  @override
  Widget build(BuildContext context) {
    final w = workout;
    final media = MediaQuery.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: Metrics.screenPadding,
          right: Metrics.screenPadding,
          top: Metrics.space16,
          bottom: media.padding.bottom + Metrics.space24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Palette.hairlineStrong,
                  borderRadius: BorderRadius.circular(Metrics.cornerPill),
                ),
              ),
            ),
            const SizedBox(height: Metrics.space20),
            Row(
              children: [
                Icon(_sportIcon(w.sport),
                    color: Palette.effortColor, size: 26),
                const SizedBox(width: Metrics.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.sport,
                          style: NoopType.title2
                              .copyWith(color: Palette.textPrimary)),
                      Text('${Fmt.shortDate(w.start)} · ${Fmt.clock(w.start)}',
                          style: NoopType.caption
                              .copyWith(color: Palette.textTertiary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(w.effort.round().toString(),
                        style: NoopType.number(24)
                            .copyWith(color: Palette.effortColor)),
                    Text('effort',
                        style: NoopType.footnote
                            .copyWith(color: Palette.textTertiary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Metrics.space20),
            MetricGrid([
              MetricTile(
                label: 'Duration',
                value: Fmt.hm(w.duration),
                accent: Palette.metricCyan,
              ),
              MetricTile(
                label: 'Calories',
                value: Fmt.intComma(w.calories),
                unit: 'kcal',
                accent: Palette.stressColor,
              ),
              MetricTile(
                label: 'Avg HR',
                value: w.avgHr.round().toString(),
                unit: 'bpm',
                accent: Palette.metricRose,
              ),
              MetricTile(
                label: 'Max HR',
                value: w.maxHr.round().toString(),
                unit: 'bpm',
                accent: Palette.metricPurple,
              ),
              if (w.distanceKm != null)
                MetricTile(
                  label: 'Distance',
                  value: Fmt.km(w.distanceKm!),
                  accent: Palette.chargeColor,
                ),
            ]),
            const SizedBox(height: Metrics.space24),
            Overline('Time in zones'),
            const SizedBox(height: Metrics.space12),
            _ZoneBars(zones: w.zoneDurations),
          ],
        ),
      ),
    );
  }
}
