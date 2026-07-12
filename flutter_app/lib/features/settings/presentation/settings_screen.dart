import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/weather.dart';
import 'package:noop/core/state/prefs.dart';
import 'package:noop/core/state/providers.dart';
import 'package:noop/features/settings/presentation/location_settings_screen.dart';
import 'package:noop/shared/widgets/behavior.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/common.dart';
import 'package:noop/shared/widgets/controls.dart';
import 'package:noop/shared/widgets/scaffold.dart';
import 'package:noop/shared/widgets/settings_tiles.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/noop_theme.dart';
import 'package:noop/core/theme/palette.dart';

// ── Local UI state (display toggles) ────────────────────────────────────────
// File-level StateProviders keep [SettingsScreen] a plain ConsumerWidget while
// letting the switches visibly flip. Each is seeded from persisted [Prefs]
// (per-key default) and written back on change, so every toggle survives a
// restart.
bool _tog(String k, bool def) => Prefs.instance.toggles[k] ?? def;
final _keepConnected = StateProvider<bool>((_) => _tog('keep_connected', true));
final _continuousHrv = StateProvider<bool>((_) => _tog('continuous_hrv', true));
final _illnessWatch = StateProvider<bool>((_) => _tog('illness_watch', true));
final _hydrationReminders =
    StateProvider<bool>((_) => _tog('hydration_reminders', false));
final _autoDetectWorkouts =
    StateProvider<bool>((_) => _tog('auto_detect_workouts', true));
final _keepScreenOn = StateProvider<bool>((_) => _tog('keep_screen_on', false));

/// Flip a persisted toggle: update its provider and write it through to storage.
void _setTog(WidgetRef ref, StateProvider<bool> p, String key, bool v) {
  ref.read(p.notifier).state = v;
  Prefs.instance.setToggle(key, v);
}

// Editable body-profile fields live in [bodyWeightProvider] / [bodyHeightProvider]
// / [hrMaxProvider] / [metricProvider] (providers.dart) — persisted and applied
// to [profileProvider], so a change actually sticks and feeds the rest of the app.

/// App settings, rebuilt in the Material 3 Expressive idiom: a prominent tonal
/// profile card, bold coloured group headers, and *connected* grouped lists —
/// each row is its own filled tile whose outer corners are extra-large and
/// inner (touching) corners are small, separated by a hairline gap.
///
/// The animated controls stay: every on/off uses [NoopToggle] (the nav-bar pill
/// with a sliding highlight) and every segmented choice uses [NoopSegmented]
/// (the shared gliding segmented control). Riverpod remains the single source
/// of truth.
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
        ('AI estimator', 'Food-photo calories (your key)',
            Icons.auto_awesome_rounded, Palette.effortColor, const _AiSettings()),
        ('Data', 'Backup & sync', Icons.cloud_rounded, Palette.metricCyan,
            const _DataSettings()),
        ('About', "Version & what's new", Icons.info_rounded,
            Palette.textSecondary, const _AboutScreen()),
      ],
    ];

    // One Column so ScreenScaffold's screenRowSpacing isn't inserted between
    // every group — we own the (tighter) inter-group gap ourselves.
    return ScreenScaffold(
      title: 'Settings',
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var gi = 0; gi < groups.length; gi++) ...[
              ConnectedGroup([
                for (final r in groups[gi])
                  (radius) => SettingsTile(
                        radius: radius,
                        icon: r.$3,
                        iconColor: r.$4,
                        title: r.$1,
                        detail: r.$2,
                        onTap: () => Navigator.of(context).push(noopRoute(r.$5)),
                      ),
              ]),
              if (gi != groups.length - 1)
                const SizedBox(height: Metrics.space12),
            ],
            Padding(
              padding: const EdgeInsets.only(top: Metrics.space16),
              child: Center(
                child: Text('Recovery · sleep · strain',
                    style:
                        NoopType.footnote.copyWith(color: Palette.textTertiary)),
              ),
            ),
          ],
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
      backgroundColor: Palette.fillRaised,
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
                style:
                    NoopType.body.copyWith(color: Palette.textSecondary))),
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
    final w = ref.watch(bodyWeightProvider) ?? profile.weightKg;
    final h = ref.watch(bodyHeightProvider) ?? profile.heightCm;
    final hr = ref.watch(hrMaxProvider) ?? profile.hrMaxOverride;
    return ScreenScaffold(title: 'Body', children: [
      ConnectedGroup([
        (r) => SettingsTile(
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
                  onSet: (v) {
                    ref.read(bodyWeightProvider.notifier).state = v;
                    Prefs.instance.setBodyWeight(v);
                  }),
            ),
        (r) => SettingsTile(
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
                  onSet: (v) {
                    ref.read(bodyHeightProvider.notifier).state = v;
                    Prefs.instance.setBodyHeight(v);
                  }),
            ),
        (r) => SettingsTile(
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
                  onSet: (v) {
                    ref.read(hrMaxProvider.notifier).state = v.round();
                    Prefs.instance.setHrMaxOverride(v.round());
                  }),
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
    final metric = ref.watch(metricProvider) ?? profile.metric;
    return ScreenScaffold(title: 'Units', children: [
      ConnectedGroup([
        (r) => SettingsTile(
              radius: r,
              icon: Icons.straighten_rounded,
              iconColor: Palette.metricCyan,
              title: 'Measurement system',
              detail: metric ? 'Metric' : 'Imperial',
              trailing: NoopToggle(
                  value: metric,
                  onChanged: (v) {
                    ref.read(metricProvider.notifier).state = v;
                    Prefs.instance.setMetric(v);
                  }),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.thermostat_rounded,
              iconColor: Palette.metricCyan,
              title: 'Temperature',
              trailing: NoopSegmented<bool>(
                segments: const [
                  NoopSegment(false, '°C'),
                  NoopSegment(true, '°F'),
                ],
                value: ref.watch(fahrenheitProvider),
                onChanged: (v) {
                  ref.read(fahrenheitProvider.notifier).state = v;
                  Prefs.instance.setFahrenheit(v);
                },
              ),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.bolt_rounded,
              iconColor: Palette.effortColor,
              title: 'Effort scale',
              detail: 'How day strain is shown',
              trailing: NoopSegmented<EffortScale>(
                segments: const [
                  NoopSegment(EffortScale.hundred, '0–100'),
                  NoopSegment(EffortScale.whoop, '0–21'),
                ],
                value: ref.watch(effortScaleProvider),
                onChanged: (v) {
                  ref.read(effortScaleProvider.notifier).state = v;
                  Prefs.instance.setEffortScale(v);
                },
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
    final loc = ref.watch(weatherLocationProvider);
    final wallUrl = ref.watch(wallpaperUrlProvider);
    return ScreenScaffold(title: 'Appearance', children: [
      ConnectedGroup([
        (r) => SettingsTile(
              radius: r,
              icon: Icons.brightness_6_rounded,
              iconColor: Palette.metricPurple,
              title: 'Theme',
              detail: 'How the app adapts to your device',
              trailing: NoopSegmented<AppearanceMode>(
                segments: [
                  for (final m in AppearanceMode.values) NoopSegment(m, m.label),
                ],
                value: appearance,
                onChanged: (m) {
                  ref.read(appearanceProvider.notifier).state = m;
                  Prefs.instance.setAppearanceMode(m.name);
                },
              ),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.palette_rounded,
              iconColor: Palette.metricPurple,
              title: 'Chart colours',
              detail: 'Palette used across graphs',
              trailing: NoopSegmented<ChartStyle>(
                segments: const [
                  NoopSegment(ChartStyle.titanium, 'Titanium'),
                  NoopSegment(ChartStyle.classic, 'Classic'),
                ],
                value: chartStyle,
                onChanged: (s) {
                  ref.read(chartStyleProvider.notifier).state = s;
                  Prefs.instance.setChartStyle(s.name);
                },
              ),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.bar_chart_rounded,
              iconColor: Palette.metricPurple,
              title: 'Trend graphs',
              detail: 'Bars or a line',
              trailing: NoopSegmented<bool>(
                segments: const [
                  NoopSegment(false, 'Line'),
                  NoopSegment(true, 'Bars'),
                ],
                value: ref.watch(trendsBarsProvider),
                onChanged: (v) {
                  ref.read(trendsBarsProvider.notifier).state = v;
                  Prefs.instance.setTrendsBars(v);
                },
              ),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.blur_circular_rounded,
              iconColor: Palette.metricPurple,
              title: 'Score dials',
              detail: 'Liquid vessel or a classic arc ring',
              trailing: NoopSegmented<GaugeStyle>(
                segments: const [
                  NoopSegment(GaugeStyle.liquid, 'Water'),
                  NoopSegment(GaugeStyle.ring, 'Ring'),
                ],
                value: gaugeStyle,
                onChanged: (s) {
                  ref.read(gaugeStyleProvider.notifier).state = s;
                  Prefs.instance.setGaugeStyle(s);
                },
              ),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.location_on_rounded,
              iconColor: Palette.metricCyan,
              title: 'Weather location',
              detail: (loc != null && loc.name.isNotEmpty)
                  ? loc.name
                  : 'Automatic',
              trailing: Icon(Icons.chevron_right_rounded,
                  color: Palette.textTertiary, size: 20),
              onTap: () => Navigator.of(context)
                  .push(noopRoute(const LocationSettingsScreen())),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.wallpaper_rounded,
              iconColor: Palette.metricPurple,
              title: 'Home wallpaper',
              detail: 'Show a photo behind the home screen',
              trailing: NoopToggle(
                value: ref.watch(wallpaperProvider),
                onChanged: (v) {
                  ref.read(wallpaperProvider.notifier).state = v;
                  Prefs.instance.setWallpaper(v);
                },
              ),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.image_rounded,
              iconColor: Palette.metricPurple,
              title: 'Wallpaper image',
              detail: (wallUrl != null && wallUrl.isNotEmpty)
                  ? wallUrl
                  : 'Bundled photo · tap to use any image URL',
              trailing: Icon(Icons.chevron_right_rounded,
                  color: Palette.textTertiary, size: 20),
              onTap: () => _editWallpaperUrl(context, ref, wallUrl),
            ),
      ]),
    ]);
  }
}

/// Set a custom wallpaper image URL (any jpg/png/webp). Saving a non-empty URL
/// also switches the wallpaper on; "Use default" clears it back to the asset.
Future<void> _editWallpaperUrl(
    BuildContext context, WidgetRef ref, String? current) async {
  final ctrl = TextEditingController(text: current ?? '');
  // Recommended minimum resolution: the wallpaper spans all four tabs and pans
  // as you swipe, so it wants to be roughly the screen's pixel size × the number
  // of tabs wide to stay crisp on this device.
  const tabs = 4;
  final mq = MediaQuery.of(context);
  final wPx = (mq.size.width * mq.devicePixelRatio).round();
  final hPx = (mq.size.height * mq.devicePixelRatio).round();
  final recW = wPx * tabs;
  final result = await showDialog<String?>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Palette.fillRaised,
      title: Text('Wallpaper image',
          style: NoopType.title2.copyWith(color: Palette.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paste a link to any image (jpg, png, webp). It is downloaded and '
            'shown behind the home.',
            style: NoopType.caption.copyWith(color: Palette.textTertiary),
          ),
          const SizedBox(height: Metrics.space8),
          Text(
            'For a crisp backdrop across all $tabs tabs on this phone, use an '
            'image at least $recW×$hPx px (about $tabs screens wide).',
            style: NoopType.caption.copyWith(color: Palette.accent),
          ),
          const SizedBox(height: Metrics.space12),
          TextField(
            controller: ctrl,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.url,
            style: NoopType.body.copyWith(color: Palette.textPrimary),
            decoration: const InputDecoration(hintText: 'https://…'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, ''),
          child: Text('Use default',
              style: NoopType.body.copyWith(color: Palette.textSecondary)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (result == null) return; // dismissed
  final url = result.isEmpty ? null : result;
  ref.read(wallpaperUrlProvider.notifier).state = url;
  await Prefs.instance.setWallpaperUrl(url);
  if (url != null) {
    // A custom image is only visible with the wallpaper on — enable it.
    ref.read(wallpaperProvider.notifier).state = true;
    await Prefs.instance.setWallpaper(true);
  }
}

class _StrapSettings extends ConsumerWidget {
  const _StrapSettings();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenScaffold(title: 'Strap', children: [
      ConnectedGroup([
        (r) => SettingsTile(
              radius: r,
              icon: Icons.bluetooth_connected_rounded,
              iconColor: Palette.effortColor,
              title: 'Connection',
              detail: 'Band 4',
              trailing: Text('Connected',
                  style:
                      NoopType.body.copyWith(color: Palette.statusPositive)),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.sync_rounded,
              iconColor: Palette.effortColor,
              title: 'Keep connected in background',
              detail: 'Maintain sync while the app is closed',
              trailing: NoopToggle(
                value: ref.watch(_keepConnected),
                onChanged: (v) =>
                    _setTog(ref, _keepConnected, 'keep_connected', v),
              ),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.monitor_heart_rounded,
              iconColor: Palette.effortColor,
              title: 'Continuous HRV',
              detail: 'Sample HRV throughout the day',
              trailing: NoopToggle(
                value: ref.watch(_continuousHrv),
                onChanged: (v) =>
                    _setTog(ref, _continuousHrv, 'continuous_hrv', v),
              ),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.bedtime_rounded,
              iconColor: Palette.effortColor,
              title: 'HRV window',
              detail: ref.watch(hrvWindowProvider) == HrvWindow.deepSleep
                  ? 'Deep sleep (WHOOP-comparable) · applies on restart'
                  : 'Whole night (default)',
              trailing: NoopSegmented<HrvWindow>(
                segments: const [
                  NoopSegment(HrvWindow.wholeNight, 'Night'),
                  NoopSegment(HrvWindow.deepSleep, 'Deep'),
                ],
                value: ref.watch(hrvWindowProvider),
                onChanged: (v) {
                  ref.read(hrvWindowProvider.notifier).state = v;
                  Prefs.instance.setHrvWindow(v);
                  noopToast(context,
                      'HRV window saved — re-scores on next launch');
                },
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
      ConnectedGroup([
        (r) => SettingsTile(
              radius: r,
              icon: Icons.sick_rounded,
              iconColor: Palette.chargeColor,
              title: 'Illness watch',
              detail: 'Flag elevated skin temp & respiratory rate',
              trailing: NoopToggle(
                value: ref.watch(_illnessWatch),
                onChanged: (v) =>
                    _setTog(ref, _illnessWatch, 'illness_watch', v),
              ),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.water_drop_rounded,
              iconColor: Palette.metricCyan,
              title: 'Hydration reminders',
              trailing: NoopToggle(
                value: ref.watch(_hydrationReminders),
                onChanged: (v) => _setTog(
                    ref, _hydrationReminders, 'hydration_reminders', v),
              ),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.directions_run_rounded,
              iconColor: Palette.effortColor,
              title: 'Auto-detect workouts',
              trailing: NoopToggle(
                value: ref.watch(_autoDetectWorkouts),
                onChanged: (v) => _setTog(
                    ref, _autoDetectWorkouts, 'auto_detect_workouts', v),
              ),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.screen_lock_portrait_rounded,
              iconColor: Palette.textSecondary,
              title: 'Keep screen on',
              detail: 'While viewing live metrics',
              trailing: NoopToggle(
                value: ref.watch(_keepScreenOn),
                onChanged: (v) =>
                    _setTog(ref, _keepScreenOn, 'keep_screen_on', v),
              ),
            ),
      ]),
    ]);
  }
}

/// AI food-photo estimator — bring-your-own OpenAI-compatible key (OpenAI or
/// xAI Grok). The key is a secret stored only in secure storage; the request
/// goes device→provider, so the user pays for their own usage.
class _AiSettings extends ConsumerStatefulWidget {
  const _AiSettings();
  @override
  ConsumerState<_AiSettings> createState() => _AiSettingsState();
}

class _AiSettingsState extends ConsumerState<_AiSettings> {
  late final TextEditingController _key =
      TextEditingController(text: Prefs.instance.aiApiKey ?? '');
  late final TextEditingController _base =
      TextEditingController(text: Prefs.instance.aiBaseUrl);
  late final TextEditingController _model =
      TextEditingController(text: Prefs.instance.aiModel);
  bool _obscure = true;

  @override
  void dispose() {
    _key.dispose();
    _base.dispose();
    _model.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController c, String label,
      {bool obscure = false, Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Metrics.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: NoopType.caption.copyWith(color: Palette.textTertiary)),
          const SizedBox(height: Metrics.space4),
          TextField(
            controller: c,
            obscureText: obscure,
            autocorrect: false,
            enableSuggestions: false,
            style: NoopType.body.copyWith(color: Palette.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: Palette.surfaceRaised,
              suffixIcon: suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Metrics.cornerCard),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(title: 'AI estimator', children: [
      NoopCard(
        padding: const EdgeInsets.all(Metrics.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Estimate calories from a meal photo. Works with any '
              'OpenAI-compatible endpoint — OpenAI or xAI Grok. Your key stays '
              'on this device and is only sent to the provider you choose; '
              'usage is billed to your own account.',
              style: NoopType.body.copyWith(color: Palette.textSecondary),
            ),
            const SizedBox(height: Metrics.space16),
            _field(_key, 'API key',
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                      _obscure
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 20,
                      color: Palette.textTertiary),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )),
            _field(_base, 'Base URL (e.g. https://api.openai.com/v1 · Grok: https://api.x.ai/v1)'),
            _field(_model, 'Model (e.g. gpt-4o-mini · Grok: grok-2-vision-1212)'),
            NoopButton('Save', icon: Icons.check_rounded, onPressed: () async {
              await Prefs.instance.setAiConfig(
                  _key.text.trim(), _base.text.trim(), _model.text.trim());
              if (context.mounted) {
                noopToast(context, 'AI settings saved',
                    kind: ToastKind.success);
              }
            }),
          ],
        ),
      ),
    ]);
  }
}

class _DataSettings extends StatelessWidget {
  const _DataSettings();
  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(title: 'Data', children: [
      ConnectedGroup([
        (r) => SettingsTile(
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
          SettingsGroup('App', Palette.textSecondary, [
            (r) => SettingsTile(
                  radius: r,
                  icon: Icons.info_rounded,
                  iconColor: Palette.textSecondary,
                  title: 'Version',
                  trailing: Text('8.0.1 (build 168)',
                      style: NoopType.body
                          .copyWith(color: Palette.textSecondary)),
                ),
            (r) => SettingsTile(
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


