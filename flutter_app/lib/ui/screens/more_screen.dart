import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/behavior.dart';
import '../components/cards.dart';
import '../components/common.dart';
import '../components/scaffold.dart';
import '../theme/metrics.dart';
import '../theme/palette.dart';
import 'health_screen.dart';
import 'settings_screen.dart';
import 'workouts_screen.dart';

/// The "More" tab — grouped, sectioned navigation into the deeper screens.
/// Mirrors MoreScreen. Live destinations open; not-yet-ported ones show a
/// "coming soon" toast so the shell stays coherent.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(Widget screen) =>
        Navigator.of(context).push(noopRoute(Scaffold(body: screen)));
    void soon(String name) => noopToast(context, '$name — coming soon');

    return ScreenScaffold(
      title: 'More',
      children: [
        _Group('Body', [
          _Item(Icons.fitness_center_rounded, 'Workouts', Palette.effortColor,
              () => open(const WorkoutsScreen())),
          _Item(Icons.monitor_heart_rounded, 'Health', Palette.metricRose,
              () => open(const HealthScreen())),
          _Item(Icons.self_improvement_rounded, 'Breathe', Palette.metricCyan,
              () => soon('Breathe')),
          _Item(Icons.bolt_rounded, 'Stress', Palette.stressColor, () => soon('Stress')),
        ]),
        _Group('Insights', [
          _Item(Icons.auto_awesome_rounded, 'Coach', Palette.gold, () => soon('Coach')),
          _Item(Icons.insights_rounded, 'Insights', Palette.chargeColor, () => soon('Insights')),
          _Item(Icons.compare_arrows_rounded, 'Compare', Palette.metricPurple,
              () => soon('Compare')),
        ]),
        _Group('Data', [
          _Item(Icons.devices_other_rounded, 'Devices', Palette.accent, () => soon('Devices')),
          _Item(Icons.cloud_sync_rounded, 'Backup & sync', Palette.metricCyan,
              () => soon('Backup & Sync')),
          _Item(Icons.favorite_rounded, 'Apple Health', Palette.metricRose,
              () => soon('Apple Health')),
        ]),
        _Group('App', [
          _Item(Icons.settings_rounded, 'Settings', Palette.textSecondary,
              () => open(const SettingsScreen())),
          _Item(Icons.notifications_rounded, 'Notifications', Palette.metricAmber,
              () => soon('Notifications')),
          _Item(Icons.favorite_border_rounded, 'Support NOOP', Palette.statusCritical,
              () => soon('Support')),
        ]),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<_Item> items;
  const _Group(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        NoopCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                items[i],
                if (i != items.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Metrics.cardPadding),
                    child: const Hairline(),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Item(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Metrics.cardPadding, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(Metrics.cornerSm),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: Metrics.space12),
              Expanded(
                child: Text(label,
                    style: NoopType.body.copyWith(color: Palette.textPrimary)),
              ),
              Icon(Icons.chevron_right_rounded, color: Palette.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
