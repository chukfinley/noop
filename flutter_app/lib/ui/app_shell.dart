import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components/behavior.dart';
import 'components/motion.dart';
import 'theme/metrics.dart';
import 'theme/palette.dart';
import 'screens/today_screen.dart';
import 'screens/trends_screen.dart';
import 'screens/sleep_screen.dart';
import 'screens/more_screen.dart';

/// The app shell — a floating, solid black-grey pill of tabs plus a detached
/// round "+" button, over an [IndexedStack] body. No glass/blur. A single indigo
/// highlight *slides* horizontally from the old tab to the new one, so switching
/// reads as the selection gliding across rather than popping in place.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _tabs = [
    _Dest(Icons.grid_view_outlined, Icons.grid_view_rounded),
    _Dest(Icons.trending_up_outlined, Icons.trending_up_rounded),
    _Dest(Icons.bedtime_outlined, Icons.bedtime_rounded),
    _Dest(Icons.apps_outlined, Icons.apps_rounded),
  ];

  static const _pages = [
    TodayScreen(),
    TrendsScreen(),
    SleepScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: FadeThroughStack(index: _index, children: _pages),
      bottomNavigationBar: _SlideBar(
        tabs: _tabs,
        index: _index,
        onTap: (i) => setState(() => _index = i),
        onAdd: () => _showQuickActions(context),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showNoopSheet<void>(
      context,
      title: 'Quick actions',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final a in const [
            (Icons.fitness_center_rounded, 'Start workout'),
            (Icons.favorite_rounded, 'Live heart rate'),
            (Icons.edit_note_rounded, 'Log journal'),
            (Icons.self_improvement_rounded, 'Breathe'),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(a.$1, color: Palette.accent),
              title: Text(a.$2, style: TextStyle(color: Palette.textPrimary)),
              trailing: Icon(Icons.chevron_right_rounded, color: Palette.textTertiary),
              onTap: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}

class _Dest {
  final IconData icon;
  final IconData activeIcon;
  const _Dest(this.icon, this.activeIcon);
}

class _SlideBar extends StatelessWidget {
  final List<_Dest> tabs;
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;
  const _SlideBar({
    required this.tabs,
    required this.index,
    required this.onTap,
    required this.onAdd,
  });

  static const _height = 64.0;
  static const _slide = Duration(milliseconds: 340);
  static const _curve = Curves.easeOutCubic;
  // Subtle grey highlight (like Plane) — a soft lift off the bar, not a colour.
  static const _highlight = Color(0x24FFFFFF);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Row(
          children: [
            Expanded(child: _bar(scheme)),
            const SizedBox(width: Metrics.space12),
            _addButton(scheme),
          ],
        ),
      ),
    );
  }

  BoxDecoration _solid(ColorScheme scheme, BorderRadius radius) => BoxDecoration(
        // Black-grey, only lightly translucent — plain transparency, no glass.
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.93),
        borderRadius: radius,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      );

  Widget _bar(ColorScheme scheme) {
    final radius = BorderRadius.circular(Metrics.cornerPill);
    final n = tabs.length;
    // Slot-centre alignment for the sliding highlight: -1 (first) … 1 (last).
    final alignX = n <= 1 ? 0.0 : -1 + 2 * index / (n - 1);
    return Container(
      height: _height,
      decoration: _solid(scheme, radius),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Stack(
          children: [
            // The one highlight that glides between tabs.
            AnimatedAlign(
              alignment: Alignment(alignX, 0),
              duration: _slide,
              curve: _curve,
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                // Fills the full inner height so its rounded ends share the bar's
                // curvature and nest concentrically into the corners — an even
                // gap all around, never a mismatched curve at the left/right end.
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _highlight,
                    borderRadius: BorderRadius.circular(Metrics.cornerPill),
                  ),
                ),
              ),
            ),
            // Icons on top; the active one rides the highlight.
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: _tab(scheme, i),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(ColorScheme scheme, int i) {
    final active = i == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(Metrics.cornerPill),
        onTap: () => onTap(i),
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: Center(
          child: AnimatedSwitcher(
            duration: _slide,
            child: Icon(
              active ? tabs[i].activeIcon : tabs[i].icon,
              key: ValueKey(active),
              size: 24,
              color: active ? Colors.white : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _addButton(ColorScheme scheme) => Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onAdd,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          focusColor: Colors.transparent,
          child: Container(
            width: _height,
            height: _height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Outline circle — transparent fill, thin ring (Plane's "+").
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7), width: 1),
            ),
            child: Icon(Icons.add_rounded, size: 28, color: Colors.white),
          ),
        ),
      );
}
