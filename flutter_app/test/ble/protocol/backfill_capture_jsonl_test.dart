import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/backfill_capture.dart';

/// Faithful Dart port of `BackfillCaptureJsonlTest.kt`.
void main() {
  test('encodesCaptureRecordAsStableJsonLine', () {
    final line = BackfillCaptureJsonl.encode(
      BackfillCaptureRecord(
        capturedAtMs: 1234,
        sessionId: 'whoop5-1234',
        characteristic: 'fd4b0005',
        typeName: 'METADATA',
        crcOk: true,
        offload: true,
        size: 36,
        parsed: <String, Object?>{
          'meta_type': 'HISTORY_END(2)',
          'trim_cursor': 4512,
          'rr_intervals': <int>[801, 802],
        },
        hex: 'aa01',
      ),
    );

    expect(
      line,
      '{'
      '"captured_at_ms":1234,'
      '"session_id":"whoop5-1234",'
      '"characteristic":"fd4b0005",'
      '"type_name":"METADATA",'
      '"crc_ok":true,'
      '"offload":true,'
      '"size":36,'
      '"parsed":{"meta_type":"HISTORY_END(2)","rr_intervals":[801,802],"trim_cursor":4512},'
      '"hex":"aa01"'
      '}',
    );
  });

  test('escapesStringsAndNullCrc', () {
    final line = BackfillCaptureJsonl.encode(
      BackfillCaptureRecord(
        capturedAtMs: 1,
        sessionId: 's"1',
        characteristic: 'fd4b0003',
        typeName: 'type54',
        crcOk: null,
        offload: false,
        size: 2,
        parsed: <String, Object?>{'note': 'line\nbreak'},
        hex: 'aa\\bb',
      ),
    );

    expect(
      line,
      '{'
      '"captured_at_ms":1,'
      '"session_id":"s\\"1",'
      '"characteristic":"fd4b0003",'
      '"type_name":"type54",'
      '"crc_ok":null,'
      '"offload":false,'
      '"size":2,'
      '"parsed":{"note":"line\\nbreak"},'
      '"hex":"aa\\\\bb"'
      '}',
    );
  });
}
