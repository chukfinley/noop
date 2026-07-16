import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/protocol/historical_streams.dart';

/// Pins the v26 raw-PPG-waveform DECODE (#156 / upstream #415) against a **real captured frame**.
///
/// The persistence capability already ships: [extractHistoricalStreams] emits `ppgRaw`,
/// `StreamBatch.isEmpty` counts a waveform-only decode as non-empty, and `DriftStreamRepository` banks
/// it losslessly into `ppgRawSample` (schema v3). `test/ble/sync/raw_data_loss_test.dart` already pins
/// that storage path end-to-end — including the i16 codec over negative values — so this file
/// deliberately does NOT re-test the DB round-trip. (It once did; that added a second set of in-memory
/// drift databases to the run and bought nothing the synthetic codec test did not already prove.)
///
/// What it adds instead is the one thing no synthetic fixture can: the existing coverage builds its
/// v26 frame with the same repo's own frame builder, so the decoder and the builder agree even if
/// their shared assumption about the layout is wrong. This asserts the identical real WHOOP 5.0
/// fixture AND the identical expected waveform as the Kotlin `Whoop5PpgWaveformStreamTest` and Swift
/// `Whoop5PpgWaveformTests` — a clean PPG upstroke in all-negative AC-coupled ADC counts. Our Dart
/// decoder recovering those exact 24 values from those exact bytes is what makes the waveform
/// cross-platform ground truth rather than three platforms sharing one guess.
///
/// It deliberately does NOT derive SpO2. The raw optical channel is uncalibrated and reads ~65 %
/// (flutter_app/CLAUDE.md); persisting the samples is the honest ceiling, and a number derived from
/// this channel would be fabrication.
void main() {
  // Real captured WHOOP 5.0 v26 optical-PPG frame (type-47 layout v26), unix @15 == 1780917232,
  // 24 little-endian i16 samples at bytes [27:75].
  const v26Hex =
      'aa015000010035412f1a80ad418401f0a3266aae470100c3c5050068faccfa8dfb46fc8bfd4c'
      'febafedafe6dff56ffd5fffbff37ff6afce5f9d7f8dffa5efc98fddbfe5afe84fe15ff5cff40'
      '5fb33c50080101006cb67c17';

  const expectedWaveform = <int>[
    -1432, -1332, -1139, -954, -629, -436, -326, -294, //
    -147, -170, -43, -5, -201, -918, -1563, -1833, //
    -1313, -930, -616, -293, -422, -380, -235, -164,
  ];

  const unix = 1780917232;

  final frame = Uint8List.fromList(<int>[
    for (var i = 0; i + 2 <= v26Hex.length; i += 2)
      int.parse(v26Hex.substring(i, i + 2), radix: 16)
  ]);

  test("the real v26 frame decodes to upstream's exact waveform", () {
    final st = extractHistoricalStreams(
        <Uint8List>[frame], unix, unix, DeviceFamily.whoop5);
    expect(st.ppgRaw, hasLength(1));
    expect(st.ppgRaw.single.ts, unix);
    expect(st.ppgRaw.single.samples, expectedWaveform);
  });

  test('a lone real v26 second yields no HR estimate, yet still reads as non-empty', () {
    // One v26 record is one second — nowhere near the run [PpgHr] needs for a confident estimate. The
    // waveform must survive INDEPENDENTLY of that, or the record vanishes exactly as it did before
    // #415; and isEmpty must stay false, or the Backfiller's silent-data-loss diagnostic misfires and
    // archives a frame it already decoded.
    final st = extractHistoricalStreams(
        <Uint8List>[frame], unix, unix, DeviceFamily.whoop5);
    expect(st.ppgHr, isEmpty);
    expect(st.isEmpty, isFalse);
  });
}
