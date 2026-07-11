import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/data/real_repository.dart';

/// End-to-end guard: loads the REAL bundled Whoop capture, runs the full ported
/// analytics pipeline, prints a human-readable analysis report, and asserts the
/// result stays sane. This is the gate — if the algorithm changes, run
/// `flutter test` and read the report BEFORE ever building the app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  test('real capture analyses correctly through the ported pipeline', () async {
    final repo = await RealRepository.load();
    final days = repo.days;

    // ── Report ────────────────────────────────────────────────────────────────
    final withSleep = days.where((d) => d.sleep != null).toList();
    final charges = days.map((d) => d.charge).toList()..sort();
    final efforts = days.map((d) => d.effort).toList()..sort();
    double median(List<double> xs) => xs.isEmpty ? 0 : xs[xs.length ~/ 2];
    double mean(Iterable<double> xs) => xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

    // Compare resting HR + HRV to Whoop's own reduction (bundled fixture).
    final gtFile = File('test/fixtures/whoop_ground_truth.json');
    double rhrMae = -1, hrvMae = -1;
    int matched = 0;
    if (gtFile.existsSync()) {
      final gt = json.decode(gtFile.readAsStringSync()) as Map<String, dynamic>;
      final byDate = {for (final d in days) iso(d.date): d};
      final rhrErr = <double>[], hrvErr = <double>[];
      for (final e in gt.entries) {
        final d = byDate[e.key];
        if (d == null) continue;
        final g = e.value as Map<String, dynamic>;
        final gr = double.tryParse('${g['rhr']}');
        final gh = double.tryParse('${g['hrv']}');
        if (gr != null && d.rhr > 0) {
          rhrErr.add((d.rhr - gr).abs());
          matched++;
        }
        if (gh != null && d.hrv > 0) hrvErr.add((d.hrv - gh).abs());
      }
      if (rhrErr.isNotEmpty) rhrMae = mean(rhrErr);
      if (hrvErr.isNotEmpty) hrvMae = mean(hrvErr);
    }

    final report = StringBuffer()
      ..writeln('\n══════════ NOOP real-capture analysis ══════════')
      ..writeln('Days analysed   : ${days.length}  (${iso(days.first.date)} → ${iso(days.last.date)})')
      ..writeln('Nights staged   : ${withSleep.length} / ${days.length} '
          '(${(withSleep.length / days.length * 100).round()}%)')
      ..writeln('Charge (recovery): min ${charges.first.toStringAsFixed(0)}  '
          'median ${median(charges).toStringAsFixed(0)}  max ${charges.last.toStringAsFixed(0)}')
      ..writeln('Effort (strain) : min ${efforts.first.toStringAsFixed(0)}  '
          'median ${median(efforts).toStringAsFixed(0)}  max ${efforts.last.toStringAsFixed(0)}')
      ..writeln('Resting HR      : mean ${mean(days.where((d) => d.rhr > 0).map((d) => d.rhr)).toStringAsFixed(1)} bpm')
      ..writeln('HRV (RMSSD)     : mean ${mean(days.where((d) => d.hrv > 0).map((d) => d.hrv)).toStringAsFixed(1)} ms')
      ..writeln('Avg sleep       : ${(mean(withSleep.map((d) => d.sleep!.asleep.inMinutes.toDouble())) / 60).toStringAsFixed(1)} h '
          '@ ${(mean(withSleep.map((d) => d.sleep!.efficiency)) * 100).round()}% efficiency')
      ..writeln('vs Whoop truth  : resting-HR MAE ${rhrMae < 0 ? "n/a" : "${rhrMae.toStringAsFixed(1)} bpm"}'
          '   HRV MAE ${hrvMae < 0 ? "n/a" : "${hrvMae.toStringAsFixed(1)} ms"}  (over $matched days)')
      ..writeln('═══════════════════════════════════════════════');
    stdout.write(report.toString());

    // ── Assertions (loose enough for algorithm tuning, tight enough to catch
    //    real breakage) ────────────────────────────────────────────────────────
    expect(days.length, greaterThanOrEqualTo(80), reason: 'should analyse ~88 capture days');
    expect(iso(days.first.date), '2026-01-28');

    // A clear majority of days must yield a real sleep window.
    expect(withSleep.length, greaterThanOrEqualTo(days.length * 2 ~/ 3),
        reason: 'most nights should be staged');

    // Every scored value is finite and in range — no NaN / no fabricated field.
    for (final d in days) {
      expect(d.charge, inInclusiveRange(0, 100));
      expect(d.effort, inInclusiveRange(0, 100));
      expect(d.rest, inInclusiveRange(0, 100));
      expect(d.stress, inInclusiveRange(0, 100));
      expect(d.hrv, greaterThanOrEqualTo(0));
      expect(d.rhr, greaterThanOrEqualTo(0));
      expect(d.charge.isNaN, isFalse);
      if (d.sleep != null) {
        final s = d.sleep!;
        expect(s.asleep.inMinutes, greaterThan(0));
        expect(s.efficiency, inInclusiveRange(0, 1));
        // stages sum to asleep (± rounding).
        final sum = s.deep.inMinutes + s.rem.inMinutes + s.light.inMinutes;
        expect((sum - s.asleep.inMinutes).abs(), lessThanOrEqualTo(2));
        // A staged night must have a real hypnogram AND a dense timeline line
        // (the Sleep screen's up/down trace) — guards the sleep-timeline render.
        expect(s.hypnogram, isNotEmpty);
        expect(s.restlessness.length, greaterThanOrEqualTo(20));
      }
    }

    // Physiological plausibility of the population.
    final scoredRhr = days.where((d) => d.rhr > 0).map((d) => d.rhr);
    expect(mean(scoredRhr), inInclusiveRange(38, 65), reason: 'sleeping resting HR band');
    expect(median(charges), inInclusiveRange(35, 90), reason: 'median recovery healthy-ish');

    // The ported resting-HR must track Whoop's own within a few bpm.
    if (rhrMae >= 0) {
      expect(rhrMae, lessThanOrEqualTo(8.0), reason: 'resting HR should track Whoop truth');
    }
  });
}
