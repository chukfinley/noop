import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/ble/background/background_sync_service.dart';
import 'package:noop/core/ble/broadcast/hr_broadcast.dart';
import 'package:noop/core/ble/protocol/device_family.dart';
import 'package:noop/core/ble/transport/whoop_ble_client.dart'
    show
        BleConnectionState,
        ConnLogEntry,
        DiscoveredStrap,
        PairedStrap,
        SyncProgress;
import 'package:noop/core/ble/transport/whoop_providers.dart';
import 'package:noop/core/state/format.dart';
import 'package:noop/core/state/prefs.dart'
    show LastKnownBattery, Prefs, SyncState;
import 'package:noop/core/state/providers.dart';
import 'package:noop/features/alarm/presentation/alarms_screen.dart';
import 'package:noop/shared/widgets/behavior.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/common.dart';
import 'package:noop/shared/widgets/controls.dart';
import 'package:noop/shared/widgets/metric_gauge.dart';
import 'package:noop/shared/widgets/scaffold.dart';
import 'package:noop/shared/widgets/settings_tiles.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

/// The user's manual rename override for the strap (null = show the strap's own real
/// advertised name). Seeded from [Prefs] so a rename survives a restart; the DEFAULT
/// display name comes from the real paired strap via [DeviceSettingsScreen.resolveDeviceName],
/// never a hardcoded literal.
final _deviceNameOverride =
    StateProvider<String?>((_) => Prefs.instance.deviceNameOverride);

/// Device settings — the strap's LIVE charge, connection, sync status, rename,
/// firmware entry and a broadcast-heart-rate switch. Opened from the battery
/// pill on Today.
///
/// Fully live: the header, charge hero, connection dot, live heart rate and sync
/// line are all driven by the real BLE transport providers
/// ([bleConnectionProvider], [liveBatteryProvider], [liveHrProvider],
/// [syncProgressProvider]) and the broadcast providers. Those providers are
/// inert until an explicit `connect()`, so with no strap present the screen
/// honestly shows "Not connected" / "—" and never fabricates a number.
///
/// Rendered in the same Material 3 Expressive idiom as [SettingsScreen]: a charge
/// hero, then *connected* tonal-tile groups ([SettingsGroup] / [SettingsTile])
/// under bold coloured group headers — the shared settings shapes, so this page
/// reads exactly like Settings and its sub-screens.
class DeviceSettingsScreen extends ConsumerWidget {
  const DeviceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching this activates the broadcaster ↔ toggle ↔ live-HR wiring: it is
    // inert unless something watches it.
    ref.watch(hrBroadcastControllerProvider);

    final adapterOn = ref.watch(bleAdapterOnProvider).value ?? true;
    final conn =
        ref.watch(bleConnectionProvider).value ?? BleConnectionState.idle;
    final linked = _isLinked(conn);
    final busy = _isBusy(conn);

    // Battery + charging: the LIVE strap reading wins; with no live link we fall back
    // to the last REAL persisted reading (a timestamped past value, "as of X ago" — not
    // a mock), and only show "—" / "Not connected" when there has genuinely never been
    // one. Charging is never derived from percent<100.
    final double? liveBattery = ref.watch(liveBatteryProvider).value;
    final bool? liveCharging = ref.watch(liveChargingProvider).value;
    final LastKnownBattery? lastKnown = ref.watch(lastKnownBatteryProvider);
    final bool hasLive = liveBattery != null;
    final double? effBattery = liveBattery ?? lastKnown?.pct;
    final bool hasBattery = effBattery != null;
    final bool isStale = !hasLive && lastKnown != null;
    final bool? charging = hasLive ? liveCharging : lastKnown?.charging;
    final double level = (effBattery ?? 0).clamp(0.0, 1.0);
    final int pct = (level * 100).round();

    final liveHr = ref.watch(liveHrProvider).value;
    final sync = ref.watch(syncProgressProvider).value;
    final paired = ref.watch(pairedStrapProvider);
    final broadcast = ref.watch(hrBroadcastEnabledProvider);
    final bgSync = ref.watch(backgroundSyncEnabledProvider);
    final name = resolveDeviceName(paired, ref.watch(_deviceNameOverride));
    final syncState = ref.watch(syncStateProvider);
    final style = ref.watch(gaugeStyleProvider);

    return ScreenScaffold(
      title: 'Device',
      subtitle: _connLabel(conn),
      children: [
        // ── Bluetooth-off banner (on-device only; tests emit adapter ON) ─────
        if (!adapterOn) _btOffBanner(context, ref),

        // ── Charge hero ─────────────────────────────────────────────────────
        NoopCard(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Column(
            children: [
              MetricGauge(
                fraction: level,
                ramp: Palette.chargeGradientStops,
                size: 156,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: hasBattery
                      ? [
                          Text('$pct',
                              style: NoopType.number(46).copyWith(
                                color: gaugeCenterColor(style),
                                shadows: gaugeCenterShadows(style),
                              )),
                          Text('%',
                              style: NoopType.subhead.copyWith(
                                  color: gaugeCenterColor(style)
                                      .withValues(alpha: 0.7))),
                        ]
                      : [
                          Text('—',
                              style: NoopType.number(46).copyWith(
                                color: gaugeCenterColor(style),
                                shadows: gaugeCenterShadows(style),
                              )),
                        ],
                ),
              ),
              const SizedBox(height: Metrics.space16),
              Text(name,
                  style: NoopType.title2.copyWith(color: Palette.textPrimary)),
              const SizedBox(height: Metrics.space8),
              // Charging line ONLY when it's actually reported. No reading at all →
              // "Not connected"; a stale (last-known) reading adds an honest "As of X
              // ago" qualifier so the number is never mistaken for live.
              if (!hasBattery)
                Text('Not connected',
                    style:
                        NoopType.subhead.copyWith(color: Palette.textTertiary))
              else ...[
                if (charging != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          charging
                              ? Icons.bolt_rounded
                              : Icons.battery_std_rounded,
                          size: 15,
                          color: charging
                              ? Palette.statusPositive
                              : Palette.textSecondary),
                      const SizedBox(width: 5),
                      Text(charging ? 'Charging' : 'On battery',
                          style: NoopType.subhead.copyWith(
                              color: charging
                                  ? Palette.statusPositive
                                  : Palette.textSecondary)),
                    ],
                  ),
                if (isStale) ...[
                  if (charging != null) const SizedBox(height: 4),
                  Text('As of ${_relativeTime(lastKnown.at)}',
                      style: NoopType.footnote
                          .copyWith(color: Palette.textTertiary)),
                ],
              ],
            ],
          ),
        ),

        // ── Sync progress (only while an offload is running/just ran) ────────
        if (sync != null && sync.phase != 'idle') _syncCard(sync),

        // ── Connection ──────────────────────────────────────────────────────
        // Automatic pairing: the primary action is a single Connect that calls
        // connectRemembered() (auto-uses the remembered band, else a universal
        // auto-detecting scan). No manual WHOOP 4-vs-5 choice — the model is
        // detected from the strap's advertised service. "Scan for straps" opens
        // the picker for first pairing / choosing among multiple straps.
        SettingsGroup('Connection', Palette.metricCyan, [
          ..._connectionTiles(context, ref, conn, linked, busy, paired),
          if (paired != null)
            (r) => SettingsTile(
                  radius: r,
                  icon: Icons.watch_rounded,
                  iconColor: Palette.accent,
                  title: paired.name ?? 'Paired band',
                  detail: _familyLabel(paired.family),
                  trailing: _PillButton(
                    label: 'Forget',
                    color: Palette.statusWarning,
                    onTap: () => _forgetBand(context, ref),
                  ),
                ),
          (r) => SettingsTile(
                radius: r,
                icon: Icons.favorite_rounded,
                iconColor: linked ? Palette.metricRose : Palette.textTertiary,
                title: 'Live heart rate',
                detail: 'Streaming over Bluetooth',
                trailing: Text(
                  linked && liveHr != null ? '$liveHr bpm' : '—',
                  style: NoopType.number(20).copyWith(
                    color: linked && liveHr != null
                        ? Palette.metricRose
                        : Palette.textTertiary,
                  ),
                ),
              ),
        ]),

        // ── Device actions ──────────────────────────────────────────────────
        SettingsGroup('Device', Palette.accent, [
          (r) => SettingsTile(
                radius: r,
                icon: Icons.drive_file_rename_outline_rounded,
                iconColor: Palette.accent,
                title: 'Rename device',
                detail: name,
                trailing: _chevron,
                onTap: () => _rename(context, ref, name),
              ),
          (r) => SettingsTile(
                radius: r,
                icon: Icons.cloud_sync_rounded,
                iconColor: Palette.metricCyan,
                title: 'Sync now',
                detail: _syncDetail(sync, syncState),
                trailing: _chevron,
                onTap: () => _syncNow(context, ref),
              ),
          (r) => SettingsTile(
                radius: r,
                icon: Icons.alarm_rounded,
                iconColor: Palette.metricPurple,
                title: 'Smart alarms',
                detail: 'Wake-by time on the strap',
                trailing: _chevron,
                onTap: () =>
                    Navigator.of(context).push(noopRoute(const AlarmsScreen())),
              ),
          (r) => SettingsTile(
                radius: r,
                icon: Icons.restart_alt_rounded,
                iconColor: Palette.effortColor,
                title: 'Restart strap',
                detail: 'Reboot the band — your data is kept',
                trailing: _chevron,
                onTap: () => _restart(context, ref),
              ),
          (r) => SettingsTile(
                radius: r,
                icon: Icons.system_update_alt_rounded,
                iconColor: Palette.metricPurple,
                title: 'Firmware update',
                detail: 'Coming soon',
                trailing: _chevron,
                onTap: () => noopToast(context, 'Firmware updates — coming soon'),
              ),
        ]),

        // ── Broadcast heart rate ────────────────────────────────────────────
        SettingsGroup('Sharing', Palette.metricRose, [
          (r) => SettingsTile(
                radius: r,
                icon: Icons.favorite_rounded,
                iconColor:
                    broadcast ? Palette.metricRose : Palette.textTertiary,
                title: 'Broadcast heart rate',
                detail:
                    'Re-share your live heart rate over Bluetooth as a standard '
                    'sensor — a treadmill, bike, Zwift or Peloton nearby can '
                    'read it. Local Bluetooth only, nothing leaves your phone.',
                trailing: NoopToggle(
                  value: broadcast,
                  onChanged: (v) => ref
                      .read(hrBroadcastEnabledProvider.notifier)
                      .state = v,
                ),
                below: _StatusDot(
                  label: broadcast
                      ? 'Broadcasting · Standard HR sensor (0x180D)'
                      : 'Off',
                  color:
                      broadcast ? Palette.statusPositive : Palette.textTertiary,
                ),
              ),
        ]),

        // ── Background sync ─────────────────────────────────────────────────
        // Only meaningful with a strap remembered — hidden until one is paired.
        // Toggling persists the choice (Prefs) AND starts/stops the Android
        // foreground service that keeps the strap syncing while backgrounded.
        // The service is a strict no-op off Android (and in tests), so this
        // tile is inert everywhere but a real Android device.
        if (paired != null)
          SettingsGroup('Background', Palette.metricCyan, [
            (r) => SettingsTile(
                  radius: r,
                  icon: Icons.sync_rounded,
                  iconColor: bgSync ? Palette.metricCyan : Palette.textTertiary,
                  title: 'Background sync',
                  detail:
                      'Keep syncing your strap while the app is in the background '
                      '(Android). For reliability, allow NOOP to ignore battery '
                      'optimisation in system settings.',
                  trailing: NoopToggle(
                    value: bgSync,
                    onChanged: (v) => _setBackgroundSync(ref, v),
                  ),
                  below: _StatusDot(
                    label: bgSync ? 'On · syncing in the background' : 'Off',
                    color:
                        bgSync ? Palette.statusPositive : Palette.textTertiary,
                  ),
                ),
          ]),

        // ── Connection log (live scan/connect/offload/disconnect trace) ──────
        const _ConnectionLogSection(),
      ],
    );
  }

  /// The primary connect/disconnect tiles for the Connection group. Automatic
  /// pairing throughout — Connect calls `connectRemembered()` (remembered band or
  /// a universal auto-detecting scan); "Scan for straps" opens the picker for
  /// first pairing / choosing among straps. No manual model choice.
  static List<Widget Function(BorderRadius)> _connectionTiles(
    BuildContext context,
    WidgetRef ref,
    BleConnectionState conn,
    bool linked,
    bool busy,
    PairedStrap? paired,
  ) {
    if (linked || busy) {
      return [
        (r) => SettingsTile(
              radius: r,
              icon: Icons.bluetooth_connected_rounded,
              iconColor: _connColor(conn),
              title: linked ? 'Disconnect' : 'Cancel scan',
              detail:
                  linked ? 'Tap to drop the Bluetooth link' : 'Tap to stop',
              below:
                  _StatusDot(label: _connLabel(conn), color: _connColor(conn)),
              onTap: () => _toggleConnection(context, ref),
            ),
      ];
    }
    // Idle. Connect (auto) is primary when a band is remembered; otherwise the
    // scan picker is the way to pair the first strap.
    if (paired != null) {
      return [
        (r) => SettingsTile(
              radius: r,
              icon: Icons.bluetooth_rounded,
              iconColor: _connColor(conn),
              title: 'Connect',
              detail: 'Reconnect to ${paired.name ?? 'your band'} — automatic',
              below:
                  _StatusDot(label: _connLabel(conn), color: _connColor(conn)),
              onTap: () => _connect(context, ref),
            ),
        (r) => SettingsTile(
              radius: r,
              icon: Icons.bluetooth_searching_rounded,
              iconColor: Palette.textSecondary,
              title: 'Scan for straps',
              detail: 'Pair a different WHOOP nearby',
              trailing: _chevron,
              onTap: () => _openScanPicker(context, ref),
            ),
      ];
    }
    return [
      (r) => SettingsTile(
            radius: r,
            icon: Icons.bluetooth_searching_rounded,
            iconColor: _connColor(conn),
            title: 'Scan for straps',
            detail: 'Find your WHOOP nearby and pair it — the model is detected '
                'automatically',
            below: _StatusDot(label: _connLabel(conn), color: _connColor(conn)),
            onTap: () => _openScanPicker(context, ref),
          ),
    ];
  }

  /// The remembered band's model label ("WHOOP 4.0" / "WHOOP 5·MG").
  static String _familyLabel(DeviceFamily f) =>
      f == DeviceFamily.whoop5 ? 'WHOOP 5·MG' : 'WHOOP 4.0';

  /// Resolve the device display name. A manual rename [override] wins, then the strap's
  /// own REAL advertised name, then its family label, and only "WHOOP" when nothing at
  /// all is known — never a hardcoded "Band 4".
  static String resolveDeviceName(PairedStrap? paired, String? override) =>
      override ??
      paired?.name ??
      (paired == null ? null : _familyLabel(paired.family)) ??
      'WHOOP';

  /// Forget the remembered band: clear it from Prefs (via [forgetPairedStrap]) so
  /// the screen returns to the un-paired "Scan for straps" state. Drops any live
  /// link first so we don't keep talking to a band the user just un-paired.
  static Future<void> _forgetBand(BuildContext context, WidgetRef ref) async {
    await ref.read(whoopBleClientProvider).disconnect();
    await forgetPairedStrap(ref);
    if (!context.mounted) return;
    noopToast(context, 'Band forgotten');
  }

  /// Flip the background-sync preference: update the provider (so the tile
  /// reflects it immediately), persist the explicit choice to [Prefs], and
  /// start/stop the Android foreground service accordingly. The service is a
  /// strict no-op off Android and in tests, so this stays inert there.
  static void _setBackgroundSync(WidgetRef ref, bool value) {
    ref.read(backgroundSyncEnabledProvider.notifier).state = value;
    unawaited(Prefs.instance.setBackgroundSyncEnabled(value));
    final service = ref.read(backgroundSyncServiceProvider);
    unawaited(value ? service.start() : service.stop());
  }

  /// Automatic connect: `connectRemembered()` reconnects the remembered band, or
  /// runs a universal auto-detecting scan when nothing is remembered. Surfaces the
  /// transport's own error honestly (e.g. no BLE off-device).
  static Future<void> _connect(BuildContext context, WidgetRef ref) async {
    final client = ref.read(whoopBleClientProvider);
    noopToast(context, 'Connecting…');
    await client.connectRemembered();
    if (!context.mounted) return;
    final err = client.lastError;
    if (err != null) noopToast(context, err, kind: ToastKind.warning);
  }

  static Widget get _chevron =>
      Icon(Icons.chevron_right_rounded, color: Palette.textTertiary, size: 20);

  /// True once the link is up (connected or actively offloading).
  static bool _isLinked(BleConnectionState s) =>
      s == BleConnectionState.connected || s == BleConnectionState.syncing;

  /// Whether an action is in flight (scan/connect/sync) — connect is a no-op.
  static bool _isBusy(BleConnectionState s) =>
      s == BleConnectionState.scanning ||
      s == BleConnectionState.connecting ||
      s == BleConnectionState.syncing;

  static String _connLabel(BleConnectionState s) => switch (s) {
        BleConnectionState.idle => 'Not connected',
        BleConnectionState.scanning => 'Scanning…',
        BleConnectionState.connecting => 'Connecting…',
        BleConnectionState.connected => 'Connected',
        BleConnectionState.syncing => 'Syncing…',
      };

  static Color _connColor(BleConnectionState s) => switch (s) {
        BleConnectionState.connected => Palette.statusPositive,
        BleConnectionState.syncing => Palette.metricCyan,
        BleConnectionState.scanning ||
        BleConnectionState.connecting =>
          Palette.statusWarning,
        BleConnectionState.idle => Palette.textTertiary,
      };

  /// The "Sync now" tile subtitle. A live offload wins; otherwise the persisted
  /// [SyncState] drives a real "Last synced &lt;relative&gt;" (+ the last record count
  /// when known), or an honest "Never synced" before any offload has completed.
  static String _syncDetail(SyncProgress? sync, SyncState syncState) {
    if (sync != null && sync.phase != 'idle') {
      return 'Synced ${sync.recordsPersisted} records · ${sync.phase}';
    }
    final at = syncState.lastSyncAt;
    if (at == null) return 'Never synced';
    final rel = _relativeStamp(at);
    final count = syncState.recordCount;
    if (count != null && count > 0) {
      return 'Last synced $rel · ${Fmt.intComma(count)} records';
    }
    return 'Last synced $rel';
  }

  /// A relative day + the clock TIME ("just now · 07:42" / "2 days ago · 23:15"), so
  /// the sync line carries the time-of-day, not only the date. Uses the real DateTime.
  static String _relativeStamp(DateTime t) => '${_relativeTime(t)} · ${Fmt.clock(t)}';

  /// A compact human relative time ("just now" / "2 minutes ago" / "3 days ago").
  /// Local helper — Fmt has no relative formatter and format.dart is out of scope
  /// for this change. A future timestamp (clock skew) reads as "just now".
  static String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes.clamp(1, 59);
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d day${d == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 30) {
      final w = diff.inDays ~/ 7;
      return '$w week${w == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 365) {
      final mo = diff.inDays ~/ 30;
      return '$mo month${mo == 1 ? '' : 's'} ago';
    }
    final y = diff.inDays ~/ 365;
    return '$y year${y == 1 ? '' : 's'} ago';
  }

  /// A prominent "Bluetooth is off" card with a best-effort "Turn on" action.
  /// Only rendered on-device when the adapter reports OFF (tests emit ON).
  Widget _btOffBanner(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.only(bottom: Metrics.space16),
        child: NoopCard(
          bordered: false,
          accent: Palette.statusWarning,
          child: Row(
            children: [
              IconChip(Icons.bluetooth_disabled_rounded,
                  color: Palette.statusWarning),
              const SizedBox(width: Metrics.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bluetooth is off',
                        style: NoopType.headline
                            .copyWith(color: Palette.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Turn it on to find and sync your strap.',
                        style: NoopType.caption
                            .copyWith(color: Palette.textTertiary)),
                  ],
                ),
              ),
              const SizedBox(width: Metrics.space12),
              _PillButton(
                label: 'Turn on',
                color: Palette.statusWarning,
                onTap: () => _turnOnBluetooth(context, ref),
              ),
            ],
          ),
        ),
      );

  /// Best-effort power-on: `connect()` turns the adapter on first (Android) then
  /// scans; off Android it surfaces a clear "turn it on" error we relay honestly.
  Future<void> _turnOnBluetooth(BuildContext context, WidgetRef ref) async {
    noopToast(context, 'Turning Bluetooth on…');
    // connectRemembered() turns the adapter on first (Android) then reconnects the
    // remembered band, or runs a universal auto-detecting scan when none is remembered.
    await ref.read(whoopBleClientProvider).connectRemembered();
    if (!context.mounted) return;
    final err = ref.read(whoopBleClientProvider).lastError;
    if (err != null) noopToast(context, err, kind: ToastKind.warning);
  }

  /// The live-progress card for a running/just-finished historical offload —
  /// packet count, which day is decoding, a percent bar and the banked span, all
  /// straight from [syncProgressProvider]. Hidden while phase == 'idle'.
  Widget _syncCard(SyncProgress sync) {
    final complete = sync.phase == 'complete';
    final current = sync.currentTsMs;
    final oldest = sync.oldestTsMs;
    final newest = sync.newestTsMs;
    final percent = sync.percent;
    DateTime at(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);
    return Padding(
      padding: const EdgeInsets.only(bottom: Metrics.space16),
      child: NoopCard(
        bordered: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconChip(Icons.cloud_sync_rounded, color: Palette.metricCyan),
                const SizedBox(width: Metrics.space12),
                Expanded(
                  child: Text(complete ? 'Sync complete' : 'Syncing strap',
                      style: NoopType.headline
                          .copyWith(color: Palette.textPrimary)),
                ),
                Text(complete ? 'Complete' : 'Offloading…',
                    style:
                        NoopType.caption.copyWith(color: Palette.metricCyan)),
              ],
            ),
            const SizedBox(height: Metrics.space12),
            Text('${Fmt.intComma(sync.recordsPersisted)} packets synced',
                style:
                    NoopType.number(22).copyWith(color: Palette.textPrimary)),
            if (current != null) ...[
              const SizedBox(height: 2),
              Text(
                  'Syncing ${Fmt.longDate(at(current))} · ${Fmt.clock(at(current))}',
                  style:
                      NoopType.caption.copyWith(color: Palette.textTertiary)),
            ],
            if (percent != null) ...[
              const SizedBox(height: Metrics.space12),
              Row(
                children: [
                  Expanded(child: _ProgressBar(fraction: percent)),
                  const SizedBox(width: Metrics.space12),
                  Text('${(percent * 100).round()}%',
                      style: NoopType.captionNumber
                          .copyWith(color: Palette.textSecondary)),
                ],
              ),
            ] else if (!complete) ...[
              const SizedBox(height: Metrics.space12),
              const _ProgressBar(fraction: null),
            ],
            if (oldest != null && newest != null) ...[
              const SizedBox(height: Metrics.space8),
              Text(
                  '${Fmt.shortDate(at(oldest))} – ${Fmt.shortDate(at(newest))}',
                  style:
                      NoopType.caption.copyWith(color: Palette.textTertiary)),
            ],
          ],
        ),
      ),
    );
  }

  /// Open the live device picker: a sheet driven by [strapScanProvider] (watching
  /// it starts the scan) that lists discovered straps to tap. Tapping a strap calls
  /// `connectToStrap`, which auto-detects the picked strap's family — no manual model
  /// choice. Used for first pairing / choosing among multiple straps.
  static Future<void> _openScanPicker(
      BuildContext context, WidgetRef ref) async {
    await showNoopSheet<void>(
      context,
      title: 'Scan for straps',
      child: _StrapPicker(
        onPick: (strap) async {
          noopToast(context, 'Connecting to ${strap.name}…');
          await ref.read(whoopBleClientProvider).connectToStrap(strap);
          if (!context.mounted) return;
          final err = ref.read(whoopBleClientProvider).lastError;
          if (err != null) noopToast(context, err, kind: ToastKind.warning);
        },
      ),
    );
  }

  /// Intentionally drop the link (or cancel an in-flight scan). Off-device the
  /// transport surfaces `lastError` (no BLE) — we relay it honestly.
  static Future<void> _toggleConnection(
      BuildContext context, WidgetRef ref) async {
    final client = ref.read(whoopBleClientProvider);
    await client.disconnect();
    if (!context.mounted) return;
    noopToast(context, 'Disconnected');
  }

  /// Sync now: connect if idle, otherwise force a resync (drop + reconnect so a
  /// fresh offload runs). Surfaces the transport's own error/progress honestly.
  Future<void> _syncNow(BuildContext context, WidgetRef ref) async {
    final client = ref.read(whoopBleClientProvider);
    final conn =
        ref.read(bleConnectionProvider).value ?? BleConnectionState.idle;
    if (conn != BleConnectionState.idle) {
      await client.disconnect();
    }
    if (!context.mounted) return;
    noopToast(context, 'Syncing…');
    await client.connectRemembered();
    if (!context.mounted) return;
    final err = client.lastError;
    if (err != null) {
      noopToast(context, err, kind: ToastKind.warning);
      return;
    }
    // The real "last synced" time is banked by the sync-state listener when the
    // offload actually reaches phase == 'complete' (see whoop_providers.dart) — no
    // optimistic wall-clock stamp here, so the tile never claims a sync that a
    // no-device / failed offload did not really finish.
    noopToast(context, 'Syncing…', kind: ToastKind.success);
  }

  /// Confirmation-gated strap reboot (ryanbr #166). Non-destructive — stored
  /// data is kept. In this replay build there is no live BLE link, so the flow
  /// surfaces the same UX (confirm → "Reconnecting…" → back to Active) without a
  /// real reboot command going out.
  Future<void> _restart(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.fillRaised,
        title: Text('Restart strap?',
            style: NoopType.title2.copyWith(color: Palette.textPrimary)),
        content: Text(
          'The band reboots and reconnects in a few seconds. Your stored data '
          'is kept — nothing is erased.',
          style: NoopType.body.copyWith(color: Palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: NoopType.body.copyWith(color: Palette.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    noopToast(context, 'Reconnecting…');
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!context.mounted) return;
    noopToast(context, 'Strap restarted · Active', kind: ToastKind.success);
  }

  Future<void> _rename(
      BuildContext context, WidgetRef ref, String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.fillRaised,
        title: Text('Rename device',
            style: NoopType.title2.copyWith(color: Palette.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: NoopType.body.copyWith(color: Palette.textPrimary),
          decoration: const InputDecoration(hintText: 'Device name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style:
                      NoopType.body.copyWith(color: Palette.textSecondary))),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      ref.read(_deviceNameOverride.notifier).state = result;
      unawaited(Prefs.instance.setDeviceNameOverride(result));
    }
  }
}

/// A coloured status dot + label — the live line under the connection and
/// broadcast tiles (e.g. "Connected" / "Broadcasting · Standard HR sensor").
class _StatusDot extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: NoopType.caption.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// A small tinted pill action button (used by the Bluetooth-off banner).
class _PillButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PillButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(Metrics.cornerPill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Metrics.space14, vertical: Metrics.space8),
            child: Text(label,
                style: NoopType.footnote
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}

/// The live connection-log section — a collapsible (default collapsed) NoopCard
/// under a coloured group header that lists the recent [ConnLogEntry] lines
/// newest-first, each as "HH:mm:ss · message". This is the surface the user
/// watches on real hardware to see the link drop / reconnect / actually sync.
///
/// Driven by [connectionLogProvider], which is inert until the client logs its
/// first line, so with no device it honestly shows "No activity yet".
class _ConnectionLogSection extends ConsumerStatefulWidget {
  const _ConnectionLogSection();

  @override
  ConsumerState<_ConnectionLogSection> createState() =>
      _ConnectionLogSectionState();
}

class _ConnectionLogSectionState extends ConsumerState<_ConnectionLogSection> {
  bool _expanded = false;

  /// "HH:mm:ss" for a log entry — Fmt.clock gives HH:mm; append the seconds.
  static String _time(DateTime t) =>
      '${Fmt.clock(t)}:${t.second.toString().padLeft(2, '0')}';

  Future<void> _copy(List<ConnLogEntry> entries) async {
    final text = entries
        .map((e) => '${_time(e.ts)} · ${e.message}')
        .join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    noopToast(context, 'Log copied');
  }

  @override
  Widget build(BuildContext context) {
    // newest-last from the client → reverse for newest-first display.
    final entries =
        (ref.watch(connectionLogProvider).value ?? const <ConnLogEntry>[])
            .reversed
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GroupHeader('Connection log', Palette.metricPurple),
        NoopCard(
          bordered: false,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row: toggles expansion; shows the entry count + a copy
              // action when there is something to copy.
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Metrics.space14,
                        vertical: Metrics.space12),
                    child: Row(
                      children: [
                        IconChip(Icons.receipt_long_rounded,
                            color: Palette.metricPurple),
                        const SizedBox(width: Metrics.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Connection log',
                                  style: NoopType.body.copyWith(
                                      color: Palette.textPrimary,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(
                                  entries.isEmpty
                                      ? 'No activity yet'
                                      : '${entries.length} events · newest first',
                                  style: NoopType.caption.copyWith(
                                      color: Palette.textTertiary)),
                            ],
                          ),
                        ),
                        if (entries.isNotEmpty) ...[
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.copy_rounded,
                                size: 18, color: Palette.textTertiary),
                            onPressed: () => _copy(entries),
                          ),
                        ],
                        Icon(
                            _expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: Palette.textTertiary,
                            size: 22),
                      ],
                    ),
                  ),
                ),
              ),
              if (_expanded) ...[
                Divider(
                    height: 1, thickness: 1, color: Palette.fillInset),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Metrics.space14,
                      Metrics.space12, Metrics.space14, Metrics.space14),
                  child: entries.isEmpty
                      ? Text('No activity yet',
                          style: NoopType.footnote
                              .copyWith(color: Palette.textTertiary))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final e in entries) _logRow(e),
                          ],
                        ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _logRow(ConnLogEntry e) => Padding(
        padding: const EdgeInsets.only(bottom: Metrics.space8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_time(e.ts),
                style: NoopType.captionNumber
                    .copyWith(color: Palette.textSecondary)),
            const SizedBox(width: Metrics.space8),
            Text('·',
                style:
                    NoopType.caption.copyWith(color: Palette.textTertiary)),
            const SizedBox(width: Metrics.space8),
            Expanded(
              child: Text(e.message,
                  style:
                      NoopType.caption.copyWith(color: Palette.textSecondary)),
            ),
          ],
        ),
      );
}

/// A slim token-styled progress fill. [fraction] null → indeterminate.
class _ProgressBar extends StatelessWidget {
  final double? fraction;
  const _ProgressBar({required this.fraction});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(Metrics.cornerXs),
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: Metrics.progressHeight,
          backgroundColor: Palette.fillInset,
          valueColor: AlwaysStoppedAnimation<Color>(Palette.metricCyan),
        ),
      );
}

/// The live scan picker body: watching [strapScanProvider] starts a scan and
/// pushes discovered straps; a spinner runs while scanning, an empty state shows
/// until one is found. Tapping a strap connects to it and auto-detects its family —
/// there is no manual model choice.
class _StrapPicker extends ConsumerWidget {
  final void Function(DiscoveredStrap) onPick;
  const _StrapPicker({required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final straps = ref.watch(strapScanProvider).value ?? const <DiscoveredStrap>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Palette.accent),
            ),
            const SizedBox(width: Metrics.space10),
            Text('Scanning nearby…',
                style:
                    NoopType.footnote.copyWith(color: Palette.textTertiary)),
          ],
        ),
        const SizedBox(height: Metrics.space14),
        if (straps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Metrics.space20),
            child: Center(
              child: Text('No straps found yet — keep the strap close.',
                  style:
                      NoopType.subhead.copyWith(color: Palette.textTertiary)),
            ),
          )
        else
          for (final strap in straps) ...[
            _strapRow(context, strap),
            const SizedBox(height: Metrics.space8),
          ],
      ],
    );
  }

  Widget _strapRow(BuildContext context, DiscoveredStrap strap) => Material(
        color: Palette.fillRaised,
        borderRadius: BorderRadius.circular(Metrics.cornerLarge),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            onPick(strap);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Metrics.space14, vertical: Metrics.space12),
            child: Row(
              children: [
                Icon(Icons.watch_rounded, size: 20, color: Palette.accent),
                const SizedBox(width: Metrics.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strap.name,
                          style: NoopType.body.copyWith(
                              color: Palette.textPrimary,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                          strap.family == DeviceFamily.whoop5
                              ? 'WHOOP 5 · MG'
                              : 'WHOOP 4',
                          style: NoopType.caption
                              .copyWith(color: Palette.textTertiary)),
                    ],
                  ),
                ),
                const SizedBox(width: Metrics.space10),
                _SignalBars(rssi: strap.rssi),
              ],
            ),
          ),
        ),
      );

}

/// A 4-bar signal-strength glyph derived from a strap's advertised RSSI (dBm).
class _SignalBars extends StatelessWidget {
  final int rssi;
  const _SignalBars({required this.rssi});

  int get _level {
    if (rssi >= -55) return 4;
    if (rssi >= -67) return 3;
    if (rssi >= -78) return 2;
    if (rssi >= -90) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final lvl = _level;
    final color = lvl >= 3
        ? Palette.statusPositive
        : (lvl >= 2 ? Palette.statusWarning : Palette.statusCritical);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 4; i++) ...[
          Container(
            width: 4,
            height: 6.0 + i * 3,
            decoration: BoxDecoration(
              color: i < lvl ? color : Palette.fillInset,
              borderRadius: BorderRadius.circular(Metrics.cornerXs),
            ),
          ),
          if (i != 3) const SizedBox(width: 2),
        ],
      ],
    );
  }
}
