import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// One-time runtime-permission gate for the live WHOOP strap link (BLE).
///
/// This module only *requests* permissions — it wires no BLE logic. The manifest
/// (Android) and Info.plist (iOS) declare the full permission set; this asks the
/// user for the runtime grants those platforms gate behind a dialog.
///
/// Platform behaviour:
/// - **Android 12+ (API 31+):** needs `bluetoothScan` + `bluetoothConnect`.
/// - **Android <=11 (API 30-):** legacy BLE scanning also needs `location`.
/// - **iOS:** the single `bluetooth` grant covers scan + connect; it is surfaced
///   the first time BLE is actually used, so we request it here too.
/// - **Desktop / web (Linux, macOS, Windows):** there is no runtime permission
///   model to satisfy, so this no-ops and reports success — the app also runs on
///   Linux and must never crash there.

/// Whether the current platform has a BLE runtime-permission model at all.
///
/// `permission_handler` only implements Bluetooth permissions on Android and iOS;
/// on web and desktop the plugin throws, so we guard every call behind this.
bool get _blePlatform {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// The outcome of one BLE permission request, rich enough for `BlePermissionGate` to tell a
/// re-promptable state from a latched one. A bare bool cannot: it collapses "the user has not been
/// asked yet" and "the OS will never ask again" into the same value, which is exactly the conflation
/// that produced a single dead `'Bluetooth permission denied.'` string for both.
class BlePermissionRequestResult {
  const BlePermissionRequestResult({
    required this.granted,
    required this.permanentlyDenied,
  });

  /// Scan AND connect both came back granted — the transport is clear to proceed.
  final bool granted;

  /// The platform latched the denial: no amount of retrying will raise the dialog again, so only
  /// system Settings can change it. Folds in iOS `restricted` (a managed device / Screen Time
  /// blocking Bluetooth), which is equally un-retryable — the two differ only in the wording of the
  /// guidance, which `BlePermissionGate.hintFor` owns.
  final bool permanentlyDenied;

  /// Off-mobile there is no runtime-permission model to fail, so every caller is clear to proceed.
  static const BlePermissionRequestResult notApplicable =
      BlePermissionRequestResult(granted: true, permanentlyDenied: false);
}

/// Requests the permissions needed to scan for and connect to the strap over BLE, reporting BOTH
/// whether we ended up with what we need and whether a refusal is latched.
///
/// Safe to call on any platform: on desktop/web it reports granted without touching the plugin, so
/// callers can treat it as "clear to proceed" everywhere. `permission_handler` itself only shows the
/// system dialog the first time; subsequent calls resolve immediately from the stored decision —
/// which is precisely why a caller with no Activity behind it can get a latched-looking answer that
/// no dialog ever produced. Resolving that is `BlePermissionGate`'s job, not this function's: this
/// one only reports what the platform said.
Future<BlePermissionRequestResult> requestBlePermissions() async {
  // No runtime-permission model off-mobile — nothing to request, don't crash.
  if (!_blePlatform) return BlePermissionRequestResult.notApplicable;

  final requests = <Permission>[
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
  ];

  // Pre-Android-12 BLE scanning is gated behind location; iOS/newer Android
  // ignore this. Android SDK level isn't cheaply available here, so we include
  // it on Android and let the OS drop it where it doesn't apply (an unrequired
  // permission simply resolves as granted).
  if (Platform.isAndroid) {
    requests.add(Permission.location);
  }

  final statuses = await requests.request();

  // We only hard-require the two Bluetooth grants; location is a legacy-only
  // helper and may be permanently denied on modern Android without blocking BLE.
  final scan = statuses[Permission.bluetoothScan];
  final connect = statuses[Permission.bluetoothConnect];
  final granted = (scan?.isGranted ?? false) && (connect?.isGranted ?? false);

  // Latched if EITHER required grant is latched — one blocked permission is enough to keep BLE dead,
  // and the user has to visit the same Settings screen either way. Location is excluded on purpose:
  // it is a pre-Android-12 legacy helper that is routinely permanently-denied on modern phones
  // WITHOUT blocking BLE at all, so counting it would wedge the guidance for a healthy install.
  bool latched(PermissionStatus? s) =>
      s != null && (s.isPermanentlyDenied || s.isRestricted);
  final permanentlyDenied = !granted && (latched(scan) || latched(connect));

  return BlePermissionRequestResult(
      granted: granted, permanentlyDenied: permanentlyDenied);
}

/// Whether the app ended up with the BLE grants it needs. The bool-only face of
/// [requestBlePermissions], kept for callers that only branch on go/no-go and surface their own
/// message. Callers that show the user guidance should use [requestBlePermissions] + the
/// `BlePermissionGate` instead, so a re-promptable state is not mistaken for a latched one.
Future<bool> ensureBlePermissions() async =>
    (await requestBlePermissions()).granted;

/// Requests the notification permission (Android 13+ `POST_NOTIFICATIONS`) so the
/// background-sync foreground service can show its status notification. iOS asks
/// its own way; older Android grants implicitly. No-ops off mobile. Returns
/// whether notifications ended up allowed — never blocks the app either way.
Future<bool> ensureNotificationPermission() async {
  if (!_blePlatform) return true;
  final status = await Permission.notification.request();
  return status.isGranted;
}

/// Asks the user to exempt NOOP from Android battery optimisation, so the OS does
/// not doze/throttle/kill the app mid-offload (the usual cause of a background sync
/// that silently stalls). Android-only — iOS has no equivalent and this no-ops
/// there. Shows the system "allow unrestricted background" dialog once; a decline
/// never blocks the app, sync just runs less reliably in the background.
Future<bool> ensureBatteryOptimizationExemption() async {
  if (kIsWeb || !Platform.isAndroid) return true;
  final status = await Permission.ignoreBatteryOptimizations.request();
  return status.isGranted;
}
