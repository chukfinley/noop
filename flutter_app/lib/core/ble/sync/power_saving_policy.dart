/// Dart port of the pure battery-adaptive decision logic from `WhoopBleClient.kt`
/// (`idleThrottleActive` / `offloadIntervalMsFor`, ryanbr/noop #478) and its Swift twin
/// `BLEManager.lowPowerThrottleActive` / `offloadInterval` (#482, closing #477).
///
/// Eases BLE load on a strap that is running out of charge. Two levers, both benign (neither touches
/// the connection parameters, so neither can cause a supervision-timeout drop — the RISKY
/// `CONNECTION_PRIORITY_LOW_POWER` half of #478 is Android-GATT-only and deliberately NOT ported):
///
///  1. **Stretch the background history sync** from every 15 min to every 45
///     ([normalSyncIntervalMs] → [lowBatterySyncIntervalMs]). The offload tick is a PURE sync timer
///     (the live-stream keep-alive is separate), so stretching it cannot affect link health — worst
///     case is fresher data arriving in slightly larger batches; the strap banks everything to its own
///     flash meanwhile, so NO DATA IS LOST.
///  2. **Release the always-on continuous-HRV stream** ([releaseContinuousHrv], a sub-option) — the
///     biggest continuous drain on the strap. Only the held-open BACKGROUND capture is dropped; a
///     visible Live screen arms the stream on its own separate want, so live HR still works. Re-arms
///     automatically once the strap is charged.
///
/// Keyed on the **STRAP's** battery, never the phone's (#482): the levers reduce how much the STRAP
/// transmits (fewer offloads, no continuous stream), so they extend the STRAP's life when it wasn't
/// charged in time. The phone's own Battery Saver / Low Power Mode deliberately does NOT trigger them —
/// saving the phone's battery is not what these levers do. (Android #478 additionally OR'd in the
/// phone's power-save because it also keyed on the phone; #482 settled the cross-platform contract on
/// the strap alone, which is what this port follows.)
///
/// OFF BY DEFAULT ([enabled] = false) and NEVER while the strap is charging — a charging strap has
/// nothing to conserve. The user picks the strap-battery threshold it starts at
/// ([minThresholdPct]–[maxThresholdPct]). The threshold IS its own hysteresis: battery % moves slowly,
/// so a boundary crossing flips at most once per point.
///
/// Pure + side-effect-free: no I/O, no timers, no prefs, no clock reads. The BLE client owns the
/// battery snapshot (`batteryNow` / `Stream<double?> get battery`, `chargingNow` /
/// `Stream<bool?> get charging`) and re-reads this policy at each timer re-arm / realtime reconcile.
library;

class PowerSavingPolicy {
  const PowerSavingPolicy({
    this.enabled = false,
    this.thresholdPct = defaultThresholdPct,
    this.releaseContinuousHrv = false,
  });

  /// Normal background history-sync cadence: 900_000 ms = 15 min (matches WHOOP's own).
  static const int normalSyncIntervalMs = 900000;

  /// Stretched cadence while the strap is low: 2_700_000 ms = 45 min. The strap banks to flash
  /// meanwhile, so this only delays sync (larger batches), never loses data.
  static const int lowBatterySyncIntervalMs = 2700000;

  /// Bounds of the user-facing threshold picker. Below 10% the strap is about to die anyway (the lever
  /// would buy nothing); above 30% we'd be throttling a strap with most of a day left in it.
  static const int minThresholdPct = 10;
  static const int maxThresholdPct = 30;

  /// Default picker position — low enough to be clearly "running out", high enough that the stretched
  /// 45-min cadence still has real runtime left to save.
  static const int defaultThresholdPct = 20;

  /// Master arm. FALSE BY DEFAULT: the whole feature ships dormant, so [syncIntervalMs] returns
  /// [normalSyncIntervalMs] and [dropContinuousHrv] returns false — byte-for-byte today's behaviour.
  final bool enabled;

  /// Strap-battery percentage at/below which the levers engage while discharging. Clamped into
  /// [minThresholdPct]..[maxThresholdPct] by [effectiveThresholdPct] so a corrupt/legacy stored pref
  /// can never widen the lever beyond the picker's range.
  final int thresholdPct;

  /// Sub-option: also release the always-on continuous-HRV stream when engaged. Independent of the
  /// (always-on-when-engaged) sync stretch — dropping the stream is the more noticeable of the two, so
  /// the user opts into it separately.
  final bool releaseContinuousHrv;

  /// [thresholdPct] clamped to the picker's range.
  int get effectiveThresholdPct =>
      thresholdPct < minThresholdPct
          ? minThresholdPct
          : (thresholdPct > maxThresholdPct ? maxThresholdPct : thresholdPct);

  /// True when power saving should be active for this strap snapshot.
  ///
  /// [batteryFraction] is the strap's 0..1 charge (the client's `batteryNow`), null when unknown
  /// (disconnected / not yet read). [charging] is the client's `chargingNow`.
  ///
  /// Unknown or non-finite battery → NEVER engages: it fails SAFE, exactly like the upstream
  /// `?? 100` sentinel. We must never throttle on a reading we don't have, and a disconnected strap has
  /// nothing to throttle anyway.
  ///
  /// [charging] == null means "unknown", which we treat as DISCHARGING (upstream's `state.charging ==
  /// true` semantics). This is deliberate and load-bearing: the standard 0x2A19 battery profile carries
  /// no charging bit, so a WHOOP 4 reports a fraction with a null charging flag — treating null as
  /// "charging" would silently disable the whole feature on that strap. Both levers are benign (no link
  /// risk, no data loss), so engaging on an unknown charging state costs nothing but a slower sync.
  bool engaged({required double? batteryFraction, required bool? charging}) {
    if (!enabled) return false;
    if (batteryFraction == null || !batteryFraction.isFinite) return false;
    if (charging == true) return false; // a charging strap has nothing to conserve
    // Round to whole percent before comparing, matching upstream's integer battery-% contract, so the
    // boundary is exact and deterministic (0.205 → 21% → above a 20% threshold → not engaged).
    final pct = (batteryFraction * 100).round();
    return pct <= effectiveThresholdPct;
  }

  /// The delay before the next background history sync for this strap snapshot: stretched to
  /// [lowBatterySyncIntervalMs] while engaged, else the normal [normalSyncIntervalMs].
  int syncIntervalMs({required double? batteryFraction, required bool? charging}) =>
      engaged(batteryFraction: batteryFraction, charging: charging)
          ? lowBatterySyncIntervalMs
          : normalSyncIntervalMs;

  /// Whether the always-on background continuous-HRV stream should be released for this strap
  /// snapshot. Requires BOTH the master arm (via [engaged]) and the [releaseContinuousHrv] sub-option.
  bool dropContinuousHrv({required double? batteryFraction, required bool? charging}) =>
      releaseContinuousHrv &&
      engaged(batteryFraction: batteryFraction, charging: charging);

  /// Copy with overrides — the seam the settings layer uses to apply a picker change.
  PowerSavingPolicy copyWith({
    bool? enabled,
    int? thresholdPct,
    bool? releaseContinuousHrv,
  }) =>
      PowerSavingPolicy(
        enabled: enabled ?? this.enabled,
        thresholdPct: thresholdPct ?? this.thresholdPct,
        releaseContinuousHrv: releaseContinuousHrv ?? this.releaseContinuousHrv,
      );
}
