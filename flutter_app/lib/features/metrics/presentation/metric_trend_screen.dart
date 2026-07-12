import 'package:flutter/material.dart';

import 'package:noop/core/state/format.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/coming_soon.dart';
import 'package:noop/shared/widgets/controls.dart';
import 'package:noop/shared/widgets/health_charts.dart' show ghWeekdayInitial;
import 'package:noop/shared/widgets/interactive_trend_chart.dart';
import 'package:noop/shared/widgets/scaffold.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

enum TrendChart { line, bars }

/// Everything the Google-Health-style grid card and its detail screen need for
/// one metric. Carries the full daily history so the detail can re-window it.
class TrendMetric {
  final String title;
  final String unit;
  final Color color;
  final TrendChart chart;
  final List<double> daily; // oldest → newest
  final List<DateTime> dates; // aligned with [daily]
  final String valueText; // big value on the grid card (latest / total)
  final String status; // status chip text
  final double? targetLow;
  final double? targetHigh;
  final String Function(double v) fmt; // format a single value / average

  /// No real capture source yet — the grid renders a "coming soon" placeholder
  /// instead of the (fabricated) chart + value.
  final bool comingSoon;

  const TrendMetric({
    required this.title,
    required this.unit,
    required this.color,
    required this.chart,
    required this.daily,
    required this.dates,
    required this.valueText,
    required this.status,
    required this.fmt,
    this.targetLow,
    this.targetHigh,
    this.comingSoon = false,
  });

  List<double> lastN(int n) =>
      daily.length <= n ? daily : daily.sublist(daily.length - n);
  List<DateTime> lastDates(int n) =>
      dates.length <= n ? dates : dates.sublist(dates.length - n);
}

class _Range {
  final String label;
  final int days;
  const _Range(this.label, this.days);
}

const _ranges = [
  _Range('T', 1),
  _Range('W', 7),
  _Range('M', 14),
  _Range('3M', 30),
  _Range('J', 90),
];

/// Google-Health-style metric detail: range tabs, a big average, a large chart
/// with a target band + value axis, a legend and a per-day list.
class MetricTrendScreen extends StatefulWidget {
  final TrendMetric metric;
  const MetricTrendScreen({super.key, required this.metric});

  @override
  State<MetricTrendScreen> createState() => _MetricTrendScreenState();
}

class _MetricTrendScreenState extends State<MetricTrendScreen> {
  int _rangeIdx = 1; // W

  @override
  Widget build(BuildContext context) {
    final m = widget.metric;
    final n = _ranges[_rangeIdx].days.clamp(1, m.daily.length);
    final values = m.lastN(n);
    final dates = m.lastDates(n);
    final labels = dates.map(ghWeekdayInitial).toList();
    final avg = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;
    final rangeLabel = dates.isEmpty
        ? ''
        : '${Fmt.shortDate(dates.first)} – ${Fmt.shortDate(dates.last)}';

    // The SAME shared shell as every other metric detail screen — a
    // ScenicBackground, the one CenteredHeader / back button, and the staggered
    // Reveal enter — so a Trends sub-screen is byte-for-byte consistent with a
    // Home metric detail (was a bespoke Scaffold + custom app bar before).
    return ScreenScaffold(
      title: m.title,
      glow: m.color,
      leadingHeader: CenteredHeader(title: m.title),
      children: [
        if (m.comingSoon) _comingSoonBanner(m),
        _rangeTabs(),
        // The date range + big average + chart + legend sit in their own
        // translucent box (like the day-list tiles below), so the graph reads
        // against a surface instead of floating straight on the scenic sky.
        NoopCard(
          squircle: true,
          radius: Metrics.cornerHero,
          bordered: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rangeLabel,
                  style: NoopType.title2.copyWith(color: Palette.textPrimary)),
              const SizedBox(height: 16),
              _bigValue(m, avg),
              const SizedBox(height: 24),
              InteractiveTrendChart(
                values: values,
                dates: dates,
                labels: labels,
                color: m.color,
                kind: m.chart == TrendChart.bars
                    ? TrendChartKind.bars
                    : TrendChartKind.line,
                targetLow: m.targetLow,
                targetHigh: m.targetHigh,
                fmt: m.fmt,
                unit: m.unit,
              ),
              const SizedBox(height: 20),
              _legend(),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rangeLabel,
                style: NoopType.title2.copyWith(color: Palette.textPrimary)),
            const SizedBox(height: 12),
            _dayList(m, values, dates),
          ],
        ),
      ],
    );
  }

  /// A small honest banner for metrics with no calibrated source yet: the whole
  /// screen still renders (chart, average, day list) so the UI is complete, but
  /// this makes clear the numbers are a rough estimate, not a trusted reading.
  Widget _comingSoonBanner(TrendMetric m) => NoopCard(
        squircle: true,
        radius: Metrics.cornerLarge,
        bordered: false,
        padding: const EdgeInsets.all(Metrics.space14),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded, size: 22, color: m.color),
            const SizedBox(width: Metrics.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estimated preview',
                      style: NoopType.subhead.copyWith(
                          color: Palette.textPrimary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                      'No calibrated ${m.title.toLowerCase()} source in the capture yet — these numbers are rough estimates.',
                      style: NoopType.caption
                          .copyWith(color: Palette.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: Metrics.space8),
            const ComingSoonBadge(compact: true),
          ],
        ),
      );

  Widget _rangeTabs() => NoopSegmented<int>(
        expand: true,
        height: 44,
        value: _rangeIdx,
        onChanged: (i) => setState(() => _rangeIdx = i),
        segments: [
          for (var i = 0; i < _ranges.length; i++)
            NoopSegment(i, _ranges[i].label),
        ],
      );

  Widget _bigValue(TrendMetric m, double avg) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(m.fmt(avg),
              style: NoopType.display(52).copyWith(color: Palette.textPrimary)),
          const SizedBox(width: 6),
          Flexible(
            child: Text('${m.unit} per day (avg)',
                style: NoopType.subhead.copyWith(color: Palette.textSecondary)),
          ),
        ],
      );

  Widget _legend() => Wrap(
        alignment: WrapAlignment.center,
        spacing: 22,
        runSpacing: 8,
        children: [
          _legendItem(Palette.statusPositive, 'Personal range', ring: true),
          _legendItem(Palette.statusPositive, 'In range'),
          _legendItem(widget.metric.color, 'Below range'),
        ],
      );

  Widget _legendItem(Color c, String label, {bool ring = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: ring ? Colors.transparent : c,
              shape: BoxShape.circle,
              border: ring ? Border.all(color: c, width: 2) : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: NoopType.footnote.copyWith(color: Palette.textSecondary)),
        ],
      );

  Widget _dayList(TrendMetric m, List<double> values, List<DateTime> dates) {
    // Newest first — every day in the selected range (the range tabs decide how
    // many), so you can scroll every other day, not just a handful.
    final items = <(String, String)>[];
    for (var i = values.length - 1; i >= 0; i--) {
      final isLast = i == values.length - 1;
      final isPrev = i == values.length - 2;
      final label = isLast
          ? 'Today'
          : (isPrev ? 'Yesterday' : Fmt.shortDate(dates[i]));
      items.add((label, m.fmt(values[i])));
    }

    // The SAME connected-group language as the Settings menu: each entry is its
    // own translucent tile; the group's outer corners are extra-large and the
    // inner (touching) corners are small, with a hairline gap between rows — no
    // divider lines.
    const outer = Radius.circular(Metrics.cornerLarge);
    const inner = Radius.circular(Metrics.cornerBadge);
    final n = items.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < n; i++) ...[
          Material(
            color: Palette.fillRaised,
            borderRadius: BorderRadius.vertical(
              top: i == 0 ? outer : inner,
              bottom: i == n - 1 ? outer : inner,
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Metrics.space16, vertical: Metrics.space14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(items[i].$1,
                        style: NoopType.body
                            .copyWith(color: Palette.textSecondary)),
                  ),
                  Text(items[i].$2,
                      style: NoopType.number(22)
                          .copyWith(color: Palette.textPrimary)),
                ],
              ),
            ),
          ),
          if (i != n - 1) const SizedBox(height: 3),
        ],
      ],
    );
  }
}
