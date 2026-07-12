import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/transport/whoop_ble_client.dart' show PairedStrap;
import 'package:noop/core/state/prefs.dart';
import 'package:noop/features/settings/presentation/device_settings_screen.dart';

/// Covers the persistence + resolution added for the three Device-screen bug fixes —
/// no radio, no device (project rule: never launch). Mirrors paired_strap_test /
/// sync_state_test's in-memory secure-storage mock.
///   • Prefs round-trip for the device-name override,
///   • Prefs round-trip for the last-known battery fields + the [LastKnownBattery] getter,
///   • the device-name resolution order (override ?? strap name ?? family ?? "WHOOP").
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // In-memory stand-in for flutter_secure_storage so Prefs round-trips without a keyring.
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final store = <String, String>{};

  setUp(() {
    store.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      switch (call.method) {
        case 'write':
          store[args['key'] as String] = args['value'] as String;
          return null;
        case 'read':
          return store[args['key'] as String];
        case 'readAll':
          return Map<String, String>.from(store);
        case 'delete':
          store.remove(args['key'] as String);
          return null;
        case 'deleteAll':
          store.clear();
          return null;
        case 'containsKey':
          return store.containsKey(args['key'] as String);
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('Prefs deviceNameOverride', () {
    test('round-trips through storage', () async {
      final prefs = Prefs.instance;
      await prefs.setDeviceNameOverride('My Strap');
      expect(prefs.deviceNameOverride, 'My Strap');

      prefs.deviceNameOverride = null;
      await prefs.load();
      expect(prefs.deviceNameOverride, 'My Strap');
    });

    test('null/empty/whitespace clears back to null (not "")', () async {
      final prefs = Prefs.instance;
      await prefs.setDeviceNameOverride('X');
      await prefs.setDeviceNameOverride('   ');
      expect(prefs.deviceNameOverride, isNull);
      await prefs.load();
      expect(prefs.deviceNameOverride, isNull);
    });

    test('trims surrounding whitespace', () async {
      final prefs = Prefs.instance;
      await prefs.setDeviceNameOverride('  Left Wrist  ');
      expect(prefs.deviceNameOverride, 'Left Wrist');
      await prefs.load();
      expect(prefs.deviceNameOverride, 'Left Wrist');
    });

    test('unset over an empty store loads as null', () async {
      final prefs = Prefs.instance;
      prefs.deviceNameOverride = 'stale';
      await prefs.load();
      expect(prefs.deviceNameOverride, isNull);
    });
  });

  group('Prefs lastKnownBattery', () {
    test('recordBatteryReading round-trips pct + at + charging', () async {
      final prefs = Prefs.instance;
      await prefs.recordBatteryReading(
        pct: 0.87,
        atMs: 1750000000000,
        charging: true,
      );
      expect(prefs.lastKnownBatteryPct, 0.87);
      expect(prefs.lastKnownBatteryAtMs, 1750000000000);
      expect(prefs.lastKnownCharging, isTrue);

      prefs.lastKnownBatteryPct = null;
      prefs.lastKnownBatteryAtMs = null;
      prefs.lastKnownCharging = null;
      await prefs.load();
      expect(prefs.lastKnownBatteryPct, 0.87);
      expect(prefs.lastKnownBatteryAtMs, 1750000000000);
      expect(prefs.lastKnownCharging, isTrue);
    });

    test('null charging persists as null (not false)', () async {
      final prefs = Prefs.instance;
      await prefs.recordBatteryReading(pct: 0.5, atMs: 1750000000000);
      expect(prefs.lastKnownCharging, isNull);
      await prefs.load();
      expect(prefs.lastKnownCharging, isNull);
      expect(prefs.lastKnownBatteryPct, 0.5);
    });

    test('pct is clamped to 0..1', () async {
      final prefs = Prefs.instance;
      await prefs.recordBatteryReading(pct: 1.4, atMs: 1);
      expect(prefs.lastKnownBatteryPct, 1.0);
      await prefs.recordBatteryReading(pct: -0.2, atMs: 2);
      expect(prefs.lastKnownBatteryPct, 0.0);
    });

    test('lastKnownBattery getter reconstructs the value; null when unseen',
        () async {
      final prefs = Prefs.instance;
      await prefs.load(); // empty store
      expect(prefs.lastKnownBattery, isNull);

      await prefs.recordBatteryReading(
          pct: 0.42, atMs: 1750000000000, charging: false);
      final lk = prefs.lastKnownBattery;
      expect(lk, isNotNull);
      expect(lk!.pct, 0.42);
      expect(lk.at, DateTime.fromMillisecondsSinceEpoch(1750000000000));
      expect(lk.charging, isFalse);
    });

    test('a later reading overwrites the earlier one', () async {
      final prefs = Prefs.instance;
      await prefs.recordBatteryReading(pct: 0.9, atMs: 1000, charging: true);
      await prefs.recordBatteryReading(pct: 0.3, atMs: 2000, charging: false);
      await prefs.load();
      expect(prefs.lastKnownBatteryPct, 0.3);
      expect(prefs.lastKnownBatteryAtMs, 2000);
      expect(prefs.lastKnownCharging, isFalse);
    });
  });

  group('DeviceSettingsScreen.resolveDeviceName order', () {
    const strap4 = PairedStrap(id: 'a', family: DeviceFamily.whoop4, name: 'Nova');
    const strap5NoName = PairedStrap(id: 'b', family: DeviceFamily.whoop5);

    test('override wins over everything', () {
      expect(
          DeviceSettingsScreen.resolveDeviceName(strap4, 'Nickname'), 'Nickname');
    });

    test('strap advertised name when no override', () {
      expect(DeviceSettingsScreen.resolveDeviceName(strap4, null), 'Nova');
    });

    test('family label when strap has no advertised name', () {
      expect(DeviceSettingsScreen.resolveDeviceName(strap5NoName, null),
          'WHOOP 5·MG');
    });

    test('"WHOOP" when nothing at all is known — never a hardcoded "Band 4"', () {
      final name = DeviceSettingsScreen.resolveDeviceName(null, null);
      expect(name, 'WHOOP');
      expect(name, isNot('Band 4'));
    });
  });
}
