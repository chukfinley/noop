import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/transport/whoop_ble_client.dart';

/// Pins the auto-connect adoption policy: **an automatic connect may only ever reconnect a strap the
/// user already chose.**
///
/// The failure mode (reported against the tanarchytan/noop fork): first pairing was "run a scan and
/// take whatever answers first". A scan hit is not a choice — a partner's, a flatmate's or a
/// stranger's WHOOP advertises the same service UUID, and which one wins the race is decided by
/// radio conditions. It is not self-correcting either: a successful connect emits on
/// `connectedStrap`, which the provider layer persists to Prefs as THE paired strap, so one unlucky
/// scan silently re-points every later auto-reconnect, background offload and synced metric at the
/// wrong band — with no moment where the user was asked anything.
void main() {
  final remembered = PairedStrap(
      id: 'AA:BB:CC:DD:EE:FF', family: DeviceFamily.whoop4, name: 'My WHOOP');

  group('nothing chosen — refuse, do not guess', () {
    test('no remembered strap and no opt-in REFUSES rather than adopting an advertiser', () {
      expect(
        WhoopBleClient.resolveAutoConnect(null, allowAdoptUnknown: false),
        AutoConnectDecision.refuseNoStrapChosen,
      );
    });

    test('refusing is the DEFAULT — the safe verdict cannot need an argument to reach', () {
      // If adopting were the default, every automatic caller would have to remember to opt out, and
      // the one that forgot would be a silent headless auto-pairing loop. Only the dangerous branch
      // takes a flag.
      expect(
        WhoopBleClient.resolveAutoConnect(null, allowAdoptUnknown: false),
        isNot(AutoConnectDecision.adoptUnknownByScan),
      );
    });

    test('the refusal hint points at picking, and promises no background retry', () {
      final hint = WhoopBleClient.noStrapChosenHint.toLowerCase();
      // Choosing is the ONLY thing that resolves this state, so that is the only instruction.
      expect(hint, contains('scan for straps'));
      // It must not read as "hang on, we're trying" — nothing is retrying and nothing will, so a
      // waiting user would wait forever.
      expect(hint, isNot(contains('retry')));
      expect(hint, isNot(contains('searching')));
      // And it must say the quiet part out loud: the refusal is deliberate, not a failure.
      expect(hint, contains('will not connect'));
    });
  });

  group('a chosen strap always wins', () {
    test('a remembered strap reconnects directly', () {
      expect(
        WhoopBleClient.resolveAutoConnect(remembered, allowAdoptUnknown: false),
        AutoConnectDecision.reconnectRemembered,
      );
    });

    test('allowAdoptUnknown must NOT override a strap the user already chose', () {
      // Ordering invariant: the opt-in is a fallback for "nothing chosen", never a licence to go
      // scanning past a real choice. If this ever inverted, opting in anywhere would let a
      // stronger-signal stranger's band outrank the user's own.
      expect(
        WhoopBleClient.resolveAutoConnect(remembered, allowAdoptUnknown: true),
        AutoConnectDecision.reconnectRemembered,
      );
    });
  });

  group('the opt-in still exists, and is the only way to adopt', () {
    test('an explicit opt-in with nothing remembered may scan and adopt', () {
      expect(
        WhoopBleClient.resolveAutoConnect(null, allowAdoptUnknown: true),
        AutoConnectDecision.adoptUnknownByScan,
      );
    });
  });

  group('resolveConnectFamily is unchanged by this policy', () {
    test('the remembered family still seeds a filtered scan', () {
      // The two rules are independent: family resolution narrows a scan, adoption decides whether a
      // scan may claim what it finds. Pinned so a change to one is not read as covering the other.
      expect(WhoopBleClient.resolveConnectFamily(remembered), DeviceFamily.whoop4);
      expect(WhoopBleClient.resolveConnectFamily(null), isNull);
    });
  });
}
