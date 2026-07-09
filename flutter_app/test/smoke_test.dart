import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:noop/main.dart';
import 'package:noop/state/providers.dart';
import 'package:noop/data/repository.dart';
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
    expect(find.text('More', skipOffstage: false), findsWidgets);
    expect(tester.takeException(), isNull);
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
