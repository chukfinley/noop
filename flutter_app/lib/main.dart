import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/db/database.dart';
import 'package:noop/core/data/nutrition/off_client.dart';
import 'package:noop/core/ble/background/background_sync_service.dart';
import 'package:noop/core/ble/background/background_sync_scheduler.dart';
import 'package:noop/core/ble/transport/whoop_providers.dart';
import 'package:noop/core/data/live_repository.dart';
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

  // LIVE, strap-synced data ONLY — no bundled history. The app starts EMPTY and
  // scores real strap syncs from the drift stream tables through the ported
  // analytics; personal baselines recalibrate over the first days. On a DB-open
  // failure we fall back to an EMPTY live repo (real-or-nothing: never the mock's
  // fabricated numbers on device).
  Repository repo;
  try {
    repo = await LiveRepository.load(db, hrvWindow: Prefs.instance.hrvWindow);
  } catch (e, st) {
    debugPrint('LiveRepository.load failed, starting empty: $e\n$st');
    repo = LiveRepository.empty();
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

  // Auto-connect the moment Bluetooth is switched ON (by any means — the in-app
  // "Turn on" banner, Android quick-settings, …): if a strap is remembered,
  // reconnect and offload, so a sync begins a few seconds after the adapter
  // powers on — the "turn on Bluetooth → strap connects → sync starts" behaviour
  // the user wants.
  //
  // The `pairedStrapProvider != null` guard is LOAD-BEARING, not a fast path.
  // connectRemembered() reconnects a REMEMBERED strap and otherwise refuses
  // ([WhoopBleClient.resolveAutoConnect] never adopts an arbitrary advertiser —
  // it once did, which made an unattended tick pair with whichever band was
  // nearby). This listener fires with no user present, so it must never be the
  // thing that FIRST pairs a strap: pairing is an explicit pick, via onboarding's
  // "Find your strap" or Settings → Scan for straps.
  //
  // Fires only on the false→true transition, and only on a real BLE platform.
  container.listen<AsyncValue<bool>>(bleAdapterOnProvider, (prev, next) {
    final wasOn = prev?.valueOrNull ?? false;
    final isOn = next.valueOrNull ?? false;
    if (!wasOn && isOn && container.read(pairedStrapProvider) != null) {
      unawaited(container.read(whoopBleClientProvider).connectRemembered());
    }
  });

  // Re-derive scores as new strap data lands: a debounced listen on the WHOOP
  // biometric stream tables rebuilds the live repository and swaps it into
  // repositoryProvider, so every day-driven surface grows as syncs complete
  // (empty → first days → warmed baselines). Inert under `flutter test` — tests
  // build their own ProviderScope and never call main().
  _wireLiveReload(container, db);

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

  // Re-arm the foreground service on every backgrounding: the service dismisses
  // its own notification once each sync completes (so it never hangs a permanent
  // "syncing" notification), which means a later backgrounding needs to start a
  // fresh cycle. No-op when background sync is off / nothing paired / off Android.
  WidgetsBinding.instance
      .addObserver(_BackgroundSyncLifecycleObserver(container));

  runApp(UncontrolledProviderScope(
    container: container,
    child: const NoopApp(),
  ));
}

/// Restarts the background-sync foreground service each time the app is
/// backgrounded, pairing with the service's dismiss-on-complete behaviour: every
/// background cycle runs a sync whose notification shows while it works and clears
/// when it is done. Continued sync between cycles is the periodic WorkManager job.
class _BackgroundSyncLifecycleObserver extends WidgetsBindingObserver {
  _BackgroundSyncLifecycleObserver(this._container);
  final ProviderContainer _container;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Start the foreground service (keeps syncing + shows the notification while
      // backgrounded) AND register the periodic killed-app WorkManager job. Doing
      // both here — not only at launch — means a strap paired MID-SESSION gets
      // full background sync the first time the app is backgrounded, without
      // needing a relaunch. Both no-op when bg sync is off / nothing paired.
      unawaited(maybeStartBackgroundSync(_container));
      unawaited(maybeRegisterBackgroundSyncWork(_container));
    }
  }
}

/// Debounced live re-derivation: on any change to the WHOOP HR/RR/gravity stream
/// tables, rebuild [LiveRepository] from the DB and push it into the container so
/// dependent providers (days, vitals, …) refresh. Debounced because one offload
/// writes many rows in bursts. Never cancelled — it lives for the app's lifetime.
void _wireLiveReload(ProviderContainer container, AppDatabase db) {
  Timer? debounce;
  var loading = false; // a rebuild is in flight
  var pending = false; // another was requested while one was running

  // Rebuild the repository, guarded so at most ONE runs at a time. Extra
  // requests during a run collapse into a single trailing rebuild. Without this
  // guard a long offload (which writes rows in bursts) could start overlapping
  // full re-scores of the whole store — the CPU peg that overheated the phone.
  Future<void> reload() async {
    if (loading) {
      pending = true;
      return;
    }
    loading = true;
    try {
      final fresh =
          await LiveRepository.load(db, hrvWindow: Prefs.instance.hrvWindow);
      container.updateOverrides([
        repositoryProvider.overrideWithValue(fresh),
        databaseProvider.overrideWithValue(db),
      ]);
    } catch (e, st) {
      debugPrint('live reload failed: $e\n$st');
    } finally {
      loading = false;
      if (pending) {
        pending = false;
        unawaited(reload()); // run the coalesced trailing rebuild once
      }
    }
  }

  db.watchWhoopStreams().listen((_) {
    debounce?.cancel();
    // A longer settle window than the raw stream cadence: one offload writes
    // rows in dense bursts, and each rebuild re-queries the whole store and
    // re-scores the active engine. Coalescing to ~2 s keeps a long sync from
    // triggering a rebuild storm.
    debounce = Timer(const Duration(milliseconds: 2000), reload);
  });

  // Switching analysis engine only re-points the UI at that engine's scores —
  // but a not-yet-computed engine has to be scored first. Rebuild on the change
  // so the newly-selected engine is computed on demand (guarded/off-isolate).
  container.listen<String>(selectedEngineProvider, (_, __) => reload());

  // A data import writes rows via raw SQL that drift's stream tracking misses,
  // so rebuild when the import counter bumps — otherwise imported history would
  // only surface after a restart or the next strap sync.
  container.listen<int>(dataRevisionProvider, (_, __) => reload());
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
