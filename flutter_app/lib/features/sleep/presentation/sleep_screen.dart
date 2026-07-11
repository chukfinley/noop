import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/models.dart';
import 'package:noop/core/state/format.dart';
import 'package:noop/core/state/providers.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/health_charts.dart';
import 'package:noop/shared/widgets/metric_gauge.dart';
import 'package:noop/shared/widgets/scaffold.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

/// Sleep — a WHOOP/Fitbit-style single-screen view in the app's own palette:
/// a score ring, the headline stats, a restlessness timeline and the stage
/// breakdown, tuned compact so nearly everything fits at once.
class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  SleepStage? _selected; // the stage highlighted in the timeline

  void _toggle(SleepStage s) =>
      setState(() => _selected = _selected == s ? null : s);

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(daysProvider);
    final maxI = days.length - 1;
    final idx = ref.watch(selectedDayIndexProvider).clamp(0, maxI);
    // Honour the day chosen in the shared day-switcher, changeable in-screen
    // with the same chevron pager the home header uses (never a dropdown).
    final day = days[idx];
    final sleep = day.sleep;

    // 30-day averages across nights.
    final nights = days.where((d) => d.sleep != null).map((d) => d.sleep!).toList();
    Duration avgOf(int Function(SleepRecord) f) => nights.isEmpty
        ? Duration.zero
        : Duration(minutes: (nights.map(f).reduce((a, b) => a + b) / nights.length).round());

    return ScreenScaffold(
      title: 'Sleep',
      glow: Palette.restColor,
      leadingHeader: Column(
        children: [
          const CenteredHeader(title: 'Sleep'),
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
        if (sleep == null)
          Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.nightlight_round,
                      size: 40, color: Palette.textTertiary),
                  const SizedBox(height: 12),
                  Text('No sleep recorded for this day.',
                      style:
                          NoopType.body.copyWith(color: Palette.textTertiary)),
                ],
              ),
            ),
          )
        else ...[
          _ScoreGauge(sleep: sleep, score: day.rest),
          _StatRow(
              sleep: sleep,
              avgAsleep: avgOf((s) => s.asleep.inMinutes),
              avgRestore: avgOf((s) => s.deep.inMinutes + s.rem.inMinutes)),
          _TimelineCard(sleep: sleep, selected: _selected),
          _StagesCard(sleep: sleep, selected: _selected, onSelect: _toggle),
        ],
      ],
    );
  }
}

/// The sleep-score hero — the app's signature liquid gauge (or ring, per the
/// user's setting) centred, flanked by the night's bedtime and wake times so
/// the row fills the screen width instead of leaving dead space either side.
/// "Sleep Score" and a status dot sit below.
class _ScoreGauge extends ConsumerWidget {
  final SleepRecord sleep;

  /// The canonical Sleep score (DayRecord.rest) — the SAME value the home
  /// screen shows, so the two never disagree. Not the raw asleep/need ratio.
  final double score;
  const _ScoreGauge({required this.sleep, required this.score});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(gaugeStyleProvider);
    final state = score < 50
        ? 'Poor'
        : (score < 70 ? 'Fair' : (score < 85 ? 'Good' : 'Optimal'));
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _sideStat(Icons.bedtime_rounded, 'BEDTIME',
                  Fmt.clock(sleep.bedtime), CrossAxisAlignment.end),
            ),
            const SizedBox(width: 8),
            MetricGauge(
              fraction: (score / 100).clamp(0, 1),
              ramp: Palette.restGradientStops,
              size: 130,
              center: Text(score.round().toString(),
                  style: NoopType.number(40).copyWith(
                    color: gaugeCenterColor(style),
                    shadows: gaugeCenterShadows(style),
                  )),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _sideStat(Icons.wb_sunny_rounded, 'WAKE',
                  Fmt.clock(sleep.wake), CrossAxisAlignment.start),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Sleep Score',
            style: NoopType.headline.copyWith(color: Palette.restColor)),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state,
                style: NoopType.subhead.copyWith(color: Palette.textSecondary)),
            const SizedBox(width: 6),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                  color: Palette.restColor, shape: BoxShape.circle),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sideStat(
          IconData icon, String label, String value, CrossAxisAlignment align) =>
      Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Palette.restColor),
          const SizedBox(height: 8),
          Text(label,
              style: NoopType.overline.copyWith(
                  color: Palette.textTertiary, letterSpacing: 1.4)),
          const SizedBox(height: 2),
          Text(value,
              style: NoopType.number(20).copyWith(color: Palette.textPrimary)),
        ],
      );
}

class _StatRow extends StatelessWidget {
  final SleepRecord sleep;
  final Duration avgAsleep;
  final Duration avgRestore;
  const _StatRow(
      {required this.sleep, required this.avgAsleep, required this.avgRestore});

  @override
  Widget build(BuildContext context) {
    final restore = sleep.deep + sleep.rem;
    final restorePct =
        sleep.asleep.inMinutes == 0 ? 0 : (restore.inMinutes / sleep.asleep.inMinutes * 100).round();
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _stat('SLEEP TIME', Fmt.hm(sleep.asleep), Palette.textPrimary,
                'Total', '${Fmt.hm(avgAsleep)}\n30-day avg'),
          ),
          _divider(),
          Expanded(
            child: _stat('RESTORATIVE SLEEP', Fmt.hm(restore), Palette.restColor,
                '$restorePct%', '${Fmt.hm(avgRestore)}\n30-day avg',
                subColor: Palette.restColor),
          ),
          _divider(),
          Expanded(
            child: _stat('TIME IN BED', Fmt.hm(sleep.timeInBed), Palette.textPrimary,
                'Efficiency ${(sleep.efficiency * 100).round()}%', ''),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Palette.hairline.withValues(alpha: 0.6));

  Widget _stat(String label, String big, Color bigColor, String sub, String foot,
          {Color? subColor}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed two-line label box so every column's big value aligns on the
          // same line, whether the label wraps or not.
          SizedBox(
            height: 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NoopType.caption.copyWith(
                          color: Palette.textTertiary,
                          letterSpacing: 0.4,
                          height: 1.2)),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(Icons.info_outline_rounded,
                      size: 12, color: Palette.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(big, style: NoopType.number(24).copyWith(color: bigColor)),
          const SizedBox(height: 3),
          Text(sub,
              style: NoopType.footnote.copyWith(
                  color: subColor ?? Palette.textSecondary,
                  fontWeight: subColor != null ? FontWeight.w700 : FontWeight.w400)),
          const SizedBox(height: 8),
          // Reserve the footer line in every column so the baselines match even
          // when a column has no 30-day average (e.g. Time in bed).
          Text(foot.isEmpty ? ' ' : foot,
              maxLines: 2,
              style: NoopType.caption
                  .copyWith(color: Palette.textTertiary, height: 1.3)),
        ],
      );
}

class _TimelineCard extends StatelessWidget {
  final SleepRecord sleep;
  final SleepStage? selected;
  const _TimelineCard({required this.sleep, this.selected});

  @override
  Widget build(BuildContext context) {
    final series =
        sleep.restlessness.map((r) => (r * 100).clamp(0.0, 100.0)).toList();
    final mid = DateTime.fromMillisecondsSinceEpoch(
        (sleep.bedtime.millisecondsSinceEpoch + sleep.wake.millisecondsSinceEpoch) ~/ 2);

    // Fractional spans of the selected stage across the night.
    final spanMs =
        sleep.wake.millisecondsSinceEpoch - sleep.bedtime.millisecondsSinceEpoch;
    final highlights = <(double, double)>[];
    if (selected != null && spanMs > 0) {
      for (final seg in sleep.hypnogram.where((s) => s.stage == selected)) {
        final a = (seg.start.millisecondsSinceEpoch -
                sleep.bedtime.millisecondsSinceEpoch) /
            spanMs;
        final b = (seg.start.millisecondsSinceEpoch +
                seg.duration.inMilliseconds -
                sleep.bedtime.millisecondsSinceEpoch) /
            spanMs;
        highlights.add((a, b));
      }
    }
    final hlColor = selected == null ? null : _stageColor(selected!);

    return SectionCard(
      title: 'SLEEP TIMELINE',
      trailing: Text(selected == null ? 'View stages' : 'Clear',
          style: NoopType.footnote.copyWith(color: Palette.restColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (series.length >= 2)
            HealthTimeline(
              values: series,
              color: Palette.restColor,
              axisLabels: [Fmt.clock(sleep.bedtime), Fmt.clock(mid), Fmt.clock(sleep.wake)],
              height: 120,
              highlights: highlights,
              highlightColor: hlColor,
            )
          else
            const SizedBox(height: 120),
          const SizedBox(height: 10),
          Text(
              selected == null
                  ? 'Higher = awake / REM, lower = deep sleep across the night.'
                  : 'Highlighted: ${_stageName(selected!)}.',
              style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
        ],
      ),
    );
  }
}

Color _stageColor(SleepStage s) => switch (s) {
      SleepStage.awake => Palette.sleepAwake,
      SleepStage.light => Palette.sleepLight,
      SleepStage.deep => Palette.sleepDeep,
      SleepStage.rem => Palette.sleepREM,
    };

String _stageName(SleepStage s) => switch (s) {
      SleepStage.awake => 'Awake',
      SleepStage.light => 'Light',
      SleepStage.deep => 'Deep',
      SleepStage.rem => 'REM',
    };

class _StagesCard extends StatelessWidget {
  final SleepRecord sleep;
  final SleepStage? selected;
  final ValueChanged<SleepStage> onSelect;
  const _StagesCard(
      {required this.sleep, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final total = sleep.awake + sleep.light + sleep.deep + sleep.rem;
    final t = total.inMinutes == 0 ? 1 : total.inMinutes;
    int pct(Duration d) => (d.inMinutes / t * 100).round();
    return SectionCard(
      title: 'SLEEP STAGES',
      trailing: Text('Tap a stage',
          style: NoopType.footnote.copyWith(color: Palette.restColor)),
      child: Column(
        children: [
          _row('Awake', pct(sleep.awake), sleep.awake, Palette.sleepAwake, SleepStage.awake),
          const SizedBox(height: 8),
          _row('Light', pct(sleep.light), sleep.light, Palette.sleepLight, SleepStage.light),
          const SizedBox(height: 8),
          _row('Deep', pct(sleep.deep), sleep.deep, Palette.sleepDeep, SleepStage.deep),
          const SizedBox(height: 8),
          _row('REM', pct(sleep.rem), sleep.rem, Palette.sleepREM, SleepStage.rem),
        ],
      ),
    );
  }

  Widget _row(String name, int pct, Duration dur, Color color, SleepStage stage) {
    final isSel = selected == stage;
    final dim = selected != null && !isSel;
    return Material(
      color: isSel ? color.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(Metrics.cornerCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(Metrics.cornerCard),
        onTap: () => onSelect(stage),
        child: Opacity(
          opacity: dim ? 0.45 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label (+%) on the left, duration on the right — above the strip.
                Row(
                  children: [
                    Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                            color: color, borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 8),
                    Text(name,
                        style: NoopType.subhead.copyWith(
                            color: Palette.textPrimary, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text('$pct%',
                        style: NoopType.caption.copyWith(color: Palette.textTertiary)),
                    const Spacer(),
                    Text(Fmt.hm(dur),
                        style: NoopType.subhead.copyWith(
                            color: Palette.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                // Full-width distribution strip.
                SizedBox(
                  width: double.infinity,
                  height: 14,
                  child: CustomPaint(
                    painter: _StageStripPainter(
                        sleep.hypnogram, stage, color, sleep.bedtime, sleep.wake),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageStripPainter extends CustomPainter {
  final List<StageSegment> segments;
  final SleepStage stage;
  final Color color;
  final DateTime bedtime;
  final DateTime wake;
  _StageStripPainter(
      this.segments, this.stage, this.color, this.bedtime, this.wake);

  @override
  void paint(Canvas canvas, Size size) {
    final spanMs = wake.millisecondsSinceEpoch - bedtime.millisecondsSinceEpoch;
    if (spanMs <= 0) return;
    final r = Radius.circular(size.height / 2);
    // Track.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, r),
      Paint()..color = Palette.surfaceInset,
    );
    for (final seg in segments.where((s) => s.stage == stage)) {
      final x0 = (seg.start.millisecondsSinceEpoch - bedtime.millisecondsSinceEpoch) /
          spanMs *
          size.width;
      final x1 = ((seg.start.millisecondsSinceEpoch +
                  seg.duration.inMilliseconds) -
              bedtime.millisecondsSinceEpoch) /
          spanMs *
          size.width;
      final rect =
          Rect.fromLTRB(x0.clamp(0.0, size.width), 0, x1.clamp(0.0, size.width), size.height);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, r), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_StageStripPainter old) =>
      old.segments != segments || old.stage != stage;
}
