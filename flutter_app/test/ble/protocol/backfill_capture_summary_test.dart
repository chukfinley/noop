import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/backfill_capture.dart';

/// Faithful Dart port of `BackfillCaptureSummaryTest.kt`.
void main() {
  test('countsPacketTypesAndRetainsOnlyFirstUnknownSamples', () {
    final summary = BackfillCaptureSummary(maxUnknownSamples: 2);

    summary.record('METADATA', true, 36, 'fd4b0005', 'aa01');
    summary.record('type54', true, 28, 'fd4b0005', 'aa02');
    summary.record('type54', true, 28, 'fd4b0005', 'aa03');
    summary.record('type54', true, 28, 'fd4b0005', 'aa04');
    summary.record('COMMAND_RESPONSE', false, 20, 'fd4b0003', 'aa05');

    expect(summary.countsText(), 'COMMAND_RESPONSE=1, METADATA=1, type54=3');
    expect(
      summary.unknownSamplesText(),
      'type54(size=28,char=fd4b0005,crc=true,hex=aa02); '
      'type54(size=28,char=fd4b0005,crc=true,hex=aa03)',
    );
  });

  test('reportsNoneWhenNoUnknownSamplesWereCaptured', () {
    final summary = BackfillCaptureSummary(maxUnknownSamples: 2);

    summary.record('METADATA', true, 36, 'fd4b0005', 'aa01');
    summary.record('EVENT', true, 24, 'fd4b0005', 'aa02');

    expect(summary.countsText(), 'EVENT=1, METADATA=1');
    expect(summary.unknownSamplesText(), 'none');
  });
}
