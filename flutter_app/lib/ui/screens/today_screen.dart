import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../state/format.dart';
import '../../state/providers.dart';
import '../components/backgrounds.dart';
import '../components/behavior.dart';
import '../components/cards.dart';
import '../components/charts.dart';
import '../components/common.dart';
import '../components/liquid.dart';
import '../components/motion.dart';
import '../components/tiles.dart';
import '../theme/metrics.dart';
import '../theme/palette.dart';

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
    final day = days.last;
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
              name: ref.watch(profileProvider).name,
              battery: ref.watch(strapBatteryProvider),
              onAdd: () => _quickActions(context),
            )),
            const SizedBox(height: Metrics.space16),
            reveal(_Hero(day: day)),
            const SizedBox(height: Metrics.space24),
            reveal(_HeartRate(day: day)),
            const SizedBox(height: Metrics.space24),
            reveal(_head('Your cards', trailing: 'Customise')),
            reveal(_YourCards(day: day)),
            const SizedBox(height: Metrics.space24),
            reveal(_Synthesis(day: day, name: ref.watch(profileProvider).name)),
            const SizedBox(height: Metrics.space24),
            reveal(_head('Recovery vitals')),
            reveal(_RecoveryVitals(day: day, tail: tail)),
            const SizedBox(height: Metrics.space24),
            reveal(_head('Key metrics', trailing: '14-day trend')),
            reveal(_KeyMetrics(day: day, tail: tail)),
            if (day.workouts.isNotEmpty) ...[
              const SizedBox(height: Metrics.space24),
              reveal(_head('Last workouts', trailing: '${day.workouts.length} total')),
              for (final w in day.workouts) reveal(_WorkoutRow(w)),
            ],
            const SizedBox(height: Metrics.space24),
            reveal(_head('Data sources', trailing: 'Provenance')),
            reveal(_DataSources(battery: ref.watch(strapBatteryProvider))),
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

  static void _quickActions(BuildContext context) {
    showNoopSheet<void>(
      context,
      title: 'Quick actions',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final a in const [
            (Icons.favorite_rounded, 'Live heart rate'),
            (Icons.fitness_center_rounded, 'Start workout'),
            (Icons.edit_note_rounded, 'Log journal'),
            (Icons.self_improvement_rounded, 'Breathe'),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(a.$1, color: Palette.accent),
              title: Text(a.$2, style: TextStyle(color: Palette.textPrimary)),
              trailing: Icon(Icons.chevron_right_rounded, color: Palette.textTertiary),
              onTap: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}

/// Header row (day title + date + controls) and the centred NOOP wordmark.
class _Scene extends StatelessWidget {
  final DayRecord day;
  final String name;
  final double battery;
  final VoidCallback onAdd;
  const _Scene({required this.day, required this.name, required this.battery, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Fmt.dayTitle(day.date),
                      style: NoopType.display(28).copyWith(color: Palette.textPrimary)),
                  Text(Fmt.longDate(day.date),
                      style: NoopType.subhead.copyWith(color: Palette.textTertiary)),
                ],
              ),
            ),
            _CircleButton(
              icon: Icons.favorite_rounded,
              color: Palette.chargeColor,
              onTap: () {},
            ),
            const SizedBox(width: Metrics.space8),
            _Avatar(name: name),
            const SizedBox(width: Metrics.space8),
            _CircleButton(icon: Icons.add_rounded, color: Palette.textPrimary, onTap: onAdd),
            const SizedBox(width: Metrics.space8),
            _StrapBattery(level: battery),
          ],
        ),
        const SizedBox(height: Metrics.space20),
        Center(
          child: Text('NOOP',
              style: NoopType.overline.copyWith(
                color: Palette.textSecondary.withValues(alpha: 0.55),
                letterSpacing: 6,
                fontSize: 13,
              )),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Palette.surfaceOverlay.withValues(alpha: 0.5),
        shape: CircleBorder(
          side: BorderSide(color: Palette.hairline.withValues(alpha: 0.6), width: 1),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 36, height: 36, child: Icon(icon, size: 19, color: color)),
        ),
      );
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Palette.surfaceOverlay.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Metrics.cornerPill),
        border: Border.all(color: Palette.hairline.withValues(alpha: 0.6), width: 1),
      ),
      child: _BatteryGlyph(level: l, color: color),
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

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});
  @override
  Widget build(BuildContext context) {
    final stops = Palette.titaniumGradient;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Palette.gradientColors(stops),
          stops: Palette.gradientPositions(stops),
        ),
      ),
      child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: NoopType.headline.copyWith(color: Palette.titaniumDeep)),
    );
  }
}

/// The three hero water gauges — Charge · Effort · Rest, equal columns.
class _Hero extends StatelessWidget {
  final DayRecord day;
  const _Hero({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Metrics.space16, horizontal: Metrics.space12),
      decoration: BoxDecoration(
        color: const Color(0xCC0D0E14),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.11), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 30, offset: const Offset(0, 16)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _HeroCell(
              label: 'Charge',
              value: day.charge,
              ramp: Palette.recoveryStops,
              color: Palette.chargeColor,
              pill: 'WHOOP',
            ),
          ),
          Expanded(
            child: _HeroCell(
              label: 'Effort',
              value: day.effort,
              ramp: Palette.effortGradientStops,
              color: Palette.effortColor,
            ),
          ),
          Expanded(
            child: _HeroCell(
              label: 'Rest',
              value: day.rest,
              ramp: Palette.restGradientStops,
              color: Palette.restColor,
              pill: 'WHOOP',
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCell extends StatelessWidget {
  final String label;
  final double value;
  final List<Stop> ramp;
  final Color color;
  final String? pill;
  const _HeroCell({
    required this.label,
    required this.value,
    required this.ramp,
    required this.color,
    this.pill,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiquidVessel(
          fraction: (value / 100).clamp(0, 1),
          ramp: ramp,
          size: 84,
          center: Text(value.round().toString(),
              style: NoopType.number(24).copyWith(
                color: Colors.white,
                shadows: [const Shadow(color: Colors.black54, blurRadius: 6)],
              )),
        ),
        const SizedBox(height: Metrics.space8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label.toUpperCase(),
                style: NoopType.overline.copyWith(color: color, letterSpacing: 1.4)),
            const SizedBox(width: 3),
            Icon(Icons.chevron_right_rounded, size: 12, color: color.withValues(alpha: 0.6)),
          ],
        ),
        const SizedBox(height: 5),
        if (pill != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(Metrics.cornerPill),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1),
            ),
            child: Text(pill!,
                style: NoopType.footnote.copyWith(
                    color: Palette.textSecondary, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 8.5)),
          )
        else
          const SizedBox(height: 18),
      ],
    );
  }
}

class _HeartRate extends StatelessWidget {
  final DayRecord day;
  const _HeartRate({required this.day});
  @override
  Widget build(BuildContext context) {
    if (day.hr.isEmpty) return const SizedBox.shrink();
    final bpm = day.hr.map((s) => s.bpm).toList();
    final current = bpm.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TodayScreen._head('Heart rate', trailing: 'Live'),
        NoopCard(
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.favorite_rounded, size: 16, color: Palette.metricRose),
                  const SizedBox(width: 6),
                  Text('${current.round()}',
                      style: NoopType.number(22).copyWith(color: Palette.textPrimary)),
                  const SizedBox(width: 3),
                  Text('bpm', style: NoopType.caption.copyWith(color: Palette.textTertiary)),
                  const Spacer(),
                  Text('Full day', style: NoopType.caption.copyWith(color: Palette.accent)),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Palette.accent),
                ],
              ),
              const SizedBox(height: Metrics.space10),
              SizedBox(
                height: Metrics.compactChartHeight,
                child: Sparkline(
                  values: bpm,
                  color: Palette.metricRose,
                  width: double.infinity,
                  height: Metrics.compactChartHeight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Your cards" — the WHOOP-style dashboard rows.
class _YourCards extends StatelessWidget {
  final DayRecord day;
  const _YourCards({required this.day});

  @override
  Widget build(BuildContext context) {
    final rows = <_DashRow>[
      _DashRow(Icons.bolt_rounded, 'STRESS', _stressLabel(day.stress),
          day.stress.round().toString(), '', Palette.stressColor),
      _DashRow(Icons.hourglass_bottom_rounded, 'FITNESS AGE', 'estimated',
          day.fitnessAge.toString(), 'yr', Palette.metricCyan),
      _DashRow(Icons.local_fire_department_rounded, 'VITALITY', 'today',
          day.vitality.toString(), '', Palette.chargeColor),
      _DashRow(Icons.monitor_heart_rounded, 'HRV', 'last night',
          day.hrv.round().toString(), 'ms', Palette.metricPurple),
      _DashRow(Icons.favorite_border_rounded, 'RESTING HR', 'last night',
          day.rhr.round().toString(), 'bpm', Palette.metricRose),
    ];
    return NoopCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Metrics.cardPadding),
                child: const Hairline(),
              ),
          ],
        ],
      ),
    );
  }

  static String _stressLabel(double s) => s < 33 ? 'low' : (s < 66 ? 'medium' : 'high');
}

class _DashRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final String value;
  final String unit;
  final Color color;
  const _DashRow(this.icon, this.label, this.sub, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Metrics.cardPadding, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(Metrics.cornerSm),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: Metrics.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: NoopType.overline.copyWith(color: Palette.textSecondary)),
                Text(sub, style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
              ],
            ),
          ),
          Text(value, style: NoopType.number(22).copyWith(color: Palette.textPrimary)),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(unit, style: NoopType.caption.copyWith(color: Palette.textTertiary)),
            ),
          ],
          const SizedBox(width: Metrics.space8),
          Icon(Icons.chevron_right_rounded, color: Palette.textTertiary, size: 20),
        ],
      ),
    );
  }
}

/// Synthesis — a greeting, readiness pills, and a one-line read of the day.
class _Synthesis extends StatelessWidget {
  final DayRecord day;
  final String name;
  const _Synthesis({required this.day, required this.name});

  @override
  Widget build(BuildContext context) {
    final state = Palette.recoveryState(day.charge);
    final stateColor = Palette.recoveryColor(day.charge);
    final calibrating = day.hr.length < 4;
    return SectionCard(
      title: 'Synthesis',
      accent: Palette.chargeColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_greeting()}, ${name.isEmpty ? 'Athlete' : name}.',
              style: NoopType.title2.copyWith(color: Palette.textPrimary)),
          const SizedBox(height: Metrics.space10),
          Row(
            children: [
              _pill(state, stateColor, filled: true),
              const SizedBox(width: Metrics.space8),
              _pill(calibrating ? 'Calibrating' : 'Solid',
                  calibrating ? Palette.statusWarning : Palette.chargeColor),
            ],
          ),
          const SizedBox(height: Metrics.space12),
          Text(_summary(),
              style: NoopType.body.copyWith(color: Palette.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _summary() {
    final c = day.charge.round();
    final restrained = day.charge < 50;
    final base = 'Charge is $c%, ${Palette.recoveryState(day.charge).toLowerCase()}. '
        'HRV ${day.hrv.round()} ms · resting HR ${day.rhr.round()} bpm.';
    return restrained
        ? '$base Keep effort moderate and prioritise rest today.'
        : '$base You have headroom for a harder session.';
  }

  Widget _pill(String text, Color color, {bool filled = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: filled ? 0.16 : 0.0),
          borderRadius: BorderRadius.circular(Metrics.cornerPill),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(text.toUpperCase(),
                style: NoopType.footnote.copyWith(
                    color: color, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          ],
        ),
      );
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
          const SizedBox(height: Metrics.space14),
          _vital('Respiratory rate', day.respiratoryRate.toStringAsFixed(1), 'rpm',
              tail((d) => d.respiratoryRate), Palette.accent),
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
          label: 'Recovery',
          value: day.charge.round().toString(),
          unit: '%',
          spark: tail((d) => d.charge),
          sparkRamp: Palette.recoveryStops,
          accent: Palette.chargeColor,
        ),
        MetricTile(
          label: 'Strain',
          value: day.effort.round().toString(),
          spark: tail((d) => d.effort),
          accent: Palette.effortColor,
        ),
        MetricTile(
          label: 'Sleep',
          value: day.rest.round().toString(),
          unit: '%',
          spark: tail((d) => d.rest),
          accent: Palette.restColor,
        ),
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
        MetricTile(
          label: 'Steps',
          value: Fmt.intComma(day.steps),
          spark: tail((d) => d.steps.toDouble()),
          accent: Palette.metricPurple,
        ),
      ],
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  final Workout w;
  const _WorkoutRow(this.w);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Metrics.gap),
      child: NoopCard(
        accent: Palette.effortColor,
        child: Row(
          children: [
            Icon(Icons.fitness_center_rounded, color: Palette.effortColor, size: 22),
            const SizedBox(width: Metrics.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.sport, style: NoopType.headline.copyWith(color: Palette.textPrimary)),
                  Text('${Fmt.hm(w.duration)} · ${w.calories} kcal · ${w.avgHr.round()} bpm avg',
                      style: NoopType.caption.copyWith(color: Palette.textTertiary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(w.effort.toStringAsFixed(1),
                    style: NoopType.number(20).copyWith(color: Palette.effortColor)),
                Text('effort', style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Data sources — provenance + the strap battery row.
class _DataSources extends StatelessWidget {
  final double battery;
  const _DataSources({required this.battery});

  @override
  Widget build(BuildContext context) {
    return NoopCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.cloud_done_rounded, size: 20, color: Palette.accent),
              const SizedBox(width: Metrics.space12),
              Expanded(
                child: Text('Synced from on-device sensors',
                    style: NoopType.body.copyWith(color: Palette.textSecondary)),
              ),
              Text('View sources', style: NoopType.caption.copyWith(color: Palette.accent)),
              Icon(Icons.chevron_right_rounded, size: 16, color: Palette.accent),
            ],
          ),
          const SizedBox(height: Metrics.space12),
          const Hairline(),
          const SizedBox(height: Metrics.space12),
          Row(
            children: [
              Icon(Icons.watch_rounded, size: 20, color: Palette.textTertiary),
              const SizedBox(width: Metrics.space12),
              Expanded(
                child: Text('Strap battery',
                    style: NoopType.body.copyWith(color: Palette.textSecondary)),
              ),
              _StrapBattery(level: battery),
            ],
          ),
        ],
      ),
    );
  }
}
