import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/state/prefs.dart';
import 'package:noop/core/state/providers.dart';
import 'package:noop/shared/widgets/behavior.dart';
import 'package:noop/shared/widgets/controls.dart';
import 'package:noop/shared/widgets/scaffold.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/noop_theme.dart';
import 'package:noop/core/theme/palette.dart';

// ── Local UI state (display toggles) ────────────────────────────────────────
// File-level StateProviders keep [SettingsScreen] a plain ConsumerWidget while
// letting the switches visibly flip. None of these persist — they are session
// UI state only.
final _tempFahrenheit = StateProvider<bool>((_) => false);
final _keepConnected = StateProvider<bool>((_) => true);
final _continuousHrv = StateProvider<bool>((_) => true);
final _illnessWatch = StateProvider<bool>((_) => true);
final _hydrationReminders = StateProvider<bool>((_) => false);
final _autoDetectWorkouts = StateProvider<bool>((_) => true);
final _keepScreenOn = StateProvider<bool>((_) => false);

// Editable profile fields — seeded null, fall back to the repository profile
// until the user changes them.
final _weightKg = StateProvider<double?>((_) => null);
final _heightCm = StateProvider<double?>((_) => null);
final _hrMax = StateProvider<int?>((_) => null);
final _metric = StateProvider<bool?>((_) => null);

/// App settings, rebuilt in the Material 3 Expressive idiom: a prominent tonal
/// profile card, bold coloured group headers, and *connected* grouped lists —
/// each row is its own filled tile whose outer corners are extra-large and
/// inner (touching) corners are small, separated by a hairline gap.
///
/// The animated controls stay: every on/off uses [_Toggle] (the nav-bar pill
/// with a sliding highlight) and every segmented choice uses [_PillGroup] (the
/// gliding segmented control). Riverpod remains the single source of truth.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The hub — the SAME connected tonal-tile groups the sub-pages use, so the
    // main page reads like its own sub-screens. Each row opens a sub-screen.
    // No account / plan / sign-out: the app is open-source, there is nothing to
    // sign into and no Pro tier.
    final groups = <List<(String, String, IconData, Color, Widget)>>[
      [
        ('Body', 'Weight, height, max HR', Icons.person_rounded, Palette.accent,
            const _BodySettings()),
        ('Units', 'Measurement & temperature', Icons.straighten_rounded,
            Palette.metricCyan, const _UnitsSettings()),
      ],
      [
        ('Appearance', 'Theme, colours & dials', Icons.palette_rounded,
            Palette.metricPurple, const _AppearanceSettings()),
        ('Strap', 'Connection & sensors', Icons.watch_rounded,
            Palette.effortColor, const _StrapSettings()),
        ('Health & wellness', 'Reminders & detection', Icons.favorite_rounded,
            Palette.chargeColor, const _WellnessSettings()),
      ],
      [
        ('Data', 'Backup & sync', Icons.cloud_rounded, Palette.metricCyan,
            const _DataSettings()),
        ('About', "Version & what's new", Icons.info_rounded,
            Palette.textSecondary, const _AboutScreen()),
      ],
    ];

    return ScreenScaffold(
      title: 'Settings',
      children: [
        for (final g in groups) ...[
          _ConnectedGroup([
            for (final r in g)
              (radius) => _Tile(
                    radius: radius,
                    icon: r.$3,
                    iconColor: r.$4,
                    title: r.$1,
                    detail: r.$2,
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: Palette.textTertiary, size: 20),
                    onTap: () => Navigator.of(context).push(noopRoute(r.$5)),
                  ),
          ]),
          const SizedBox(height: Metrics.space12),
        ],
        Padding(
          padding: const EdgeInsets.only(top: Metrics.space8),
          child: Center(
            child: Text('Recovery · sleep · strain',
                style: NoopType.footnote.copyWith(color: Palette.textTertiary)),
          ),
        ),
      ],
    );
  }
}

// ── Category sub-screens ─────────────────────────────────────────────────────

String _fmtNum(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

Widget _val(String text) =>
    Text(text, style: NoopType.body.copyWith(color: Palette.textSecondary));

/// A number-editor dialog for a profile field.
Future<void> _editNumber(
  BuildContext context, {
  required String title,
  required String unit,
  required double value,
  required double min,
  required double max,
  required ValueChanged<double> onSet,
}) async {
  final ctrl = TextEditingController(text: _fmtNum(value));
  final result = await showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Palette.surfaceRaised,
      title: Text(title,
          style: NoopType.title2.copyWith(color: Palette.textPrimary)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: NoopType.number(26).copyWith(color: Palette.textPrimary),
        decoration: InputDecoration(
          suffixText: unit,
          suffixStyle: NoopType.body.copyWith(color: Palette.textTertiary),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Palette.textSecondary))),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
            if (v != null && v >= min && v <= max) Navigator.pop(ctx, v);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (result != null) onSet(result);
}

class _BodySettings extends ConsumerWidget {
  const _BodySettings();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final w = ref.watch(_weightKg) ?? profile.weightKg;
    final h = ref.watch(_heightCm) ?? profile.heightCm;
    final hr = ref.watch(_hrMax) ?? profile.hrMaxOverride;
    return ScreenScaffold(title: 'Body', children: [
      _ConnectedGroup([
        (r) => _Tile(
              radius: r,
              icon: Icons.monitor_weight_rounded,
              iconColor: Palette.accent,
              title: 'Weight',
              trailing: _val('${_fmtNum(w)} kg'),
              onTap: () => _editNumber(context,
                  title: 'Weight',
                  unit: 'kg',
                  value: w,
                  min: 30,
                  max: 300,
                  onSet: (v) => ref.read(_weightKg.notifier).state = v),
            ),
        (r) => _Tile(
              radius: r,
              icon: Icons.height_rounded,
              iconColor: Palette.accent,
              title: 'Height',
              trailing: _val('${_fmtNum(h)} cm'),
              onTap: () => _editNumber(context,
                  title: 'Height',
                  unit: 'cm',
                  value: h,
                  min: 100,
                  max: 250,
                  onSet: (v) => ref.read(_heightCm.notifier).state = v),
            ),
        (r) => _Tile(
              radius: r,
              icon: Icons.favorite_rounded,
              iconColor: Palette.metricRose,
              title: 'Max HR override',
              detail: 'Used for heart-rate zones',
              trailing: _val(hr?.toString() ?? 'Auto'),
              onTap: () => _editNumber(context,
                  title: 'Max HR',
                  unit: 'bpm',
                  value: (hr ?? 190).toDouble(),
                  min: 120,
                  max: 230,
                  onSet: (v) => ref.read(_hrMax.notifier).state = v.round()),
            ),
      ]),
    ]);
  }
}

class _UnitsSettings extends ConsumerWidget {
  const _UnitsSettings();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final metric = ref.watch(_metric) ?? profile.metric;
    return ScreenScaffold(title: 'Units', children: [
      _ConnectedGroup([
        (r) => _Tile(
              radius: r,
              icon: Icons.straighten_rounded,
              iconColor: Palette.metricCyan,
              title: 'Measurement system',
              detail: metric ? 'Metric' : 'Imperial',
              trailing: NoopToggle(
                  value: metric,
                  onChanged: (v) => ref.read(_metric.notifier).state = v),
            ),
        (r) => _Tile(
              radius: r,
              icon: Icons.thermostat_rounded,
              iconColor: Palette.metricCyan,
              title: 'Temperature',
              trailing: _PillGroup<bool>(
                options: const [(false, '°C'), (true, '°F')],
                value: ref.watch(_tempFahrenheit),
                onChanged: (v) => ref.read(_tempFahrenheit.notifier).state = v,
              ),
            ),
      ]),
    ]);
  }
}

class _AppearanceSettings extends ConsumerWidget {
  const _AppearanceSettings();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final chartStyle = ref.watch(chartStyleProvider);
    final gaugeStyle = ref.watch(gaugeStyleProvider);
    return ScreenScaffold(title: 'Appearance', children: [
      _ConnectedGroup([
        (r) => _Tile(
              radius: r,
              icon: Icons.brightness_6_rounded,
              iconColor: Palette.metricPurple,
              title: 'Theme',
              detail: 'How the app adapts to your device',
              trailing: _PillGroup<AppearanceMode>(
                options: [for (final m in AppearanceMode.values) (m, m.label)],
                value: appearance,
                onChanged: (m) =>
                    ref.read(appearanceProvider.notifier).state = m,
              ),
            ),
        (r) => _Tile(
              radius: r,
              icon: Icons.palette_rounded,
              iconColor: Palette.metricPurple,
              title: 'Chart colours',
              detail: 'Palette used across graphs',
              trailing: _PillGroup<ChartStyle>(
                options: const [
                  (ChartStyle.titanium, 'Titanium'),
                  (ChartStyle.classic, 'Classic'),
                ],
                value: chartStyle,
                onChanged: (s) =>
                    ref.read(chartStyleProvider.notifier).state = s,
              ),
            ),
        (r) => _Tile(
              radius: r,
              icon: Icons.blur_circular_rounded,
              iconColor: Palette.metricPurple,
              title: 'Score dials',
              detail: 'Liquid vessel or a classic arc ring',
              trailing: _PillGroup<GaugeStyle>(
                options: const [
                  (GaugeStyle.liquid, 'Water'),
                  (GaugeStyle.ring, 'Ring'),
                ],
                value: gaugeStyle,
                onChanged: (s) {
                  ref.read(gaugeStyleProvider.notifier).state = s;
                  Prefs.instance.setGaugeStyle(s);
                },
              ),
            ),
      ]),
    ]);
  }
}

class _StrapSettings extends ConsumerWidget {
  const _StrapSettings();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenScaffold(title: 'Strap', children: [
      _ConnectedGroup([
        (r) => _Tile(
              radius: r,
              icon: Icons.bluetooth_connected_rounded,
              iconColor: Palette.effortColor,
              title: 'Connection',
              detail: 'Band 4',
              trailing: Text('Connected',
                  style:
                      NoopType.body.copyWith(color: Palette.statusPositive)),
            ),
        (r) => _Tile(
              radius: r,
              icon: Icons.sync_rounded,
              iconColor: Palette.effortColor,
              title: 'Keep connected in background',
              detail: 'Maintain sync while the app is closed',
              trailing: NoopToggle(
                value: ref.watch(_keepConnected),
                onChanged: (v) => ref.read(_keepConnected.notifier).state = v,
              ),
            ),
        (r) => _Tile(
              radius: r,
              icon: Icons.monitor_heart_rounded,
              iconColor: Palette.effortColor,
              title: 'Continuous HRV',
              detail: 'Sample HRV throughout the day',
              trailing: NoopToggle(
                value: ref.watch(_continuousHrv),
                onChanged: (v) => ref.read(_continuousHrv.notifier).state = v,
              ),
            ),
      ]),
    ]);
  }
}

class _WellnessSettings extends ConsumerWidget {
  const _WellnessSettings();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenScaffold(title: 'Health & wellness', children: [
      _ConnectedGroup([
        (r) => _Tile(
              radius: r,
              icon: Icons.sick_rounded,
              iconColor: Palette.chargeColor,
              title: 'Illness watch',
              detail: 'Flag elevated skin temp & respiratory rate',
              trailing: NoopToggle(
                value: ref.watch(_illnessWatch),
                onChanged: (v) => ref.read(_illnessWatch.notifier).state = v,
              ),
            ),
        (r) => _Tile(
              radius: r,
              icon: Icons.water_drop_rounded,
              iconColor: Palette.metricCyan,
              title: 'Hydration reminders',
              trailing: NoopToggle(
                value: ref.watch(_hydrationReminders),
                onChanged: (v) =>
                    ref.read(_hydrationReminders.notifier).state = v,
              ),
            ),
        (r) => _Tile(
              radius: r,
              icon: Icons.directions_run_rounded,
              iconColor: Palette.effortColor,
              title: 'Auto-detect workouts',
              trailing: NoopToggle(
                value: ref.watch(_autoDetectWorkouts),
                onChanged: (v) =>
                    ref.read(_autoDetectWorkouts.notifier).state = v,
              ),
            ),
        (r) => _Tile(
              radius: r,
              icon: Icons.screen_lock_portrait_rounded,
              iconColor: Palette.textSecondary,
              title: 'Keep screen on',
              detail: 'While viewing live metrics',
              trailing: NoopToggle(
                value: ref.watch(_keepScreenOn),
                onChanged: (v) => ref.read(_keepScreenOn.notifier).state = v,
              ),
            ),
      ]),
    ]);
  }
}

class _DataSettings extends StatelessWidget {
  const _DataSettings();
  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(title: 'Data', children: [
      _ConnectedGroup([
        (r) => _Tile(
              radius: r,
              icon: Icons.cloud_sync_rounded,
              iconColor: Palette.metricCyan,
              title: 'Backup & sync',
              onTap: () {},
            ),
      ]),
    ]);
  }
}


/// About — a small sub-page kept off the main Settings list.
class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) => ScreenScaffold(
        title: 'About',
        children: [
          _SettingsGroup('App', Palette.textSecondary, [
            (r) => _Tile(
                  radius: r,
                  icon: Icons.info_rounded,
                  iconColor: Palette.textSecondary,
                  title: 'Version',
                  trailing: Text('8.0.1 (build 168)',
                      style: NoopType.body
                          .copyWith(color: Palette.textSecondary)),
                ),
            (r) => _Tile(
                  radius: r,
                  icon: Icons.auto_awesome_rounded,
                  iconColor: Palette.gold,
                  title: "What's New",
                  onTap: () {},
                ),
          ]),
        ],
      );
}

// ── Grouping primitives ─────────────────────────────────────────────────────

/// An emphasised, coloured group header — the bold accent label that sits above
/// each connected group in the Expressive style.
class _GroupHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _GroupHeader(this.title, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
            left: Metrics.space6, bottom: Metrics.space10),
        child: Text(
          title,
          style: NoopType.headline
              .copyWith(color: color, fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      );
}

/// A group = a coloured header above a [_ConnectedGroup] of filled tiles.
class _SettingsGroup extends StatelessWidget {
  final String title;
  final Color color;
  final List<Widget Function(BorderRadius radius)> tiles;
  const _SettingsGroup(this.title, this.color, this.tiles);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GroupHeader(title, color),
          _ConnectedGroup(tiles),
        ],
      );
}

/// A *connected* list: each tile builder is handed the [BorderRadius] it should
/// wear so the group's OUTER corners are extra-large and the INNER touching
/// corners are small, with a thin gap between rows — the Material 3 Expressive
/// grouped-list shape.
class _ConnectedGroup extends StatelessWidget {
  final List<Widget Function(BorderRadius radius)> tiles;
  const _ConnectedGroup(this.tiles);

  static const double _outer = 26;
  static const double _inner = 6;
  static const double _gap = 3;

  @override
  Widget build(BuildContext context) {
    final n = tiles.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < n; i++) ...[
          tiles[i](BorderRadius.vertical(
            top: Radius.circular(i == 0 ? _outer : _inner),
            bottom: Radius.circular(i == n - 1 ? _outer : _inner),
          )),
          if (i != n - 1) const SizedBox(height: _gap),
        ],
      ],
    );
  }
}

// ── Row / tile primitives ───────────────────────────────────────────────────

/// A tonal icon chip: a rounded-square filled with the icon's colour at low
/// alpha, the icon itself in the full colour.
class _IconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconChip({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 17, color: color),
      );
}

/// A single filled setting tile: a leading tonal icon chip, a title (+ optional
/// detail line) and a trailing control. Its own filled surface, shaped by the
/// [radius] the connected group hands it. Tappable when [onTap] is supplied.
class _Tile extends StatelessWidget {
  final BorderRadius radius;
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? detail;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _Tile({
    required this.radius,
    this.icon,
    this.iconColor,
    required this.title,
    this.detail,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Palette.accent;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Metrics.space14, vertical: Metrics.space10),
      child: Row(
        children: [
          if (icon != null) ...[
            _IconChip(icon: icon!, color: color),
            const SizedBox(width: Metrics.space12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: NoopType.body.copyWith(
                        color: Palette.textPrimary,
                        fontWeight: FontWeight.w500)),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail!,
                      style: NoopType.caption
                          .copyWith(color: Palette.textTertiary)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Metrics.space12),
            trailing!,
          ],
        ],
      ),
    );
    return Material(
      color: Palette.surfaceRaised,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// A segmented control with a single highlight that *glides* between options —
/// the same slide mechanic as the bottom nav bar (equal slots, easeOutCubic).
class _PillGroup<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  const _PillGroup({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  static const _height = 30.0;
  static const _slide = Duration(milliseconds: 340);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Metrics.cornerPill);
    final n = options.length;
    // Equal slot width sized to the widest label so the highlight glides evenly.
    var maxLabel = 0.0;
    for (final (_, label) in options) {
      final tp = TextPainter(
        text: TextSpan(text: label, style: NoopType.caption),
        textDirection: TextDirection.ltr,
      )..layout();
      if (tp.width > maxLabel) maxLabel = tp.width;
    }
    final slotW = maxLabel + Metrics.space12 * 2;
    final idx = options.indexWhere((o) => o.$1 == value).clamp(0, n - 1);
    final alignX = n <= 1 ? 0.0 : -1 + 2 * idx / (n - 1);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: Palette.surfaceInset, borderRadius: radius),
      child: SizedBox(
        width: slotW * n,
        height: _height,
        child: Stack(
          children: [
            // The one highlight that slides between slots.
            AnimatedAlign(
              alignment: Alignment(alignX, 0),
              duration: _slide,
              curve: _curve,
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Palette.accent, borderRadius: radius),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  SizedBox(
                    width: slotW,
                    child: GestureDetector(
                      onTap: () => onChanged(options[i].$1),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: _slide,
                          curve: _curve,
                          style: NoopType.caption.copyWith(
                            color: i == idx ? Palette.surfaceBase : Palette.textSecondary,
                          ),
                          child: Text(options[i].$2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

