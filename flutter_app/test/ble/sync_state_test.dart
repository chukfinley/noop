import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noop/core/state/prefs.dart';

/// Covers the persisted WHOOP sync-state (Prefs `recordSyncCompleted` + the three
/// fields + the [SyncState] reconstruction) over an in-memory secure-storage mock —
/// no radio, no device (project rule: never launch). Mirrors paired_strap_test.
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

  group('Prefs sync-state', () {
    test('recordSyncCompleted round-trips all three fields through storage',
        () async {
      final prefs = Prefs.instance;
      await prefs.recordSyncCompleted(
        atMs: 1750000000000,
        newestRecordTsMs: 1749990000000,
        recordCount: 4321,
      );
      // In-memory fields update immediately.
      expect(prefs.lastSyncAtMs, 1750000000000);
      expect(prefs.lastSyncedRecordTsMs, 1749990000000);
      expect(prefs.lastSyncRecordCount, 4321);

      // And a fresh load() from the same backing store recovers them.
      prefs.lastSyncAtMs = null;
      prefs.lastSyncedRecordTsMs = null;
      prefs.lastSyncRecordCount = null;
      await prefs.load();
      expect(prefs.lastSyncAtMs, 1750000000000);
      expect(prefs.lastSyncedRecordTsMs, 1749990000000);
      expect(prefs.lastSyncRecordCount, 4321);
    });

    test('null newestRecordTs / recordCount persist as null, not 0', () async {
      final prefs = Prefs.instance;
      await prefs.recordSyncCompleted(atMs: 1750000000000);
      expect(prefs.lastSyncAtMs, 1750000000000);
      expect(prefs.lastSyncedRecordTsMs, isNull);
      expect(prefs.lastSyncRecordCount, isNull);
      await prefs.load();
      expect(prefs.lastSyncAtMs, 1750000000000);
      expect(prefs.lastSyncedRecordTsMs, isNull);
      expect(prefs.lastSyncRecordCount, isNull);
    });

    test('unset over an empty store loads as null (never synced)', () async {
      final prefs = Prefs.instance;
      // Pollute the in-memory fields, then load over an empty backing store.
      prefs.lastSyncAtMs = 999;
      prefs.lastSyncedRecordTsMs = 999;
      prefs.lastSyncRecordCount = 999;
      await prefs.load();
      expect(prefs.lastSyncAtMs, isNull);
      expect(prefs.lastSyncedRecordTsMs, isNull);
      expect(prefs.lastSyncRecordCount, isNull);
    });

    test('a later sync overwrites the earlier record', () async {
      final prefs = Prefs.instance;
      await prefs.recordSyncCompleted(
          atMs: 1750000000000, newestRecordTsMs: 1749990000000, recordCount: 10);
      await prefs.recordSyncCompleted(
          atMs: 1750000600000, newestRecordTsMs: 1750000500000, recordCount: 25);
      await prefs.load();
      expect(prefs.lastSyncAtMs, 1750000600000);
      expect(prefs.lastSyncedRecordTsMs, 1750000500000);
      expect(prefs.lastSyncRecordCount, 25);
    });
  });

  group('SyncState reconstruction (Prefs → SyncState)', () {
    test('never synced → all null, everSynced false', () async {
      final prefs = Prefs.instance;
      await prefs.load(); // empty store
      final s = prefs.syncState;
      expect(s.lastSyncAt, isNull);
      expect(s.lastSyncedRecordTs, isNull);
      expect(s.recordCount, isNull);
      expect(s.everSynced, isFalse);
    });

    test('reconstructs DateTimes + count from the persisted ms fields', () async {
      final prefs = Prefs.instance;
      await prefs.recordSyncCompleted(
        atMs: 1750000000000,
        newestRecordTsMs: 1749990000000,
        recordCount: 88,
      );
      final s = prefs.syncState;
      expect(s.everSynced, isTrue);
      expect(s.lastSyncAt,
          DateTime.fromMillisecondsSinceEpoch(1750000000000));
      expect(s.lastSyncedRecordTs,
          DateTime.fromMillisecondsSinceEpoch(1749990000000));
      expect(s.recordCount, 88);
    });

    test('survives a reload and reconstructs the same SyncState', () async {
      final prefs = Prefs.instance;
      await prefs.recordSyncCompleted(
          atMs: 1750000000000, newestRecordTsMs: 1749990000000, recordCount: 88);
      prefs.lastSyncAtMs = null;
      prefs.lastSyncedRecordTsMs = null;
      prefs.lastSyncRecordCount = null;
      await prefs.load();
      final s = prefs.syncState;
      expect(s.lastSyncAt,
          DateTime.fromMillisecondsSinceEpoch(1750000000000));
      expect(s.lastSyncedRecordTs,
          DateTime.fromMillisecondsSinceEpoch(1749990000000));
      expect(s.recordCount, 88);
    });
  });
}
