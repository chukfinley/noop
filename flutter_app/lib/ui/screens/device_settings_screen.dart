import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/format.dart';
import '../../state/providers.dart';
import '../components/behavior.dart';
import '../components/cards.dart';
import '../components/controls.dart';
import '../components/metric_gauge.dart';
import '../components/scaffold.dart';
import '../theme/metrics.dart';
import '../theme/palette.dart';

final _deviceName = StateProvider<String>((_) => 'Band 4');
final _lastSync = StateProvider<DateTime?>((_) => null);
final _broadcastHr = StateProvider<bool>((_) => false);

/// Device settings — the strap's charge, sync status, rename, firmware entry and
/// a broadcast-heart-rate switch. Opened from the battery pill on Today. Built
/// entirely from the app's shared shell + components.
class DeviceSettingsScreen extends ConsumerWidget {
  const DeviceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(strapBatteryProvider);
    final pct = (level * 100).round();
    final name = ref.watch(_deviceName);
    final lastSync = ref.watch(_lastSync) ?? DateTime.now();
    final broadcast = ref.watch(_broadcastHr);
    final style = ref.watch(gaugeStyleProvider);
    final charging = pct < 100;

    return ScreenScaffold(
      title: 'Device',
      subtitle: 'Connected',
      children: [
        // ── Charge hero ─────────────────────────────────────────────────────
        NoopCard(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Column(
            children: [
              MetricGauge(
                fraction: level.clamp(0, 1),
                ramp: Palette.chargeGradientStops,
                size: 156,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$pct',
                        style: NoopType.number(46).copyWith(
                          color: gaugeCenterColor(style),
                          shadows: gaugeCenterShadows(style),
                        )),
                    Text('%',
                        style: NoopType.subhead.copyWith(
                            color: gaugeCenterColor(style)
                                .withValues(alpha: 0.7))),
                  ],
                ),
              ),
              const SizedBox(height: Metrics.space16),
              Text(name,
                  style: NoopType.title2.copyWith(color: Palette.textPrimary)),
              const SizedBox(height: Metrics.space8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      charging
                          ? Icons.bolt_rounded
                          : Icons.check_circle_rounded,
                      size: 15,
                      color: Palette.statusPositive),
                  const SizedBox(width: 5),
                  Text(charging ? 'Charging' : 'Fully charged',
                      style: NoopType.subhead
                          .copyWith(color: Palette.statusPositive)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Metrics.space16),

        // ── Actions ─────────────────────────────────────────────────────────
        NoopCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _row(
                icon: Icons.drive_file_rename_outline_rounded,
                color: Palette.accent,
                title: 'Rename device',
                detail: name,
                onTap: () => _rename(context, ref, name),
              ),
              _divider(),
              _row(
                icon: Icons.cloud_sync_rounded,
                color: Palette.metricCyan,
                title: 'Sync now',
                detail: 'Last synced at ${Fmt.clock(lastSync)}',
                onTap: () {
                  ref.read(_lastSync.notifier).state = DateTime.now();
                  noopToast(context, 'Strap synced', kind: ToastKind.success);
                },
              ),
              _divider(),
              _row(
                icon: Icons.system_update_alt_rounded,
                color: Palette.metricPurple,
                title: 'Firmware update',
                detail: 'Coming soon',
                onTap: () =>
                    noopToast(context, 'Firmware updates — coming soon'),
              ),
            ],
          ),
        ),
        const SizedBox(height: Metrics.space16),

        // ── Broadcast heart rate ────────────────────────────────────────────
        NoopCard(
          child: Row(
            children: [
              _chip(Icons.favorite_rounded,
                  broadcast ? Palette.metricRose : Palette.textTertiary),
              const SizedBox(width: Metrics.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Broadcast heart rate',
                        style: NoopType.body.copyWith(
                            color: Palette.textPrimary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('To compatible apps & devices',
                        style: NoopType.caption
                            .copyWith(color: Palette.textTertiary)),
                  ],
                ),
              ),
              const SizedBox(width: Metrics.space12),
              NoopToggle(
                value: broadcast,
                onChanged: (v) => ref.read(_broadcastHr.notifier).state = v,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.only(left: 62),
        child: Divider(
            height: 1,
            thickness: 1,
            color: Palette.hairline.withValues(alpha: 0.6)),
      );

  Widget _chip(IconData icon, Color color) => Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 19, color: color),
      );

  Widget _row({
    required IconData icon,
    required Color color,
    required String title,
    required String detail,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Metrics.space16, vertical: Metrics.space12),
            child: Row(
              children: [
                _chip(icon, color),
                const SizedBox(width: Metrics.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: NoopType.body.copyWith(
                              color: Palette.textPrimary,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NoopType.caption
                              .copyWith(color: Palette.textTertiary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Palette.textTertiary, size: 20),
              ],
            ),
          ),
        ),
      );

  Future<void> _rename(
      BuildContext context, WidgetRef ref, String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.surfaceRaised,
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
                  style: TextStyle(color: Palette.textSecondary))),
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
    if (result != null) ref.read(_deviceName.notifier).state = result;
  }
}
