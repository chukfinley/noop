/// Re-broadcasts NOOP's LIVE heart rate back OUT as a standard Bluetooth Heart Rate
/// peripheral (Wave E1), so a gym treadmill, Zwift, Peloton, a bike computer, or any
/// fitness app can read the WHOOP HR that NOOP is already receiving off the strap.
///
/// Faithful Dart twin of the Kotlin `HrBroadcaster` (android/.../ble/HrBroadcaster.kt).
/// It hosts a GATT server exposing the standard Heart Rate Service (0x180D) with the
/// Heart Rate Measurement characteristic (0x2A37, notify), advertises 0x180D, and
/// notifies 0x2A37 with the SIG-spec flags + bpm encoding whenever NOOP has a fresh
/// live HR sample.
///
/// OFFLINE, OPT-IN, ADDITIVE: LOCAL Bluetooth only — nothing leaves the device to any
/// cloud. OFF by default; it only runs while the user's "Broadcast heart rate" toggle
/// is on. It is a pure CONSUMER of the live HR the app already has (fed via [update]);
/// it writes nothing back into the WHOOP path, so the strap connection cannot regress.
///
/// PLATFORM: `bluetooth_low_energy`'s `PeripheralManager` supports the peripheral role
/// (GATT server + advertising) on Android/iOS/macOS. `flutter_blue_plus` (the strap
/// transport) is central-only and cannot do this. Every peripheral call is guarded
/// behind [Platform.isAndroid] || [Platform.isIOS], so this is an inert no-op on
/// desktop/web and in unit tests (nothing touches the radio, nothing is constructed
/// until [start]).
library;

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

/// Standard BLE Heart Rate service + measurement characteristic UUIDs.
final UUID _heartRateService = UUID.fromString('0000180D-0000-1000-8000-00805F9B34FB');
final UUID _heartRateChar = UUID.fromString('00002A37-0000-1000-8000-00805F9B34FB');

/// The friendly name gym kit shows when it discovers the broadcast.
const String _advertisedName = 'NOOP HR';

class HrBroadcaster {
  HrBroadcaster({void Function(String)? log}) : _log = log ?? _noop;

  final void Function(String) _log;
  static void _noop(String _) {}

  /// Peripheral role is only supported on Android/iOS (macOS too, but the app ships
  /// mobile). Everywhere else — desktop, web, the test host — this stays a pure no-op.
  bool get _supported => Platform.isAndroid || Platform.isIOS;

  /// Lazily created so that merely constructing an [HrBroadcaster] (or reading its
  /// provider) touches no native radio — the `PeripheralManager` is only instantiated
  /// the first time [start] runs on a supported platform.
  PeripheralManager? _manager;
  GATTCharacteristic? _hrCharacteristic;
  StreamSubscription<GATTCharacteristicNotifyStateChangedEventArgs>? _notifyStateSub;

  /// Centrals (gym kit / apps) currently subscribed to 0x2A37 notifications.
  final List<Central> _subscribers = <Central>[];

  /// True once [start] was called and we want to be advertising.
  bool _wantAdvertising = false;

  /// The most recent live HR pushed in, re-sent to a central that subscribes mid-session
  /// so a newly connected machine shows a value at once. null until the first sample.
  int? _lastBpm;

  /// True while a start() sequence is in flight, to keep [start] idempotent under
  /// overlapping async calls.
  bool _starting = false;

  // MARK: - Lifecycle

  /// Begin acting as a standard HR peripheral: open the GATT server, publish the 0x180D
  /// service, and start advertising 0x180D. Idempotent. Degrades to a logged note (never
  /// a throw) if Bluetooth is off / unsupported / the runtime permission was revoked.
  Future<void> start() async {
    if (!_supported) {
      _log('HR-out: peripheral role unsupported on this platform, cannot broadcast');
      return;
    }
    if (_wantAdvertising || _starting) return;
    _starting = true;
    _wantAdvertising = true;
    try {
      final manager = _manager ??= PeripheralManager();
      if (Platform.isAndroid && manager.state == BluetoothLowEnergyState.unauthorized) {
        await manager.authorize();
      }
      if (manager.state != BluetoothLowEnergyState.poweredOn) {
        _log('HR-out: Bluetooth not powered on (${manager.state}), cannot broadcast');
        _wantAdvertising = false;
        return;
      }

      _notifyStateSub ??=
          manager.characteristicNotifyStateChanged.listen(_onNotifyStateChanged);

      // A mutable characteristic with the notify property; the plugin manages the CCCD
      // (0x2902) subscription handshake for us and surfaces it via
      // characteristicNotifyStateChanged.
      final characteristic = GATTCharacteristic.mutable(
        uuid: _heartRateChar,
        properties: [GATTCharacteristicProperty.notify],
        permissions: [GATTCharacteristicPermission.read],
        descriptors: [],
      );
      final service = GATTService(
        uuid: _heartRateService,
        isPrimary: true,
        includedServices: [],
        characteristics: [characteristic],
      );
      await manager.removeAllServices();
      await manager.addService(service);
      _hrCharacteristic = characteristic;

      await manager.startAdvertising(
        Advertisement(
          name: _advertisedName,
          serviceUUIDs: [_heartRateService],
        ),
      );
      _log('HR-out: advertising 0x180D heart-rate service');
    } catch (e) {
      _wantAdvertising = false;
      _log('HR-out: start failed ($e)');
    } finally {
      _starting = false;
    }
  }

  /// Stop advertising, tear down the GATT server, and clear all state. Idempotent. A
  /// stale HR is cleared so a later restart never re-emits an old value.
  Future<void> stop() async {
    _wantAdvertising = false;
    _lastBpm = null;
    _subscribers.clear();
    final manager = _manager;
    _hrCharacteristic = null;
    if (manager == null) return;
    try {
      await manager.stopAdvertising();
    } catch (_) {}
    try {
      await manager.removeAllServices();
    } catch (_) {}
    _log('HR-out: broadcast stopped');
  }

  /// Release resources permanently (provider disposal).
  Future<void> dispose() async {
    await stop();
    await _notifyStateSub?.cancel();
    _notifyStateSub = null;
  }

  /// Feed a live HR sample (bpm) to broadcast. null (no current reading) sends nothing —
  /// we never invent a value. A non-physiological bpm is dropped so untrusted/garbage
  /// input can't be re-broadcast. Mirrors the Kotlin `update(bpm)`.
  void update(int? bpm) {
    if (!_wantAdvertising || bpm == null || bpm < 20 || bpm > 255) return;
    _lastBpm = bpm;
    unawaited(_notifyAll(bpm));
  }

  // MARK: - Subscriptions + notify

  void _onNotifyStateChanged(GATTCharacteristicNotifyStateChangedEventArgs args) {
    if (args.characteristic.uuid != _heartRateChar) return;
    final central = args.central;
    if (args.state) {
      if (!_subscribers.contains(central)) {
        _subscribers.add(central);
        _log('HR-out: a central subscribed (now ${_subscribers.length})');
      }
      // Push the latest reading at once so a freshly subscribed machine shows a value.
      final bpm = _lastBpm;
      if (bpm != null) unawaited(_notifyOne(central, bpm));
    } else {
      _subscribers.remove(central);
    }
  }

  /// Send a 0x2A37 measurement to every subscribed central.
  Future<void> _notifyAll(int bpm) async {
    final manager = _manager;
    final ch = _hrCharacteristic;
    if (manager == null || ch == null) return;
    final payload = measurement(bpm);
    for (final central in List<Central>.of(_subscribers)) {
      try {
        await manager.notifyCharacteristic(central, ch, value: payload);
      } catch (_) {}
    }
  }

  /// Send a 0x2A37 measurement to one specific central (the just-subscribed case).
  Future<void> _notifyOne(Central central, int bpm) async {
    final manager = _manager;
    final ch = _hrCharacteristic;
    if (manager == null || ch == null) return;
    try {
      await manager.notifyCharacteristic(central, ch, value: measurement(bpm));
    } catch (_) {}
  }

  // MARK: - SIG encoding

  /// Encode one Bluetooth SIG Heart Rate Measurement (0x2A37) payload for a given bpm.
  ///
  /// Byte-for-byte mirror of the Kotlin `HrBroadcaster.measurement`:
  ///   - flags bit0 = 0 -> HR is a single u8 byte (emitted for any bpm < 256);
  ///   - flags bit0 = 1 -> HR is u16 little-endian (only for an out-of-range bpm >= 256).
  /// Bit3 (Energy Expended) and bit4 (R-R) are never set — a plain instantaneous HR.
  /// The bpm is clamped to a non-negative 16-bit range so a stray value can't overflow.
  static Uint8List measurement(int bpm) {
    final clamped = bpm.clamp(0, 0xFFFF);
    if (clamped < 256) {
      return Uint8List.fromList([0x00, clamped]); // flags=0 (u8 HR)
    }
    return Uint8List.fromList([
      0x01,
      clamped & 0xFF,
      (clamped >> 8) & 0xFF,
    ]); // flags=1 (u16 LE)
  }
}
