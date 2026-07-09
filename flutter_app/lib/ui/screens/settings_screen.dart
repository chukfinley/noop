import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../components/cards.dart';
import '../components/common.dart';
import '../components/scaffold.dart';
import '../theme/metrics.dart';
import '../theme/noop_theme.dart';
import '../theme/palette.dart';

// ── Local UI state (display toggles) ────────────────────────────────────────
// File-level StateProviders keep [SettingsScreen] a plain ConsumerWidget while
// letting the switches visibly flip. None of these persist — they are session
// UI state only.
final _tempFahrenheit = StateProvider<bool>((_) => false);
final _keepConnected = StateProvider<bool>((_) => true);
final _continuousHrv = StateProvider<bool>((_) => true);
final _illnessWatch = StateProvider<bool>((_) => true);
final _hydrationReminders = StateProvider<bool>((_) => false);
final _stressCheckIns = StateProvider<bool>((_) => true);
final _autoDetectWorkouts = StateProvider<bool>((_) => true);
final _keepScreenOn = StateProvider<bool>((_) => false);

/// App settings — grouped setting cards for profile, units, appearance, the
/// strap, health toggles and about. Mirrors TodayScreen in style.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final appearance = ref.watch(appearanceProvider);
    final chartStyle = ref.watch(chartStyleProvider);

    return ScreenScaffold(
      title: 'Settings',
      children: [
        // ── Profile ─────────────────────────────────────────────────────────
        SectionCard(
          title: 'Profile',
          accent: Palette.accent,
          child: _Group([
            _SettingRow(title: 'Name', trailing: _value(profile.name)),
            _SettingRow(title: 'Age', trailing: _value('${profile.age}')),
            _SettingRow(
                title: 'Sex',
                trailing: _value(profile.male ? 'Male' : 'Female')),
            _SettingRow(
                title: 'Weight', trailing: _value('${profile.weightKg} kg')),
            _SettingRow(
                title: 'Height', trailing: _value('${profile.heightCm} cm')),
            _SettingRow(
              title: 'Max HR override',
              detail: 'Used for heart-rate zones',
              trailing:
                  _value(profile.hrMaxOverride?.toString() ?? 'Auto (Tanaka)'),
            ),
          ]),
        ),

        // ── Units ───────────────────────────────────────────────────────────
        SectionCard(
          title: 'Units',
          child: _Group([
            _SettingRow(
              title: 'Measurement system',
              detail: profile.metric ? 'Metric' : 'Imperial',
              trailing: _Toggle(
                value: profile.metric,
                onChanged: (_) {},
              ),
            ),
            _SettingRow(
              title: 'Temperature',
              detail: ref.watch(_tempFahrenheit) ? 'Fahrenheit' : 'Celsius',
              trailing: _PillGroup<bool>(
                options: const [(false, '°C'), (true, '°F')],
                value: ref.watch(_tempFahrenheit),
                onChanged: (v) =>
                    ref.read(_tempFahrenheit.notifier).state = v,
              ),
            ),
          ]),
        ),

        // ── Appearance ──────────────────────────────────────────────────────
        SectionCard(
          title: 'Appearance',
          accent: Palette.accent,
          child: _Group([
            _SettingRow(
              title: 'Theme',
              detail: 'How NOOP adapts to your device',
              trailing: _PillGroup<AppearanceMode>(
                options: [
                  for (final m in AppearanceMode.values) (m, m.label),
                ],
                value: appearance,
                onChanged: (m) =>
                    ref.read(appearanceProvider.notifier).state = m,
              ),
            ),
            _SettingRow(
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
          ]),
        ),

        // ── Strap ───────────────────────────────────────────────────────────
        SectionCard(
          title: 'Strap',
          accent: Palette.effortColor,
          child: _Group([
            _SettingRow(
              title: 'Connection',
              detail: 'NOOP Band 4',
              trailing: Text('Connected',
                  style: NoopType.body
                      .copyWith(color: Palette.statusPositive)),
            ),
            _SettingRow(
              title: 'Keep connected in background',
              detail: 'Maintain sync while the app is closed',
              trailing: _Toggle(
                value: ref.watch(_keepConnected),
                onChanged: (v) =>
                    ref.read(_keepConnected.notifier).state = v,
              ),
            ),
            _SettingRow(
              title: 'Continuous HRV',
              detail: 'Sample HRV throughout the day',
              trailing: _Toggle(
                value: ref.watch(_continuousHrv),
                onChanged: (v) =>
                    ref.read(_continuousHrv.notifier).state = v,
              ),
            ),
          ]),
        ),

        // ── Health & wellness ───────────────────────────────────────────────
        SectionCard(
          title: 'Health & wellness',
          child: _Group([
            _SettingRow(
              title: 'Illness watch',
              detail: 'Flag elevated skin temp & respiratory rate',
              trailing: _Toggle(
                value: ref.watch(_illnessWatch),
                onChanged: (v) =>
                    ref.read(_illnessWatch.notifier).state = v,
              ),
            ),
            _SettingRow(
              title: 'Hydration reminders',
              trailing: _Toggle(
                value: ref.watch(_hydrationReminders),
                onChanged: (v) =>
                    ref.read(_hydrationReminders.notifier).state = v,
              ),
            ),
            _SettingRow(
              title: 'Stress check-ins',
              trailing: _Toggle(
                value: ref.watch(_stressCheckIns),
                onChanged: (v) =>
                    ref.read(_stressCheckIns.notifier).state = v,
              ),
            ),
            _SettingRow(
              title: 'Auto-detect workouts',
              trailing: _Toggle(
                value: ref.watch(_autoDetectWorkouts),
                onChanged: (v) =>
                    ref.read(_autoDetectWorkouts.notifier).state = v,
              ),
            ),
            _SettingRow(
              title: 'Keep screen on',
              detail: 'While viewing live metrics',
              trailing: _Toggle(
                value: ref.watch(_keepScreenOn),
                onChanged: (v) =>
                    ref.read(_keepScreenOn.notifier).state = v,
              ),
            ),
          ]),
        ),

        // ── About ───────────────────────────────────────────────────────────
        SectionCard(
          title: 'About',
          child: _Group([
            _SettingRow(
                title: 'Version', trailing: _value('8.0.1 (build 168)')),
            _SettingRow(
              title: "What's New",
              trailing: const _Chevron(),
              onTap: () {},
            ),
            _SettingRow(
              title: 'How NOOP works',
              trailing: const _Chevron(),
              onTap: () {},
            ),
            _SettingRow(
              title: 'Scoring guide',
              trailing: const _Chevron(),
              onTap: () {},
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Metrics.space12),
          child: Center(
            child: Text('NOOP — recovery, sleep & strain',
                style:
                    NoopType.footnote.copyWith(color: Palette.textTertiary)),
          ),
        ),
      ],
    );
  }

  static Widget _value(String text) =>
      Text(text, style: NoopType.body.copyWith(color: Palette.textSecondary));
}

/// Stacks setting rows with hairline separators between them.
class _Group extends StatelessWidget {
  final List<Widget> rows;
  const _Group(this.rows);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i != rows.length - 1) const Hairline(),
        ],
      ],
    );
  }
}

/// A single labelled row: title (+ optional detail) on the left, trailing on
/// the right. Tappable when [onTap] is supplied.
class _SettingRow extends StatelessWidget {
  final String title;
  final String? detail;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingRow({
    required this.title,
    this.detail,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: NoopType.body.copyWith(color: Palette.textPrimary)),
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
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Metrics.cornerSm),
      child: row,
    );
  }
}

/// Thin wrapper around [Switch] using the app accent.
class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Palette.accent,
      inactiveThumbColor: Palette.textTertiary,
      inactiveTrackColor: Palette.hairlineStrong,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// A segmented control rendered as a row of tappable pills. The selected pill
/// is filled with the accent colour.
class _PillGroup<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  const _PillGroup({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Palette.surfaceInset,
        borderRadius: BorderRadius.circular(Metrics.cornerPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (opt, label) in options)
            _Pill(
              label: label,
              selected: opt == value,
              onTap: () => onChanged(opt),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Motion.durationFast,
        curve: Motion.easeOut,
        padding: const EdgeInsets.symmetric(
            horizontal: Metrics.space12, vertical: Metrics.space8),
        decoration: BoxDecoration(
          color: selected ? Palette.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(Metrics.cornerPill),
        ),
        child: Text(
          label,
          style: NoopType.caption.copyWith(
            color: selected ? Palette.surfaceBase : Palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();
  @override
  Widget build(BuildContext context) => Icon(
        Icons.chevron_right_rounded,
        color: Palette.textTertiary,
        size: 20,
      );
}
