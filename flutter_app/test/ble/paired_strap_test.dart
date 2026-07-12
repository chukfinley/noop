import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/transport/whoop_ble_client.dart';
import 'package:noop/core/ble/transport/whoop_providers.dart';
import 'package:noop/core/state/prefs.dart';

/// Covers the pure/persistence half of the automatic-pairing feature — no radio, no device.
///   • Prefs paired-strap round-trip + clear (over an in-memory secure-storage mock),
///   • the family token conversion + reconstruction ([readPairedStrap]),
///   • the null-family resolution rule ([WhoopBleClient.resolveConnectFamily]).
/// The device-facing scan/connect code is deliberately NOT exercised (project rule: never launch).
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

  group('Prefs paired strap', () {
    test('round-trips id + family + name through storage', () async {
      final prefs = Prefs.instance;
      await prefs.setPairedStrap('AA:BB:CC', 'whoop5', 'My Band');
      // In-memory fields update immediately.
      expect(prefs.pairedStrapId, 'AA:BB:CC');
      expect(prefs.pairedStrapFamily, 'whoop5');
      expect(prefs.pairedStrapName, 'My Band');

      // And a fresh load() from the same backing store recovers them.
      prefs.pairedStrapId = null;
      prefs.pairedStrapFamily = null;
      prefs.pairedStrapName = null;
      await prefs.load();
      expect(prefs.pairedStrapId, 'AA:BB:CC');
      expect(prefs.pairedStrapFamily, 'whoop5');
      expect(prefs.pairedStrapName, 'My Band');
    });

    test('a null/empty name persists as null, not ""', () async {
      final prefs = Prefs.instance;
      await prefs.setPairedStrap('id-1', 'whoop4', null);
      expect(prefs.pairedStrapName, isNull);
      await prefs.load();
      expect(prefs.pairedStrapId, 'id-1');
      expect(prefs.pairedStrapFamily, 'whoop4');
      expect(prefs.pairedStrapName, isNull);
    });

    test('clearPairedStrap forgets everything', () async {
      final prefs = Prefs.instance;
      await prefs.setPairedStrap('id-2', 'whoop5', 'Band');
      await prefs.clearPairedStrap();
      expect(prefs.pairedStrapId, isNull);
      expect(prefs.pairedStrapFamily, isNull);
      expect(prefs.pairedStrapName, isNull);
      // A load() over the cleared store stays cleared.
      await prefs.load();
      expect(prefs.pairedStrapId, isNull);
      expect(prefs.pairedStrapFamily, isNull);
      expect(prefs.pairedStrapName, isNull);
    });
  });

  group('PairedStrap family token', () {
    test('token round-trips both families', () {
      expect(PairedStrap.familyToToken(DeviceFamily.whoop4), 'whoop4');
      expect(PairedStrap.familyToToken(DeviceFamily.whoop5), 'whoop5');
      expect(PairedStrap.familyFromToken('whoop4'), DeviceFamily.whoop4);
      expect(PairedStrap.familyFromToken('whoop5'), DeviceFamily.whoop5);
    });

    test('unknown/null token falls back to WHOOP 4.0', () {
      expect(PairedStrap.familyFromToken(null), DeviceFamily.whoop4);
      expect(PairedStrap.familyFromToken(''), DeviceFamily.whoop4);
      expect(PairedStrap.familyFromToken('garbage'), DeviceFamily.whoop4);
    });

    test('familyToken getter agrees with the static conversion', () {
      const strap = PairedStrap(id: 'x', family: DeviceFamily.whoop5);
      expect(strap.familyToken, 'whoop5');
    });
  });

  group('readPairedStrap (Prefs → PairedStrap)', () {
    test('null when nothing remembered', () async {
      await Prefs.instance.clearPairedStrap();
      expect(readPairedStrap(), isNull);
    });

    test('reconstructs the remembered strap with its family + name', () async {
      await Prefs.instance.setPairedStrap('DE:AD:BE:EF', 'whoop5', 'Strap 5');
      final strap = readPairedStrap();
      expect(strap, isNotNull);
      expect(strap!.id, 'DE:AD:BE:EF');
      expect(strap.family, DeviceFamily.whoop5);
      expect(strap.name, 'Strap 5');
    });
  });

  group('null-family resolution rule', () {
    test('null when nothing remembered → caller runs a universal scan', () {
      expect(WhoopBleClient.resolveConnectFamily(null), isNull);
    });

    test('adopts the remembered family when present', () {
      expect(
        WhoopBleClient.resolveConnectFamily(
            const PairedStrap(id: 'a', family: DeviceFamily.whoop5)),
        DeviceFamily.whoop5,
      );
      expect(
        WhoopBleClient.resolveConnectFamily(
            const PairedStrap(id: 'b', family: DeviceFamily.whoop4)),
        DeviceFamily.whoop4,
      );
    });
  });
}
