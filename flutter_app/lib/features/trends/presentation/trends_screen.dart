import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/models.dart';
import 'package:noop/core/state/format.dart';
import 'package:noop/core/state/providers.dart';
import 'package:noop/shared/widgets/backgrounds.dart';
import 'package:noop/shared/widgets/behavior.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/coming_soon.dart';
import 'package:noop/shared/widgets/health_charts.dart';
import 'package:noop/shared/widgets/motion.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/features/health/presentation/heart_rate_screen.dart';
import 'package:noop/features/health/presentation/weight_screen.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(daysProvider);
    // No strap data synced yet → the metric grid has nothing to plot; show the
    // empty/calibrating state instead of indexing an empty day list.
    if (days.isEmpty) {
      return const ScenicBackground(
        child: SafeArea(child: ConnectStrapView()),
      );
    }
    final weightLog = ref.watch(weightLogProvider);
    final waterLog = ref.watch(waterLogProvider);
    final profile = ref.watch(profileProvider);

    // Weight: carry the last known logged weight forward so gaps between
    // weigh-ins read as flat, not a drop to zero.
    double? lastW;
    final weightDaily = <double>[];
    final weightDates = <DateTime>[];
    for (final d in days) {
      final v = weightLog[isoDay(d.date)];
      if (v != null) lastW = v;
      weightDaily.add(lastW ?? profile.weightKg);
      weightDates.add(d.date);
    }
    // Water: user-entered ml per day; 0 is a valid real value.
    final waterDaily = [for (final d in days) (waterLog[isoDay(d.date)] ?? 0.0)];
    final waterDates = [for (final d in days) d.date];

    final win = days.length <= 14 ? days : days.sublist(days.length - 14);
    final dates = win.map((d) => d.date).toList();
    List<double> field(double Function(DayRecord) f) => win.map(f).toList();
    final last7 = win.length <= 7 ? win.length : 7;

    double sumLast(List<double> v, int n) {
      final s = v.length <= n ? v : v.sublist(v.length - n);
      return s.fold(0.0, (a, b) => a + b);
    }

    // Mean intraday heart rate for a day (0 when the day has no HR thread).
    double avgHr(DayRecord d) => d.hr.isEmpty
        ? 0
        : d.hr.map((e) => e.bpm).reduce((a, b) => a + b) / d.hr.length;

    final metrics = <TrendMetric>[
      // Weight — real, user-logged; coming-soon only until the first weigh-in.
      TrendMetric(
        title: 'Weight',
        unit: 'kg',
        color: Palette.metricCyan,
        chart: TrendChart.line,
        daily: weightDaily,
        dates: weightDates,
        valueText:
            '${(weightLog.isEmpty ? profile.weightKg : (lastW ?? profile.weightKg)).toStringAsFixed(1)} kg',
        status: 'Logged',
        fmt: (v) => v.toStringAsFixed(1),
        comingSoon: weightLog.isEmpty,
      ),
      // Heart rate — real intraday capture; opens the second/minute history.
      TrendMetric(
        title: 'Heart rate',
        unit: 'bpm',
        color: Palette.metricRose,
        chart: TrendChart.line,
        daily: field((d) => avgHr(d)),
        dates: dates,
        valueText: '${avgHr(win.last).round()} bpm',
        status: 'Second · minute',
        fmt: (v) => v.round().toString(),
      ),
      // Water — real, user-entered; 0 is a valid value, never coming-soon.
      TrendMetric(
        title: 'Water',
        unit: 'ml',
        color: Palette.metricCyan,
        chart: TrendChart.bars,
        daily: waterDaily,
        dates: waterDates,
        valueText: '${(waterDaily.isEmpty ? 0 : waterDaily.last).round()} ml',
        status: 'Today',
        fmt: (v) => '${v.round()}',
        comingSoon: false,
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
      ),
      TrendMetric(
        title: 'Recovery',
        unit: win.last.chargeCalibrating
            ? 'nights'
            : win.last.chargeNoData
                ? ''
                : '%',
        color: Palette.chargeColor,
        chart: TrendChart.line,
        daily: field((d) => d.charge),
        dates: dates,
        valueText: win.last.chargeCalibrating
            ? '${win.last.chargeCalibrationNights}/$recoveryCalibrationNightsNeeded'
            : win.last.chargeNoData
                ? '—'
                : win.last.charge.round().toString(),
        status: win.last.chargeCalibrating
            ? 'Calibrating baseline'
            : win.last.chargeNoData
                ? 'No data last night'
                : Palette.recoveryState(win.last.charge),
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
      ),
    ];

    final labels7 =
        dates.sublist(dates.length - last7).map(ghWeekdayInitial).toList();

    // No nested Scaffold: the app shell has extendBody + a floating frosted nav
    // bar, so the page must fill the whole body (content scrolling *under* the
    // bar) for its transparency to read. A solid inner Scaffold broke that.
    return ScenicBackground(
      child: SafeArea(
        bottom: false,
        // The "Trends" title floats over the scroll with a transparent
        // background, so content stays visible as it scrolls past it instead of
        // vanishing behind an opaque bar.
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(
                  Metrics.space16, 48, Metrics.space16, 120),
              children: [
                // No second title here — the floating "Trends" header names the
                // screen. This line instead states which day the data runs to,
                // with its weekday, so it's obvious how current the numbers are.
                Reveal(
                  index: 0,
                  child: Text(
                    days.isEmpty
                        ? ''
                        : 'Latest data · ${Fmt.longDate(days.last.date)}',
                    style: NoopType.subhead
                        .copyWith(color: Palette.textSecondary),
                  ),
                ),
                const SizedBox(height: Metrics.space16),
                for (var i = 0; i < metrics.length; i += 2)
                    Reveal(
                      index: i ~/ 2 + 1,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: Metrics.space12),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                  child: _MetricCard(
                                      metric: metrics[i],
                                      labels: labels7,
                                      n: last7)),
                              const SizedBox(width: Metrics.space12),
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
                    ),
              ],
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _Header(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            Metrics.space16, Metrics.space8, Metrics.space16, Metrics.space8),
        child: Center(
          child: Text('Trends',
              style: NoopType.title2.copyWith(color: Palette.textPrimary)),
        ),
      );
}

class _MetricCard extends ConsumerWidget {
  final TrendMetric metric;
  final List<String> labels;
  final int n;
  const _MetricCard(
      {required this.metric, required this.labels, required this.n});

  /// Weight has its own editable tracker; Heart rate opens the second/minute
  /// intraday history; every other metric opens the generic trend detail.
  static Widget _detailFor(TrendMetric m) => switch (m.title) {
        'Weight' => const WeightScreen(),
        'Heart rate' => const HeartRateScreen(),
        _ => MetricTrendScreen(metric: m),
      };

  static IconData _iconFor(String title) => switch (title) {
        'Weight' => Icons.monitor_weight_rounded,
        'Steps' => Icons.directions_walk_rounded,
        'Calories burned' => Icons.local_fire_department_rounded,
        'Fitness age' => Icons.cake_rounded,
        _ => Icons.hourglass_empty_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No real source yet — drop a matching-radius placeholder into the grid.
    // When we at least have an estimated series, the placeholder is tappable and
    // opens the same detail screen (flagged as an estimated preview inside).
    if (metric.comingSoon) {
      return ComingSoonTile(
        label: metric.title,
        icon: _iconFor(metric.title),
        radius: Metrics.cornerLarge,
        onTap: metric.daily.isEmpty
            ? null
            : () => Navigator.of(context)
                .push(noopRoute(_detailFor(metric))),
      );
    }
    final values = metric.lastN(n);
    // Tonal tinted surface via NoopCard's accent fill (accent@0.12).
    return NoopCard(
      accent: metric.color,
      radius: Metrics.cornerLarge,
      padding: const EdgeInsets.all(Metrics.space14),
      onTap: () => Navigator.of(context).push(noopRoute(_detailFor(metric))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.title,
              style: NoopType.footnote.copyWith(color: Palette.textSecondary)),
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
          // A metric can prefer bars; the global "Trends bars" setting
          // (ryanbr #134) forces bars on every card when enabled.
          (metric.chart == TrendChart.bars || ref.watch(trendsBarsProvider))
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
    );
  }
}
