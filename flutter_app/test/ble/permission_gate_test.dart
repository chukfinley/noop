import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/permission_gate.dart';

/// Pins the pure transient-vs-wedged BLE permission policy: which state gets which verdict, and
/// which guidance is honest for it.
///
/// The invariant behind every case here: **the guidance must be a thing that actually works.**
/// "Tap Connect and allow" is a lie once Android has latched the denial (the tap raises nothing,
/// forever — the stuck-banner bug). "Open Settings and allow" is a lie before the user has ever been
/// asked (there is nothing there to change, and we sent them looking). One dead
/// `'Bluetooth permission denied.'` string served both, which is how it managed to be wrong in both.
void main() {
  group('granted', () {
    test('a granted request is granted regardless of the other signals', () {
      // permanentlyDenied can only be stale noise once we hold the grant — granted wins outright.
      expect(
        BlePermissionGate.classify(
            granted: true, permanentlyDenied: false, couldPrompt: true),
        BlePermissionOutcome.granted,
      );
      expect(
        BlePermissionGate.classify(
            granted: true, permanentlyDenied: true, couldPrompt: false),
        BlePermissionOutcome.granted,
      );
    });

    test('granted says nothing to the user', () {
      expect(BlePermissionGate.hintFor(BlePermissionOutcome.granted, apple: false), isNull);
      expect(BlePermissionGate.hintFor(BlePermissionOutcome.granted, apple: true), isNull);
    });
  });

  group('transient — the OS will ask again, so the retry IS the fix', () {
    test('a plain denial from a request that could prompt is transient, not wedged', () {
      // Android's first decline leaves the permission re-promptable: the next tap really does raise
      // the dialog. Sending this user to Settings would be guidance for a problem they do not have.
      expect(
        BlePermissionGate.classify(
            granted: false, permanentlyDenied: false, couldPrompt: true),
        BlePermissionOutcome.transient,
      );
    });

    test('the transient hint never mentions Settings — there is nothing to change there', () {
      final hint = BlePermissionGate.transientHint.toLowerCase();
      expect(hint, isNot(contains('settings')));
      // It has to name the action that does work.
      expect(hint, contains('allow'));
    });
  });

  group('couldPrompt — a request that raised no dialog is not evidence', () {
    test('a latched-looking denial from a background probe stays TRANSIENT', () {
      // The load-bearing case. Our automatic paths (launch kick, Bluetooth-on listener, foreground
      // service nudge, headless WorkManager isolate) request permissions with no Activity behind
      // them. Android derives permanentlyDenied from shouldShowRequestPermissionRationale()==false,
      // which is ALSO false with no Activity and false when the user has simply never been asked —
      // so this exact input can arrive on a perfectly healthy install. Wedging off it would park a
      // permanent, false "your permission is blocked" banner on a user who was never asked anything.
      expect(
        BlePermissionGate.classify(
            granted: false, permanentlyDenied: true, couldPrompt: false),
        BlePermissionOutcome.transient,
        reason: 'a request that could not prompt proves nothing about the user’s decision',
      );
    });

    test('the SAME inputs from a foreground request DO wedge — couldPrompt is the only difference', () {
      // Pins that couldPrompt is genuinely the discriminator and not decoration: identical
      // granted/permanentlyDenied, opposite verdicts.
      expect(
        BlePermissionGate.classify(
            granted: false, permanentlyDenied: true, couldPrompt: true),
        BlePermissionOutcome.wedged,
      );
    });

    test('a background probe that is merely denied is transient too', () {
      expect(
        BlePermissionGate.classify(
            granted: false, permanentlyDenied: false, couldPrompt: false),
        BlePermissionOutcome.transient,
      );
    });
  });

  group('wedged — only Settings can fix it, so say only that', () {
    test('the Android hint sends the user to Settings and names the right permission', () {
      final hint = BlePermissionGate.wedgedHintAndroid.toLowerCase();
      expect(hint, contains('settings'));
      // Android 12+ calls the Bluetooth permission "Nearby devices" on that screen; "Bluetooth" is a
      // different toggle entirely and sends the user hunting for something that isn't there.
      expect(hint, contains('nearby devices'));
    });

    test('the wedged hint must NOT tell the user to retry — the retry is what does not work', () {
      // The stuck-banner bug in one assertion: a latched permission raises no dialog ever again, so
      // "tap Connect and allow" is advice that cannot succeed.
      expect(BlePermissionGate.wedgedHintAndroid, isNot(contains(BlePermissionGate.transientHint)));
      expect(BlePermissionGate.wedgedHintAndroid.toLowerCase(), contains('will not ask again'));
      expect(BlePermissionGate.wedgedHintApple.toLowerCase(), contains('will not ask again'));
    });

    test('neither wedged hint suggests re-pairing — no bond exists to be at fault', () {
      // The permission gate fails BEFORE any scan runs, so nothing was ever paired. Re-pair guidance
      // would cost the user a teardown that cannot fix a permission (the #147 honesty rule).
      for (final hint in [
        BlePermissionGate.wedgedHintAndroid,
        BlePermissionGate.wedgedHintApple,
        BlePermissionGate.transientHint,
      ]) {
        expect(hint.toLowerCase(), isNot(contains('pair')));
        expect(hint.toLowerCase(), isNot(contains('forget')));
        expect(hint.toLowerCase(), isNot(contains('unpair')));
      }
    });

    test('the iOS hint names the iOS path, and covers a restriction it cannot unblock', () {
      final hint = BlePermissionGate.wedgedHintApple.toLowerCase();
      expect(hint, contains('settings'));
      // permissions.dart folds iOS `restricted` (managed device / Screen Time) into the same latched
      // signal. There the Bluetooth switch may not exist at all, so the hint must not leave the user
      // concluding the app is broken when they cannot find it.
      expect(hint, contains('screen time'));
      expect(hint, isNot(contains('nearby devices')),
          reason: 'that is Android’s name for it — naming it on iOS sends the user hunting');
    });

    test('hintFor routes each platform to its own wedged string', () {
      expect(BlePermissionGate.hintFor(BlePermissionOutcome.wedged, apple: false),
          BlePermissionGate.wedgedHintAndroid);
      expect(BlePermissionGate.hintFor(BlePermissionOutcome.wedged, apple: true),
          BlePermissionGate.wedgedHintApple);
      // The transient advice is a retry, which is identical on both platforms.
      expect(BlePermissionGate.hintFor(BlePermissionOutcome.transient, apple: false),
          BlePermissionGate.transientHint);
      expect(BlePermissionGate.hintFor(BlePermissionOutcome.transient, apple: true),
          BlePermissionGate.transientHint);
    });
  });

  group('no streak — a latched denial is authoritative, unlike a #147', () {
    test('ONE foreground permanentlyDenied wedges immediately', () {
      // Deliberately unlike the #147 tracker, which needs two consecutive timeouts because one is
      // genuine edge-of-range noise. There is no analogous noise here: Android already performed the
      // transient/wedged split before handing us the status (first decline → denied and
      // re-promptable; second → permanentlyDenied and latched). Requiring our own second strike
      // would only withhold correct guidance for one more pointless tap.
      expect(
        BlePermissionGate.classify(
            granted: false, permanentlyDenied: true, couldPrompt: true),
        BlePermissionOutcome.wedged,
      );
    });

    test('the classifier is stateless — history cannot change a verdict', () {
      // A pure function of its inputs, so no ordering can wedge a healthy install or unwedge a
      // blocked one. Same inputs, same answer, whatever came before.
      for (var i = 0; i < 5; i++) {
        BlePermissionGate.classify(
            granted: false, permanentlyDenied: true, couldPrompt: false);
      }
      expect(
        BlePermissionGate.classify(
            granted: false, permanentlyDenied: false, couldPrompt: true),
        BlePermissionOutcome.transient,
      );
    });
  });
}
