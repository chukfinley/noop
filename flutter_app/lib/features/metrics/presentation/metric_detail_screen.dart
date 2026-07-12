import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/models.dart';
import 'package:noop/core/state/format.dart';
import 'package:noop/core/state/prefs.dart' show EffortScale;
import 'package:noop/core/state/providers.dart';
import 'package:noop/shared/widgets/behavior.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/charts.dart';
import 'package:noop/shared/widgets/common.dart';
import 'package:noop/shared/widgets/controls.dart';
import 'package:noop/shared/widgets/coming_soon.dart';
import 'package:noop/shared/widgets/health_charts.dart';
import 'package:noop/shared/widgets/liquid.dart';
import 'package:noop/shared/widgets/metric_gauge.dart';
import 'package:noop/shared/widgets/scaffold.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/features/sleep/presentation/sleep_screen.dart';

/// Which hero metric a [MetricDetailScreen] presents.
enum MetricKind { recovery, strain, sleep, stress }

/// The windows the trend selector at the top of every detail screen offers —
/// (label, days). Shared so Recovery/Strain/Sleep/Stress all read identically.
const _trendRanges = <(String, int)>[
  ('W', 7),
  ('M', 14),
  ('3M', 30),
  ('Y', 90),
];

/// Selected trend window, shared across the detail screens (index into
/// [_trendRanges]). Defaults to 'M' (14 days) — the old fixed window.
final _trendRangeProvider = StateProvider<int>((_) => 1);

/// A dense 0..100 timeline series (+ 3 time-axis labels) for a metric — the
/// same jagged detail line the Today cards use, so tapping in keeps the look.
/// Sleep uses the restlessness strip; others use the intraday HR thread, with a
/// deterministic wavy fallback when no samples exist.
(List<double>, List<String>) metricTimeline(DayRecord day, MetricKind kind) {
  final s = day.sleep;
  if (kind == MetricKind.sleep && s != null && s.restlessness.length >= 6) {
    final series = s.restlessness.map((r) => (r * 100).clamp(0.0, 100.0)).toList();
    final mid = DateTime.fromMillisecondsSinceEpoch(
        (s.bedtime.millisecondsSinceEpoch + s.wake.millisecondsSinceEpoch) ~/ 2);
    return (series, [Fmt.clock(s.bedtime), Fmt.clock(mid), Fmt.clock(s.wake)]);
  }
  if (day.hr.length >= 8) {
    final bpm = day.hr.map((e) => e.bpm).toList();
    final lo = bpm.reduce((a, b) => a < b ? a : b);
    final hi = bpm.reduce((a, b) => a > b ? a : b);
    final span = (hi - lo).abs() < 1e-6 ? 1.0 : (hi - lo);
    final series = bpm.map((b) => ((b - lo) / span) * 92 + 4).toList();
    final t = day.hr;
    return (
      series,
      [Fmt.clock(t.first.time), Fmt.clock(t[t.length ~/ 2].time), Fmt.clock(t.last.time)]
    );
  }
  final seed = kind.index * 7 + 3;
  final series = List<double>.generate(72, (i) {
    final wave = 50 + 26 * math.sin((i / 72) * 6.283 * 3 + seed);
    final noise = (((i * 2654435761 + seed * 40503) % 1000) / 1000 - 0.5) * 26;
    return (wave + noise).clamp(4.0, 98.0);
  });
  return (series, ['12 AM', '12 PM', 'Now']);
}

/// A single detail screen, parameterised per hero metric — opened by tapping
/// Recovery / Strain / Sleep on Today. Big gauge + state, a 14-day trend and
/// the contributing signals that drive the score.
class MetricDetailScreen extends ConsumerWidget {
  final MetricKind kind;
  const MetricDetailScreen({super.key, required this.kind});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(daysProvider);
    final maxI = days.length - 1;
    final idx = ref.watch(selectedDayIndexProvider).clamp(0, maxI);
    // The day the user is looking at — changeable in-screen with the same
    // chevron pager the home header uses, so it stays tied to the gauge tapped.
    final day = days[idx];

    List<double> tail(double Function(DayRecord) f, [int n = 14]) =>
        days.sublist(days.length - n).map(f).toList();

    final spec = _specFor(kind, day, ref.watch(effortScaleProvider));
    // Windowed trend — the shared range selector picks how many days feed the
    // chart, clamped to the data we actually have.
    final rangeIdx = ref.watch(_trendRangeProvider).clamp(0, _trendRanges.length - 1);
    final n = _trendRanges[rangeIdx].$2.clamp(1, days.length);
    final series = tail(spec.field, n);
    final maxV = kind == MetricKind.strain
        ? (series.fold<double>(1, (m, v) => v > m ? v : m) * 1.15)
        : 100.0;
    final (timeline, axis) = metricTimeline(day, kind);
    final activity = _activitySection(context, kind, day);

    return ScreenScaffold(
      title: spec.title,
      glow: spec.color,
      // Same centred title + chevron day-pager as the Sleep screen, so every
      // detail screen reads identically.
      leadingHeader: Column(
        children: [
          CenteredHeader(title: spec.title),
          DayNavStrip(
            label: idx == maxI ? 'Today' : Fmt.dayTitle(day.date),
            sub: Fmt.shortDate(day.date),
            canPrev: idx > 0,
            canNext: idx < maxI,
            onPrev: () =>
                ref.read(selectedDayIndexProvider.notifier).state = idx - 1,
            onNext: () =>
                ref.read(selectedDayIndexProvider.notifier).state = idx + 1,
          ),
        ],
      ),
      children: [
        // Hero — the signature liquid gauge, same vessel as the Today home
        // cell, blown up big. This is what ties the detail back to the gauge
        // you tapped.
        _HeroGauge(spec: spec),
        // Intraday detail — the jagged timeline in a recessed squircle card,
        // matching the Today "Your cards" surface.
        _TimelineCard(spec: spec, timeline: timeline, axis: axis),
        SectionCard(
          title: 'Trend',
          accent: spec.color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NoopSegmented<int>(
                expand: true,
                height: 40,
                value: rangeIdx,
                onChanged: (i) =>
                    ref.read(_trendRangeProvider.notifier).state = i,
                segments: [
                  for (var i = 0; i < _trendRanges.length; i++)
                    NoopSegment(i, _trendRanges[i].$1),
                ],
              ),
              const SizedBox(height: Metrics.space16),
              BarSeries(
                values: series,
                color: spec.color,
                height: 150,
                maxValue: maxV,
                highlightIndex: series.length - 1,
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Contributors',
          accent: spec.color,
          child: Column(
            children: [
              for (var i = 0; i < spec.contributors.length; i++) ...[
                if (i != 0) const SizedBox(height: Metrics.space16),
                _ContribRow(c: spec.contributors[i], tail: tail),
              ],
            ],
          ),
        ),
        if (activity != null) activity,
      ],
    );
  }
}

/// The "Timeline" section, mirroring the reference: the day's activities that
/// fed this score. Strain → the workouts (auto-detection is a planned source,
/// so it shows a coming-soon row, never a fabricated workout). Recovery → the
/// night that drove it, a real row linking into the Sleep screen.
Widget? _activitySection(BuildContext context, MetricKind kind, DayRecord day) {
  switch (kind) {
    case MetricKind.strain:
      return SectionCard(
        title: 'Timeline',
        accent: Palette.effortColor,
        child: _TimelineRow(
          icon: Icons.directions_run_rounded,
          color: Palette.effortColor,
          title: 'Workouts',
          subtitle: 'Auto-detected activities',
          trailing: const ComingSoonBadge(compact: true),
        ),
      );
    case MetricKind.recovery:
      final s = day.sleep;
      if (s == null) return null;
      return SectionCard(
        title: 'Timeline',
        accent: Palette.chargeColor,
        child: _TimelineRow(
          icon: Icons.bedtime_rounded,
          color: Palette.restColor,
          badge: day.rest.round().toString(),
          title: 'Primary sleep',
          subtitle: '${Fmt.clock(s.bedtime)} – ${Fmt.clock(s.wake)}',
          trailing: Icon(Icons.chevron_right_rounded,
              color: Palette.textTertiary, size: 20),
          onTap: () =>
              Navigator.of(context).push(noopRoute(const SleepScreen())),
        ),
      );
    case MetricKind.sleep:
    case MetricKind.stress:
      return null;
  }
}

/// A single timeline row: a tonal icon badge (optionally stamped with a score),
/// a title + timestamp, and a trailing control. Mirrors the reference's
/// activity rows in the app's own tokens.
class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? badge;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  const _TimelineRow({
    required this.icon,
    required this.color,
    this.badge,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        // Icon badge with an optional small score stamp in the corner.
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconChip(icon, color: color, size: 40),
              if (badge != null)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Palette.fillRaised,
                      borderRadius: BorderRadius.circular(Metrics.cornerBadge),
                      border: Border.all(
                          color: color.withValues(alpha: 0.5), width: 1),
                    ),
                    child: Text(badge!,
                        style: NoopType.captionNumber.copyWith(color: color)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: Metrics.space14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: NoopType.body.copyWith(
                      color: Palette.textPrimary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style:
                      NoopType.caption.copyWith(color: Palette.textTertiary)),
            ],
          ),
        ),
        const SizedBox(width: Metrics.space12),
        trailing,
      ],
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Metrics.cornerChip),
        onTap: onTap,
        child: row,
      ),
    );
  }
}

/// The hero — a big liquid "water" gauge in a squircle card, echoing the Today
/// home hero cell and the Sleep score. The score sits in the vessel, the state
/// pill and a short blurb underneath.
class _HeroGauge extends ConsumerWidget {
  final _Spec spec;
  const _HeroGauge({required this.spec});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(gaugeStyleProvider);
    return NoopCard(
      squircle: true,
      radius: Metrics.cornerHero,
      bordered: false,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          MetricGauge(
            fraction: (spec.value / 100).clamp(0, 1),
            ramp: spec.ramp,
            size: 168,
            center: Text(spec.valueLabel ?? spec.value.round().toString(),
                style: NoopType.number(52).copyWith(
                  color: gaugeCenterColor(style),
                  shadows: gaugeCenterShadows(style),
                )),
          ),
          const SizedBox(height: Metrics.space16),
          // State chip in the metric colour.
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: spec.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(Metrics.cornerPill),
            ),
            child: Text(spec.state.toUpperCase(),
                style: NoopType.overline
                    .copyWith(color: spec.color, letterSpacing: 1.6)),
          ),
          const SizedBox(height: Metrics.space16),
          Text(spec.blurb,
              textAlign: TextAlign.center,
              style: NoopType.body
                  .copyWith(color: Palette.textSecondary, height: 1.45)),
        ],
      ),
    );
  }
}

/// The intraday timeline in the same recessed squircle surface the Today "Your
/// cards" use, so tapping in keeps the home look.
class _TimelineCard extends StatelessWidget {
  final _Spec spec;
  final List<double> timeline;
  final List<String> axis;
  const _TimelineCard(
      {required this.spec, required this.timeline, required this.axis});

  @override
  Widget build(BuildContext context) {
    final recessed =
        Color.lerp(Palette.surfaceBase, Palette.surfaceRaised, 0.5)!;
    return NoopCard(
      squircle: true,
      radius: Metrics.cornerHero,
      bordered: false,
      fillColor: recessed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TODAY',
              style: NoopType.overline
                  .copyWith(color: Palette.textSecondary, letterSpacing: 1.4)),
          const SizedBox(height: Metrics.space16),
          HealthTimeline(
            values: timeline,
            color: spec.color,
            axisLabels: axis,
            height: 150,
          ),
        ],
      ),
    );
  }
}

class _ContribRow extends StatelessWidget {
  final _Contrib c;
  final List<double> Function(double Function(DayRecord), [int]) tail;
  const _ContribRow({required this.c, required this.tail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Same little liquid bead the Today "Recovery vitals" rows use.
        LiquidVessel(
          fraction: 0.6,
          ramp: [Stop(0, c.color), Stop(1, c.color)],
          size: 26,
        ),
        const SizedBox(width: Metrics.space12),
        Expanded(
          child: Text(c.label,
              style: NoopType.body.copyWith(color: Palette.textSecondary)),
        ),
        if (c.comingSoon)
          const ComingSoonBadge(compact: true)
        else ...[
          Sparkline(values: tail(c.field), color: c.color),
          const SizedBox(width: Metrics.space12),
          Text(c.value,
              style: NoopType.number(18).copyWith(color: Palette.textPrimary)),
          if (c.unit.isNotEmpty) ...[
            const SizedBox(width: 3),
            Text(c.unit,
                style: NoopType.caption.copyWith(color: Palette.textTertiary)),
          ],
        ],
      ],
    );
  }
}

/// Resolved presentation data for one metric.
class _Spec {
  final String title;
  final double value;

  /// Optional pre-formatted hero number (e.g. Effort on the WHOOP 0..21 scale,
  /// ryanbr #45). Falls back to `value.round()` when null. The gauge fill still
  /// uses [value] on its native 0..100 scale.
  final String? valueLabel;
  final List<Stop> ramp;
  final Color color;
  final String state;
  final String blurb;
  final double Function(DayRecord) field;
  final List<_Contrib> contributors;
  const _Spec({
    required this.title,
    required this.value,
    this.valueLabel,
    required this.ramp,
    required this.color,
    required this.state,
    required this.blurb,
    required this.field,
    required this.contributors,
  });
}

class _Contrib {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final double Function(DayRecord) field;

  /// No real source yet — the row shows a "coming soon" chip instead of a
  /// (fabricated) value + sparkline.
  final bool comingSoon;

  const _Contrib(this.label, this.value, this.unit, this.color, this.field,
      {this.comingSoon = false});
}

_Spec _specFor(MetricKind kind, DayRecord day, EffortScale effortScale) {
  switch (kind) {
    case MetricKind.recovery:
      return _Spec(
        title: 'Recovery',
        value: day.charge,
        ramp: Palette.recoveryStops,
        color: Palette.chargeColor,
        state: Palette.recoveryState(day.charge),
        blurb: day.charge < 50
            ? 'Your body is still catching up. Keep effort moderate and prioritise rest today.'
            : 'You are well recovered and have headroom for a harder session.',
        field: (d) => d.charge,
        contributors: [
          _Contrib('Heart rate variability', '${day.hrv.round()}', 'ms',
              Palette.metricCyan, (d) => d.hrv),
          _Contrib('Resting heart rate', '${day.rhr.round()}', 'bpm',
              Palette.metricRose, (d) => d.rhr),
          _Contrib('Respiratory rate', day.respiratoryRate.toStringAsFixed(1),
              'rpm', Palette.accent, (d) => d.respiratoryRate,
              comingSoon: true),
        ],
      );
    case MetricKind.strain:
      final s = day.effort;
      return _Spec(
        title: 'Strain',
        value: s,
        valueLabel: Fmt.effort(s, effortScale),
        ramp: Palette.effortGradientStops,
        color: Palette.effortColor,
        state: s < 33 ? 'Light' : (s < 66 ? 'Moderate' : 'Strenuous'),
        blurb: s < 33
            ? 'A light day so far. There is plenty of room to build load.'
            : 'You have put meaningful load on your body today.',
        field: (d) => d.effort,
        contributors: [
          _Contrib('Calories', Fmt.intComma(day.calories), 'kcal',
              Palette.effortColor, (d) => d.calories.toDouble(),
              comingSoon: true),
          _Contrib('Steps', Fmt.intComma(day.steps), '', Palette.metricPurple,
              (d) => d.steps.toDouble(),
              comingSoon: true),
          _Contrib('Stress', '${day.stress.round()}', '', Palette.stressColor,
              (d) => d.stress),
        ],
      );
    case MetricKind.sleep:
      final v = day.rest;
      return _Spec(
        title: 'Sleep',
        value: v,
        ramp: Palette.restGradientStops,
        color: Palette.restColor,
        state: v < 50 ? 'Poor' : (v < 70 ? 'Fair' : (v < 85 ? 'Good' : 'Optimal')),
        blurb: v < 70
            ? 'Sleep fell short of what your body needed. An earlier night would help.'
            : 'You hit most of your sleep need — a solid night of recovery.',
        field: (d) => d.rest,
        contributors: [
          _Contrib('Respiratory rate', day.respiratoryRate.toStringAsFixed(1),
              'rpm', Palette.accent, (d) => d.respiratoryRate,
              comingSoon: true),
          _Contrib('Resting heart rate', '${day.rhr.round()}', 'bpm',
              Palette.metricRose, (d) => d.rhr),
          _Contrib('Heart rate variability', '${day.hrv.round()}', 'ms',
              Palette.metricCyan, (d) => d.hrv),
        ],
      );
    case MetricKind.stress:
      final s = day.stress;
      final high = (s + (100 - s) * 0.75).clamp(0, 100);
      final low = (s * 0.3).clamp(0, 100);
      return _Spec(
        title: 'Stress',
        value: s,
        ramp: Palette.stressGradientStops,
        color: Palette.stressColor,
        state: s < 33 ? 'Low' : (s < 66 ? 'Moderate' : 'High'),
        blurb: s < 33
            ? 'Your body stayed calm today — a low-stress day with plenty of recovery signal.'
            : (s < 66
                ? 'A moderate-stress day. Some load on your nervous system, still within range.'
                : 'A high-stress day. Consider some downregulation — breathwork or an early night.'),
        field: (d) => d.stress,
        contributors: [
          _Contrib('Highest', '${high.round()}', '', Palette.statusCritical,
              (d) => (d.stress + (100 - d.stress) * 0.75).clamp(0, 100)),
          _Contrib('Lowest', '${low.round()}', '', Palette.metricCyan,
              (d) => (d.stress * 0.3).clamp(0, 100)),
          _Contrib('Resting heart rate', '${day.rhr.round()}', 'bpm',
              Palette.metricRose, (d) => d.rhr),
        ],
      );
  }
}
