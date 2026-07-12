import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/ppg_hr.dart';

/// Faithful Dart port of `Whoop4HistoricalV25PpgTest.kt`.
///
/// WHOOP 4.0 **v25** PPG → HR feasibility guard (issue #194, RFC — NOT a live decode). Pins, against the
/// three REAL v25 frames, that (1) at ryanbr's start offset (15) the bare autocorrelation's bpm tracks
/// the record period `1440/N` exactly — the concatenation artifact, (2) the #194-proposed span (start 25)
/// yields NO HR through the shipped [PpgHr] lane, but (3) the SAME lane reading from offset 15 still
/// emits a fabricated 60 bpm — so the start byte is load-bearing and v25→HR must not ship unpinned.
void main() {
  Uint8List bytes(String s) {
    final out = Uint8List(s.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  final records = <Uint8List>[
    bytes(
        'aa50000c2f1900006800007dff2a6a20430900433103007e026502ba026c022eff70f996f879fad6fd8300d6017e0267027201be00290258030e05c507f00c030ead11cb15791500d2553c9003000000d6393716'),
    bytes(
        'aa50000c2f1900016800007eff2a6a283e0900a0ad03007a0e880698018bfff5fb61eee9f2a7fa2bfe1af5fdf618fdf0f9c2fb0804510a14046a004dffd0ff6dfdddfd670183014e071a3f9003000000587bbabf'),
    bytes(
        'aa50000c2f1900026800007fff2a6a38390900729103003608a2fd0104850d4f1bd21aa60f080d850edb116b0f160b7d063f06ab04d5041704a4045f04f003f5ffd7ff7efe73ffa8b2333e9003010000fa54e5e9'),
  ];

  int? i16(Uint8List f, int off) {
    if (off + 2 > f.length) return null;
    final u = (f[off] & 0xFF) | ((f[off + 1] & 0xFF) << 8);
    return u >= 0x8000 ? u - 0x10000 : u;
  }

  int u32(Uint8List f, int off) =>
      (f[off] & 0xFF) |
      ((f[off + 1] & 0xFF) << 8) |
      ((f[off + 2] & 0xFF) << 16) |
      ((f[off + 3] & 0xFF) << 24);

  /// 24 odd-grid i16 PPG samples from `start`.
  List<int> ppg(Uint8List f, int start) =>
      List<int?>.generate(24, (it) => i16(f, start + it * 2)).whereType<int>().toList();

  /// Build the concatenated PpgHr input: every sample of a record shares the record's ts.
  List<PpgSample> samples(int start) => records
      .expand((f) => ppg(f, start).map((v) => PpgSample(ts: u32(f, 11), value: v)))
      .toList();

  /// Bare windowed autocorrelation (ryanbr's pre-notch method), exact band of the #194 repro.
  int bareBpm(List<int> sig, {int fs = 24}) {
    final mean = sig.fold<int>(0, (a, b) => a + b) / sig.length;
    final x = sig.map((it) => it - mean).toList();
    if (x.fold<double>(0.0, (a, b) => a + b * b) == 0.0) return 0;
    final lo = 60 * fs ~/ 220 > 1 ? 60 * fs ~/ 220 : 1;
    final hi = sig.length - 1 < 60 * fs ~/ 30 ? sig.length - 1 : 60 * fs ~/ 30;
    var best = lo;
    var bestV = double.negativeInfinity;
    for (var lag = lo; lag <= hi; lag++) {
      var s = 0.0;
      for (var k = 0; k < x.length - lag; k++) {
        s += x[k] * x[k + lag];
      }
      if (s > bestV) {
        bestV = s;
        best = lag;
      }
    }
    return (fs * 60.0 / best).round();
  }

  test('fixtureIsV25Consecutive', () {
    final ts = records.map((r) => u32(r, 11)).toList();
    expect(ts, <int>[ts[0], ts[0] + 1, ts[0] + 2]);
    for (final f in records) {
      expect(f[5] & 0xFF, 25);
      expect(ppg(f, 25).length, 24);
    }
  });

  test('concatenationArtifactTracksRecordPeriodNotHr', () {
    const start = 15;
    for (final n in <int>[16, 18, 20, 24, 30]) {
      final sig = records
          .expand((f) =>
              List<int?>.generate(n, (it) => i16(f, start + it * 2)).whereType<int>())
          .toList();
      expect(bareBpm(sig), 1440 ~/ n,
          reason: 'N=$n: bare bpm should equal record period 1440/N');
    }
  });

  test('proposedSpanEmitsNoHrThroughShippedLane', () {
    expect(PpgHr.estimate(samples(25)).isEmpty, isTrue);
  });

  test('notchDoesNotFullyProtectV25SoStartByteIsLoadBearing', () {
    final hr = PpgHr.estimate(samples(15));
    expect(hr.isEmpty, isFalse,
        reason: 'offset-15 read should surface the artifact the notch misses');
    expect(hr.every((e) => e.bpm == 60), isTrue,
        reason: 'surviving artifact is the record-period 60 bpm');
    expect(hr.every((e) => e.conf < 0.5), isTrue,
        reason: 'artifact confidence is low-but-passing, the worst false positive');
  });
}
