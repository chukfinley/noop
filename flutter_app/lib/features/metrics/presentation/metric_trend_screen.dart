import 'package:flutter/material.dart';

import 'package:noop/core/state/format.dart';
import 'package:noop/shared/widgets/health_charts.dart';
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

    return Scaffold(
      backgroundColor: Palette.surfaceBase,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _appBar(context, m.title),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  _rangeTabs(),
                  const SizedBox(height: 20),
                  Text(rangeLabel,
                      style: NoopType.title2.copyWith(color: Palette.textPrimary)),
                  const SizedBox(height: 16),
                  _bigValue(m, avg),
                  const SizedBox(height: 24),
                  HealthDetailChart(
                    values: values,
                    labels: labels,
                    color: m.color,
                    kind: m.chart == TrendChart.bars
                        ? HealthChartKind.bars
                        : HealthChartKind.line,
                    targetLow: m.targetLow,
                    targetHigh: m.targetHigh,
                  ),
                  const SizedBox(height: 20),
                  _legend(),
                  const SizedBox(height: 28),
                  Text(rangeLabel,
                      style: NoopType.title2.copyWith(color: Palette.textPrimary)),
                  const SizedBox(height: 12),
                  _dayList(m, values, dates),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: Row(
          children: [
            NoopBackButton(onTap: () => Navigator.of(context).maybePop()),
            const SizedBox(width: 4),
            Expanded(
              child: Text(title,
                  style: NoopType.title2.copyWith(color: Palette.textPrimary)),
            ),
            IconButton(
              icon: Icon(Icons.add_rounded, color: Palette.textPrimary),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: Palette.textPrimary),
              onPressed: () {},
            ),
          ],
        ),
      );

  Widget _rangeTabs() => Row(
        children: [
          for (var i = 0; i < _ranges.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _rangeIdx = i),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: i == _rangeIdx
                        ? Palette.accent.withValues(alpha: 0.28)
                        : Palette.surfaceRaised,
                    borderRadius: BorderRadius.circular(Metrics.cornerPill),
                  ),
                  child: Text(_ranges[i].label,
                      style: NoopType.subhead.copyWith(
                          color: i == _rangeIdx
                              ? Palette.accent
                              : Palette.textSecondary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            if (i != _ranges.length - 1) const SizedBox(width: 8),
          ],
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
    // Newest first, up to 6 rows.
    final rows = <Widget>[];
    for (var i = values.length - 1; i >= 0 && rows.length < 6; i--) {
      final isLast = i == values.length - 1;
      final isPrev = i == values.length - 2;
      final label = isLast
          ? 'Today'
          : (isPrev ? 'Yesterday' : Fmt.shortDate(dates[i]));
      rows.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Palette.surfaceRaised,
          borderRadius: BorderRadius.vertical(
            top: rows.isEmpty ? const Radius.circular(18) : Radius.zero,
          ),
          border: Border(
            bottom: BorderSide(color: Palette.surfaceBase, width: 2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: NoopType.body.copyWith(color: Palette.textSecondary)),
            ),
            Text(m.fmt(values[i]),
                style: NoopType.number(22).copyWith(color: Palette.textPrimary)),
          ],
        ),
      ));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Column(children: rows),
    );
  }
}
