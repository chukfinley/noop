import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/providers.dart';
import 'ui/app_shell.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/theme/metrics.dart';
import 'ui/theme/noop_theme.dart';
import 'ui/theme/palette.dart';

void main() => runApp(const ProviderScope(child: NoopApp()));

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
      home: AnimatedSwitcher(
        duration: Motion.durationStandard,
        child: onboarded ? const AppShell() : const OnboardingScreen(),
      ),
    );
  }
}
