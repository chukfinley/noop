import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/models.dart';
import 'package:noop/core/data/weather.dart';
import 'package:noop/core/state/format.dart';
import 'package:noop/core/state/prefs.dart' show EffortScale, LastKnownBattery;
import 'package:noop/core/state/providers.dart';
import 'package:noop/core/ble/transport/whoop_providers.dart';
import 'package:noop/shared/widgets/backgrounds.dart';
import 'package:noop/shared/widgets/behavior.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/coming_soon.dart';
import 'package:noop/shared/widgets/health_charts.dart';
import 'package:noop/shared/widgets/metric_gauge.dart';
import 'package:noop/shared/widgets/motion.dart';
import 'package:noop/shared/widgets/reorderable_cluster.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/features/settings/presentation/device_settings_screen.dart';
import 'package:noop/features/metrics/presentation/metric_detail_screen.dart';
import 'package:noop/features/health/presentation/health_monitor_section.dart';
import 'package:noop/features/today/presentation/home_layout.dart';
import 'package:noop/features/today/presentation/water_section.dart';

/// Home — the scene header + the three water dials (Recovery · Strain · Sleep)
/// in their frosted-glass panel, then Stress, the Health-Monitor grid and Your
/// cards. Exactly the shipping look.
///
/// Tap the "Edit" pill to enter arrange mode: the layout stays identical, but
/// the three score dials become individually draggable (long-press one and slide
/// to reorder the trio) and each Health-Monitor tile becomes draggable within
/// its 2-up grid. Normal taps are suppressed while arranging.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  static const _pad = EdgeInsets.symmetric(horizontal: Metrics.space16);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(daysProvider);
    // No strap data synced yet → the whole home surface is the empty/calibrating
    // state (never a crash or a fabricated day).
    if (days.isEmpty) {
      return const ScenicBackground(
        child: SafeArea(child: ConnectStrapView()),
      );
    }
    final maxI = days.length - 1;
    final idx = ref.watch(selectedDayIndexProvider).clamp(0, maxI);
    final day = days[idx];
    final media = MediaQuery.of(context);
    final layout = ref.watch(homeLayoutProvider);
    final editing = ref.watch(homeEditModeProvider);

    List<double> tail(double Function(DayRecord) f, [int n = 14]) =>
        days.sublist(days.length - n).map(f).toList();

    // ── Arrange mode ───────────────────────────────────────────────────────
    // Same sections, same look — now nested drag:
    //  • long-press a whole SECTION (its chrome/empty area) to move the block
    //    among the others (the score panel, Water, Stress, Health, Your cards);
    //  • long-press a DIAL or a HEALTH TILE to reorder it inside its own group
    //    (that inner drag has a shorter delay, so it wins on the tile itself).
    if (editing) {
      final visible = [for (final c in layout) if (c.visible) c];
      final notifier = ref.read(homeLayoutProvider.notifier);
      return ScenicBackground(
        child: Column(
          children: [
            _ArrangeBar(topInset: media.padding.top),
            Expanded(
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                padding: EdgeInsets.only(
                  top: Metrics.space10,
                  bottom: media.padding.bottom + 120,
                ),
                proxyDecorator: (child, index, animation) => Material(
                  color: Colors.transparent,
                  child: Transform.scale(scale: 1.02, child: child),
                ),
                itemCount: visible.length,
                onReorder: notifier.reorderVisible,
                itemBuilder: (ctx, index) {
                  final cfg = visible[index];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey('sec-${cfg.id}'),
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: Metrics.space24),
                      child: Padding(
                        padding: _pad,
                        child: _section(cfg.id, day, tail, ctx, editing: true),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // ── Normal home ──────────────────────────────────────────────────────────
    var i = 0;
    Widget reveal(Widget child) =>
        Reveal(index: i++, child: Padding(padding: _pad, child: child));

    final sections = <Widget>[];
    for (final cfg in layout) {
      if (!cfg.visible) continue;
      sections
        ..add(reveal(_section(cfg.id, day, tail, context)))
        ..add(const SizedBox(height: Metrics.space24));
    }
    if (sections.isNotEmpty) sections.removeLast();

    final content = RefreshIndicator(
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
            // Live strap battery when connected; else the last REAL persisted reading
            // (shown timestamped, "87 · 2h ago"). Only "—" when there's never been one.
            battery: ref.watch(liveBatteryProvider).value,
            lastKnownBattery: ref.watch(lastKnownBatteryProvider),
            isToday: idx == maxI,
            canPrev: idx > 0,
            canNext: idx < maxI,
            onPrev: () =>
                ref.read(selectedDayIndexProvider.notifier).state = idx - 1,
            onNext: () =>
                ref.read(selectedDayIndexProvider.notifier).state = idx + 1,
          )),
          reveal(const _WeatherRow()),
          const SizedBox(height: Metrics.space16),
          ...sections,
        ],
      ),
    );

    // Long-press any widget on the home to drop into arrange mode (the pill is
    // gone). Cards keep their normal taps; only a *hold* enters editing.
    return ScenicBackground(
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onLongPress: () =>
            ref.read(homeEditModeProvider.notifier).state = true,
        child: content,
      ),
    );
  }

  static Widget _head(String title) => Padding(
        padding:
            const EdgeInsets.only(bottom: Metrics.space8, top: Metrics.space2),
        child: Text(title.toUpperCase(),
            style: NoopType.overline
                .copyWith(color: Palette.textTertiary, letterSpacing: 1.6)),
      );
}

/// Build one home section. While [editing] the dials/health tiles inside become
/// draggable and every other section's taps are suppressed.
Widget _section(
  String id,
  DayRecord day,
  List<double> Function(double Function(DayRecord), [int]) tail,
  BuildContext context, {
  bool editing = false,
}) {
  switch (id) {
    case 'hero':
      return _Hero(day: day, editing: editing);
    case 'water':
      return WaterSection(day: day, editing: editing);
    case 'stress':
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TodayScreen._head('Stress & Energy'),
          _StressEnergy(day: day, editing: editing),
        ],
      );
    case 'health':
      return HealthMonitorSection(day: day, editing: editing);
    case 'yourcards':
      return _YourCards(day: day, tail: tail, editing: editing);
    default:
      return const SizedBox.shrink();
  }
}

/// Open a metric's own detail screen. All three hero dials (Recovery, Strain,
/// Sleep) go to the SAME kind of focused metric-detail screen — a distinct
/// pushed screen, NOT the swipeable Sleep tab (which felt like "it just slid to
/// the Sleep tab"). The rich full Sleep tab stays reachable by swiping to it.
void _openDetail(BuildContext context, MetricKind kind) {
  Navigator.of(context).push(noopRoute(MetricDetailScreen(kind: kind)));
}

// ── Arrange-mode chrome ──────────────────────────────────────────────────────

/// The pinned top bar in arrange mode.
class _ArrangeBar extends ConsumerWidget {
  final double topInset;
  const _ArrangeBar({required this.topInset});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: EdgeInsets.only(
          top: topInset + Metrics.space16,
          left: Metrics.space16,
          right: Metrics.space16,
          bottom: Metrics.space10,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ARRANGE HOME',
                      style: NoopType.overline.copyWith(
                          color: Palette.textPrimary, letterSpacing: 1.6)),
                  const SizedBox(height: 2),
                  Text('Long-press a section to move it · a dial or tile to reorder inside',
                      style: NoopType.footnote
                          .copyWith(color: Palette.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: Metrics.space12),
            _DoneButton(
              onTap: () =>
                  ref.read(homeEditModeProvider.notifier).state = false,
            ),
          ],
        ),
      );
}

/// The prominent, always-visible "Done" button that leaves arrange mode.
class _DoneButton extends StatelessWidget {
  final VoidCallback onTap;
  const _DoneButton({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Palette.accent,
        borderRadius: BorderRadius.circular(Metrics.cornerLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Metrics.space16, vertical: Metrics.space10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                const SizedBox(width: Metrics.space6),
                Text('Done',
                    style: NoopType.subhead.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
}

// ── Scene header ─────────────────────────────────────────────────────────────

class _Scene extends StatelessWidget {
  final DayRecord day;
  final double? battery;
  final LastKnownBattery? lastKnownBattery;
  final bool isToday;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _Scene({
    required this.day,
    required this.battery,
    required this.lastKnownBattery,
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
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _HeartRatePill(day: day),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NavArrow(
                icon: Icons.chevron_left_rounded,
                enabled: canPrev,
                onTap: onPrev),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isToday ? 'TODAY' : Fmt.dayTitle(day.date).toUpperCase(),
                  style: NoopType.overline
                      .copyWith(color: Palette.textPrimary, letterSpacing: 1.4),
                ),
                Text(Fmt.shortDate(day.date),
                    style: NoopType.footnote
                        .copyWith(color: Palette.textTertiary)),
              ],
            ),
            _NavArrow(
                icon: Icons.chevron_right_rounded,
                enabled: canNext,
                onTap: onNext),
          ],
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.of(context)
                  .push(noopRoute(const DeviceSettingsScreen())),
              child: _StrapBattery(
                  level: battery, lastKnown: lastKnownBattery),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _NavArrow(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon,
          size: 22,
          color: enabled
              ? Palette.textSecondary
              : Palette.textTertiary.withValues(alpha: 0.4)),
    );
  }
}

class _HeartRatePill extends ConsumerWidget {
  final DayRecord day;
  const _HeartRatePill({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live HR from the strap when connected; else the day's last recorded sample.
    final liveHr = ref.watch(liveHrProvider).value;
    final bpm = liveHr ?? (day.hr.isEmpty ? null : day.hr.last.bpm.round());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.surfaceOverlay.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Metrics.cornerPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, size: 13, color: Palette.metricRose),
          const SizedBox(width: 5),
          Text(bpm == null ? '--' : '$bpm',
              style: NoopType.captionNumber
                  .copyWith(color: Palette.textSecondary)),
        ],
      ),
    );
  }
}

class _StrapBattery extends StatelessWidget {
  final double? level;
  final LastKnownBattery? lastKnown;
  const _StrapBattery({required this.level, this.lastKnown});

  @override
  Widget build(BuildContext context) {
    // Live reading wins; else the last REAL persisted one (shown with an honest
    // "· 2h ago" so it's never mistaken for live); only "—" when there's never been one.
    final bool live = level != null;
    final double? eff = level ?? lastKnown?.pct;
    final bool has = eff != null;
    final l = (eff ?? 0).clamp(0.0, 1.0);
    final color = !has
        ? Palette.textTertiary
        : (l > 0.4
            ? Palette.statusPositive
            : (l > 0.15 ? Palette.statusWarning : Palette.statusCritical));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.surfaceOverlay.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Metrics.cornerPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BatteryGlyph(level: has ? l : 0, color: color),
          const SizedBox(width: 5),
          Text(has ? '${(l * 100).round()}' : '—',
              style: NoopType.captionNumber
                  .copyWith(color: Palette.textSecondary)),
          // Stale (last-known) reading → append the honest relative age.
          if (!live && has) ...[
            const SizedBox(width: 4),
            Text('· ${_agoShort(lastKnown!.at)}',
                style:
                    NoopType.caption.copyWith(color: Palette.textTertiary)),
          ],
        ],
      ),
    );
  }

  /// Compact relative age for the pill ("now" / "5m ago" / "2h ago" / "3d ago"). A
  /// future timestamp (clock skew) reads as "now". Local helper — Fmt has no relative
  /// formatter and format.dart is out of scope here.
  static String _agoShort(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
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
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(1)),
            ),
          ),
        ],
      ),
    );
  }
}

/// The weather control row — the live conditions chip on the right. Entering
/// arrange mode is by long-pressing any home widget (no edit pill).
class _WeatherRow extends ConsumerWidget {
  const _WeatherRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weatherProvider);
    final metric = ref.watch(profileProvider).metric;
    return Padding(
      padding: const EdgeInsets.only(top: Metrics.space12),
      child: Row(
        children: [
          const Spacer(),
          _WeatherPill(
            wx: async.valueOrNull,
            loading: async.isLoading,
            metric: metric,
          ),
        ],
      ),
    );
  }
}

class _WeatherPill extends StatelessWidget {
  final Weather? wx;
  final bool loading;
  final bool metric;
  const _WeatherPill({
    required this.wx,
    required this.loading,
    required this.metric,
  });

  IconData get _icon {
    final w = wx;
    if (w == null) return Icons.cloud_outlined;
    final c = w.code;
    if (c == 0) return Icons.wb_sunny_rounded;
    if (c <= 2) return Icons.wb_cloudy_rounded;
    if (c <= 48) return Icons.cloud_rounded;
    if (c <= 67) return Icons.grain_rounded;
    if (c <= 77) return Icons.ac_unit_rounded;
    if (c <= 82) return Icons.grain_rounded;
    if (c <= 86) return Icons.ac_unit_rounded;
    return Icons.thunderstorm_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final w = wx;
    final String value;
    if (w != null) {
      final t = metric ? w.tempC : w.tempC * 9 / 5 + 32;
      value = '${t.round()}${metric ? '°C' : '°F'}';
    } else {
      value = loading ? '…' : '--';
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Metrics.space12, vertical: Metrics.space6),
      decoration: BoxDecoration(
        color: Palette.surfaceRaised,
        borderRadius: BorderRadius.circular(Metrics.cornerLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 17, color: Palette.textSecondary),
          const SizedBox(width: 7),
          Text(value,
              style: NoopType.subhead.copyWith(
                  color: Palette.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Hero: the three score dials ──────────────────────────────────────────────

/// The three hero water dials — Recovery · Strain · Sleep — framed as one
/// floating frosted-glass panel. While [editing] the dials become individually
/// draggable (they stay in the panel; long-press one and slide to reorder).
class _Hero extends ConsumerWidget {
  final DayRecord day;
  final bool editing;
  const _Hero({required this.day, this.editing = false});

  /// The gauge cell for a trio [id], or null for an unknown id.
  Widget? _cell(String id, BuildContext context, WidgetRef ref) {
    switch (id) {
      case 'recovery':
        return _HeroCell(
          label: 'Recovery',
          value: day.charge,
          ramp: Palette.recoveryStops,
          color: Palette.chargeColor,
          calibrationText: day.chargeCalibrating
              ? '${day.chargeCalibrationNights}/$recoveryCalibrationNightsNeeded'
              : null,
          onTap:
              editing ? null : () => _openDetail(context, MetricKind.recovery),
        );
      case 'strain':
        return _HeroCell(
          label: 'Strain',
          value: day.effort,
          ramp: Palette.effortGradientStops,
          color: Palette.effortColor,
          isEffort: true,
          onTap: editing ? null : () => _openDetail(context, MetricKind.strain),
        );
      case 'sleep':
        return _HeroCell(
          label: 'Sleep',
          value: day.rest,
          ramp: Palette.restGradientStops,
          color: Palette.restColor,
          // Sleep has its own tab — jump straight to it in the bottom nav
          // instead of pushing a separate detail screen.
          onTap: editing
              ? null
              : () => ref.read(selectedTabProvider.notifier).state =
                  kSleepTabIndex,
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(cardsLayoutProvider);
    final visibleIds = [
      for (final cfg in layout)
        if (cfg.visible && _cell(cfg.id, context, ref) != null) cfg.id,
    ];
    if (visibleIds.isEmpty) return const SizedBox.shrink();

    if (editing) {
      // Same panel, same dials — now each is its own draggable tile.
      return _GlassPanel(
        child: ReorderableCluster(
          ids: visibleIds,
          columns: visibleIds.length,
          cellHeight: 118,
          spacing: 0,
          builder: (id) => _cell(id, context, ref) ?? const SizedBox.shrink(),
          onOrder: (order) =>
              ref.read(cardsLayoutProvider.notifier).setVisibleOrder(order),
        ),
      );
    }

    final cells = <Widget>[];
    for (final id in visibleIds) {
      if (cells.isNotEmpty) cells.add(const _CellDivider());
      cells.add(Expanded(child: _cell(id, context, ref)!));
    }
    return _GlassPanel(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: cells,
        ),
      ),
    );
  }
}

/// Floating frosted-glass shell — same visual grammar as the nav bar.
class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Metrics.cornerHero);
    if (Palette.isLight) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Palette.surfaceRaised,
          borderRadius: radius,
          border: Border.all(
              color: Palette.hairline.withValues(alpha: 0.8), width: 1),
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
  final bool isEffort;

  /// When set, the metric is not scoreable yet (e.g. recovery is still
  /// calibrating its baseline): the gauge reads empty and shows this text (like
  /// "2/4") instead of a misleading number.
  final String? calibrationText;
  const _HeroCell({
    required this.label,
    required this.value,
    required this.ramp,
    required this.color,
    this.onTap,
    this.isEffort = false,
    this.calibrationText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(gaugeStyleProvider);
    final calibrating = calibrationText != null;
    final centerText = calibrating
        ? calibrationText!
        : (isEffort
            ? Fmt.effort(value, ref.watch(effortScaleProvider))
            : value.round().toString());
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Metrics.cornerChip),
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
                fraction: calibrating ? 0 : (value / 100).clamp(0, 1),
                ramp: ramp,
                size: 78,
                center: Text(centerText,
                    style: NoopType.number(calibrating ? 22 : 24).copyWith(
                      color: gaugeCenterColor(style),
                      shadows: gaugeCenterShadows(style),
                    )),
              ),
              const SizedBox(height: Metrics.space12),
              Text(calibrating ? 'CALIBRATING' : label.toUpperCase(),
                  style: NoopType.overline
                      .copyWith(color: color, letterSpacing: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stress & Energy ──────────────────────────────────────────────────────────

class _StressEnergy extends ConsumerWidget {
  final DayRecord day;
  final bool editing;
  const _StressEnergy({required this.day, this.editing = false});

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
          radius: Metrics.cornerHero,
          onTap: editing
              ? null
              : () => Navigator.of(context).push(
                  noopRoute(const MetricDetailScreen(kind: MetricKind.stress))),
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
                      style: NoopType.headline
                          .copyWith(color: Palette.textPrimary)),
                ],
              ),
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
          radius: Metrics.cornerHero,
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, color: Palette.chargeColor, size: 22),
              const SizedBox(width: Metrics.space12),
              Expanded(
                  child: _EnergyBar(fraction: (day.vitality / 100).clamp(0, 1))),
              const SizedBox(width: Metrics.space12),
              Text('${day.vitality}%',
                  style:
                      NoopType.number(18).copyWith(color: Palette.textPrimary)),
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
            Text(label,
                style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
          ],
        ),
      );
}

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

// ── Your cards ───────────────────────────────────────────────────────────────

/// "Your cards" — the three score timelines. Order follows the shared trio order
/// (reordering the hero dials reorders these too). While [editing] their taps
/// are suppressed.
class _YourCards extends ConsumerWidget {
  final DayRecord day;
  final List<double> Function(double Function(DayRecord), [int]) tail;
  final bool editing;
  const _YourCards({
    required this.day,
    required this.tail,
    this.editing = false,
  });

  Widget? _card(String id, EffortScale effortScale) {
    switch (id) {
      case 'recovery':
        return _MetricChartCard(
          kind: MetricKind.recovery,
          label: 'Recovery',
          value: day.chargeCalibrating
              ? '${day.chargeCalibrationNights}/$recoveryCalibrationNightsNeeded'
              : day.charge.round().toString(),
          unit: day.chargeCalibrating ? 'nights' : '%',
          state: day.chargeCalibrating
              ? 'Calibrating'
              : Palette.recoveryState(day.charge),
          color: Palette.chargeColor,
          caption: day.chargeCalibrating
              ? 'Recovery needs $recoveryCalibrationNightsNeeded full nights to '
                  'learn your baseline. HRV, resting HR & sleep are already real.'
              : 'Higher, steadier peaks mean better readiness.',
          day: day,
          tappable: !editing,
        );
      case 'strain':
        return _MetricChartCard(
          kind: MetricKind.strain,
          label: 'Strain',
          value: Fmt.effort(day.effort, effortScale),
          unit: '',
          state: day.effort < 33
              ? 'Light'
              : (day.effort < 66 ? 'Moderate' : 'Strenuous'),
          color: Palette.effortColor,
          caption: 'Peaks mark bursts of exertion through the day.',
          day: day,
          tappable: !editing,
        );
      case 'sleep':
        return _MetricChartCard(
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
          tappable: !editing,
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effortScale = ref.watch(effortScaleProvider);
    final layout = ref.watch(cardsLayoutProvider);

    final cards = <Widget>[];
    for (final cfg in layout) {
      if (!cfg.visible) continue;
      final card = _card(cfg.id, effortScale);
      if (card == null) continue;
      if (cards.isNotEmpty) cards.add(const SizedBox(height: Metrics.gap));
      cards.add(card);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              bottom: Metrics.space8, top: Metrics.space2),
          child: Text('YOUR CARDS',
              style: NoopType.overline
                  .copyWith(color: Palette.textTertiary, letterSpacing: 1.6)),
        ),
        ...cards,
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
  final bool tappable;
  const _MetricChartCard({
    required this.kind,
    required this.label,
    required this.value,
    required this.unit,
    required this.state,
    required this.color,
    required this.caption,
    required this.day,
    this.tappable = true,
  });

  @override
  Widget build(BuildContext context) {
    final (series, axis) = metricTimeline(day, kind);
    final recessed =
        Color.lerp(Palette.surfaceBase, Palette.surfaceRaised, 0.5)!;
    return NoopCard(
      squircle: true,
      radius: Metrics.cornerHero,
      bordered: false,
      fillColor: recessed,
      onTap: tappable
          ? () => Navigator.of(context)
              .push(noopRoute(MetricDetailScreen(kind: kind)))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label.toUpperCase(),
                  style: NoopType.overline.copyWith(
                      color: Palette.textSecondary, letterSpacing: 1.4)),
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
                  style:
                      NoopType.number(30).copyWith(color: Palette.textPrimary)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(unit,
                    style:
                        NoopType.subhead.copyWith(color: Palette.textTertiary)),
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
