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

/// Requests (once) the permissions needed to scan for and connect to the strap
/// over BLE, and returns whether the app ended up with what it needs.
///
/// Safe to call on any platform: on desktop/web it returns `true` without
/// touching the plugin, so callers can treat a `true` result as "clear to
/// proceed" everywhere. `permission_handler` itself only shows the system dialog
/// the first time; subsequent calls resolve immediately from the stored decision.
Future<bool> ensureBlePermissions() async {
  // No runtime-permission model off-mobile — nothing to request, don't crash.
  if (!_blePlatform) return true;

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
  final scanOk = statuses[Permission.bluetoothScan]?.isGranted ?? false;
  final connectOk = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
  return scanOk && connectOk;
}
