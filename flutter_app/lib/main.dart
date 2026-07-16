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

/// Meters calls to a live rebuild so a strap offload cannot peg the CPU.
///
/// A rebuild is [LiveRepository.load] — it re-reads the WHOOP stream tables for
/// every local day the store holds and re-scores them. Its cost is linear in
/// TOTAL history and it is not small: 19eb1b2a measured it, on a store seeded at
/// realistic offload density, at 652 ms for 1 day, 3.5 s for 7, 13.4 s for 30 and
/// **44 s for 90** — and 95 % of that (the reads, the merge, the bucketing) is on
/// the main isolate; only the scoring is handed to [Isolate.run]. An offload
/// writes rows in bursts over minutes, so the requests do not stop coming while
/// one of these is running.
///
/// The policy this replaces was a bare 2 s trailing-edge debounce plus a
/// single-flight guard that re-ran immediately on completion. It had no notion of
/// what a rebuild costs, and so was wrong in BOTH tick regimes, in opposite
/// directions:
///
///  * **Ticks further apart than the settle window → thrash.** The timer fires
///    during the 44 s rebuild, the guard latches `pending`, and completion starts
///    the next rebuild back-to-back. One such gap anywhere in a rebuild is enough
///    to latch it, and it re-latches every cycle: the store is then re-read
///    end-to-end, continuously, for the whole offload and once more after it. That
///    is ~100 % main-isolate occupancy — the overheating the user reports. A 2 s
///    debounce can only ever meter work that FINISHES inside 2 s; this never does.
///  * **Ticks closer together than the settle window → starvation.** Each tick
///    cancelled and re-armed the timer, so a burst that never pauses for 2 s
///    deferred the rebuild indefinitely and NOTHING appeared until the sync ended.
///
/// Both follow from metering by wall-clock alone, so the fix is to meter against
/// the measured cost instead:
///
///  * [settle] still coalesces a burst (unchanged intent, unchanged 2 s).
///  * [maxWait] caps how long re-arming can defer the FIRST rebuild of a burst —
///    a burst that never pauses is not a burst, and past this point we stop
///    waiting for a lull that is not coming and show what we have. It bounds only
///    that first rebuild's latency; everything after is governed by the cooldown,
///    so guessing it wrong costs at most one extra rebuild per offload.
///  * [dutyFactor] is the load-bearing one: after a rebuild finishes, the next may
///    not START for `dutyFactor x` however long that rebuild actually TOOK. That
///    caps sustained main-isolate occupancy at `1 / (1 + dutyFactor)` — 20 % at
///    the default 4 — no matter how much history exists, and it scales itself: a
///    1-day store rebuilds in 652 ms and is free again 2.6 s later (still feels
///    live), a 90-day store takes 44 s and is left alone for ~3 min. No fixed
///    constant does both; that is precisely why raising the 2 s would not have
///    fixed this — at 90 days the phone still cooks at any constant below ~3 min,
///    while at 1 day that same constant makes a nearly-free rebuild feel broken.
///
/// Deliberately NOT capped at some maximum cooldown. A cap re-introduces the bug
/// it was capping: a store big enough for the cap to bind is exactly a store whose
/// rebuild is expensive, so clamping the gap puts occupancy straight back up (a
/// 350 s rebuild under a 3 min cap runs 66 % of the time). The duty bound is the
/// whole guarantee; it only holds if it is unconditional. The floor is [settle],
/// so a trivially cheap store is never throttled below the burst coalescing it
/// needs anyway.
///
/// The cost is measured on the WALL clock, which is not the same as CPU time: if
/// the process is suspended mid-rebuild the measurement absorbs the suspension and
/// the next cooldown comes out too long. Accepted knowingly, because every way it
/// can go wrong is bounded and mild — the meter is per-process, so a launch always
/// loads fresh regardless; a user action ([request] with `immediate`) ignores the
/// cooldown outright; and the only symptom left is live updates pausing too long
/// inside one session, which is the direction we would rather err. Measuring CPU
/// time instead would need a clock Dart does not portably offer, and a suspended
/// app is not the one overheating.
///
/// The real fix is to stop re-reading unchanged days at all — an offload appends
/// to the tail, so a rebuild should touch the days that moved, not all 90. That is
/// a change to [LiveRepository] and its day cache, not to the metering; until it
/// lands, this bounds the damage.
class LiveReloadScheduler {
  LiveReloadScheduler({
    required Future<void> Function() load,
    this.settle = const Duration(seconds: 2),
    this.maxWait = const Duration(seconds: 15),
    this.dutyFactor = 4,
    DateTime Function()? clock,
    Timer Function(Duration, void Function())? timerFactory,
  })  : _load = load,
        _clock = clock ?? DateTime.now,
        _timerFactory = timerFactory ?? Timer.new;

  final Future<void> Function() _load;
  final DateTime Function() _clock;
  final Timer Function(Duration, void Function()) _timerFactory;

  /// How long a burst must be quiet before its rebuild runs.
  final Duration settle;

  /// The longest [settle] may keep deferring the first rebuild of a burst.
  final Duration maxWait;

  /// Idle multiple of the last rebuild's duration to wait before the next starts.
  final int dutyFactor;

  Timer? _timer;
  bool _running = false;
  bool _pending = false; // a metered request arrived mid-rebuild
  bool _pendingNow = false; // ...and at least one of them was a user action
  DateTime? _firstRequestAt; // start of the burst currently being coalesced
  DateTime? _earliestStart; // cooldown floor from the last rebuild's cost

  /// Ask for a rebuild.
  ///
  /// [immediate] means a person is waiting on this exact rebuild — they switched
  /// analysis engine, or they imported a backup — as opposed to the strap having
  /// written some rows. Those bypass settle and cooldown both: they arrive at
  /// human speed so they cannot thrash, and making someone wait out a 3-minute
  /// cooldown to see the engine they just picked would trade this bug for a worse
  /// one. They still respect single-flight.
  void request({bool immediate = false}) {
    if (_running) {
      _pending = true;
      _pendingNow |= immediate;
      return;
    }
    final now = _clock();
    if (immediate) {
      _arm(Duration.zero);
      return;
    }
    _firstRequestAt ??= now;
    // The earlier of "settle after this tick" and "maxWait after the burst
    // began" — then held back to the cooldown floor, which outranks both.
    var target = now.add(settle);
    final cap = _firstRequestAt!.add(maxWait);
    if (cap.isBefore(target)) target = cap;
    final floor = _earliestStart;
    if (floor != null && floor.isAfter(target)) target = floor;
    final wait = target.difference(now);
    _arm(wait.isNegative ? Duration.zero : wait);
  }

  void _arm(Duration d) {
    _timer?.cancel();
    _timer = _timerFactory(d, _run);
  }

  void _run() {
    if (_running) {
      _pending = true;
      return;
    }
    _running = true;
    _firstRequestAt = null;
    final startedAt = _clock();
    // Deliberately not `await`ed: _run is a timer callback. The continuation
    // below carries the whole completion path.
    unawaited(_load().catchError((Object e, StackTrace st) {
      // A failed rebuild still COST its time, so it still owes the cooldown —
      // returning here (rather than rethrowing) keeps the finally-equivalent
      // below on the one path that updates the meter.
      debugPrint('live reload failed: $e\n$st');
    }).whenComplete(() {
      _running = false;
      final took = _clock().difference(startedAt);
      // Cooldown from COMPLETION, not from start: gap = dutyFactor x cost gives a
      // flat 1/(1+dutyFactor) duty cycle, which is the number this class promises.
      var cool = took * dutyFactor;
      if (cool < settle) cool = settle;
      _earliestStart = _clock().add(cool);
      if (!_pending) return;
      final wasNow = _pendingNow;
      _pending = false;
      _pendingNow = false;
      request(immediate: wasNow);
    }));
  }

  /// Stops any armed timer. The app-lifetime instance never needs this; tests do.
  void dispose() => _timer?.cancel();
}

/// Metered live re-derivation: on any change to the WHOOP HR/RR/gravity stream
/// tables, rebuild [LiveRepository] from the DB and push it into the container so
/// dependent providers (days, vitals, …) refresh. Metering — the part that keeps a
/// long offload from cooking the phone — lives in [LiveReloadScheduler]. Never
/// cancelled: it lives for the app's lifetime.
void _wireLiveReload(ProviderContainer container, AppDatabase db) {
  final scheduler = LiveReloadScheduler(load: () async {
    final fresh =
        await LiveRepository.load(db, hrvWindow: Prefs.instance.hrvWindow);
    container.updateOverrides([
      repositoryProvider.overrideWithValue(fresh),
      databaseProvider.overrideWithValue(db),
    ]);
  });

  db.watchWhoopStreams().listen((_) => scheduler.request());

  // Switching analysis engine only re-points the UI at that engine's scores —
  // but a not-yet-computed engine has to be scored first. Rebuild on the change
  // so the newly-selected engine is computed on demand (guarded/off-isolate).
  // `immediate`: the user is looking at the picker waiting for it.
  container.listen<String>(
      selectedEngineProvider, (_, __) => scheduler.request(immediate: true));

  // A data import writes rows via raw SQL that drift's stream tracking misses,
  // so rebuild when the import counter bumps — otherwise imported history would
  // only surface after a restart or the next strap sync. `immediate`: the user
  // just picked the file and is waiting on it.
  container.listen<int>(
      dataRevisionProvider, (_, __) => scheduler.request(immediate: true));
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
