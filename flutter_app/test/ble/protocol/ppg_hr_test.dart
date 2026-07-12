import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/ppg_hr.dart';

/// Faithful Dart port of `PpgHrTest.kt`.
///
/// [PpgHr] — derive HR from the WHOOP 5/MG v26 optical PPG waveform by autocorrelation (#156).
///
/// Internal ground truth (the Swift lane's method): a clean pulse-shaped signal autocorrelates
/// strongly at its period, so a synthetic 70 bpm sine at 24 Hz must recover ~70 bpm with high
/// confidence; white noise has no periodicity, so it must yield NO estimate (conf < 0.3).
void main() {
  const fs = PpgHr.sampleRateHz; // 24

  /// Build [seconds] of a [bpm] sine at the 24 Hz grid, one [PpgSample] per sample.
  List<PpgSample> sine(double bpm, int seconds, {int baseTs = 1000000}) {
    final freqHz = bpm / 60.0;
    final total = seconds * fs;
    return List<PpgSample>.generate(total, (i) {
      final t = i.toDouble() / fs;
      // Scale to ADC-count-ish integers; DC offset removed inside estimate().
      final v = (1000.0 * sin(2.0 * pi * freqHz * t)).toInt();
      return PpgSample(ts: baseTs + (i ~/ fs), value: v);
    });
  }

  test('recovers70BpmFromCleanSine', () {
    // 16 s so several 8 s windows slide across it.
    final est = PpgHr.estimate(sine(70.0, 16));
    expect(est.isNotEmpty, isTrue, reason: 'expected at least one estimate from a clean sine');
    // Every window of a pure periodic signal should land within 2 bpm of the truth.
    for (final e in est) {
      expect(e.bpm >= 68 && e.bpm <= 72, isTrue, reason: 'bpm ${e.bpm} not within 70±2');
      expect(e.conf >= PpgHr.minConfidence, isTrue, reason: 'confidence ${e.conf} below gate');
      expect(e.conf <= 1.0, isTrue, reason: 'confidence ${e.conf} > 1');
    }
  });

  test('noiseYieldsNoEstimate', () {
    final rng = Random(42);
    final noise = List<PpgSample>.generate(16 * fs, (i) {
      return PpgSample(ts: 1000000 + (i ~/ fs), value: rng.nextInt(2000) - 1000);
    });
    final est = PpgHr.estimate(noise);
    // White noise has no periodic structure → autocorrelation never clears the 0.3 gate.
    expect(est.isEmpty, isTrue, reason: 'noise produced estimates: $est');
  });

  test('tooFewSamplesYieldsEmpty', () {
    // A run shorter than 3 consecutive seconds cannot be estimated. 2 s → nothing.
    final short = sine(70.0, 2); // 48 samples, run of 2
    expect(PpgHr.estimate(short), <PpgEstimate>[]);
  });

  test('recoversFromShortThreeSecondRun', () {
    // Swift parity: a 3 s run DOES produce HR (each second's centred window holds >= 3 s).
    final est = PpgHr.estimate(sine(70.0, 3));
    expect(est.isNotEmpty, isTrue, reason: 'expected estimates from a 3 s run');
    for (final e in est) {
      expect(e.bpm >= 67 && e.bpm <= 73, isTrue, reason: 'bpm ${e.bpm} not within 70±3');
    }
  });

  test('prefersFundamentalNotHalfRate', () {
    // A clean 50 bpm sine autocorrelates strongly at the true period AND at 2× the period (25 bpm).
    // Fundamental-period preference must report ~50 (Swift parity, #219).
    final est = PpgHr.estimate(sine(50.0, 16));
    expect(est.isNotEmpty, isTrue, reason: 'expected estimates from a clean 50 bpm sine');
    for (final e in est) {
      expect(e.bpm >= 47 && e.bpm <= 53, isTrue, reason: 'bpm ${e.bpm} not near 50 (harmonic leak?)');
    }
  });

  test('flatSignalYieldsEmpty', () {
    final flat = List<PpgSample>.generate(16 * fs, (i) {
      return PpgSample(ts: 1000000 + (i ~/ fs), value: 500);
    });
    // Zero variance → zero energy → no estimate (never a divide-by-zero).
    expect(PpgHr.estimate(flat).isEmpty, isTrue);
  });

  test('lowHrWithRecordRateArtifactDoesNotSnapTo60', () {
    // A true ~50 bpm pulse PLUS a per-record sawtooth that resets every fs samples — the
    // record-rate artifact (#194). Without the boundary-gated notch a sleeping HR would snap to 60.
    final f = 50.0 / 60.0;
    final samples = <PpgSample>[];
    for (var s = 0; s < 10; s++) {
      for (var i = 0; i < fs; i++) {
        final pulse = 1000.0 * sin(2.0 * pi * f * (s * fs + i) / fs);
        final sawtooth = 25.0 * i; // 0..575 within a record, drops at the boundary
        samples.add(PpgSample(ts: 1000000 + s, value: (pulse + sawtooth).toInt()));
      }
    }
    final est = PpgHr.estimate(samples);
    expect(est.isNotEmpty, isTrue,
        reason: 'a real low-HR pulse under a record-rate artifact must still estimate');
    for (final e in est) {
      expect(e.bpm >= 46 && e.bpm <= 54, isTrue, reason: 'snapped to ${e.bpm} — artifact not removed');
    }
  });

  test('true60BpmIsPreservedNotNotchedAway', () {
    // A clean 60 bpm pulse is also period-fs but flows smoothly across record boundaries — the
    // boundary gate must NOT treat it as the artifact and erase it.
    final est = PpgHr.estimate(sine(60.0, 10));
    expect(est.isNotEmpty, isTrue, reason: 'true 60 bpm must not be notched away');
    for (final e in est) {
      expect(e.bpm >= 57 && e.bpm <= 63, isTrue, reason: 'bpm ${e.bpm} not near 60');
    }
  });
}
