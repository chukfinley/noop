import 'dart:ui' show ImageFilter;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/shared/widgets/coming_soon.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/features/today/presentation/today_screen.dart';
import 'package:noop/features/trends/presentation/trends_screen.dart';
import 'package:noop/features/sleep/presentation/sleep_screen.dart';
import 'package:noop/features/settings/presentation/settings_screen.dart';

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
  bool _reverse = false;
  bool _collapsed = false; // nav bar shrinks (labels hide) on scroll-down

  void _select(int i) => setState(() {
        _reverse = i < _index; // going to an earlier tab → slide back
        _index = i;
        _collapsed = false; // always show the full bar when switching tabs
      });

  bool _onScroll(UserScrollNotification n) {
    if (n.depth != 0) return false; // only the page's primary scroll view
    final dir = n.direction;
    if (dir == ScrollDirection.reverse && !_collapsed) {
      setState(() => _collapsed = true);
    } else if (dir == ScrollDirection.forward && _collapsed) {
      setState(() => _collapsed = false);
    }
    return false;
  }

  static const _tabs = [
    _Dest(Icons.today_outlined, Icons.today_rounded, 'Today'),
    _Dest(Icons.trending_up_outlined, Icons.trending_up_rounded, 'Trends'),
    _Dest(Icons.bedtime_outlined, Icons.bedtime_rounded, 'Sleep'),
    _Dest(Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  static const _pages = [
    TodayScreen(),
    TrendsScreen(),
    SleepScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScroll,
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 400),
          reverse: _reverse,
          transitionBuilder: (child, primary, secondary) => SharedAxisTransition(
            animation: primary,
            secondaryAnimation: secondary,
            transitionType: SharedAxisTransitionType.horizontal,
            fillColor: Colors.transparent,
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey<int>(_index),
            child: _pages[_index],
          ),
        ),
      ),
      bottomNavigationBar: _SlideBar(
        tabs: _tabs,
        index: _index,
        collapsed: _collapsed,
        onTap: _select,
        onAdd: () => _showLogWeight(context),
      ),
    );
  }

  void _showLogWeight(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      // Very light scrim so the page genuinely shows through the frosted glass
      // instead of the panel reading as a flat dark slab.
      barrierColor: Colors.black.withValues(alpha: 0.08),
      builder: (_) => const _LogWeightSheet(),
    );
  }
}

/// A frosted-glass bottom sheet — same material language as the nav bar. The
/// quick-add actions (workout · weight · journal) have no real capture source
/// yet, so each is shown as an inert "coming soon" tile rather than writing
/// fabricated entries.
class _LogWeightSheet extends StatelessWidget {
  const _LogWeightSheet();

  /// A translucent inner tile — the glass-on-glass surface used for each action.
  BoxDecoration _tileBox(Color onGlass) => BoxDecoration(
        color: onGlass.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(Metrics.cornerLarge),
        border: Border.all(color: onGlass.withValues(alpha: 0.10), width: 1),
      );

  /// A square, non-interactive placeholder tile — icon, label and a compact
  /// "SOON" badge, muted so it reads as planned rather than active.
  Widget _tile(Color onGlass,
          {required IconData icon, required String label}) =>
      Container(
        decoration: _tileBox(onGlass),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: onGlass.withValues(alpha: 0.55), size: 26),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: NoopType.footnote
                    .copyWith(color: onGlass.withValues(alpha: 0.6))),
            const SizedBox(height: 10),
            ComingSoonBadge(compact: true, onColor: onGlass),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onGlass = Palette.isLight ? Palette.textPrimary : Colors.white;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Metrics.cornerSheet),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(Metrics.cornerSheet),
              border: Border.all(
                  color: onGlass.withValues(alpha: 0.10), width: 1),
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Centred title (no grab handle, no close — swipe/tap-away to
                  // dismiss).
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Center(
                      child: Text('Add to today',
                          style: NoopType.headline.copyWith(color: onGlass)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Center(
                      child: Text('Quick-add is coming soon',
                          style: NoopType.footnote.copyWith(
                              color: onGlass.withValues(alpha: 0.6))),
                    ),
                  ),
                  // Three equal placeholder tiles: workout · weight · journal.
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _tile(onGlass,
                              icon: Icons.fitness_center_rounded,
                              label: 'Workout'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _tile(onGlass,
                              icon: Icons.monitor_weight_rounded,
                              label: 'Weight'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _tile(onGlass,
                              icon: Icons.edit_note_rounded,
                              label: 'Journal'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dest {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _Dest(this.icon, this.activeIcon, this.label);
}

class _SlideBar extends StatelessWidget {
  final List<_Dest> tabs;
  final int index;
  final bool collapsed;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;
  const _SlideBar({
    required this.tabs,
    required this.index,
    required this.collapsed,
    required this.onTap,
    required this.onAdd,
  });

  static const _fullH = 64.0;
  static const _collapsedH = 52.0;
  double get _height => collapsed ? _collapsedH : _fullH;
  static const _slide = Duration(milliseconds: 260);
  static const _curve = Curves.easeOutCubic;
  // Subtle highlight (like Plane) — a soft lift off the bar, not a colour. Dark
  // on the white light-mode bar, light on the dark bar.
  static Color get _highlight => Palette.isLight
      ? Colors.black.withValues(alpha: 0.06)
      : const Color(0x24FFFFFF);
  // Active icon / the "+" glyph — near-black on the light bar, white on the dark.
  static Color get _onBar => Palette.isLight ? Palette.textPrimary : Colors.white;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
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
            color: Colors.black.withValues(alpha: Palette.isLight ? 0.10 : 0.34),
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
    return AnimatedContainer(
      duration: _slide,
      curve: _curve,
      height: _height,
      decoration: _solid(scheme, radius),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Stack(
          alignment: Alignment.center,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: _slide,
              child: Icon(
                active ? tabs[i].activeIcon : tabs[i].icon,
                key: ValueKey(active),
                size: 22,
                color: active ? _onBar : scheme.onSurfaceVariant,
              ),
            ),
            // The label collapses to nothing on scroll-down, leaving just icons.
            AnimatedSize(
              duration: _slide,
              curve: _curve,
              child: collapsed
                  ? const SizedBox(width: 0, height: 0)
                  : Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        tabs[i].label,
                        style: NoopType.footnote.copyWith(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                          color: active ? _onBar : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ],
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
          child: AnimatedContainer(
            duration: _slide,
            curve: _curve,
            width: _height,
            height: _height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Same solid fill as the bar so nothing shows through it.
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.93),
              shape: BoxShape.circle,
              border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: Palette.isLight ? 0.10 : 0.34),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.add_rounded, size: 28, color: _onBar),
          ),
        ),
      );
}
