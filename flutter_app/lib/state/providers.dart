import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository.dart';
import '../data/models.dart';
import '../ui/theme/noop_theme.dart';
import '../ui/theme/palette.dart';

/// The data seam. Swap [MockRepository] for a Kotlin-native platform-channel
/// implementation without touching any screen.
final repositoryProvider = Provider<Repository>((ref) => MockRepository());

final profileProvider = Provider<UserProfile>((ref) => ref.watch(repositoryProvider).profile);

/// All days oldest → newest.
final daysProvider = Provider<List<DayRecord>>((ref) => ref.watch(repositoryProvider).days);

/// Index into [daysProvider]; defaults to the latest day.
final selectedDayIndexProvider = StateProvider<int>(
  (ref) => ref.watch(daysProvider).length - 1,
);

final selectedDayProvider = Provider<DayRecord>((ref) {
  final days = ref.watch(daysProvider);
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

/// Appearance mode (system/light/dark). Also mirrored into [Palette].
final appearanceProvider =
    StateProvider<AppearanceMode>((ref) => AppearanceMode.dark);

/// Chart colour style (titanium/classic).
final chartStyleProvider = StateProvider<ChartStyle>((ref) => ChartStyle.titanium);

/// Whether the intro/onboarding has been completed (gates the app shell).
final onboardedProvider = StateProvider<bool>((ref) => false);
