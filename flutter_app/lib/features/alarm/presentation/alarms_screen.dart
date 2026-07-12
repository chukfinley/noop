import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/data/db/database.dart';
import 'package:noop/features/alarm/state/alarm.dart';
import 'package:noop/shared/widgets/behavior.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/common.dart';
import 'package:noop/shared/widgets/controls.dart';
import 'package:noop/shared/widgets/scaffold.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

/// Smart alarms — set a wake-by time the strap will buzz at. Minimal for now
/// (UI is being rebuilt); the schedule persists and reports honestly that it is
/// queued until a live-BLE bridge can arm the strap.
class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmsProvider).valueOrNull ?? const [];
    return ScreenScaffold(
      title: 'Alarms',
      glow: Palette.effortColor,
      children: [
        NoopCard(
          padding: const EdgeInsets.all(Metrics.space14),
          child: Text(
            'NOOP sets the strap\'s own smart alarm. Without a live strap link '
            'in this build, a new alarm is saved and queued — it arms the next '
            'time the strap connects.',
            style: NoopType.body.copyWith(color: Palette.textSecondary),
          ),
        ),
        const SizedBox(height: Metrics.space16),
        if (alarms.isEmpty)
          NoopCard(
            padding: const EdgeInsets.all(Metrics.space20),
            child: Center(
              child: Text('No alarms yet',
                  style: NoopType.body.copyWith(color: Palette.textTertiary)),
            ),
          )
        else
          for (final a in alarms) ...[
            _AlarmCard(alarm: a),
            const SizedBox(height: Metrics.space10),
          ],
        const SizedBox(height: Metrics.space8),
        NoopButton('Add alarm',
            icon: Icons.add_alarm_rounded,
            onPressed: () => _addAlarm(context, ref)),
      ],
    );
  }

  Future<void> _addAlarm(BuildContext context, WidgetRef ref) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
    );
    if (picked == null) return;
    final id = 'a-${picked.hour}-${picked.minute}-${DateTime.now().microsecondsSinceEpoch}';
    await ref
        .read(alarmServiceProvider)
        .save(id: id, hour: picked.hour, minute: picked.minute);
    if (context.mounted) {
      noopToast(context, 'Alarm queued', kind: ToastKind.success);
    }
  }
}

class _AlarmCard extends ConsumerWidget {
  final Alarm alarm;
  const _AlarmCard({required this.alarm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hh = alarm.hour.toString().padLeft(2, '0');
    final mm = alarm.minute.toString().padLeft(2, '0');
    return NoopCard(
      padding: const EdgeInsets.all(Metrics.space16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$hh:$mm',
                    style: NoopType.number(30)
                        .copyWith(color: Palette.textPrimary)),
                const SizedBox(height: 2),
                Text(alarmStatusLabel(alarm),
                    style: NoopType.caption
                        .copyWith(color: Palette.textTertiary)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                size: 20, color: Palette.textTertiary),
            onPressed: () => ref.read(alarmServiceProvider).delete(alarm.id),
          ),
          const SizedBox(width: Metrics.space4),
          NoopToggle(
            value: alarm.enabled,
            onChanged: (v) => ref.read(alarmServiceProvider).setEnabled(alarm, v),
          ),
        ],
      ),
    );
  }
}
