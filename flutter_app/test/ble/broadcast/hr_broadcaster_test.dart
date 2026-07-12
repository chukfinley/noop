import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/broadcast/hr_broadcaster.dart';

/// A minimal off-radio [Central] stand-in — the peripheral is inert in tests, so we only
/// need a peer identity ([Central.uuid]) to exercise the pure subscriber-set logic.
class _FakeCentral implements Central {
  _FakeCentral(String id) : uuid = UUID.fromString(id);
  @override
  final UUID uuid;
}

void main() {
  // MEDIUM-1: an abrupt central disconnect must prune the subscriber so the set can't
  // grow unbounded and stale centrals are no longer "notified". The disconnect handler
  // routes through `pruneSubscriber`; here we pin that pure operation.
  group('subscriber prune (MEDIUM-1)', () {
    test('disconnect prunes the matching central and keeps the count honest', () {
      final a = _FakeCentral('00000000-0000-0000-0000-0000000000a1');
      final b = _FakeCentral('00000000-0000-0000-0000-0000000000b2');
      final subs = <Central>[];

      expect(HrBroadcaster.addSubscriber(subs, a), isTrue);
      expect(HrBroadcaster.addSubscriber(subs, b), isTrue);
      expect(subs.length, 2);

      // The gym machine drops without writing CCCD=0 — a fresh Central instance for the
      // same peer arrives on the connection-state stream; matched by uuid it still prunes.
      final aAgain = _FakeCentral('00000000-0000-0000-0000-0000000000a1');
      expect(HrBroadcaster.pruneSubscriber(subs, aAgain), isTrue);
      expect(subs.length, 1);
      expect(subs.single.uuid, b.uuid);
    });

    test('pruning an unknown central is a no-op (no false count change)', () {
      final a = _FakeCentral('00000000-0000-0000-0000-0000000000a1');
      final ghost = _FakeCentral('00000000-0000-0000-0000-0000000000ff');
      final subs = <Central>[a];

      expect(HrBroadcaster.pruneSubscriber(subs, ghost), isFalse);
      expect(subs.length, 1);
    });

    test('add is idempotent by uuid — a re-subscribe never double-counts', () {
      final a = _FakeCentral('00000000-0000-0000-0000-0000000000a1');
      final aAgain = _FakeCentral('00000000-0000-0000-0000-0000000000a1');
      final subs = <Central>[];

      expect(HrBroadcaster.addSubscriber(subs, a), isTrue);
      expect(HrBroadcaster.addSubscriber(subs, aAgain), isFalse);
      expect(subs.length, 1);
    });
  });

  // The 0x2A37 encoder is unchanged, but keep a guard that it stays SIG-correct.
  group('measurement encoding', () {
    test('u8 HR for bpm < 256 (flags bit0 = 0)', () {
      expect(HrBroadcaster.measurement(72), equals([0x00, 72]));
    });

    test('u16 LE for an out-of-range bpm >= 256 (flags bit0 = 1)', () {
      expect(HrBroadcaster.measurement(300), equals([0x01, 0x2C, 0x01]));
    });
  });

  // Off-device (linux test host) the peripheral role is unsupported, so the broadcaster
  // must be a pure inert no-op: no radio touched, no throw. Guards the test-safety
  // contract the widget/smoke tests rely on.
  group('inert off supported platforms', () {
    test('start/update/stop/dispose never throw and touch no radio', () async {
      final b = HrBroadcaster();
      await b.start();
      b.update(88);
      b.update(null);
      await b.stop();
      await b.dispose();
    });
  });
}
