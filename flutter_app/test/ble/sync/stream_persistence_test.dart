import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/streams.dart';
import 'package:noop/core/ble/sync/stream_persistence.dart';

/// Port of `StreamPersistenceSpo2SkinTempTest.kt`. Pins that [StreamPersistence.toBatch] widens the
/// live protocol [Streams]' spo2/skinTemp lists 1:1 onto the [StreamBatch] insert shape (so a live
/// biometric source like the Oura ring lands SpO2/skinTemp), while a WHOOP batch (no spo2/skinTemp)
/// still produces empty lists.
void main() {
  test('spo2 and skin-temp widen onto StreamBatch', () {
    final streams = Streams(
      spo2: [const Spo2Sample(100, 97, 0)],
      skinTemp: [const SkinTempSample(101, 3327)],
    );
    final batch = StreamPersistence.toBatch(streams);
    expect(batch.spo2, hasLength(1));
    expect(batch.spo2.first.ts, 100);
    expect(batch.spo2.first.red, 97);
    expect(batch.spo2.first.ir, 0);
    expect(batch.skinTemp, hasLength(1));
    expect(batch.skinTemp.first.ts, 101);
    expect(batch.skinTemp.first.raw, 3327);
  });

  test('whoop batch has no spo2 or skin-temp', () {
    final streams = Streams(hr: [const HrSample(5, 70)]);
    final batch = StreamPersistence.toBatch(streams);
    expect(batch.hr, hasLength(1));
    expect(batch.spo2, isEmpty);
    expect(batch.skinTemp, isEmpty);
  });

  // encodePayload — deterministic sorted-keys JSON (port of WhoopStore.encodePayload). Not in the
  // Kotlin Spo2/SkinTemp test, but pins the canonical encoder the offload event path depends on.
  test('encodePayload sorts keys ascending and quotes by type', () {
    expect(StreamPersistence.encodePayload({}), '{}');
    expect(
      StreamPersistence.encodePayload({'b': 2, 'a': 1}),
      '{"a":1,"b":2}',
    );
    expect(
      StreamPersistence.encodePayload({
        'flag': true,
        'name': 'wrist off',
        'list': [1, 2, 3],
        'z': null,
      }),
      '{"flag":true,"list":[1,2,3],"name":"wrist off","z":null}',
    );
  });
}
