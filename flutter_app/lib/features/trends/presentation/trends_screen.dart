import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/models.dart';
import 'package:noop/core/state/providers.dart';
import 'package:noop/shared/widgets/behavior.dart';
import 'package:noop/shared/widgets/coming_soon.dart';
import 'package:noop/shared/widgets/health_charts.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/features/metrics/presentation/metric_trend_screen.dart';

/// Trends — a Google-Health-style grid of metric cards. Each card shows the
/// current value, a mini chart and a status chip, and opens a detail screen.
class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  static String _grp(num n) {
    final s = n.round().abs().toString();
    final b = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  static String _fmt1(double kg) =>
      kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(daysProvider);
    final profile = ref.watch(profileProvider);

    final win = days.length <= 14 ? days : days.sublist(days.length - 14);
    final dates = win.map((d) => d.date).toList();
    List<double> field(double Function(DayRecord) f) => win.map(f).toList();
    final last7 = win.length <= 7 ? win.length : 7;

    double sumLast(List<double> v, int n) {
      final s = v.length <= n ? v : v.sublist(v.length - n);
      return s.fold(0.0, (a, b) => a + b);
    }

    final metrics = <TrendMetric>[
      // Weight is a manual log with no real source wired up yet.
      TrendMetric(
        title: 'Weight',
        unit: 'kg',
        color: Palette.metricCyan,
        chart: TrendChart.line,
        daily: const [],
        dates: const [],
        valueText: '',
        status: '',
        fmt: _fmt1,
        comingSoon: true,
      ),
      TrendMetric(
        title: 'Calories burned',
        unit: 'kcal',
        color: Palette.metricCyan,
        chart: TrendChart.bars,
        daily: field((d) => d.calories.toDouble()),
        dates: dates,
        valueText: _grp(win.last.calories),
        status:
            'Weekly total: ${_grp(sumLast(field((d) => d.calories.toDouble()), 7).round())}',
        fmt: (v) => _grp(v),
        targetLow: 2000,
        targetHigh: 2600,
        comingSoon: true,
      ),
      TrendMetric(
        title: 'Recovery',
        unit: '%',
        color: Palette.chargeColor,
        chart: TrendChart.line,
        daily: field((d) => d.charge),
        dates: dates,
        valueText: win.last.charge.round().toString(),
        status: Palette.recoveryState(win.last.charge),
        fmt: (v) => v.round().toString(),
        targetLow: 70,
        targetHigh: 100,
      ),
      TrendMetric(
        title: 'Sleep',
        unit: '%',
        color: Palette.restColor,
        chart: TrendChart.line,
        daily: field((d) => d.rest),
        dates: dates,
        valueText: win.last.rest.round().toString(),
        status: win.last.rest < 70 ? 'Below target' : 'On target',
        fmt: (v) => v.round().toString(),
        targetLow: 70,
        targetHigh: 100,
      ),
      TrendMetric(
        title: 'HRV',
        unit: 'ms',
        color: Palette.metricPurple,
        chart: TrendChart.line,
        daily: field((d) => d.hrv),
        dates: dates,
        valueText: win.last.hrv.round().toString(),
        status: 'Last night',
        fmt: (v) => v.round().toString(),
      ),
      TrendMetric(
        title: 'Resting HR',
        unit: 'bpm',
        color: Palette.metricRose,
        chart: TrendChart.line,
        daily: field((d) => d.rhr),
        dates: dates,
        valueText: win.last.rhr.round().toString(),
        status: 'Last night',
        fmt: (v) => v.round().toString(),
      ),
      TrendMetric(
        title: 'Steps',
        unit: '',
        color: Palette.metricPurple,
        chart: TrendChart.bars,
        daily: field((d) => d.steps.toDouble()),
        dates: dates,
        valueText: _grp(win.last.steps),
        status:
            'Weekly total: ${_grp(sumLast(field((d) => d.steps.toDouble()), 7).round())}',
        fmt: (v) => _grp(v),
        targetLow: 8000,
        targetHigh: 12000,
        comingSoon: true,
      ),
      TrendMetric(
        title: 'Stress',
        unit: '',
        color: Palette.stressColor,
        chart: TrendChart.line,
        daily: field((d) => d.stress),
        dates: dates,
        valueText: win.last.stress.round().toString(),
        status: win.last.stress < 33
            ? 'Low'
            : (win.last.stress < 66 ? 'Moderate' : 'High'),
        fmt: (v) => v.round().toString(),
      ),
      // ── Merged from the old Health screen: the daily vitals ────────────────
      TrendMetric(
        title: 'Respiratory rate',
        unit: 'rpm',
        color: Palette.accent,
        chart: TrendChart.line,
        daily: field((d) => d.respiratoryRate),
        dates: dates,
        valueText: win.last.respiratoryRate.toStringAsFixed(1),
        status: 'Last night',
        fmt: (v) => v.toStringAsFixed(1),
        comingSoon: true,
      ),
      TrendMetric(
        title: 'Blood oxygen',
        unit: '%',
        color: Palette.metricCyan,
        chart: TrendChart.line,
        daily: field((d) => d.spo2),
        dates: dates,
        valueText: win.last.spo2.round().toString(),
        status: 'Last night',
        fmt: (v) => v.round().toString(),
        comingSoon: true,
      ),
      TrendMetric(
        title: 'Fitness age',
        unit: 'yr',
        color: Palette.metricPurple,
        chart: TrendChart.line,
        daily: field((d) => d.fitnessAge.toDouble()),
        dates: dates,
        valueText: win.last.fitnessAge.toString(),
        status: 'Estimated',
        fmt: (v) => v.round().toString(),
        comingSoon: true,
      ),
    ];

    final labels7 =
        dates.sublist(dates.length - last7).map(ghWeekdayInitial).toList();

    // No nested Scaffold: the app shell has extendBody + a floating frosted nav
    // bar, so the page must fill the whole body (content scrolling *under* the
    // bar) for its transparency to read. A solid inner Scaffold broke that.
    return Container(
      color: Palette.surfaceBase,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(initial: profile.name.isEmpty ? 'A' : profile.name[0]),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text('Key metrics',
                            style: NoopType.title1
                                .copyWith(color: Palette.textPrimary)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Customise',
                            style: NoopType.body.copyWith(color: Palette.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < metrics.length; i += 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                                child: _MetricCard(
                                    metric: metrics[i],
                                    labels: labels7,
                                    n: last7)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: i + 1 < metrics.length
                                  ? _MetricCard(
                                      metric: metrics[i + 1],
                                      labels: labels7,
                                      n: last7)
                                  : const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String initial;
  const _Header({required this.initial});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Icon(Icons.devices_other_rounded,
                color: Palette.textSecondary, size: 24),
            Expanded(
              child: Center(
                child: Text('Trends',
                    style: NoopType.title2.copyWith(color: Palette.textPrimary)),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Palette.surfaceRaised,
                shape: BoxShape.circle,
              ),
              child: Text(initial.toUpperCase(),
                  style: NoopType.subhead.copyWith(color: Palette.textSecondary)),
            ),
          ],
        ),
      );
}

class _MetricCard extends StatelessWidget {
  final TrendMetric metric;
  final List<String> labels;
  final int n;
  const _MetricCard(
      {required this.metric, required this.labels, required this.n});

  static IconData _iconFor(String title) => switch (title) {
        'Weight' => Icons.monitor_weight_rounded,
        'Steps' => Icons.directions_walk_rounded,
        'Calories burned' => Icons.local_fire_department_rounded,
        'Fitness age' => Icons.cake_rounded,
        _ => Icons.hourglass_empty_rounded,
      };

  @override
  Widget build(BuildContext context) {
    // No real source yet — drop a matching-radius placeholder into the grid.
    if (metric.comingSoon) {
      return ComingSoonTile(
        label: metric.title,
        icon: _iconFor(metric.title),
        radius: 28,
      );
    }
    final values = metric.lastN(n);
    // M3-Expressive: a tonal tinted surface, large 28dp rounding, compact.
    final fill = Color.alphaBlend(
        metric.color.withValues(alpha: 0.10), Palette.surfaceRaised);
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context)
            .push(noopRoute(MetricTrendScreen(metric: metric))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(metric.title,
                  style: NoopType.footnote
                      .copyWith(color: Palette.textSecondary)),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(metric.valueText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NoopType.number(22)
                            .copyWith(color: Palette.textPrimary)),
                  ),
                  if (metric.unit.isNotEmpty) ...[
                    const SizedBox(width: 3),
                    Text(metric.unit,
                        style: NoopType.caption
                            .copyWith(color: Palette.textTertiary)),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              metric.chart == TrendChart.bars
                  ? HealthMiniBars(
                      values: values,
                      labels: labels,
                      color: metric.color,
                      height: 44)
                  : HealthMiniLine(
                      values: values,
                      labels: labels,
                      color: metric.color,
                      height: 44),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(Metrics.cornerPill),
                ),
                child: Text(metric.status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NoopType.caption.copyWith(
                        color: Palette.textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
