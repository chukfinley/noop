import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/repository.dart';
import '../../state/format.dart';
import '../../state/providers.dart';
import '../components/cards.dart';
import '../components/charts.dart';
import '../components/common.dart';
import '../components/gauge.dart';
import '../components/scaffold.dart';
import '../components/tiles.dart';
import '../theme/metrics.dart';
import '../theme/palette.dart';

/// Health Monitor — live vitals streamed from the strap. Sync status, a heart
/// rate hero + sparkline, a vital-signs grid, fitness age / vitality gauges,
/// and recovery contributor bars. Mirrors TodayScreen in style.
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(daysProvider).last;
    final vitals = ref.watch(vitalsProvider);
    final syncState = ref.watch(repositoryProvider).syncState;

    return ScreenScaffold(
      title: 'Health',
      subtitle: 'Live vitals',
      glow: Palette.chargeGlow.withValues(alpha: 0.10),
      children: [
        _SyncStatusCard(state: syncState),
        _HeartRateSection(day: day),
        _VitalSignsSection(vitals: vitals),
        _FitnessAgeCard(day: day),
        _VitalityCard(day: day),
        _ContributorsCard(day: day),
      ],
    );
  }
}

/// A small status dot + label describing the current sync state, with a
/// (no-op) "Sync now" action on the right.
class _SyncStatusCard extends StatelessWidget {
  final SyncState state;
  const _SyncStatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      SyncState.synced => ('Synced just now', Palette.statusPositive),
      SyncState.syncing => ('Syncing…', Palette.statusWarning),
      SyncState.needsStrap => ('Connect your strap', Palette.statusCritical),
    };
    return NoopCard(
      accent: color,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: Metrics.space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STRAP',
                    style: NoopType.overline
                        .copyWith(color: Palette.textTertiary)),
                Text(label,
                    style: NoopType.headline
                        .copyWith(color: Palette.textPrimary)),
              ],
            ),
          ),
          const SizedBox(width: Metrics.space12),
          NoopButton('Sync now', icon: Icons.sync, onPressed: () {}),
        ],
      ),
    );
  }
}

/// Big current bpm hero + a full-width day sparkline + min/avg/max footer.
class _HeartRateSection extends StatelessWidget {
  final DayRecord day;
  const _HeartRateSection({required this.day});

  @override
  Widget build(BuildContext context) {
    final samples = day.hr;
    return SectionCard(
      title: 'Heart rate',
      accent: Palette.metricRose,
      trailing: Text('bpm',
          style: NoopType.caption.copyWith(color: Palette.textTertiary)),
      child: samples.isEmpty
          ? Text('No samples yet',
              style: NoopType.body.copyWith(color: Palette.textTertiary))
          : _content(samples),
    );
  }

  Widget _content(List<HrSample> samples) {
    final bpm = samples.map((s) => s.bpm).toList();
    final current = bpm.last;
    final min = bpm.reduce(math.min);
    final max = bpm.reduce(math.max);
    final avg = bpm.reduce((a, b) => a + b) / bpm.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(current.round().toString(),
                style: NoopType.display(40).copyWith(color: Palette.textPrimary)),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('bpm',
                  style: NoopType.caption.copyWith(color: Palette.textTertiary)),
            ),
            const Spacer(),
            Icon(Icons.favorite_rounded, size: 18, color: Palette.metricRose),
          ],
        ),
        const SizedBox(height: Metrics.space12),
        SizedBox(
          height: 150,
          child: Sparkline(
            values: bpm,
            color: Palette.metricRose,
            width: double.infinity,
            height: 150,
          ),
        ),
        const SizedBox(height: Metrics.space14),
        Row(
          children: [
            _stat('Min', min),
            _stat('Avg', avg),
            _stat('Max', max),
          ],
        ),
      ],
    );
  }

  Widget _stat(String label, double value) => Expanded(
        child: Column(
          children: [
            Text(value.round().toString(),
                style: NoopType.number(20).copyWith(color: Palette.textPrimary)),
            const SizedBox(height: 2),
            Text(label,
                style: NoopType.overline.copyWith(color: Palette.textTertiary)),
          ],
        ),
      );
}

/// A grid of vital readings, one MetricTile each, accents cycling.
class _VitalSignsSection extends StatelessWidget {
  final List<VitalReading> vitals;
  const _VitalSignsSection({required this.vitals});

  @override
  Widget build(BuildContext context) {
    // Theme-dependent colours — resolved per build, never cached in a const.
    final accents = [
      Palette.metricCyan,
      Palette.metricPurple,
      Palette.metricRose,
      Palette.metricAmber,
      Palette.chargeColor,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Vital signs',
            trailing: Text('${vitals.length} readings',
                style: NoopType.caption.copyWith(color: Palette.textTertiary))),
        MetricGrid([
          for (var i = 0; i < vitals.length; i++)
            MetricTile(
              label: vitals[i].label,
              value: _fmt(vitals[i]),
              unit: vitals[i].unit,
              spark: vitals[i].series,
              accent: accents[i % accents.length],
            ),
        ]),
      ],
    );
  }

  static String _fmt(VitalReading v) {
    final label = v.label.toLowerCase();
    if (label.contains('temp')) return Fmt.signed(v.value, digits: 1);
    final whole = (v.value - v.value.roundToDouble()).abs() < 0.05;
    return whole ? v.value.toStringAsFixed(0) : v.value.toStringAsFixed(1);
  }
}

/// A ring gauge whose fill grows as fitness age drops toward 18.
class _FitnessAgeCard extends StatelessWidget {
  final DayRecord day;
  const _FitnessAgeCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final fraction = (1 - (day.fitnessAge - 18) / 62).clamp(0.0, 1.0);
    return SectionCard(
      title: 'Fitness age',
      accent: Palette.metricCyan,
      trailing: Text('± 5 yr',
          style: NoopType.caption.copyWith(color: Palette.textTertiary)),
      child: Row(
        children: [
          RingGauge(
            fraction: fraction,
            stops: Palette.recoveryStops,
            size: 92,
            stroke: 9,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(day.fitnessAge.toString(),
                    style: NoopType.number(26)
                        .copyWith(color: Palette.textPrimary)),
                Text('yr',
                    style: NoopType.footnote
                        .copyWith(color: Palette.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: Metrics.space16),
          Expanded(
            child: Text(
              'Your cardiovascular fitness reads younger than your years. '
              'Keep the effort steady to hold the trend.',
              style: NoopType.body.copyWith(color: Palette.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// A ring gauge for the composite vitality score, with body-age caption.
class _VitalityCard extends StatelessWidget {
  final DayRecord day;
  const _VitalityCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Vitality',
      accent: Palette.chargeColor,
      child: Row(
        children: [
          RingGauge(
            fraction: (day.vitality / 100).clamp(0.0, 1.0),
            stops: DomainTheme.charge.gradientStops,
            size: 92,
            stroke: 9,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(day.vitality.toString(),
                    style: NoopType.number(26)
                        .copyWith(color: Palette.textPrimary)),
                Text('/100',
                    style: NoopType.footnote
                        .copyWith(color: Palette.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: Metrics.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Body age ${day.fitnessAge}',
                    style: NoopType.headline
                        .copyWith(color: Palette.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  'A blend of recovery, sleep and cardio load. Higher means '
                  'your systems are running fresh.',
                  style: NoopType.body.copyWith(color: Palette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Four labelled horizontal progress bars for the recovery drivers.
class _ContributorsCard extends StatelessWidget {
  final DayRecord day;
  const _ContributorsCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, double)>[
      ('HRV', (day.hrv / 90).clamp(0.0, 1.0)),
      ('Resting HR', (1 - (day.rhr - 40) / 40).clamp(0.0, 1.0)),
      ('Sleep', (day.rest / 100).clamp(0.0, 1.0)),
      ('Respiratory', (1 - (day.respiratoryRate - 11) / 8).clamp(0.0, 1.0)),
    ];
    return SectionCard(
      title: 'Recovery contributors',
      accent: Palette.chargeColor,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _ContributorBar(label: rows[i].$1, fraction: rows[i].$2),
            if (i != rows.length - 1) const SizedBox(height: Metrics.space14),
          ],
        ],
      ),
    );
  }
}

class _ContributorBar extends StatelessWidget {
  final String label;
  final double fraction;
  const _ContributorBar({required this.label, required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: NoopType.body.copyWith(color: Palette.textSecondary)),
            ),
            Text('${(fraction * 100).round()}%',
                style: NoopType.captionNumber
                    .copyWith(color: Palette.chargeColor)),
          ],
        ),
        const SizedBox(height: Metrics.space8),
        ClipRRect(
          borderRadius: BorderRadius.circular(Metrics.cornerBadge),
          child: Container(
            height: 8,
            color: Palette.hairline,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Palette.chargeColor.withValues(alpha: 0.7),
                      Palette.chargeColor,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
