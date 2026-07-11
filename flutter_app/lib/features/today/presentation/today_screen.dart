import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/models.dart';
import 'package:noop/core/state/format.dart';
import 'package:noop/core/state/providers.dart';
import 'package:noop/shared/widgets/backgrounds.dart';
import 'package:noop/shared/widgets/behavior.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/charts.dart';
import 'package:noop/shared/widgets/coming_soon.dart';
import 'package:noop/shared/widgets/health_charts.dart';
import 'package:noop/shared/widgets/liquid.dart';
import 'package:noop/shared/widgets/metric_gauge.dart';
import 'package:noop/shared/widgets/motion.dart';
import 'package:noop/shared/widgets/tiles.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/features/settings/presentation/device_settings_screen.dart';
import 'package:noop/features/metrics/presentation/metric_detail_screen.dart';
import 'package:noop/features/sleep/presentation/sleep_screen.dart';

/// Home — a flattened Material 3 rebuild of the shipping Liquid Today: the
/// scene header + NOOP wordmark + the three water gauges (Charge · Effort · Rest),
/// then Heart rate, Your cards, Synthesis, Recovery vitals, Key metrics, Last
/// workouts and Data sources — the same sections the iOS home shows.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  static const _pad = EdgeInsets.symmetric(horizontal: Metrics.space16);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(daysProvider);
    final maxI = days.length - 1;
    final idx = ref.watch(selectedDayIndexProvider).clamp(0, maxI);
    final day = days[idx];
    final media = MediaQuery.of(context);

    List<double> tail(double Function(DayRecord) f, [int n = 14]) =>
        days.sublist(days.length - n).map(f).toList();

    var i = 0;
    Widget reveal(Widget child) =>
        Reveal(index: i++, child: Padding(padding: _pad, child: child));

    return ScenicBackground(
      child: RefreshIndicator(
        color: Palette.accent,
        backgroundColor: Palette.surfaceRaised,
        onRefresh: () => Future<void>.delayed(const Duration(milliseconds: 700)),
        child: ListView(
          key: const PageStorageKey<String>('screen:Today'),
          padding: EdgeInsets.only(
            top: media.padding.top + Metrics.space24,
            bottom: media.padding.bottom + 96,
          ),
          children: [
            reveal(_Scene(
              day: day,
              battery: ref.watch(strapBatteryProvider),
              isToday: idx == maxI,
              canPrev: idx > 0,
              canNext: idx < maxI,
              onPrev: () =>
                  ref.read(selectedDayIndexProvider.notifier).state = idx - 1,
              onNext: () =>
                  ref.read(selectedDayIndexProvider.notifier).state = idx + 1,
            )),
            const SizedBox(height: Metrics.space16),
            reveal(_Hero(day: day)),
            const SizedBox(height: Metrics.space24),
            reveal(_head('Stress & Energy')),
            reveal(_StressEnergy(day: day)),
            const SizedBox(height: Metrics.space24),
            reveal(_head('Your cards', trailing: 'Customise')),
            reveal(_YourCards(day: day, tail: tail)),
            const SizedBox(height: Metrics.space24),
            reveal(_head('Recovery vitals')),
            reveal(_RecoveryVitals(day: day, tail: tail)),
            const SizedBox(height: Metrics.space24),
            reveal(_head('Key metrics', trailing: '14-day trend')),
            reveal(_KeyMetrics(day: day, tail: tail)),
          ],
        ),
      ),
    );
  }

  static Widget _head(String title, {String? trailing}) => Padding(
        padding: const EdgeInsets.only(bottom: Metrics.space8, top: Metrics.space2),
        child: Row(
          children: [
            Expanded(
              child: Text(title.toUpperCase(),
                  style: NoopType.overline.copyWith(
                      color: Palette.textTertiary, letterSpacing: 1.6)),
            ),
            if (trailing != null)
              Text(trailing,
                  style: NoopType.caption.copyWith(color: Palette.textTertiary)),
          ],
        ),
      );

}

/// Header row — day title + date on the left, two matching status pills on the
/// right: a live heart-rate pill and the strap battery, both the same shape so
/// they read as a proportional pair.
class _Scene extends StatelessWidget {
  final DayRecord day;
  final double battery;
  final bool isToday;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _Scene({
    required this.day,
    required this.battery,
    required this.isToday,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: live heart rate.
        _HeartRatePill(day: day),
        // Centre: the day, with prev/next switches.
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavArrow(icon: Icons.chevron_left_rounded, enabled: canPrev, onTap: onPrev),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isToday ? 'TODAY' : Fmt.dayTitle(day.date).toUpperCase(),
                    style: NoopType.overline
                        .copyWith(color: Palette.textPrimary, letterSpacing: 1.4),
                  ),
                  Text(Fmt.shortDate(day.date),
                      style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
                ],
              ),
              _NavArrow(icon: Icons.chevron_right_rounded, enabled: canNext, onTap: onNext),
            ],
          ),
        ),
        // Right: strap charge — opens device settings.
        GestureDetector(
          onTap: () => Navigator.of(context)
              .push(noopRoute(const DeviceSettingsScreen())),
          child: _StrapBattery(level: battery),
        ),
      ],
    );
  }
}

/// A subtle chevron used to page between days; dimmed when at a boundary.
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon,
          size: 22,
          color: enabled ? Palette.textSecondary : Palette.textTertiary.withValues(alpha: 0.4)),
    );
  }
}


/// Live heart-rate pill — same silhouette as the battery pill (a heart glyph +
/// the current bpm), so the header pair stays visually balanced.
class _HeartRatePill extends StatelessWidget {
  final DayRecord day;
  const _HeartRatePill({required this.day});

  @override
  Widget build(BuildContext context) {
    final bpm = day.hr.isEmpty ? null : day.hr.last.bpm.round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.surfaceOverlay.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Metrics.cornerPill),
        border: Border.all(color: Palette.hairline.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, size: 13, color: Palette.metricRose),
          const SizedBox(width: 5),
          Text(bpm == null ? '--' : '$bpm',
              style: NoopType.captionNumber.copyWith(color: Palette.textSecondary)),
        ],
      ),
    );
  }
}

/// WHOOP-style strap battery pill.
class _StrapBattery extends StatelessWidget {
  final double level;
  const _StrapBattery({required this.level});

  @override
  Widget build(BuildContext context) {
    final l = level.clamp(0.0, 1.0);
    final color = l > 0.4
        ? Palette.statusPositive
        : (l > 0.15 ? Palette.statusWarning : Palette.statusCritical);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.surfaceOverlay.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Metrics.cornerPill),
        border: Border.all(color: Palette.hairline.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BatteryGlyph(level: l, color: color),
          const SizedBox(width: 5),
          Text('${(l * 100).round()}',
              style: NoopType.captionNumber.copyWith(color: Palette.textSecondary)),
        ],
      ),
    );
  }
}

class _BatteryGlyph extends StatelessWidget {
  final double level;
  final Color color;
  const _BatteryGlyph({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 12,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 12,
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Palette.textTertiary, width: 1),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: level.clamp(0.06, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 2,
            height: 5,
            margin: const EdgeInsets.only(left: 1),
            decoration: BoxDecoration(
              color: Palette.textTertiary,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(1)),
            ),
          ),
        ],
      ),
    );
  }
}

/// The three hero water gauges — Charge · Effort · Rest — framed as one floating
/// frosted-glass panel that echoes the bottom nav bar's language: a translucent
/// pane over the scenic sky (real backdrop blur), a hairline outline and a soft
/// drop shadow. The signature liquid gauges stay; a faint top sheen and slim
/// vertical dividers give it depth without the old per-cell colour boxes.
class _Hero extends StatelessWidget {
  final DayRecord day;
  const _Hero({required this.day});

  void _open(BuildContext context, MetricKind kind) {
    // Sleep has its own rich, fully-built screen; the others use the generic
    // metric detail.
    final Widget screen = kind == MetricKind.sleep
        ? const SleepScreen()
        : MetricDetailScreen(kind: kind);
    Navigator.of(context).push(noopRoute(Scaffold(body: screen)));
  }

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _HeroCell(
                label: 'Recovery',
                value: day.charge,
                ramp: Palette.recoveryStops,
                color: Palette.chargeColor,
                onTap: () => _open(context, MetricKind.recovery),
              ),
            ),
            const _CellDivider(),
            Expanded(
              child: _HeroCell(
                label: 'Strain',
                value: day.effort,
                ramp: Palette.effortGradientStops,
                color: Palette.effortColor,
                onTap: () => _open(context, MetricKind.strain),
              ),
            ),
            const _CellDivider(),
            Expanded(
              child: _HeroCell(
                label: 'Sleep',
                value: day.rest,
                ramp: Palette.restGradientStops,
                color: Palette.restColor,
                onTap: () => _open(context, MetricKind.sleep),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating frosted-glass shell — same visual grammar as the nav bar: soft
/// shadow lift, thin light hairline, translucent fill, plus a real backdrop
/// blur so the scenic sky diffuses through it.
class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(40);
    // Light mode: a clean white card with a soft lift and a subtle hairline —
    // no dark frost. Dark mode: the translucent frosted pane over the scenic sky.
    if (Palette.isLight) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.surfaceRaised,
          borderRadius: radius,
          border: Border.all(color: Palette.hairline.withValues(alpha: 0.8), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
          child: child,
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
            decoration: BoxDecoration(
              // Flat, uniform frosted fill — no gradient, no outline edge.
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: radius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Slim inset divider between hero cells.
class _CellDivider extends StatelessWidget {
  const _CellDivider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 12),
        color: (Palette.isLight ? Colors.black : Colors.white)
            .withValues(alpha: Palette.isLight ? 0.06 : 0.08),
      );
}

class _HeroCell extends ConsumerWidget {
  final String label;
  final double value;
  final List<Stop> ramp;
  final Color color;
  final VoidCallback? onTap;
  const _HeroCell({
    required this.label,
    required this.value,
    required this.ramp,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(gaugeStyleProvider);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MetricGauge(
                fraction: (value / 100).clamp(0, 1),
                ramp: ramp,
                size: 78,
                center: Text(value.round().toString(),
                    style: NoopType.number(24).copyWith(
                      color: gaugeCenterColor(style),
                      shadows: gaugeCenterShadows(style),
                    )),
              ),
              const SizedBox(height: Metrics.space12),
              Text(label.toUpperCase(),
                  style: NoopType.overline.copyWith(color: color, letterSpacing: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Stress & Energy" — today's stress with high/low/average + a compact dial,
/// and an energy (body battery) bar. Mirrors the Noop home section.
class _StressEnergy extends ConsumerWidget {
  final DayRecord day;
  const _StressEnergy({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stress = day.stress;
    final avg = stress.round();
    final high = (stress + (100 - stress) * 0.75).clamp(0, 100).round();
    final low = (stress * 0.3).clamp(0, 100).round();
    final label = stress < 33 ? 'Low' : (stress < 66 ? 'Med' : 'High');
    final updated = day.hr.isEmpty ? null : Fmt.clock(day.hr.last.time);
    final style = ref.watch(gaugeStyleProvider);
    final centerColor = gaugeCenterColor(style);

    return Column(
      children: [
        NoopCard(
          bordered: false,
          squircle: true,
          radius: 36,
          onTap: () => Navigator.of(context)
              .push(noopRoute(const MetricDetailScreen(kind: MetricKind.stress))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: Palette.stressColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: Metrics.space8),
                  Text("Today's stress",
                      style: NoopType.headline.copyWith(color: Palette.textPrimary)),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: Palette.textTertiary, size: 20),
                ],
              ),
              // Always reserve this line so switching to a day without HR data
              // doesn't collapse it and shift the whole card up.
              const SizedBox(height: 2),
              Text(updated != null ? 'Last updated at $updated' : ' ',
                  style: NoopType.caption.copyWith(color: Palette.textTertiary)),
              const SizedBox(height: Metrics.space16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _stat('Highest', high, Palette.statusCritical),
                        _stat('Lowest', low, Palette.metricCyan),
                        _stat('Average', avg, Palette.chargeColor),
                      ],
                    ),
                  ),
                  const SizedBox(width: Metrics.space12),
                  MetricGauge(
                    fraction: (stress / 100).clamp(0, 1),
                    ramp: Palette.stressGradientStops,
                    size: 66,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$avg',
                            style: NoopType.number(18).copyWith(
                              color: centerColor,
                              shadows: gaugeCenterShadows(style),
                            )),
                        Text(label,
                            style: NoopType.footnote.copyWith(
                                color: centerColor.withValues(alpha: 0.75))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Metrics.gap),
        NoopCard(
          bordered: false,
          squircle: true,
          radius: 36,
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, color: Palette.chargeColor, size: 22),
              const SizedBox(width: Metrics.space12),
              Expanded(child: _EnergyBar(fraction: (day.vitality / 100).clamp(0, 1))),
              const SizedBox(width: Metrics.space12),
              Text('${day.vitality}%',
                  style: NoopType.number(18).copyWith(color: Palette.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, int value, Color color) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: NoopType.number(22).copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label, style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
          ],
        ),
      );
}

/// A segmented "body battery" bar filled to [fraction].
class _EnergyBar extends StatelessWidget {
  final double fraction;
  const _EnergyBar({required this.fraction});

  @override
  Widget build(BuildContext context) {
    const n = 26;
    final filled = (fraction * n).round();
    return Row(
      children: [
        for (var i = 0; i < n; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.8),
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: i < filled ? Palette.chargeColor : Palette.surfaceInset,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "Your cards" — the three hero scores, each a big card with a detailed,
/// jagged up/down timeline (à la a sleep timeline). Tapping opens the detail.
class _YourCards extends StatelessWidget {
  final DayRecord day;
  final List<double> Function(double Function(DayRecord), [int]) tail;
  const _YourCards({required this.day, required this.tail});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetricChartCard(
          kind: MetricKind.recovery,
          label: 'Recovery',
          value: day.charge.round().toString(),
          unit: '%',
          state: Palette.recoveryState(day.charge),
          color: Palette.chargeColor,
          caption: 'Higher, steadier peaks mean better readiness.',
          day: day,
        ),
        const SizedBox(height: Metrics.gap),
        _MetricChartCard(
          kind: MetricKind.strain,
          label: 'Strain',
          value: day.effort.round().toString(),
          unit: '',
          state: day.effort < 33 ? 'Light' : (day.effort < 66 ? 'Moderate' : 'Strenuous'),
          color: Palette.effortColor,
          caption: 'Peaks mark bursts of exertion through the day.',
          day: day,
        ),
        const SizedBox(height: Metrics.gap),
        _MetricChartCard(
          kind: MetricKind.sleep,
          label: 'Sleep timeline',
          value: day.rest.round().toString(),
          unit: '%',
          state: day.rest < 50
              ? 'Poor'
              : (day.rest < 70 ? 'Fair' : (day.rest < 85 ? 'Good' : 'Optimal')),
          color: Palette.restColor,
          caption: 'Peaks may indicate brief awakenings or stress.',
          day: day,
        ),
      ],
    );
  }
}

/// A big metric card: title + "View" link, current value + state, and a
/// detailed jagged timeline underneath with a short caption.
class _MetricChartCard extends StatelessWidget {
  final MetricKind kind;
  final String label;
  final String value;
  final String unit;
  final String state;
  final Color color;
  final String caption;
  final DayRecord day;
  const _MetricChartCard({
    required this.kind,
    required this.label,
    required this.value,
    required this.unit,
    required this.state,
    required this.color,
    required this.caption,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final (series, axis) = metricTimeline(day, kind);
    // Recessed fill — halfway between the background and a raised card, so the
    // cards sit closer to the canvas.
    final recessed =
        Color.lerp(Palette.surfaceBase, Palette.surfaceRaised, 0.5)!;
    return NoopCard(
      squircle: true,
      radius: 36,
      bordered: false,
      fillColor: recessed,
      onTap: () => Navigator.of(context)
          .push(noopRoute(MetricDetailScreen(kind: kind))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label.toUpperCase(),
                  style: NoopType.overline
                      .copyWith(color: Palette.textSecondary, letterSpacing: 1.4)),
              const Spacer(),
              Text('View', style: NoopType.footnote.copyWith(color: color)),
              Icon(Icons.chevron_right_rounded, color: color, size: 18),
            ],
          ),
          const SizedBox(height: Metrics.space10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: NoopType.number(30).copyWith(color: Palette.textPrimary)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(unit,
                    style: NoopType.subhead.copyWith(color: Palette.textTertiary)),
              ],
              const SizedBox(width: Metrics.space10),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(state.toUpperCase(),
                    style: NoopType.footnote
                        .copyWith(color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: Metrics.space16),
          HealthTimeline(
            values: series,
            color: color,
            axisLabels: axis,
            height: 130,
          ),
          const SizedBox(height: Metrics.space10),
          Text(caption,
              style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
        ],
      ),
    );
  }
}

class _RecoveryVitals extends StatelessWidget {
  final DayRecord day;
  final List<double> Function(double Function(DayRecord), [int]) tail;
  const _RecoveryVitals({required this.day, required this.tail});

  @override
  Widget build(BuildContext context) {
    return NoopCard(
      child: Column(
        children: [
          _vital('Heart rate variability', '${day.hrv.round()}', 'ms',
              tail((d) => d.hrv), Palette.metricCyan),
          const SizedBox(height: Metrics.space14),
          _vital('Resting heart rate', '${day.rhr.round()}', 'bpm',
              tail((d) => d.rhr), Palette.metricRose),
        ],
      ),
    );
  }

  Widget _vital(String label, String value, String unit, List<double> spark, Color color) {
    return Row(
      children: [
        LiquidVessel(
          fraction: 0.6,
          ramp: [Stop(0, color), Stop(1, color)],
          size: 26,
        ),
        const SizedBox(width: Metrics.space12),
        Expanded(
          child: Text(label, style: NoopType.body.copyWith(color: Palette.textSecondary)),
        ),
        Sparkline(values: spark, color: color),
        const SizedBox(width: Metrics.space12),
        Text(value, style: NoopType.number(18).copyWith(color: Palette.textPrimary)),
        const SizedBox(width: 3),
        Text(unit, style: NoopType.caption.copyWith(color: Palette.textTertiary)),
      ],
    );
  }
}

/// Key metrics — a 3-column grid: Recovery, Strain, Sleep, HRV, Rest HR, Steps.
class _KeyMetrics extends StatelessWidget {
  final DayRecord day;
  final List<double> Function(double Function(DayRecord), [int]) tail;
  const _KeyMetrics({required this.day, required this.tail});

  @override
  Widget build(BuildContext context) {
    return MetricGrid(
      columns: 3,
      [
        MetricTile(
          label: 'HRV',
          value: day.hrv.round().toString(),
          unit: 'ms',
          spark: tail((d) => d.hrv),
          accent: Palette.metricCyan,
        ),
        MetricTile(
          label: 'Rest HR',
          value: day.rhr.round().toString(),
          spark: tail((d) => d.rhr),
          accent: Palette.metricRose,
        ),
        // No real steps source yet — a planned placeholder, not a fake count.
        const ComingSoonTile(label: 'Steps', icon: Icons.directions_walk_rounded),
        MetricTile(
          label: 'Stress',
          value: day.stress.round().toString(),
          spark: tail((d) => d.stress),
          accent: Palette.stressColor,
        ),
        MetricTile(
          label: 'Vitality',
          value: day.vitality.toString(),
          spark: tail((d) => d.vitality.toDouble()),
          accent: Palette.chargeColor,
        ),
        // Fitness age has no real source yet.
        const ComingSoonTile(
            label: 'Fitness age', icon: Icons.cake_rounded),
      ],
    );
  }
}

