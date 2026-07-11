import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/real_repository.dart';
import 'data/repository.dart';
import 'state/prefs.dart';
import 'state/providers.dart';
import 'ui/app_shell.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/theme/metrics.dart';
import 'ui/theme/noop_theme.dart';
import 'ui/theme/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.instance.load();

  // Score the real bundled Whoop capture through the ported analytics; fall
  // back to the deterministic mock only if the asset can't be read.
  Repository repo;
  try {
    repo = await RealRepository.load();
  } catch (e, st) {
    debugPrint('RealRepository.load failed, using MockRepository: $e\n$st');
    repo = MockRepository();
  }

  runApp(ProviderScope(
    overrides: [repositoryProvider.overrideWithValue(repo)],
    child: const NoopApp(),
  ));
}

/// Hides the scrollbar on every scrollable (desktop shows one by default).
class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}

class NoopApp extends ConsumerWidget {
  const NoopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appearanceProvider);
    Palette.chartStyle = ref.watch(chartStyleProvider);
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final tokens = tokensFor(mode, platformBrightness);
    final brightness = brightnessFor(mode, platformBrightness);

    final onboarded = ref.watch(onboardedProvider);
    return MaterialApp(
      title: 'NOOP',
      debugShowCheckedModeBanner: false,
      theme: buildNoopTheme(tokens, brightness),
      scrollBehavior: const _NoScrollbarBehavior(),
      home: AnimatedSwitcher(
        duration: Motion.durationStandard,
        child: onboarded ? const AppShell() : const OnboardingScreen(),
      ),
    );
  }
}
