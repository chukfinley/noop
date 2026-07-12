import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/models.dart';
import 'package:noop/core/state/providers.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/shared/widgets/behavior.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/coming_soon.dart';
import 'package:noop/shared/widgets/reorderable_cluster.dart';
import 'package:noop/features/metrics/presentation/metric_trend_screen.dart';
import 'package:noop/features/today/presentation/home_layout.dart';

/// The home "Health Monitor" section — a 2-column grid of vital cards, each a
/// live metric with its status and where the value sits in the personal range.
///
/// Data honesty (project constraint): only metrics with a real capture source
/// show a number — Resting HR, HRV (RMSSD) and Sleep. Respiratory rate, SpO2
/// and Skin temp have no reliable source, so their cards render a muted
/// "coming soon" placeholder rather than a fabricated value/gauge.
///
/// While the home is in arrange mode ([editing]) the grid keeps its exact 2-up
/// look but every tile becomes its own draggable widget — long-press and drag to
/// reorder in place; navigation taps are suppressed.
class HealthMonitorSection extends ConsumerWidget {
  final DayRecord day;
  final bool editing;
  const HealthMonitorSection({
    super.key,
    required this.day,
    this.editing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(daysProvider);

    final win = days.length <= 14 ? days : days.sublist(days.length - 14);
    final tDates = win.map((d) => d.date).toList();
    List<double> tField(double Function(DayRecord) f) => win.map(f).toList();
    void openTrend(TrendMetric m) =>
        Navigator.of(context).push(noopRoute(MetricTrendScreen(metric: m)));

    final respTap = (editing || win.isEmpty)
        ? null
        : () => openTrend(TrendMetric(
              title: 'Respiratory rate',
              unit: 'rpm',
              color: Palette.accent,
              chart: TrendChart.line,
              daily: tField((d) => d.respiratoryRate),
              dates: tDates,
              valueText: win.last.respiratoryRate.toStringAsFixed(1),
              status: 'Last night',
              fmt: (v) => v.toStringAsFixed(1),
            ));
    final spo2Tap = (editing || win.isEmpty)
        ? null
        : () => openTrend(TrendMetric(
              title: 'Blood oxygen',
              unit: '%',
              color: Palette.metricCyan,
              chart: TrendChart.line,
              daily: tField((d) => d.spo2),
              dates: tDates,
              valueText: win.last.spo2.round().toString(),
              status: 'Last night',
              fmt: (v) => v.round().toString(),
            ));
    // The real tiles now navigate too: each metric opens its own detail screen
    // (Sleep → the rich Sleep screen; RHR/HRV → their trend detail), never a tab
    // swipe. Suppressed while arranging.
    final rhrTap = (editing || win.isEmpty)
        ? null
        : () => openTrend(TrendMetric(
              title: 'Resting HR',
              unit: 'bpm',
              color: Palette.metricRose,
              chart: TrendChart.line,
              daily: tField((d) => d.rhr),
              dates: tDates,
              valueText: win.last.rhr.round().toString(),
              status: 'Last night',
              fmt: (v) => v.round().toString(),
            ));
    final hrvTap = (editing || win.isEmpty)
        ? null
        : () => openTrend(TrendMetric(
              title: 'HRV',
              unit: 'ms',
              color: Palette.metricPurple,
              chart: TrendChart.line,
              daily: tField((d) => d.hrv),
              dates: tDates,
              valueText: win.last.hrv.round().toString(),
              status: 'Last night',
              fmt: (v) => v.round().toString(),
            ));
    // Sleep has its own tab — jump to it in the bottom nav, not a pushed screen.
    final sleepTap = editing
        ? null
        : () => ref.read(selectedTabProvider.notifier).state = kSleepTabIndex;

    (double, double) stats(double Function(DayRecord) f) {
      final values = <double>[];
      for (final d in days) {
        final v = f(d);
        if (v.isFinite) values.add(v);
      }
      if (values.isEmpty) return (0, 1);
      final mean = values.reduce((a, b) => a + b) / values.length;
      var variance = 0.0;
      for (final v in values) {
        variance += (v - mean) * (v - mean);
      }
      variance /= values.length;
      final sd = math.sqrt(variance);
      return (mean, sd == 0 ? 1 : sd);
    }

    final tiles = <String, Widget>{
      'resp': _comingSoonCard(Icons.air_rounded, 'Resp. Rate', onTap: respTap),
      'rhr': _realCard(_rhr(stats), onTap: rhrTap),
      'hrv': _realCard(_hrv(stats), onTap: hrvTap),
      'spo2': _comingSoonCard(Icons.water_drop_rounded, 'SpO₂', onTap: spo2Tap),
      'temp': _comingSoonCard(Icons.thermostat_rounded, 'Temp'),
      'sleep': _realCard(_sleep(), onTap: sleepTap),
    };

    final layout = ref.watch(healthLayoutProvider);
    final orderedIds = [
      for (final cfg in layout)
        if (cfg.visible && tiles.containsKey(cfg.id)) cfg.id,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              bottom: Metrics.space8, top: Metrics.space2),
          child: Text(
            'HEALTH MONITOR',
            style: NoopType.overline
                .copyWith(color: Palette.textTertiary, letterSpacing: 1.6),
          ),
        ),
        if (editing)
          ReorderableCluster(
            ids: orderedIds,
            columns: 2,
            cellHeight: 140,
            spacing: Metrics.space12,
            builder: (id) => tiles[id]!,
            onOrder: (order) =>
                ref.read(healthLayoutProvider.notifier).setVisibleOrder(order),
          )
        else
          ..._grid([for (final id in orderedIds) tiles[id]!]),
      ],
    );
  }

  // ── Grid helpers ───────────────────────────────────────────────────────────

  List<Widget> _grid(List<Widget> tiles) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final a = tiles[i];
      final b = i + 1 < tiles.length ? tiles[i + 1] : null;
      if (rows.isNotEmpty) rows.add(const SizedBox(height: Metrics.space12));
      rows.add(_row(a, b));
    }
    return rows;
  }

  Widget _row(Widget a, Widget? b) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: a),
            const SizedBox(width: Metrics.space12),
            Expanded(child: b ?? const SizedBox.shrink()),
          ],
        ),
      );

  Widget _comingSoonCard(IconData icon, String label, {VoidCallback? onTap}) =>
      NoopCard(
        squircle: true,
        bordered: false,
        fillColor: Palette.surfaceRaised,
        onTap: onTap,
        padding: const EdgeInsets.all(Metrics.space14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Palette.textSecondary),
                const SizedBox(width: Metrics.space8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        NoopType.subhead.copyWith(color: Palette.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Metrics.space14),
            const ComingSoonBadge(compact: true),
          ],
        ),
      );

  Widget _realCard(_Metric m, {VoidCallback? onTap}) => NoopCard(
        squircle: true,
        bordered: false,
        fillColor: Palette.surfaceRaised,
        onTap: onTap,
        padding: const EdgeInsets.all(Metrics.space14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(m.icon, size: 18, color: Palette.textSecondary),
                      const SizedBox(width: Metrics.space8),
                      Flexible(
                        child: Text(
                          m.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NoopType.subhead
                              .copyWith(color: Palette.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Metrics.space12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(m.valueText,
                          style: NoopType.number(28)
                              .copyWith(color: Palette.textPrimary)),
                      if (m.unit.isNotEmpty) ...[
                        const SizedBox(width: Metrics.space4),
                        Text(m.unit,
                            style: NoopType.caption
                                .copyWith(color: Palette.textTertiary)),
                      ],
                    ],
                  ),
                  if (m.sub != null) ...[
                    const SizedBox(height: Metrics.space4),
                    Text(m.sub!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NoopType.caption
                            .copyWith(color: Palette.textTertiary)),
                  ],
                  const SizedBox(height: Metrics.space10),
                  _StatusChip(status: m.status),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _RangeGauge(fraction: m.fraction, color: m.status.color),
          ],
        ),
      );

  // ── Metric computation ──────────────────────────────────────────────────────

  _Metric _rhr((double, double) Function(double Function(DayRecord)) stats) {
    final v = day.rhr;
    final (m, sd) = stats((d) => d.rhr);
    final fraction = ((v - (m - 2 * sd)) / (4 * sd)).clamp(0.0, 1.0);
    final z = (v - m) / sd;
    return _Metric(
      icon: Icons.favorite_rounded,
      label: 'Resting HR',
      valueText: v.toStringAsFixed(1),
      unit: 'bpm',
      status: _statusForZ(z),
      fraction: fraction,
    );
  }

  _Metric _hrv((double, double) Function(double Function(DayRecord)) stats) {
    final v = day.hrv;
    final (m, sd) = stats((d) => d.hrv);
    final fraction = ((v - (m - 2 * sd)) / (4 * sd)).clamp(0.0, 1.0);
    final z = (v - m) / sd;
    return _Metric(
      icon: Icons.monitor_heart_rounded,
      label: 'HRV',
      valueText: v.toStringAsFixed(1),
      unit: 'ms',
      status: _statusForZ(z),
      fraction: fraction,
    );
  }

  _Metric _sleep() {
    final sleep = day.sleep;
    if (sleep == null) {
      return const _Metric(
        icon: Icons.bedtime_rounded,
        label: 'Sleep',
        valueText: '—',
        unit: '',
        status: _Status.lower,
        fraction: 0,
      );
    }
    final hoursTotal = sleep.asleep.inMinutes / 60.0;
    var needH = sleep.need.inMinutes / 60.0;
    if (needH <= 0) needH = 8;
    final fraction = (hoursTotal / 9).clamp(0.0, 1.0);
    final _Status status;
    if (hoursTotal < needH * 0.85) {
      status = _Status.lower;
    } else if (hoursTotal > needH * 1.1) {
      status = _Status.higher;
    } else {
      status = _Status.normal;
    }
    return _Metric(
      icon: Icons.bedtime_rounded,
      label: 'Sleep',
      valueText: '${hoursTotal.floor()}h ${sleep.asleep.inMinutes % 60}m',
      unit: '',
      status: status,
      fraction: fraction,
      sub: 'On-device · last night',
    );
  }

  _Status _statusForZ(double z) {
    if (z < -0.75) return _Status.lower;
    if (z > 0.75) return _Status.higher;
    return _Status.normal;
  }
}

/// A resolved real metric: what the card renders.
class _Metric {
  final IconData icon;
  final String label;
  final String valueText;
  final String unit;
  final _Status status;
  final double fraction;
  final String? sub;
  const _Metric({
    required this.icon,
    required this.label,
    required this.valueText,
    required this.unit,
    required this.status,
    required this.fraction,
    this.sub,
  });
}

/// Where the value sits relative to the personal range.
enum _Status { normal, lower, higher }

extension _StatusX on _Status {
  Color get color => switch (this) {
        _Status.normal => Palette.statusPositive,
        _Status.lower => Palette.accent,
        _Status.higher => Palette.statusWarning,
      };
  IconData get icon => switch (this) {
        _Status.normal => Icons.check_circle_rounded,
        _Status.lower => Icons.arrow_downward_rounded,
        _Status.higher => Icons.arrow_upward_rounded,
      };
  String get word => switch (this) {
        _Status.normal => 'Normal',
        _Status.lower => 'Lower',
        _Status.higher => 'Higher',
      };
}

class _StatusChip extends StatelessWidget {
  final _Status status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(status.icon, size: 14, color: status.color),
        const SizedBox(width: Metrics.space4),
        Text(status.word,
            style: NoopType.footnote.copyWith(
                color: status.color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// A small vertical range gauge — a rounded track with a fill from the bottom to
/// [fraction] and a knob marking where the value sits.
class _RangeGauge extends StatelessWidget {
  final double fraction;
  final Color color;
  const _RangeGauge({required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) {
    final f = fraction.clamp(0.0, 1.0);
    return SizedBox(
      width: 12,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 10,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(Metrics.cornerPill),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: f,
              child: Container(
                width: 10,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(Metrics.cornerPill),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment(0, 1 - 2 * f),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
