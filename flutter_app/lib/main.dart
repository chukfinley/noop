import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/db/database.dart';
import 'package:noop/core/data/nutrition/off_client.dart';
import 'package:noop/core/ble/background/background_sync_service.dart';
import 'package:noop/core/ble/background/background_sync_scheduler.dart';
import 'package:noop/core/ble/transport/whoop_providers.dart';
import 'package:noop/core/data/real_repository.dart';
import 'package:noop/core/data/repository.dart';
import 'package:noop/core/state/log_store.dart';
import 'package:noop/core/state/prefs.dart';
import 'package:noop/core/state/providers.dart';
import 'package:noop/features/shell/presentation/app_shell.dart';
import 'package:noop/features/onboarding/presentation/onboarding_screen.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/noop_theme.dart';
import 'package:noop/core/theme/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.instance.load();

  // Open Food Facts requires a real User-Agent before any lookup.
  OffClient.init(appName: 'NOOP', appUrl: 'https://github.com/ryanbr/noop');

  // Open the local store and load the user logs into memory (importing any
  // legacy secure-storage logs into the DB on first run).
  final db = AppDatabase();
  await LogStore.instance.loadFrom(db);

  // Score the real bundled Whoop capture through the ported analytics; fall
  // back to the deterministic mock only if the asset can't be read.
  Repository repo;
  try {
    repo = await RealRepository.load();
  } catch (e, st) {
    debugPrint('RealRepository.load failed, using MockRepository: $e\n$st');
    repo = MockRepository();
  }

  // Build the root container ourselves so we can kick the guarded WHOOP auto-reconnect at startup
  // (a remembered strap reconnects + offloads with no user action). The kick is a strict no-op off
  // Android/iOS and when nothing is remembered — and because tests build their OWN ProviderScope and
  // never call main(), a plain `flutter test` never triggers it.
  final container = ProviderContainer(
    overrides: [
      repositoryProvider.overrideWithValue(repo),
      databaseProvider.overrideWithValue(db),
    ],
  );
  kickWhoopAutoConnect(container);

  // Android background sync: once the remembered strap is reconnecting, start a low-key foreground
  // service that keeps the app PROCESS alive so this same main-isolate client keeps auto-reconnecting
  // + offloading while the app is backgrounded. Strict no-op off Android (desktop/web/iOS), when no
  // strap is remembered, or when disabled — and tests never call main(), so it never runs under
  // `flutter test`.
  unawaited(maybeStartBackgroundSync(container));

  // Android killed-app sync: the foreground service above only survives BACKGROUNDING (it dies with
  // the process on swipe-away). To also sync AFTER the app is terminated, register a periodic
  // WorkManager job whose headless isolate reconnects + offloads on its own (Android 15-min min).
  // The two complement each other: WorkManager wakes the app after a kill, and while it runs the
  // foreground service holds the connection window. Strict no-op off Android, when nothing is
  // remembered, or when disabled — and tests never call main(), so it never registers under
  // `flutter test`. It also starts the app-alive heartbeat that makes the headless task SKIP while
  // this process is alive (the single-owner concurrency guard).
  unawaited(maybeRegisterBackgroundSyncWork(container));

  runApp(UncontrolledProviderScope(
    container: container,
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
