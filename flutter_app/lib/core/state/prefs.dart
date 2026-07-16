import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gauge rendering style for the score dials — the animated liquid vessel or a
/// classic arc ring. User-selectable, persisted.
enum GaugeStyle { liquid, ring }

/// Which sleep window nightly HRV (RMSSD) is scored over (ryanbr #141).
/// [wholeNight] averages across all sleep stages; [deepSleep] scores only the
/// deep (slow-wave) window — matching WHOOP's own methodology, which reads
/// ~1.5–2× lower than a whole-night mean. Whole-night stays the default.
enum HrvWindow { wholeNight, deepSleep }

/// The 0..100 vs WHOOP 0..21 display scale for Effort/day-strain (ryanbr #45).
/// Purely presentational — the underlying strain is always computed 0..100.
enum EffortScale { hundred, whoop }

/// Immutable snapshot of the persisted WHOOP sync-state — the WALLCLOCK story of
/// the last completed offload, for display + staleness ("last synced X ago"). The
/// strap itself remains the source of truth for WHAT to sync; this is purely the
/// human-facing "when did it last finish" record.
///   • [lastSyncAt] — wall-clock time an offload last COMPLETED (null = never),
///   • [lastSyncedRecordTs] — the newest strap-record timestamp we've persisted,
///   • [recordCount] — how many records that last sync persisted.
class SyncState {
  const SyncState({this.lastSyncAt, this.lastSyncedRecordTs, this.recordCount});

  final DateTime? lastSyncAt;
  final DateTime? lastSyncedRecordTs;
  final int? recordCount;

  /// Whether any sync has ever completed (drives "Never synced" vs a relative time).
  bool get everSynced => lastSyncAt != null;

  @override
  String toString() =>
      'SyncState(lastSyncAt: $lastSyncAt, lastSyncedRecordTs: $lastSyncedRecordTs, '
      'recordCount: $recordCount)';
}

/// Immutable snapshot of the LAST REAL strap battery reading we saw — persisted so
/// the charge hero / Today pill can honestly show a timestamped past value while the
/// strap is disconnected (a real reading "as of <time>", never a fabricated number).
///   • [pct] — the battery fraction 0..1,
///   • [at] — wall-clock time that reading arrived,
///   • [charging] — whether it reported charging then (null = unknown).
class LastKnownBattery {
  const LastKnownBattery({required this.pct, required this.at, this.charging});

  final double pct;
  final DateTime at;
  final bool? charging;

  @override
  String toString() =>
      'LastKnownBattery(pct: $pct, at: $at, charging: $charging)';
}

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
  static const _kWaterLog = 'water_log';
  static const _kWallpaper = 'home_wallpaper';
  static const _kWallpaperUrl = 'home_wallpaper_url';
  static const _kHrvWindow = 'hrv_window';
  static const _kEffortScale = 'effort_scale';
  static const _kTrendsBars = 'trends_bars';
  static const _kFahrenheit = 'temp_fahrenheit';
  static const _kAiKey = 'ai_api_key';
  static const _kAiBaseUrl = 'ai_base_url';
  static const _kAiModel = 'ai_model';
  static const _kWeatherLat = 'weather_lat';
  static const _kWeatherLon = 'weather_lon';
  static const _kWeatherPlace = 'weather_place';
  static const _kHomeLayout = 'home_layout';
  static const _kHealthLayout = 'health_layout';
  static const _kCardsLayout = 'cards_layout';
  static const _kPairedStrapId = 'paired_strap_id';
  static const _kPairedStrapFamily = 'paired_strap_family';
  static const _kPairedStrapName = 'paired_strap_name';
  static const _kBodyWeight = 'body_weight_kg';
  static const _kBodyHeight = 'body_height_cm';
  static const _kHrMax = 'hr_max_override';
  static const _kMetric = 'units_metric';
  static const _kAppearance = 'appearance_mode';
  static const _kChartStyle = 'chart_style';
  static const _kAnalysisEngine = 'analysis_engine_id';
  static const _kToggles = 'settings_toggles';
  static const _kBackgroundSync = 'background_sync_enabled';
  static const _kLastSyncAt = 'last_sync_at_ms';
  static const _kLastSyncedRecordTs = 'last_synced_record_ts_ms';
  static const _kLastSyncRecordCount = 'last_sync_record_count';
  static const _kDeviceNameOverride = 'device_name_override';
  static const _kLastKnownBatteryPct = 'last_known_battery_pct';
  static const _kLastKnownBatteryAt = 'last_known_battery_at_ms';
  static const _kLastKnownCharging = 'last_known_charging';
  static const _kPowerSaving = 'power_saving_enabled';
  static const _kPowerSavingPct = 'power_saving_threshold_pct';

  final FlutterSecureStorage _store = const FlutterSecureStorage();

  bool onboarded = false;
  GaugeStyle gaugeStyle = GaugeStyle.liquid;
  bool wallpaper = false;

  /// Optional custom wallpaper image URL (any jpg/png/webp). Empty → the bundled
  /// asset is used. Downloaded on demand by the UI.
  String? wallpaperUrl;

  /// Sleep window nightly HRV is scored over (read at pipeline construction).
  HrvWindow hrvWindow = HrvWindow.wholeNight;

  /// Display scale for Effort/day-strain.
  EffortScale effortScale = EffortScale.hundred;

  /// Render Trends graphs as zero-anchored bars instead of lines.
  bool trendsBars = false;

  /// Show temperatures in Fahrenheit instead of Celsius.
  bool fahrenheit = false;

  /// Bring-your-own-key config for the AI food-photo estimator. The key is a
  /// secret (secure storage only, never logged). Base URL + model are
  /// OpenAI-compatible, so the same client serves OpenAI or xAI Grok — the user
  /// pays for their own usage.
  String? aiApiKey;
  String aiBaseUrl = 'https://api.openai.com/v1';
  String aiModel = 'gpt-4o-mini';

  /// Which analysis engine's scores the app shows (id from `engineRegistry`).
  /// Defaults to our own model; the user can switch to OpenStrap in settings.
  String analysisEngineId = 'noop';

  /// User-selected weather location, overriding the coarse IP guess. Null when
  /// the user has not chosen one (automatic mode).
  double? weatherLat;
  double? weatherLon;
  String? weatherPlace;

  /// Daily body-weight log, keyed by ISO day (`yyyy-MM-dd`) → kilograms.
  Map<String, double> weightLog = {};

  /// Daily water-intake log, keyed by ISO day (`yyyy-MM-dd`) → millilitres.
  Map<String, double> waterLog = {};

  /// Persisted home-section layout as raw maps (`[{"id":..,"visible":..}, …]`).
  /// Null when the user has never customised it (use defaults). Kept as plain
  /// maps so this layer stays free of any UI/model imports.
  List<Map<String, dynamic>>? homeLayout;

  /// Persisted Health-Monitor tile layout, same raw shape as [homeLayout].
  /// Null when never customised.
  List<Map<String, dynamic>>? healthLayout;

  /// Persisted "Your cards" trio layout (Recovery/Strain/Sleep order + show),
  /// same raw shape as [homeLayout]. Null when never customised.
  List<Map<String, dynamic>>? cardsLayout;

  /// The last successfully-paired WHOOP strap, remembered so the app can
  /// auto-reconnect on launch without the user re-picking it. [pairedStrapId] is
  /// the platform remote-id, [pairedStrapFamily] is the family token
  /// (`"whoop4"`/`"whoop5"`), [pairedStrapName] the advertised name (may be null).
  /// All null when nothing has been paired (or after [clearPairedStrap]). Kept as
  /// plain strings so this layer stays free of any BLE/model imports.
  String? pairedStrapId;
  String? pairedStrapFamily;
  String? pairedStrapName;

  /// User-editable body profile overrides — persisted so they survive a restart
  /// (previously session-only, which reset every launch). Null → fall back to the
  /// repository's default profile value.
  double? bodyWeightKg;
  double? bodyHeightCm;
  int? hrMaxOverride;

  /// Measurement system: `true` metric, `false` imperial. Null → repo default.
  bool? metric;

  /// Persisted appearance mode (`system`/`light`/`dark`) and chart palette
  /// (`titanium`/`classic`). Stored as their string tokens.
  String appearanceMode = 'dark';
  String chartStyle = 'titanium';

  /// Simple on/off settings toggles keyed by a short id (illness watch, keep
  /// connected, hydration reminders, …). Seeded per-key defaults live in the UI;
  /// only user-changed values are stored here.
  Map<String, bool> toggles = {};

  /// Whether the Android background-sync foreground service is enabled. `null`
  /// means the user has never toggled it, so the app derives a default (ON when a
  /// strap is paired, so it "just works"). Once the user flips it in Settings we
  /// store the explicit `true`/`false`. Android-only in effect; harmless elsewhere.
  bool? backgroundSyncEnabled;

  /// Persisted WHOOP sync-state (see [SyncState]). [lastSyncAtMs] is the wall-clock
  /// ms an offload last COMPLETED, [lastSyncedRecordTsMs] the newest strap-record ts
  /// we've banked, [lastSyncRecordCount] the records in that last sync. All null
  /// until the first offload completes → the UI shows an honest "Never synced".
  int? lastSyncAtMs;
  int? lastSyncedRecordTsMs;
  int? lastSyncRecordCount;

  /// User's manual rename override for the paired strap. Null → show the strap's own
  /// real advertised name (never a hardcoded literal). Survives a restart so a rename
  /// sticks; the DEFAULT display name still comes from the live strap, not this field.
  String? deviceNameOverride;

  /// The last REAL strap battery reading (0..1), the wall-clock ms it arrived, and its
  /// charging flag. Persisted so a disconnected strap can show its last honest value
  /// (timestamped, "as of X ago"). All null until a real reading has ever been seen.
  double? lastKnownBatteryPct;
  int? lastKnownBatteryAtMs;
  bool? lastKnownCharging;

  /// Power saving (strap-battery adaptive, `core/ble/sync/power_saving_policy.dart`).
  /// OFF by default → the whole feature ships dormant and the background sync keeps its
  /// normal 15-min cadence, byte-for-byte today's behaviour. [powerSavingThresholdPct]
  /// is the STRAP-battery percentage the user picks for the levers to engage at; the
  /// policy clamps it into its own 10–30 picker range, so a corrupt/legacy stored value
  /// can never widen the lever beyond what the UI offers.
  ///
  /// Deliberately only TWO fields: the policy's `releaseContinuousHrv` sub-option has no
  /// stream to release in this port yet (the Flutter client never arms an always-on
  /// continuous-HRV capture — see the power-saving notes in the background worker), so
  /// persisting a preference for it would be a dead key behind a dead toggle.
  bool powerSavingEnabled = false;
  int powerSavingThresholdPct = 20;

  /// Reconstruct the immutable [LastKnownBattery] from the persisted fields, or null
  /// when no real reading has ever been banked (→ the UI honestly shows "—").
  LastKnownBattery? get lastKnownBattery =>
      (lastKnownBatteryPct == null || lastKnownBatteryAtMs == null)
          ? null
          : LastKnownBattery(
              pct: lastKnownBatteryPct!,
              at: DateTime.fromMillisecondsSinceEpoch(lastKnownBatteryAtMs!),
              charging: lastKnownCharging,
            );

  /// Reconstruct the immutable [SyncState] value from the persisted fields.
  SyncState get syncState => SyncState(
        lastSyncAt: lastSyncAtMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(lastSyncAtMs!),
        lastSyncedRecordTs: lastSyncedRecordTsMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(lastSyncedRecordTsMs!),
        recordCount: lastSyncRecordCount,
      );

  /// Load persisted values into memory. Safe to call before `runApp`.
  Future<void> load() async {
    try {
      final all = await _store.readAll();
      onboarded = all[_kOnboarded] == 'true';
      gaugeStyle = all[_kGaugeStyle] == 'ring' ? GaugeStyle.ring : GaugeStyle.liquid;
      wallpaper = all[_kWallpaper] == 'true';
      wallpaperUrl = all[_kWallpaperUrl];
      hrvWindow =
          all[_kHrvWindow] == 'deep' ? HrvWindow.deepSleep : HrvWindow.wholeNight;
      effortScale =
          all[_kEffortScale] == 'whoop' ? EffortScale.whoop : EffortScale.hundred;
      trendsBars = all[_kTrendsBars] == 'true';
      fahrenheit = all[_kFahrenheit] == 'true';
      final k = all[_kAiKey];
      aiApiKey = (k == null || k.isEmpty) ? null : k;
      final bu = all[_kAiBaseUrl];
      if (bu != null && bu.isNotEmpty) aiBaseUrl = bu;
      final am = all[_kAiModel];
      if (am != null && am.isNotEmpty) aiModel = am;
      weatherLat = double.tryParse(all[_kWeatherLat] ?? '');
      weatherLon = double.tryParse(all[_kWeatherLon] ?? '');
      final wp = all[_kWeatherPlace];
      weatherPlace = (wp == null || wp.isEmpty) ? null : wp;
      weightLog = _decodeDoubleMap(all[_kWeightLog]);
      waterLog = _decodeDoubleMap(all[_kWaterLog]);
      homeLayout = _decodeHomeLayout(all[_kHomeLayout]);
      healthLayout = _decodeHomeLayout(all[_kHealthLayout]);
      cardsLayout = _decodeHomeLayout(all[_kCardsLayout]);
      final psId = all[_kPairedStrapId];
      pairedStrapId = (psId == null || psId.isEmpty) ? null : psId;
      final psFam = all[_kPairedStrapFamily];
      pairedStrapFamily = (psFam == null || psFam.isEmpty) ? null : psFam;
      final psName = all[_kPairedStrapName];
      pairedStrapName = (psName == null || psName.isEmpty) ? null : psName;
      bodyWeightKg = double.tryParse(all[_kBodyWeight] ?? '');
      bodyHeightCm = double.tryParse(all[_kBodyHeight] ?? '');
      hrMaxOverride = int.tryParse(all[_kHrMax] ?? '');
      final m = all[_kMetric];
      metric = (m == null || m.isEmpty) ? null : m == 'true';
      final ap = all[_kAppearance];
      if (ap != null && ap.isNotEmpty) appearanceMode = ap;
      final cs = all[_kChartStyle];
      if (cs != null && cs.isNotEmpty) chartStyle = cs;
      final ae = all[_kAnalysisEngine];
      if (ae != null && ae.isNotEmpty) analysisEngineId = ae;
      toggles = _decodeBoolMap(all[_kToggles]);
      final bg = all[_kBackgroundSync];
      backgroundSyncEnabled = (bg == null || bg.isEmpty) ? null : bg == 'true';
      lastSyncAtMs = int.tryParse(all[_kLastSyncAt] ?? '');
      lastSyncedRecordTsMs = int.tryParse(all[_kLastSyncedRecordTs] ?? '');
      lastSyncRecordCount = int.tryParse(all[_kLastSyncRecordCount] ?? '');
      final dno = all[_kDeviceNameOverride];
      deviceNameOverride = (dno == null || dno.isEmpty) ? null : dno;
      lastKnownBatteryPct = double.tryParse(all[_kLastKnownBatteryPct] ?? '');
      lastKnownBatteryAtMs = int.tryParse(all[_kLastKnownBatteryAt] ?? '');
      final lkc = all[_kLastKnownCharging];
      lastKnownCharging = (lkc == null || lkc.isEmpty) ? null : lkc == 'true';
      powerSavingEnabled = all[_kPowerSaving] == 'true';
      powerSavingThresholdPct =
          int.tryParse(all[_kPowerSavingPct] ?? '') ?? powerSavingThresholdPct;
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

  Future<void> setWallpaper(bool value) async {
    wallpaper = value;
    await _write(_kWallpaper, value ? 'true' : 'false');
  }

  Future<void> setWallpaperUrl(String? value) async {
    final v = (value == null || value.trim().isEmpty) ? null : value.trim();
    wallpaperUrl = v;
    await _write(_kWallpaperUrl, v ?? '');
  }

  Future<void> setHrvWindow(HrvWindow value) async {
    hrvWindow = value;
    await _write(_kHrvWindow, value == HrvWindow.deepSleep ? 'deep' : 'whole');
  }

  Future<void> setEffortScale(EffortScale value) async {
    effortScale = value;
    await _write(_kEffortScale, value == EffortScale.whoop ? 'whoop' : 'hundred');
  }

  Future<void> setTrendsBars(bool value) async {
    trendsBars = value;
    await _write(_kTrendsBars, value ? 'true' : 'false');
  }

  Future<void> setFahrenheit(bool value) async {
    fahrenheit = value;
    await _write(_kFahrenheit, value ? 'true' : 'false');
  }

  /// Persist the AI food-estimator config. Empty [key] clears it.
  Future<void> setAiConfig(String? key, String baseUrl, String model) async {
    aiApiKey = (key == null || key.isEmpty) ? null : key;
    aiBaseUrl = baseUrl.trim().isEmpty ? 'https://api.openai.com/v1' : baseUrl.trim();
    aiModel = model.trim().isEmpty ? 'gpt-4o-mini' : model.trim();
    await _write(_kAiKey, aiApiKey ?? '');
    await _write(_kAiBaseUrl, aiBaseUrl);
    await _write(_kAiModel, aiModel);
  }

  /// Persist (or clear, when passed nulls) the chosen weather location.
  Future<void> setWeatherLocation(double? lat, double? lon, String? place) async {
    weatherLat = lat;
    weatherLon = lon;
    weatherPlace = place;
    await _write(_kWeatherLat, lat?.toString() ?? '');
    await _write(_kWeatherLon, lon?.toString() ?? '');
    await _write(_kWeatherPlace, place ?? '');
  }

  /// Persist the whole weight log (called after each add/edit).
  Future<void> setWeightLog(Map<String, double> log) async {
    weightLog = log;
    await _write(_kWeightLog, jsonEncode(log));
  }

  /// Persist the whole water log (called after each add/edit).
  Future<void> setWaterLog(Map<String, double> log) async {
    waterLog = log;
    await _write(_kWaterLog, jsonEncode(log));
  }

  /// Persist the home-section layout (called after each reorder / toggle).
  Future<void> setHomeLayout(List<Map<String, dynamic>> cfg) async {
    homeLayout = cfg;
    await _write(_kHomeLayout, jsonEncode(cfg));
  }

  /// Persist the Health-Monitor tile layout (called after each reorder / toggle).
  Future<void> setHealthLayout(List<Map<String, dynamic>> cfg) async {
    healthLayout = cfg;
    await _write(_kHealthLayout, jsonEncode(cfg));
  }

  /// Persist the "Your cards" trio layout (called after each reorder / toggle).
  Future<void> setCardsLayout(List<Map<String, dynamic>> cfg) async {
    cardsLayout = cfg;
    await _write(_kCardsLayout, jsonEncode(cfg));
  }

  /// Remember the strap we just successfully paired with (called on a successful
  /// connect). [family] is the token `"whoop4"`/`"whoop5"`; [name] may be null.
  Future<void> setPairedStrap(String id, String family, String? name) async {
    pairedStrapId = id;
    pairedStrapFamily = family;
    pairedStrapName = (name == null || name.isEmpty) ? null : name;
    await _write(_kPairedStrapId, id);
    await _write(_kPairedStrapFamily, family);
    await _write(_kPairedStrapName, pairedStrapName ?? '');
  }

  /// Forget the remembered strap (an explicit "unpair"). Auto-reconnect no-ops
  /// afterwards until a new strap is paired.
  Future<void> clearPairedStrap() async {
    pairedStrapId = null;
    pairedStrapFamily = null;
    pairedStrapName = null;
    await _write(_kPairedStrapId, '');
    await _write(_kPairedStrapFamily, '');
    await _write(_kPairedStrapName, '');
  }

  /// Persist a body-profile override (null clears it back to the repo default).
  Future<void> setBodyWeight(double? kg) async {
    bodyWeightKg = kg;
    await _write(_kBodyWeight, kg?.toString() ?? '');
  }

  Future<void> setBodyHeight(double? cm) async {
    bodyHeightCm = cm;
    await _write(_kBodyHeight, cm?.toString() ?? '');
  }

  Future<void> setHrMaxOverride(int? bpm) async {
    hrMaxOverride = bpm;
    await _write(_kHrMax, bpm?.toString() ?? '');
  }

  Future<void> setMetric(bool value) async {
    metric = value;
    await _write(_kMetric, value ? 'true' : 'false');
  }

  Future<void> setAppearanceMode(String value) async {
    appearanceMode = value;
    await _write(_kAppearance, value);
  }

  Future<void> setChartStyle(String value) async {
    chartStyle = value;
    await _write(_kChartStyle, value);
  }

  Future<void> setAnalysisEngine(String id) async {
    analysisEngineId = id;
    await _write(_kAnalysisEngine, id);
  }

  /// Set one on/off settings toggle by [key].
  Future<void> setToggle(String key, bool value) async {
    toggles = {...toggles, key: value};
    await _write(_kToggles, jsonEncode(toggles));
  }

  /// Persist the explicit background-sync preference (an intentional user toggle).
  /// After this, [backgroundSyncEnabled] is no longer null, so the derived default
  /// no longer applies.
  Future<void> setBackgroundSyncEnabled(bool value) async {
    backgroundSyncEnabled = value;
    await _write(_kBackgroundSync, value ? 'true' : 'false');
  }

  /// Bank the sync-state after an offload COMPLETES. [atMs] is wall-clock now;
  /// [newestRecordTsMs] the newest strap-record ts we persisted (null when the
  /// offload banked no timestamped record); [recordCount] the records in this sync.
  Future<void> recordSyncCompleted({
    required int atMs,
    int? newestRecordTsMs,
    int? recordCount,
  }) async {
    lastSyncAtMs = atMs;
    lastSyncedRecordTsMs = newestRecordTsMs;
    lastSyncRecordCount = recordCount;
    await _write(_kLastSyncAt, atMs.toString());
    await _write(_kLastSyncedRecordTs, newestRecordTsMs?.toString() ?? '');
    await _write(_kLastSyncRecordCount, recordCount?.toString() ?? '');
  }

  /// Persist the power-saving master arm (an intentional user toggle).
  Future<void> setPowerSavingEnabled(bool value) async {
    powerSavingEnabled = value;
    await _write(_kPowerSaving, value ? 'true' : 'false');
  }

  /// Persist the strap-battery percentage the power-saving levers engage at. Stored
  /// verbatim; the policy clamps it to its own picker range when it is read.
  Future<void> setPowerSavingThresholdPct(int pct) async {
    powerSavingThresholdPct = pct;
    await _write(_kPowerSavingPct, pct.toString());
  }

  /// Persist (or clear, when passed null/empty) the manual device-name override.
  Future<void> setDeviceNameOverride(String? value) async {
    final v = (value == null || value.trim().isEmpty) ? null : value.trim();
    deviceNameOverride = v;
    await _write(_kDeviceNameOverride, v ?? '');
  }

  /// Bank the latest REAL strap battery reading so a later disconnect can show it as a
  /// timestamped last-known value. [pct] is the 0..1 fraction, [atMs] wall-clock now,
  /// [charging] the reported charging flag (null = unknown).
  Future<void> recordBatteryReading({
    required double pct,
    required int atMs,
    bool? charging,
  }) async {
    lastKnownBatteryPct = pct.clamp(0.0, 1.0);
    lastKnownBatteryAtMs = atMs;
    lastKnownCharging = charging;
    await _write(_kLastKnownBatteryPct, lastKnownBatteryPct!.toString());
    await _write(_kLastKnownBatteryAt, atMs.toString());
    await _write(
        _kLastKnownCharging, charging == null ? '' : (charging ? 'true' : 'false'));
  }

  static Map<String, bool> _decodeBoolMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v == true));
    } catch (_) {
      return {};
    }
  }

  static List<Map<String, dynamic>>? _decodeHomeLayout(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list) Map<String, dynamic>.from(e as Map),
      ];
    } catch (_) {
      return null;
    }
  }

  static Map<String, double> _decodeDoubleMap(String? raw) {
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
