import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:noop/core/analytics/engine_registry.dart';
import 'package:noop/core/data/db/database.dart' show AppDatabase;
import 'package:noop/core/data/repository.dart';
import 'package:noop/core/state/log_store.dart';
import 'package:noop/core/data/models.dart';
import 'package:noop/core/theme/noop_theme.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/core/state/prefs.dart';

/// The data seam. Swap [MockRepository] for a Kotlin-native platform-channel
/// implementation without touching any screen.
final repositoryProvider = Provider<Repository>((ref) => MockRepository());

/// The local SQLite (drift) store. Overridden with an in-memory database in
/// tests; opened as a file on device. Closed when the scope disposes.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// User-editable body-profile overrides, seeded from persisted [Prefs] so they
/// survive a restart. Null → use the repository's default for that field.
final bodyWeightProvider =
    StateProvider<double?>((ref) => Prefs.instance.bodyWeightKg);
final bodyHeightProvider =
    StateProvider<double?>((ref) => Prefs.instance.bodyHeightCm);
final hrMaxProvider = StateProvider<int?>((ref) => Prefs.instance.hrMaxOverride);
final metricProvider = StateProvider<bool?>((ref) => Prefs.instance.metric);

/// The active user profile: the repository's base profile with any persisted
/// body-settings overrides applied (weight, height, max-HR, units). Passing a
/// null override to [UserProfile.copyWith] keeps the base value.
final profileProvider = Provider<UserProfile>((ref) {
  final base = ref.watch(repositoryProvider).profile;
  return base.copyWith(
    weightKg: ref.watch(bodyWeightProvider),
    heightCm: ref.watch(bodyHeightProvider),
    hrMaxOverride: ref.watch(hrMaxProvider),
    metric: ref.watch(metricProvider),
  );
});

/// Every analysis engine's scored days, keyed by engine id (all run over the
/// same raw sync). The switcher reads this to know which engines have data.
final daysByEngineProvider = Provider<Map<String, List<DayRecord>>>(
    (ref) => ref.watch(repositoryProvider).daysByEngine);

/// The analysis engine the user is viewing (persisted). Switching it re-points
/// [daysProvider] at that engine's already-computed scores — no re-analysis.
final selectedEngineProvider =
    StateProvider<String>((ref) => Prefs.instance.analysisEngineId);

/// Bumped whenever the local store is mutated OUTSIDE the live strap stream —
/// today that means a data import. A raw `customStatement` import bypasses
/// drift's table-update tracking, so the stream-driven live reload wouldn't
/// notice it; `main()` watches this counter and rebuilds the repository so an
/// import is scored immediately (not only after a restart or the next sync).
final dataRevisionProvider = StateProvider<int>((_) => 0);

/// All days oldest → newest, for the SELECTED analysis engine. Falls back to the
/// default engine (then empty) when the selected engine produced nothing.
final daysProvider = Provider<List<DayRecord>>((ref) {
  final byEngine = ref.watch(daysByEngineProvider);
  final selected = ref.watch(selectedEngineProvider);
  return byEngine[selected] ?? byEngine[defaultEngineId] ?? const [];
});

/// Index into [daysProvider]; defaults to the latest day. Clamps to 0 when the
/// live day list is still empty (no strap data synced yet) so it never underflows.
final selectedDayIndexProvider = StateProvider<int>((ref) {
  final n = ref.watch(daysProvider).length;
  return n == 0 ? 0 : n - 1;
});

/// The day the user is looking at, or null when there are no days yet (the
/// cold-start live state). Screens guard on this / on `daysProvider.isEmpty`.
final selectedDayProvider = Provider<DayRecord?>((ref) {
  final days = ref.watch(daysProvider);
  if (days.isEmpty) return null;
  final i = ref.watch(selectedDayIndexProvider).clamp(0, days.length - 1);
  return days[i];
});

final workoutsProvider =
    Provider<List<Workout>>((ref) => ref.watch(repositoryProvider).workouts);

final vitalsProvider =
    Provider<List<VitalReading>>((ref) => ref.watch(repositoryProvider).vitals);

/// Strap battery level, 0..1.
final strapBatteryProvider =
    Provider<double>((ref) => ref.watch(repositoryProvider).strapBattery);

/// Appearance mode (system/light/dark). Also mirrored into [Palette]. Persisted.
final appearanceProvider = StateProvider<AppearanceMode>((ref) =>
    switch (Prefs.instance.appearanceMode) {
      'system' => AppearanceMode.system,
      'light' => AppearanceMode.light,
      _ => AppearanceMode.dark,
    });

/// Chart colour style (titanium/classic). Persisted.
final chartStyleProvider = StateProvider<ChartStyle>((ref) =>
    Prefs.instance.chartStyle == 'classic'
        ? ChartStyle.classic
        : ChartStyle.titanium);

/// Whether the intro/onboarding has been completed (gates the app shell).
/// Seeded from [Prefs] so a completed onboarding persists across launches.
final onboardedProvider = StateProvider<bool>((ref) => Prefs.instance.onboarded);

/// Score-dial rendering style (liquid vessel vs arc ring). Persisted.
final gaugeStyleProvider =
    StateProvider<GaugeStyle>((ref) => Prefs.instance.gaugeStyle);

/// Whether the home screen shows a photo wallpaper behind translucent content. Persisted.
final wallpaperProvider = StateProvider<bool>((ref) => Prefs.instance.wallpaper);

/// Optional custom wallpaper image URL (any jpg/png/webp). Null/empty → bundled
/// asset. Persisted; the UI downloads it on demand.
final wallpaperUrlProvider =
    StateProvider<String?>((ref) => Prefs.instance.wallpaperUrl);

/// Sleep window nightly HRV is scored over (whole-night vs deep-sleep). Persisted.
/// Changing it re-scores on the next launch (the pipeline reads it at startup),
/// so the UI shows a "takes effect on restart" note.
final hrvWindowProvider =
    StateProvider<HrvWindow>((ref) => Prefs.instance.hrvWindow);

/// Effort/day-strain display scale (0..100 vs WHOOP 0..21). Persisted.
final effortScaleProvider =
    StateProvider<EffortScale>((ref) => Prefs.instance.effortScale);

/// Whether Trends graphs render as zero-anchored bars instead of lines. Persisted.
final trendsBarsProvider = StateProvider<bool>((ref) => Prefs.instance.trendsBars);

/// Whether temperatures show in Fahrenheit. Persisted.
final fahrenheitProvider = StateProvider<bool>((ref) => Prefs.instance.fahrenheit);

/// The active bottom-nav tab / pager page. Any screen can request a tab switch by
/// setting this (e.g. the home Sleep dial jumps straight to the Sleep tab rather
/// than pushing a detail screen); the shell keeps it in sync with swipes and
/// nav-bar taps. Order: 0 Today · 1 Sleep · 2 Trends · 3 Settings.
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// Tab index of the Sleep screen — keep in sync with AppShell's tab order.
const int kSleepTabIndex = 1;

/// In-plane gravity roll angle (radians) from the accelerometer, low-passed, so
/// the liquid score gauges can level their "water" to real gravity as the phone
/// turns — full 360°, any orientation. On platforms without an accelerometer
/// (desktop, tests) it simply stays 0 and the water sits flat. The accelerometer
/// needs no runtime permission at this (~30 Hz) sampling rate.
final gaugeTiltProvider = StreamProvider<double>((ref) {
  double gx = 0, gy = 9.8; // seed upright so the first frames read level
  final Stream<AccelerometerEvent> src;
  try {
    src = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 33));
  } catch (_) {
    return const Stream<double>.empty();
  }
  return src.map((e) {
    // Low-pass the gravity vector itself (dodges angle wrap-around jitter), then
    // take its screen-plane angle. If the water tilts the WRONG way on a real
    // device, flip the sign of this atan2's first argument.
    gx = gx * 0.82 + e.x * 0.18;
    gy = gy * 0.82 + e.y * 0.18;
    // When the phone lies flat on a table, gravity points into the screen (Z),
    // so the in-plane (x,y) part is near zero and its angle is pure noise — which
    // made the water jitter. Gate the tilt by how much gravity actually lies in
    // the screen plane: flat → confidence 0 → level & steady; upright → full
    // confidence → full levelling. (~4 m/s² in-plane ≈ a ~24° lift for full.)
    final mag = math.sqrt(gx * gx + gy * gy);
    final conf = (mag / 4.0).clamp(0.0, 1.0);
    return math.atan2(-gx, gy) * conf;
  }).handleError((_) {});
});

/// ISO calendar-day key (`yyyy-MM-dd`) — the shared key format for per-day logs
/// (weight, water) in [Prefs].
String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Recommended daily water intake in millilitres, by age. A simple bracket for
/// now (refined logic — sex, weight, activity — comes later).
double recommendedWaterMl(int age) {
  if (age < 18) return 2000;
  if (age <= 30) return 3000;
  if (age <= 55) return 2500;
  return 2000;
}

/// The user's daily water goal in millilitres, derived from their profile age.
final waterGoalProvider =
    Provider<double>((ref) => recommendedWaterMl(ref.watch(profileProvider).age));

/// Per-day water-intake log in millilitres, keyed by [isoDay]. User-entered
/// (there is no hydration sensor in the capture), seeded from [Prefs] and
/// persisted on every change.
class WaterLogNotifier extends StateNotifier<Map<String, double>> {
  WaterLogNotifier(this._db) : super(Map.of(LogStore.instance.water));

  final AppDatabase _db;

  /// Add [ml] to [day]'s running total (never below zero).
  void add(DateTime day, double ml) {
    final key = isoDay(day);
    setForDay(day, (state[key] ?? 0.0) + ml);
  }

  /// Set [day]'s total to exactly [ml] (clamped ≥ 0).
  void setForDay(DateTime day, double ml) {
    final key = isoDay(day);
    final v = ml < 0 ? 0.0 : ml;
    state = {...state, key: v};
    LogStore.instance.water[key] = v;
    _db.setWater(key, v);
  }

  /// Clear [day]'s entry entirely.
  void clearDay(DateTime day) {
    final key = isoDay(day);
    state = Map<String, double>.of(state)..remove(key);
    LogStore.instance.water.remove(key);
    _db.deleteWater(key);
  }
}

/// The app-wide water-log provider (drift-backed).
final waterLogProvider =
    StateNotifierProvider<WaterLogNotifier, Map<String, double>>(
  (ref) => WaterLogNotifier(ref.watch(databaseProvider)),
);

/// Per-day body-weight log in kilograms, keyed by [isoDay]. User-entered and
/// persisted — the real weight tracker (no sensor source, never fabricated).
class WeightLogNotifier extends StateNotifier<Map<String, double>> {
  WeightLogNotifier(this._db) : super(Map.of(LogStore.instance.weights));

  final AppDatabase _db;

  /// Set [day]'s weight to exactly [kg] (clamped to a sane 20–400 range).
  void setForDay(DateTime day, double kg) {
    final key = isoDay(day);
    final v = kg.clamp(20.0, 400.0);
    state = {...state, key: v};
    LogStore.instance.weights[key] = v;
    _db.setWeight(key, v);
  }

  /// Clear [day]'s entry entirely.
  void clearDay(DateTime day) {
    final key = isoDay(day);
    state = Map<String, double>.of(state)..remove(key);
    LogStore.instance.weights.remove(key);
    _db.deleteWeight(key);
  }

  /// The most recent logged weight (any day), or null if the log is empty.
  double? get latest {
    if (state.isEmpty) return null;
    final keys = state.keys.toList()..sort();
    return state[keys.last];
  }
}

/// The app-wide weight-log provider (drift-backed).
final weightLogProvider =
    StateNotifierProvider<WeightLogNotifier, Map<String, double>>(
  (ref) => WeightLogNotifier(ref.watch(databaseProvider)),
);
