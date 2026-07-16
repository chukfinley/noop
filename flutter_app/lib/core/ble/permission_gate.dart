/// Transient-vs-wedged classification for the BLE runtime-permission gate.
///
/// The problem this fixes: every permission failure in the transport surfaced the SAME dead string —
/// `'Bluetooth permission denied.'` — for two states that need OPPOSITE advice:
///
///  • **transient** — the OS has not had a real answer yet (never asked, or the user declined once on
///    Android, which leaves the permission re-promptable). The fix is a RETRY: tap Connect, get the
///    dialog, allow. Sending this user to system Settings is guidance for a problem they do not have,
///    and they will not find anything to change there.
///  • **wedged** — the OS will never raise the dialog again (Android's second denial latches
///    `permanentlyDenied`; iOS never re-prompts after the first no). The fix is ONLY system Settings.
///    Telling this user to "tap Connect and allow" is a lie: the tap does nothing, forever. That is
///    the stuck-banner failure — the user taps, nothing happens, no explanation.
///
/// Upstream parity note: ryanbr/noop v9.0.0 has NO transient/wedged split to port. Its whole BLE
/// permission story is `BlePermissions.kt` (a Compose launcher that prompts before scanning) plus one
/// `SecurityException` catch in `WhoopBleClient.startScan`, which surfaces the Settings guidance
/// UNCONDITIONALLY — so upstream tells a never-asked user to go fix it in Settings, which is the very
/// wrong-half-of-the-fork this file exists to avoid. We are deliberately not copying that. The
/// principle we DO follow is upstream's own, from `HealthKitBridge.swift`: never fall through to a
/// "fix it in Settings" state when Settings cannot fix it. `permission_handler` hands us a signal
/// Kotlin's raw `checkSelfPermission` never had (`isPermanentlyDenied`), so the split is cheap here.
///
/// Pure by construction — no `permission_handler` import, no radio, no platform. It takes plain bools
/// and returns a verdict, so the whole policy is unit-testable off-device (the project rule forbids
/// launching the app to verify anything).
library;

/// What a BLE permission request actually means for the user.
enum BlePermissionOutcome {
  /// Scan + connect are both granted — proceed.
  granted,

  /// Not granted, but the state is still re-promptable (or we simply cannot tell). A retry from the
  /// foreground can fix it, so the guidance is "tap Connect and allow" — never "go to Settings".
  transient,

  /// Not granted and the OS will not ask again. Only system Settings can fix it, so that is the only
  /// honest guidance.
  wedged,
}

/// The pure transient-vs-wedged classifier. Stateless — a single function of the request's outcome.
abstract final class BlePermissionGate {
  /// Classify one completed BLE permission request.
  ///
  /// [granted] — scan AND connect both came back granted.
  /// [permanentlyDenied] — the platform reported a latched denial (`isPermanentlyDenied`, or iOS
  ///   `restricted`): the system dialog will not be raised again by any amount of retrying.
  /// [couldPrompt] — whether this request was in a position to raise the system dialog AT ALL, i.e.
  ///   it came from a user-initiated foreground path with a live Activity. LOAD-BEARING, and the
  ///   reason this is not just `permanentlyDenied` passed through:
  ///
  ///   Our automatic paths (the launch auto-connect kick, the Bluetooth-on listener, the foreground
  ///   service's nudge, and the headless WorkManager isolate) all call the same
  ///   `ensureBlePermissions()` with no Activity behind them. Android decides `permanentlyDenied`
  ///   from `shouldShowRequestPermissionRationale() == false`, which is ALSO false when no Activity
  ///   exists and when the user has simply never been asked — so a background probe can report a
  ///   latched denial that is nothing of the sort. Classifying off that would park a permanent "your
  ///   permission is blocked, go to Settings" banner on a user whose permission is fine and who was
  ///   never asked anything. A request that could not prompt is not evidence, so it stays
  ///   [BlePermissionOutcome.transient] and the next foreground tap decides.
  ///
  /// NOTE ON WHAT WE DELIBERATELY DID NOT PORT: the sibling #147 tracker requires a STREAK (two
  /// consecutive status-147s) before it warns, because one 147 is genuine edge-of-range noise. There
  /// is no equivalent noise here and no streak: a `permanentlyDenied` from an Activity-backed request
  /// is AUTHORITATIVE, not a guess — Android's own two-strikes rule already performed the
  /// transient/wedged split before handing us the status (first decline → `denied`, re-promptable;
  /// second → `permanentlyDenied`, latched). Adding a streak on top would only delay correct guidance
  /// by an extra pointless tap. The [couldPrompt] guard, not a counter, is what filters the one real
  /// false-positive source we have.
  ///
  /// Rejected alternative: `Permission.shouldShowRequestRationale`. It cannot break the tie — it is
  /// false BOTH for never-asked and for permanently-denied, which is the exact ambiguity we need
  /// resolved. It would add a plugin call and answer nothing.
  static BlePermissionOutcome classify({
    required bool granted,
    required bool permanentlyDenied,
    required bool couldPrompt,
  }) {
    if (granted) return BlePermissionOutcome.granted;
    // A request that could not raise a dialog proves nothing about the user's decision — whatever it
    // reported, it did not ask. Never wedge off a background probe.
    if (!couldPrompt) return BlePermissionOutcome.transient;
    return permanentlyDenied
        ? BlePermissionOutcome.wedged
        : BlePermissionOutcome.transient;
  }

  /// The honest, actionable guidance for a non-granted [outcome], or null when nothing needs saying
  /// ([BlePermissionOutcome.granted]). [apple] selects the iOS wording — the two platforms bury the
  /// switch in genuinely different places, and naming the wrong menu is its own dead end.
  ///
  /// Neither string mentions pairing. A permission gate fails before any scan runs, so no bond exists
  /// to be at fault; re-pair guidance here would cost the user a teardown that cannot fix a
  /// permission (the same honesty rule the #147 hint follows).
  static String? hintFor(BlePermissionOutcome outcome, {required bool apple}) =>
      switch (outcome) {
        BlePermissionOutcome.granted => null,
        BlePermissionOutcome.transient => transientHint,
        BlePermissionOutcome.wedged => apple ? wedgedHintApple : wedgedHintAndroid,
      };

  /// Guidance while the permission is still re-promptable: the retry IS the fix. Says nothing about
  /// Settings — the user would find nothing to change there, and looking is a dead end we sent them on.
  static const String transientHint =
      'NOOP needs Bluetooth permission to find your strap. Tap Connect and choose Allow.';

  /// Guidance once Android has latched the denial. The dialog is gone for good, so a retry is exactly
  /// what does NOT work and the only honest instruction is the Settings path. Named "Nearby devices"
  /// because that is what Android 12+ calls the Bluetooth permission in that screen — "Bluetooth" is
  /// a different toggle and sends the user hunting.
  static const String wedgedHintAndroid =
      'Bluetooth permission is blocked and Android will not ask again. Open Settings → '
      'Apps → NOOP → Permissions and allow Nearby devices, then tap Connect.';

  /// The iOS twin. iOS never re-prompts after the first refusal, so the first "no" is already the
  /// latched state. The trailing sentence covers `restricted` — a managed device or Screen Time can
  /// block Bluetooth outright, and then there is no switch to find; saying so beats letting the user
  /// conclude the app is broken.
  static const String wedgedHintApple =
      'Bluetooth permission is blocked and iOS will not ask again. Open Settings → NOOP '
      'and allow Bluetooth, then tap Connect. If there is no Bluetooth switch there, a '
      'device-management or Screen Time restriction is blocking it.';
}
