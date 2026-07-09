import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../state/format.dart';
import '../../state/providers.dart';
import '../components/cards.dart';
import '../components/charts.dart';
import '../components/common.dart';
import '../components/scaffold.dart';
import '../theme/metrics.dart';
import '../theme/palette.dart';

/// A trailing time window over the day history.
enum _Range {
  week('Week', 7),
  month('Month', 30),
  quarter('Quarter', 90),
  all('All', null);

  const _Range(this.label, this.days);
  final String label;
  final int? days;
}

/// Trends overview — a range-driven Charge hero, daily-signal sparklines and a
/// recovery calendar. Holds the selected time-range in local state.
class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  _Range _range = _Range.week;

  static double _avg(List<double> v) =>
      v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;
  static double _max(List<double> v) => v.isEmpty ? 0 : v.reduce(math.max);
  static double _min(List<double> v) => v.isEmpty ? 0 : v.reduce(math.min);

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(daysProvider);

    final want = _range.days ?? days.length;
    final n = math.min(want, days.length);
    final window = n <= 0 ? const <DayRecord>[] : days.sublist(days.length - n);

    // The equal-length window immediately preceding [window], for comparison.
    final prevStart = math.max(0, days.length - n * 2);
    final prevEnd = days.length - n;
    final prevWindow = prevEnd > prevStart
        ? days.sublist(prevStart, prevEnd)
        : const <DayRecord>[];

    return ScreenScaffold(
      title: 'Trends',
      subtitle: 'Overview',
      glow: Palette.chargeGlow.withValues(alpha: 0.10),
      children: [
        _RangeControl(
          selected: _range,
          onChanged: (r) => setState(() => _range = r),
        ),
        _ChargeHero(window: window, prevWindow: prevWindow),
        SectionHeader('Daily signals'),
        _SignalCard(
          label: 'Heart rate variability',
          unit: 'ms',
          values: window.map((d) => d.hrv).toList(),
          color: Palette.metricPurple,
          decimals: 0,
        ),
        _SignalCard(
          label: 'Resting heart rate',
          unit: 'bpm',
          values: window.map((d) => d.rhr).toList(),
          color: Palette.metricRose,
          decimals: 0,
        ),
        _SignalCard(
          label: 'Effort',
          unit: '/100',
          values: window.map((d) => d.effort).toList(),
          color: Palette.effortColor,
          decimals: 0,
        ),
        _RecoveryCalendar(window: window),
      ],
    );
  }
}

/// A segmented pill row selecting the trailing window.
class _RangeControl extends StatelessWidget {
  final _Range selected;
  final ValueChanged<_Range> onChanged;
  const _RangeControl({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final r in _Range.values) ...[
          Expanded(child: _pill(r)),
          if (r != _Range.values.last) const SizedBox(width: Metrics.space8),
        ],
      ],
    );
  }

  Widget _pill(_Range r) {
    final on = r == selected;
    final accent = Palette.chargeColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Metrics.cornerPill),
        onTap: () => onChanged(r),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: on
                ? accent.withValues(alpha: 0.16)
                : Palette.surfaceOverlay.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(Metrics.cornerPill),
            border: Border.all(
              color: on ? accent.withValues(alpha: 0.55) : Palette.hairline,
              width: 1,
            ),
          ),
          child: Text(
            r.label,
            style: NoopType.footnote.copyWith(
              color: on ? accent : Palette.textSecondary,
              fontWeight: on ? FontWeight.bold : FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

/// Charge hero — window-average number, change vs. the previous window, a daily
/// Charge bar series and a footer of avg/peak/low/days stats.
class _ChargeHero extends StatelessWidget {
  final List<DayRecord> window;
  final List<DayRecord> prevWindow;
  const _ChargeHero({required this.window, required this.prevWindow});

  @override
  Widget build(BuildContext context) {
    final charge = window.map((d) => d.charge).toList();
    final avg = _TrendsScreenState._avg(charge);
    final peak = _TrendsScreenState._max(charge);
    final low = _TrendsScreenState._min(charge);
    final prevAvg =
        _TrendsScreenState._avg(prevWindow.map((d) => d.charge).toList());
    final delta = prevWindow.isEmpty ? 0.0 : avg - prevAvg;

    return SectionCard(
      title: 'Charge',
      accent: Palette.chargeColor,
      trailing: Text(
        Palette.recoveryState(avg),
        style: NoopType.overline.copyWith(color: Palette.recoveryColor(avg)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey(avg.round()),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: avg),
                builder: (context, v, _) => Text(
                  v.round().toString(),
                  style: NoopType.display(40).copyWith(color: Palette.textPrimary),
                ),
              ),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('%',
                    style: NoopType.subhead.copyWith(color: Palette.textTertiary)),
              ),
              const Spacer(),
              if (prevWindow.isNotEmpty) _DeltaChip(delta, unit: 'vs prev'),
            ],
          ),
          const SizedBox(height: Metrics.space4),
          Text('Window average',
              style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
          const SizedBox(height: Metrics.space16),
          BarSeries(
            values: charge,
            ramp: Palette.recoveryStops,
            maxValue: 100,
            height: 160,
          ),
          const SizedBox(height: Metrics.space16),
          const Hairline(),
          const SizedBox(height: Metrics.space12),
          Row(
            children: [
              _stat('Avg', avg.round().toString()),
              _stat('Peak', peak.round().toString()),
              _stat('Low', low.round().toString()),
              _stat('Days', charge.length.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: NoopType.number(20).copyWith(color: Palette.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
          ],
        ),
      );
}

/// A change chip: a signed delta with a direction arrow, tinted by sign.
class _DeltaChip extends StatelessWidget {
  final double delta;
  final String unit;
  final int decimals;
  const _DeltaChip(this.delta, {this.unit = '', this.decimals = 0});

  @override
  Widget build(BuildContext context) {
    final flat = delta.abs() < (decimals == 0 ? 0.5 : 0.05);
    final color = flat
        ? Palette.textTertiary
        : (delta > 0 ? Palette.statusPositive : Palette.statusCritical);
    final icon = flat
        ? Icons.remove_rounded
        : (delta > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded);
    final text = '${Fmt.signed(delta, digits: decimals)}${unit.isEmpty ? '' : ' $unit'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Metrics.cornerPill),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(text,
              style: NoopType.captionNumber
                  .copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// A mini trend card: label + latest value + full-width sparkline + change chip.
class _SignalCard extends StatelessWidget {
  final String label;
  final String unit;
  final List<double> values;
  final Color color;
  final int decimals;
  const _SignalCard({
    required this.label,
    required this.unit,
    required this.values,
    required this.color,
    required this.decimals,
  });

  @override
  Widget build(BuildContext context) {
    final latest = values.isEmpty ? 0.0 : values.last;
    final delta = values.length < 2 ? 0.0 : values.last - values.first;
    return NoopCard(
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(label.toUpperCase(),
                    style: NoopType.overline
                        .copyWith(color: Palette.textSecondary)),
              ),
              _DeltaChip(delta, decimals: decimals),
            ],
          ),
          const SizedBox(height: Metrics.space6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(latest.toStringAsFixed(decimals),
                  style: NoopType.number(26).copyWith(color: Palette.textPrimary)),
              const SizedBox(width: 3),
              Text(unit,
                  style: NoopType.caption.copyWith(color: Palette.textTertiary)),
            ],
          ),
          const SizedBox(height: Metrics.space8),
          if (values.length >= 2)
            Sparkline(
              values: values,
              color: color,
              width: double.infinity,
              height: 44,
            )
          else
            const SizedBox(height: 44),
        ],
      ),
    );
  }
}

/// A recovery calendar — one colour-coded square per day in the window.
class _RecoveryCalendar extends StatelessWidget {
  final List<DayRecord> window;
  const _RecoveryCalendar({required this.window});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Calendar',
      accent: Palette.chargeColor,
      trailing: Text('${window.length} days',
          style: NoopType.caption.copyWith(color: Palette.textTertiary)),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final d in window)
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Palette.recoveryColor(d.charge),
                borderRadius: BorderRadius.circular(Metrics.space4),
              ),
            ),
        ],
      ),
    );
  }
}
