import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:noop/main.dart';
import 'package:noop/state/providers.dart';
import 'package:noop/state/format.dart';
import 'package:noop/data/repository.dart';
import 'package:noop/data/real_repository.dart';
import 'package:noop/ui/screens/sleep_screen.dart';
import 'package:noop/analytics/engines.dart';
import 'package:noop/analytics/baselines.dart';

/// Boot straight into the shell (skip the onboarding gate).
Widget _bootedApp() => ProviderScope(
      overrides: [onboardedProvider.overrideWith((ref) => true)],
      child: const NoopApp(),
    );

void main() {
  // Keep tests offline & deterministic — never hit the network for fonts.
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('app boots and renders Today without exceptions', (tester) async {
    await tester.pumpWidget(_bootedApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Today'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every bottom-nav tab builds (IndexedStack mounts all)', (tester) async {
    await tester.pumpWidget(_bootedApp());
    await tester.pump(const Duration(seconds: 1));
    // All four tab screens are mounted at once (offstage) — their titles exist.
    expect(find.text('Trends', skipOffstage: false), findsWidgets);
    expect(find.text('Sleep', skipOffstage: false), findsWidgets);
    expect(find.text('Settings', skipOffstage: false), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sleep screen reflects the selected day (not hard-coded)', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final days = container.read(daysProvider);
    final iA = 10, iB = days.length - 5;
    final dayA = days[iA], dayB = days[iB];
    expect(dayA.date, isNot(dayB.date)); // the two days must differ

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SleepScreen()),
    ));

    container.read(selectedDayIndexProvider.notifier).state = iA;
    await tester.pump(const Duration(seconds: 1));
    // The day-nav strip shows the selected day's date.
    expect(find.text(Fmt.shortDate(dayA.date)), findsWidgets);
    // The Sleep hero must show the SAME sleep score as the home screen
    // (DayRecord.rest), not the raw asleep/need ratio (sleep.performance).
    expect(find.text(dayA.rest.round().toString()), findsWidgets);

    container.read(selectedDayIndexProvider.notifier).state = iB;
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(Fmt.shortDate(dayB.date)), findsWidgets);
    expect(find.text(Fmt.shortDate(dayA.date)), findsNothing); // switched away
  });

  testWidgets('Sleep screen keeps its header (back nav) on a no-sleep day', (tester) async {
    // Real capture has some days with no staged sleep — the header must still
    // render there so you can navigate back.
    final repo = await RealRepository.load();
    final container =
        ProviderContainer(overrides: [repositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    final days = container.read(daysProvider);
    final idx = days.indexWhere((d) => d.sleep == null);
    expect(idx, greaterThanOrEqualTo(0), reason: 'real data should contain a no-sleep day');

    container.read(selectedDayIndexProvider.notifier).state = idx;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SleepScreen()),
    ));
    await tester.pump(const Duration(seconds: 1));

    final d = days[idx];
    expect(find.text('No sleep recorded for this day.'), findsOneWidget);
    // Header + day-nav (date) still present → the screen is navigable, not a
    // dead end.
    expect(find.text(Fmt.shortDate(d.date)), findsWidgets);
    expect(find.text('Sleep'), findsWidgets);
  });

  testWidgets('onboarding shows first, Get started enters the shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NoopApp()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Recovery, decoded'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('MockRepository generates a full, consistent dataset', () {
    final repo = MockRepository();
    expect(repo.days.length, 90);
    expect(repo.today.charge, inInclusiveRange(0, 100));
    expect(repo.today.rest, inInclusiveRange(0, 100));
    expect(repo.today.effort, inInclusiveRange(0, 100));
    expect(repo.vitals, isNotEmpty);
    expect(repo.workouts, isNotEmpty);
    // Latest night has a hypnogram for the detail view.
    final withHypno = repo.days.where((d) => d.sleep?.hypnogram.isNotEmpty ?? false);
    expect(withHypno, isNotEmpty);
  });

  test('scoring engines are internally consistent', () {
    // Rest composite in range.
    final rest = restScore(
      asleepSec: 7 * 3600,
      needSec: 8 * 3600,
      efficiency01: 0.9,
      deepSec: 1.2 * 3600,
      remSec: 1.6 * 3600,
      consistency01: 0.8,
    );
    expect(rest, isNotNull);
    expect(rest!, inInclusiveRange(0, 100));

    // Recovery needs a usable HRV baseline; cold start returns null.
    final hrvBase = BaselineState();
    final rhrBase = BaselineState();
    final respBase = BaselineState();
    expect(
      recoveryScore(const RecoveryInput(hrv: 65, rhr: 52), hrvBase, rhrBase, respBase),
      isNull,
    );
    // After enough nights the baseline becomes usable and a score appears.
    for (var i = 0; i < 10; i++) {
      Baselines.update(hrvBase, 'hrv', 65 + i.toDouble());
      Baselines.update(rhrBase, 'resting_hr', 52);
    }
    final score = recoveryScore(
      const RecoveryInput(hrv: 70, rhr: 50, sleepPerf01: 0.9),
      hrvBase,
      rhrBase,
      respBase,
    );
    expect(score, isNotNull);
    expect(score!, inInclusiveRange(0, 100));

    // HR zones map sensibly.
    final mx = hrMax(30);
    expect(hrZoneFor(mx * 0.95, mx), 5);
    expect(hrZoneFor(mx * 0.40, mx), 0);
  });
}
