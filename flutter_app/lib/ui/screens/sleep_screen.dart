import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../state/format.dart';
import '../../state/providers.dart';
import '../components/cards.dart';
import '../components/common.dart';
import '../components/gauge.dart';
import '../components/scaffold.dart';
import '../components/tiles.dart';
import '../theme/metrics.dart';
import '../theme/palette.dart';

/// Sleep detail — rest-performance hero, hypnogram, stage breakdown, metrics
/// and sleep-debt ledger. Mirrors SleepScreen.
class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(daysProvider);
    // Latest night that has a full hypnogram.
    final withDetail = days.where((d) => d.sleep?.hypnogram.isNotEmpty ?? false).toList();
    final day = withDetail.isNotEmpty ? withDetail.last : days.last;
    final sleep = day.sleep;

    if (sleep == null) {
      return const ScreenScaffold(
        title: 'Sleep',
        subtitle: 'Last night',
        children: [
          NoopCard(child: Text('No sleep recorded yet.')),
        ],
      );
    }

    List<double> tail(double Function(DayRecord) f, [int n = 14]) => days
        .where((d) => d.sleep != null)
        .toList()
        .reversed
        .take(n)
        .toList()
        .reversed
        .map(f)
        .toList();

    return ScreenScaffold(
      title: 'Sleep',
      subtitle: Fmt.dayTitle(day.date),
      glow: Palette.restGlow.withValues(alpha: 0.12),
      children: [
        _RestHero(day: day, sleep: sleep),
        _NightDetail(sleep: sleep),
        _StageBreakdown(sleep: sleep),
        SectionHeader('Night detail',
            trailing: Text('vs typical',
                style: NoopType.caption.copyWith(color: Palette.textTertiary))),
        _SleepMetrics(day: day, sleep: sleep, tail: tail),
        _HoursVsNeeded(sleep: sleep),
      ],
    );
  }
}

class _RestHero extends StatelessWidget {
  final DayRecord day;
  final SleepRecord sleep;
  const _RestHero({required this.day, required this.sleep});

  @override
  Widget build(BuildContext context) {
    final perf = sleep.performance;
    return NoopCard(
      accent: Palette.restColor,
      padding: const EdgeInsets.symmetric(vertical: Metrics.space24),
      child: Column(
        children: [
          Text('SLEEP PERFORMANCE',
              style: NoopType.overline.copyWith(color: Palette.restColor)),
          const SizedBox(height: Metrics.space16),
          RingGauge(
            fraction: perf / 100,
            stops: DomainTheme.rest.gradientStops,
            size: 170,
            stroke: 14,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${perf.round()}',
                    style: NoopType.display(52).copyWith(color: Palette.textPrimary)),
                Text('%', style: NoopType.caption.copyWith(color: Palette.textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: Metrics.space16),
          Text('${Fmt.hm(sleep.asleep)} asleep · need ${Fmt.hm(sleep.need)}',
              style: NoopType.body.copyWith(color: Palette.textSecondary)),
        ],
      ),
    );
  }
}

class _NightDetail extends StatelessWidget {
  final SleepRecord sleep;
  const _NightDetail({required this.sleep});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Hypnogram',
      accent: Palette.restColor,
      trailing: Text('${Fmt.clock(sleep.bedtime)} – ${Fmt.clock(sleep.wake)}',
          style: NoopType.captionNumber.copyWith(color: Palette.textSecondary)),
      child: Column(
        children: [
          SizedBox(
            height: 96,
            width: double.infinity,
            child: CustomPaint(painter: _HypnogramPainter(sleep.hypnogram)),
          ),
          const SizedBox(height: Metrics.space8),
          if (sleep.restlessness.isNotEmpty)
            SizedBox(
              height: Metrics.motionStripHeight,
              width: double.infinity,
              child: CustomPaint(painter: _MotionPainter(sleep.restlessness)),
            ),
          const SizedBox(height: Metrics.space8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legend('Deep', Palette.sleepDeep),
              _legend('REM', Palette.sleepREM),
              _legend('Light', Palette.sleepLight),
              _legend('Awake', Palette.sleepAwake),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) => Row(
        children: [
          Container(
            width: Metrics.legendSwatch,
            height: Metrics.legendSwatch,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 5),
          Text(label, style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
        ],
      );
}

double _stageLevel(SleepStage s) => switch (s) {
      SleepStage.awake => 0,
      SleepStage.rem => 1,
      SleepStage.light => 2,
      SleepStage.deep => 3,
    };

Color _stageColor(SleepStage s) => switch (s) {
      SleepStage.awake => Palette.sleepAwake,
      SleepStage.rem => Palette.sleepREM,
      SleepStage.light => Palette.sleepLight,
      SleepStage.deep => Palette.sleepDeep,
    };

class _HypnogramPainter extends CustomPainter {
  final List<StageSegment> segments;
  _HypnogramPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;
    final start = segments.first.start;
    final end = segments.last.start.add(segments.last.duration);
    final totalMs = end.difference(start).inMilliseconds.toDouble();
    if (totalMs <= 0) return;

    const levels = 4;
    final rowH = size.height / levels;
    double xFor(DateTime t) => t.difference(start).inMilliseconds / totalMs * size.width;
    double yFor(SleepStage s) => (_stageLevel(s) + 0.5) * rowH;

    for (final seg in segments) {
      final x0 = xFor(seg.start);
      final x1 = xFor(seg.start.add(seg.duration));
      final y = yFor(seg.stage);
      final color = _stageColor(seg.stage);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x0, y - rowH * 0.32, (x1 - x0).clamp(1, size.width), rowH * 0.64),
        const Radius.circular(3),
      );
      canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: 0.9));
    }
  }

  @override
  bool shouldRepaint(_HypnogramPainter old) => old.segments != segments;
}

class _MotionPainter extends CustomPainter {
  final List<double> values;
  _MotionPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final barW = size.width / values.length;
    for (var i = 0; i < values.length; i++) {
      final h = values[i].clamp(0, 1) * size.height;
      canvas.drawRect(
        Rect.fromLTWH(i * barW, size.height - h, barW * 0.7, h),
        Paint()..color = Palette.sleepAwake.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_MotionPainter old) => old.values != values;
}

class _StageBreakdown extends StatelessWidget {
  final SleepRecord sleep;
  const _StageBreakdown({required this.sleep});

  @override
  Widget build(BuildContext context) {
    final total = sleep.asleep.inMinutes.toDouble();
    Widget row(String label, Duration d, Color color) {
      final pct = total <= 0 ? 0.0 : d.inMinutes / total;
      return Padding(
        padding: const EdgeInsets.only(bottom: Metrics.space12),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              child: Text(label, style: NoopType.overline.copyWith(color: color)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Metrics.cornerBadge),
                child: Container(
                  height: Metrics.segmentBarHeight,
                  color: Palette.surfaceInset,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: pct.clamp(0.02, 1.0),
                    child: Container(color: color.withValues(alpha: 0.85)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Metrics.space12),
            Text(Fmt.hm(d),
                style: NoopType.captionNumber.copyWith(color: Palette.textSecondary)),
          ],
        ),
      );
    }

    return SectionCard(
      title: 'Stages',
      accent: Palette.restColor,
      child: Column(
        children: [
          row('DEEP', sleep.deep, Palette.sleepDeep),
          row('REM', sleep.rem, Palette.sleepREM),
          row('LIGHT', sleep.light, Palette.sleepLight),
          row('AWAKE', sleep.awake, Palette.sleepAwake),
        ],
      ),
    );
  }
}

class _SleepMetrics extends StatelessWidget {
  final DayRecord day;
  final SleepRecord sleep;
  final List<double> Function(double Function(DayRecord), [int]) tail;
  const _SleepMetrics({required this.day, required this.sleep, required this.tail});

  @override
  Widget build(BuildContext context) {
    return MetricGrid([
      MetricTile(
        label: 'Efficiency',
        value: (sleep.efficiency * 100).toStringAsFixed(0),
        unit: '%',
        spark: tail((d) => (d.sleep?.efficiency ?? 0) * 100),
        accent: Palette.restColor,
      ),
      MetricTile(
        label: 'Time in bed',
        value: Fmt.hoursDecimal(sleep.timeInBed),
        unit: 'h',
        spark: tail((d) => (d.sleep?.timeInBed.inMinutes ?? 0) / 60),
        accent: Palette.metricPurple,
      ),
      MetricTile(
        label: 'Respiratory',
        value: sleep.respiratoryRate.toStringAsFixed(1),
        unit: 'rpm',
        spark: tail((d) => d.sleep?.respiratoryRate ?? 0),
        accent: Palette.metricCyan,
      ),
      MetricTile(
        label: 'Disturbances',
        value: sleep.disturbances.toString(),
        spark: tail((d) => (d.sleep?.disturbances ?? 0).toDouble()),
        accent: Palette.sleepAwake,
      ),
    ]);
  }
}

class _HoursVsNeeded extends StatelessWidget {
  final SleepRecord sleep;
  const _HoursVsNeeded({required this.sleep});

  @override
  Widget build(BuildContext context) {
    final asleep = sleep.asleep.inMinutes.toDouble();
    final need = sleep.need.inMinutes.toDouble();
    final debt = need - asleep;
    final met = (asleep / need).clamp(0.0, 1.0);
    return SectionCard(
      title: 'Hours vs needed',
      accent: Palette.restColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(Fmt.hoursDecimal(sleep.asleep),
                  style: NoopType.display(34).copyWith(color: Palette.textPrimary)),
              Text(' / ${Fmt.hoursDecimal(sleep.need)} h needed',
                  style: NoopType.body.copyWith(color: Palette.textTertiary)),
            ],
          ),
          const SizedBox(height: Metrics.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(Metrics.cornerBadge),
            child: Container(
              height: Metrics.progressHeight,
              color: Palette.surfaceInset,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: met,
                child: Container(color: Palette.restColor),
              ),
            ),
          ),
          const SizedBox(height: Metrics.space8),
          Text(
            debt > 30
                ? '${Fmt.hm(Duration(minutes: debt.round()))} short of your need'
                : 'You met your sleep need',
            style: NoopType.caption.copyWith(
                color: debt > 30 ? Palette.statusWarning : Palette.statusPositive),
          ),
        ],
      ),
    );
  }
}
