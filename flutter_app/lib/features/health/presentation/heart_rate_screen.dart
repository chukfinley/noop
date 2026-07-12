import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/models.dart';
import 'package:noop/core/state/format.dart';
import 'package:noop/core/state/providers.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/coming_soon.dart';
import 'package:noop/shared/widgets/controls.dart';
import 'package:noop/shared/widgets/health_charts.dart';
import 'package:noop/shared/widgets/scaffold.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

/// Full heart-rate history at any resolution the capture supports. Because HR is
/// stored per second, it can be viewed per **second** (every captured beat), or
/// rolled up into **minute / hour** buckets within a day, or **day / week /
/// month / year** averages across the whole record. Intraday views page across
/// days; roll-ups span the entire capture. Everything is real; nothing faked.
class HeartRateScreen extends ConsumerStatefulWidget {
  const HeartRateScreen({super.key});

  @override
  ConsumerState<HeartRateScreen> createState() => _HeartRateScreenState();
}

/// A single plotted point — a timestamp (its bucket) and the mean bpm in it.
class _Pt {
  final DateTime t;
  final double bpm;
  const _Pt(this.t, this.bpm);
}

enum _Res { second, minute, hour, day, week, month, year }

extension on _Res {
  String get label => switch (this) {
        _Res.second => 'Sec',
        _Res.minute => 'Min',
        _Res.hour => 'Hour',
        _Res.day => 'Day',
        _Res.week => 'Week',
        _Res.month => 'Month',
        _Res.year => 'Year',
      };

  /// Second/minute/hour are read within one day; the rest span every day.
  bool get intraday => this == _Res.second || this == _Res.minute || this == _Res.hour;

  String get unitWord => switch (this) {
        _Res.second => 'samples · every captured beat',
        _Res.minute => 'minutes · per-minute average',
        _Res.hour => 'hours · per-hour average',
        _Res.day => 'days · daily average',
        _Res.week => 'weeks · weekly average',
        _Res.month => 'months · monthly average',
        _Res.year => 'years · yearly average',
      };
}

class _HeartRateScreenState extends ConsumerState<HeartRateScreen> {
  _Res _res = _Res.minute;

  /// Bucket (time,bpm) pairs by a key-truncating function, averaging each bucket.
  List<_Pt> _bucket(Iterable<_Pt> pts, DateTime Function(DateTime) key) {
    final sums = <int, double>{};
    final counts = <int, int>{};
    final when = <int, DateTime>{};
    for (final p in pts) {
      final k = key(p.t);
      final ms = k.millisecondsSinceEpoch;
      sums[ms] = (sums[ms] ?? 0) + p.bpm;
      counts[ms] = (counts[ms] ?? 0) + 1;
      when[ms] = k;
    }
    final keys = sums.keys.toList()..sort();
    return [for (final ms in keys) _Pt(when[ms]!, sums[ms]! / counts[ms]!)];
  }

  /// Monday-anchored start of the week containing [d].
  DateTime _weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// Every day's mean bpm (skipping days with no HR thread) — the base series for
  /// the day/week/month/year roll-ups.
  List<_Pt> _dailyAverages(List<DayRecord> days) {
    final out = <_Pt>[];
    for (final d in days) {
      if (d.hr.isEmpty) continue;
      final avg = d.hr.map((e) => e.bpm).reduce((a, b) => a + b) / d.hr.length;
      out.add(_Pt(DateTime(d.date.year, d.date.month, d.date.day), avg));
    }
    return out;
  }

  /// Thin [pts] down to at most [maxN] points by even striding, so the per-second
  /// path stays cheap to paint without changing the line's shape.
  List<_Pt> _downsample(List<_Pt> pts, int maxN) {
    if (pts.length <= maxN) return pts;
    final step = pts.length / maxN;
    return [for (var i = 0; i < maxN; i++) pts[(i * step).floor()]];
  }

  /// The plotted series for the current resolution.
  List<_Pt> _series(List<DayRecord> days, DayRecord day) {
    switch (_res) {
      case _Res.second:
        return _downsample([for (final e in day.hr) _Pt(e.time, e.bpm)], 1500);
      case _Res.minute:
        return _bucket([for (final e in day.hr) _Pt(e.time, e.bpm)],
            (t) => DateTime(t.year, t.month, t.day, t.hour, t.minute));
      case _Res.hour:
        return _bucket([for (final e in day.hr) _Pt(e.time, e.bpm)],
            (t) => DateTime(t.year, t.month, t.day, t.hour));
      case _Res.day:
        return _dailyAverages(days);
      case _Res.week:
        return _bucket(_dailyAverages(days), _weekStart);
      case _Res.month:
        return _bucket(_dailyAverages(days), (t) => DateTime(t.year, t.month));
      case _Res.year:
        return _bucket(_dailyAverages(days), (t) => DateTime(t.year));
    }
  }

  String _axisLabel(DateTime t) =>
      _res.intraday ? Fmt.clock(t) : Fmt.shortDate(t);

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(daysProvider);
    if (days.isEmpty) {
      return const ScreenScaffold(
        title: 'Heart rate',
        children: [
          Padding(
            padding: EdgeInsets.only(top: 72),
            child: ConnectStrapView(),
          ),
        ],
      );
    }
    final maxI = days.length - 1;
    final idx = ref.watch(selectedDayIndexProvider).clamp(0, maxI);
    final day = days[idx];

    final series = _series(days, day);
    final bpms = [for (final p in series) p.bpm];
    final hasData = bpms.length > 1;

    final double avg = hasData ? bpms.reduce((a, b) => a + b) / bpms.length : 0;
    final double lo = hasData ? bpms.reduce((a, b) => a < b ? a : b) : 0;
    final double hi = hasData ? bpms.reduce((a, b) => a > b ? a : b) : 0;

    // Zoom the line to a padded [lo,hi] window so the trace fills the height
    // instead of hugging the top of a 0-based axis (which read as a flat line).
    final pad = ((hi - lo) * 0.15).clamp(3.0, 20.0);
    final base = lo - pad;
    final span = (hi + pad) - base;
    final plot = [for (final v in bpms) v - base];

    final axis = hasData
        ? [
            _axisLabel(series.first.t),
            _axisLabel(series[series.length ~/ 2].t),
            _axisLabel(series.last.t),
          ]
        : const ['', '', ''];

    return ScreenScaffold(
      title: 'Heart rate',
      glow: Palette.metricRose,
      leadingHeader: const CenteredHeader(title: 'Heart rate'),
      children: [
        // Resolution selector — the full ladder from per-second to per-year.
        NoopSegmented<_Res>(
          expand: true,
          height: 40,
          value: _res,
          onChanged: (v) => setState(() => _res = v),
          segments: [for (final r in _Res.values) NoopSegment(r, r.label)],
        ),
        // Day pager (only meaningful for the intraday views).
        if (_res.intraday)
          Row(
            children: [
              _NavBtn(
                  icon: Icons.chevron_left_rounded,
                  enabled: idx > 0,
                  onTap: () =>
                      ref.read(selectedDayIndexProvider.notifier).state =
                          idx - 1),
              Expanded(
                child: Center(
                  child: Text(
                    idx == maxI ? 'Today' : Fmt.dayTitle(day.date),
                    style:
                        NoopType.headline.copyWith(color: Palette.textPrimary),
                  ),
                ),
              ),
              _NavBtn(
                  icon: Icons.chevron_right_rounded,
                  enabled: idx < maxI,
                  onTap: () =>
                      ref.read(selectedDayIndexProvider.notifier).state =
                          idx + 1),
            ],
          )
        else if (hasData)
          Center(
            child: Text(
              '${Fmt.shortDate(series.first.t)} – ${Fmt.shortDate(series.last.t)}',
              style: NoopType.subhead.copyWith(color: Palette.textSecondary),
            ),
          ),
        NoopCard(
          squircle: true,
          radius: Metrics.cornerHero,
          bordered: false,
          child: hasData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(avg.round().toString(),
                            style: NoopType.display(52)
                                .copyWith(color: Palette.textPrimary)),
                        const SizedBox(width: 6),
                        Text('bpm avg',
                            style: NoopType.subhead
                                .copyWith(color: Palette.textSecondary)),
                        const Spacer(),
                        _MinMax(lo: lo.round(), hi: hi.round()),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${series.length} ${_res.unitWord}',
                        style: NoopType.caption
                            .copyWith(color: Palette.textTertiary)),
                    const SizedBox(height: Metrics.space20),
                    // RepaintBoundary so the (possibly dense) path isn't re-run by
                    // the screen's entrance animation.
                    RepaintBoundary(
                      child: HealthTimeline(
                        values: plot,
                        color: Palette.metricRose,
                        axisLabels: axis,
                        yMax: span,
                        height: 200,
                      ),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: Metrics.space24),
                  child: Center(
                    child: Text(
                        _res == _Res.year
                            ? 'Not enough range yet for a yearly view.'
                            : 'No heart-rate samples for this day.',
                        style: NoopType.body
                            .copyWith(color: Palette.textTertiary)),
                  ),
                ),
        ),
      ],
    );
  }
}

class _MinMax extends StatelessWidget {
  final int lo;
  final int hi;
  const _MinMax({required this.lo, required this.hi});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$lo – $hi',
              style:
                  NoopType.number(20).copyWith(color: Palette.textSecondary)),
          Text('min – max',
              style: NoopType.caption.copyWith(color: Palette.textTertiary)),
        ],
      );
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon,
            size: 26,
            color: enabled
                ? Palette.textSecondary
                : Palette.textTertiary.withValues(alpha: 0.4)),
      );
}
