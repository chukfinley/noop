import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gauge rendering style for the score dials — the animated liquid vessel or a
/// classic arc ring. User-selectable, persisted.
enum GaugeStyle { liquid, ring }

/// Tiny persistence layer over [FlutterSecureStorage]. Values are loaded once at
/// startup into memory so the rest of the app can read them synchronously;
/// writes go through to storage. Every storage call is guarded — on platforms
/// without a secret service (e.g. a bare Linux desktop) it silently falls back
/// to in-memory only, so the app never crashes over a missing keyring.
class Prefs {
  Prefs._();
  static final Prefs instance = Prefs._();

  static const _kOnboarded = 'onboarded';
  static const _kGaugeStyle = 'gauge_style';
  static const _kWeightLog = 'weight_log';

  final FlutterSecureStorage _store = const FlutterSecureStorage();

  bool onboarded = false;
  GaugeStyle gaugeStyle = GaugeStyle.liquid;

  /// Daily body-weight log, keyed by ISO day (`yyyy-MM-dd`) → kilograms.
  Map<String, double> weightLog = {};

  /// Load persisted values into memory. Safe to call before `runApp`.
  Future<void> load() async {
    try {
      final all = await _store.readAll();
      onboarded = all[_kOnboarded] == 'true';
      gaugeStyle = all[_kGaugeStyle] == 'ring' ? GaugeStyle.ring : GaugeStyle.liquid;
      weightLog = _decodeWeights(all[_kWeightLog]);
    } catch (e) {
      debugPrint('Prefs.load failed, using defaults: $e');
    }
  }

  Future<void> setOnboarded(bool value) async {
    onboarded = value;
    await _write(_kOnboarded, value ? 'true' : 'false');
  }

  Future<void> setGaugeStyle(GaugeStyle value) async {
    gaugeStyle = value;
    await _write(_kGaugeStyle, value == GaugeStyle.ring ? 'ring' : 'liquid');
  }

  /// Persist the whole weight log (called after each add/edit).
  Future<void> setWeightLog(Map<String, double> log) async {
    weightLog = log;
    await _write(_kWeightLog, jsonEncode(log));
  }

  static Map<String, double> _decodeWeights(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _store.write(key: key, value: value);
    } catch (e) {
      debugPrint('Prefs.write($key) failed: $e');
    }
  }
}
