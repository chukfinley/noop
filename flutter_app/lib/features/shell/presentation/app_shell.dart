import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/state/providers.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/features/nutrition/presentation/nutrition_screen.dart';
import 'package:noop/features/today/presentation/today_screen.dart';
import 'package:noop/features/trends/presentation/trends_screen.dart';
import 'package:noop/shared/widgets/backgrounds.dart';
import 'package:noop/shared/widgets/behavior.dart';
import 'package:noop/features/sleep/presentation/sleep_screen.dart';
import 'package:noop/features/settings/presentation/settings_screen.dart';

// ── Shared bar language (no borders anywhere) ───────────────────────────────
// The nav bar, the centre "+"/"×" and the quick-add panel all share the same
// lightly-translucent fill, the same "selected" highlight tint and the same
// on-bar ink, so the whole cluster reads as one material.
Color _barFill(ColorScheme scheme) =>
    scheme.surfaceContainerHigh.withValues(alpha: 0.93);
Color get _barHighlight => Palette.isLight
    ? Colors.black.withValues(alpha: 0.06)
    : const Color(0x24FFFFFF);
Color get _barOnColor => Palette.isLight ? Palette.textPrimary : Colors.white;

/// The app shell — a floating, solid black-grey pill of tabs with the "+" docked
/// dead-centre, over an [IndexedStack] body. Tapping "+" raises a quick-add grid
/// panel *above* the bar and morphs the "+" into an "×"; the bar itself stays
/// put and tappable. A single highlight slides horizontally between tabs.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _collapsed = false; // nav bar shrinks (labels hide) on scroll-down
  bool _addOpen = false; // quick-add panel raised

  // Drives the swipeable tab pager. Horizontal swipes move between tabs; nav-bar
  // taps (and screens that request a tab, via selectedTabProvider) animate it.
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Nav-bar tap → move to tab [i] (the pager animates via the provider listener).
  void _select(int i) {
    ref.read(selectedTabProvider.notifier).state = i;
    setState(() {
      _collapsed = false; // always show the full bar when switching tabs
      _addOpen = false; // and close the quick-add panel
    });
  }

  /// Swipe settled on a new page → keep the shared tab state in sync.
  void _onPageChanged(int i) {
    ref.read(selectedTabProvider.notifier).state = i;
    setState(() {
      _collapsed = false;
      _addOpen = false;
    });
  }

  void _toggleAdd() => setState(() => _addOpen = !_addOpen);
  void _closeAdd() {
    if (_addOpen) setState(() => _addOpen = false);
  }

  /// A quick-add tile was tapped: close the panel, then run its flow. Weight is
  /// wired to a real, persisted entry; food/activity are placeholders for now.
  void _handleQuickAdd(String id) {
    _closeAdd();
    if (id == 'weight') _logWeight();
    if (id == 'food') {
      Navigator.of(context).push(noopRoute(const NutritionScreen()));
    }
  }

  /// Enter today's body weight in a frosted, translucent sheet — saved to the
  /// persisted weight log.
  Future<void> _logWeight() async {
    final start = ref.read(weightLogProvider.notifier).latest ??
        ref.read(profileProvider).weightKg;
    final kg = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.14),
      builder: (_) => _WeightSheet(initial: start),
    );
    if (kg != null) {
      ref.read(weightLogProvider.notifier).setForDay(DateTime.now(), kg);
    }
  }

  bool _onScroll(UserScrollNotification n) {
    // Only react to VERTICAL page scrolling (the pager itself scrolls
    // horizontally and must not collapse the bar).
    if (n.metrics.axis != Axis.vertical) return false;
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
    _Dest(Icons.bedtime_outlined, Icons.bedtime_rounded, 'Sleep'),
    _Dest(Icons.trending_up_outlined, Icons.trending_up_rounded, 'Trends'),
    _Dest(Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  static const _pages = [
    TodayScreen(),
    SleepScreen(),
    TrendsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(selectedTabProvider);
    // A screen requested a tab (or a nav tap set it): glide the pager there.
    ref.listen<int>(selectedTabProvider, (_, next) {
      if (_pageController.hasClients &&
          (_pageController.page ?? 0).round() != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
    return PopScope(
      // Back closes the quick-add panel first, before popping the app.
      canPop: !_addOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeAdd();
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            // One shared wallpaper behind all tabs that pans as you swipe — the
            // pages themselves are transparent (ShellWallpaperScope).
            if (ref.watch(wallpaperProvider))
              Positioned.fill(
                child: _PanningWallpaper(
                  controller: _pageController,
                  pageCount: _pages.length,
                ),
              ),
            NotificationListener<UserScrollNotification>(
              onNotification: _onScroll,
              child: ShellWallpaperScope(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  // Calmer horizontal recognition: the pager only claims the
                  // gesture after a clearly horizontal drag, so scrolling down (or
                  // a diagonal flick) no longer flips tabs by accident.
                  physics: const _CalmPagePhysics(),
                  children: _pages,
                ),
              ),
            ),
            // Quick-add overlay sits over the page but *under* the nav bar (which
            // is drawn as bottomNavigationBar), so the "×" stays visible on top.
            _QuickAddOverlay(
              open: _addOpen,
              onClose: _closeAdd,
              onAction: _handleQuickAdd,
            ),
          ],
        ),
        bottomNavigationBar: _SlideBar(
          tabs: _tabs,
          index: index,
          collapsed: _collapsed,
          addOpen: _addOpen,
          onTap: _select,
          onAdd: _toggleAdd,
        ),
      ),
    );
  }
}

/// Page physics that makes horizontal swiping less eager: the pager's drag
/// recognizer must see a more deliberate horizontal motion before it wins the
/// gesture arena, so a mostly-vertical scroll (or a diagonal flick) stays with
/// the list instead of flipping tabs. Snap/settle behaviour is inherited.
class _CalmPagePhysics extends PageScrollPhysics {
  const _CalmPagePhysics({super.parent});

  @override
  _CalmPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _CalmPagePhysics(parent: buildParent(ancestor));

  // Default is a few logical px; raising it means the vertical list (default
  // slop) almost always wins a diagonal gesture, while a clearly sideways swipe
  // still crosses this and pages.
  @override
  double get dragStartDistanceMotionThreshold => 22.0;
}

/// The shared, parallax wallpaper drawn behind the tab pager. It listens to the
/// [PageController] and slides the (slightly over-wide) photo horizontally as you
/// swipe, so the wallpaper reads as one continuous backdrop that moves with you —
/// like a phone home-screen wallpaper spanning multiple pages. A static scrim
/// sits on top so content stays legible.
class _PanningWallpaper extends StatelessWidget {
  final PageController controller;
  final int pageCount;
  const _PanningWallpaper(
      {required this.controller, required this.pageCount});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        double page = 0;
        if (controller.hasClients &&
            controller.position.hasContentDimensions) {
          page = controller.page ?? 0;
        }
        final maxPage = (pageCount - 1).clamp(1, 999).toDouble();
        final t = (page / maxPage).clamp(0.0, 1.0);
        return LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            // Full-width parallax: the wallpaper is [pageCount] screens wide and
            // travels exactly one screen width per tab, so it moves 1:1 with the
            // swipe — a distinct full-screen slice behind each tab, like a phone
            // home-screen wallpaper spanning every page.
            final totalW = w * pageCount;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: -t * (totalW - w),
                  top: 0,
                  bottom: 0,
                  width: totalW,
                  child: const WallpaperImage(),
                ),
                ColoredBox(
                    color: Palette.surfaceBase.withValues(alpha: 0.45)),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Quick-add overlay ───────────────────────────────────────────────────────

/// One quick-add action — a round, border-less tile (the same translucent
/// "selected" fill as the centre button) with a label beneath.
class _AddAction {
  final String id;
  final IconData icon;
  final String label;
  const _AddAction(this.id, this.icon, this.label);
}

const _addActions = <_AddAction>[
  _AddAction('food', Icons.restaurant_rounded, 'Food'),
  _AddAction('weight', Icons.monitor_weight_rounded, 'Weight'),
  _AddAction('activity', Icons.directions_run_rounded, 'Log activity'),
];

/// The raised quick-add panel: a scrim that dims the page and a border-less,
/// *floating* card (margins all round, gap above the bar) carrying a row of
/// square (rounded-rect) actions. Reads as a detached panel that flies up.
class _QuickAddOverlay extends StatelessWidget {
  final bool open;
  final VoidCallback onClose;
  final ValueChanged<String> onAction;
  const _QuickAddOverlay({
    required this.open,
    required this.onClose,
    required this.onAction,
  });

  static const _anim = Duration(milliseconds: 300);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Sit right on the nav bar (bar height + safe area) — low and close, flush
    // to the bar rather than floating high above it.
    final bottomInset = MediaQuery.of(context).padding.bottom + 70;

    return IgnorePointer(
      ignoring: !open,
      child: Stack(
        children: [
          // Scrim — very light, so the page still reads through it.
          GestureDetector(
            onTap: onClose,
            child: AnimatedOpacity(
              opacity: open ? 1 : 0,
              duration: _anim,
              curve: _curve,
              child: Container(color: Colors.black.withValues(alpha: 0.10)),
            ),
          ),
          // The floating panel, sliding up a touch from its resting spot.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset),
              child: AnimatedSlide(
                offset: open ? Offset.zero : const Offset(0, 0.35),
                duration: _anim,
                curve: _curve,
                child: AnimatedOpacity(
                  opacity: open ? 1 : 0,
                  duration: _anim,
                  curve: _curve,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _barFill(scheme),
                      borderRadius: BorderRadius.circular(Metrics.cornerSheet),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                              alpha: Palette.isLight ? 0.14 : 0.42),
                          blurRadius: 34,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        for (var k = 0; k < _addActions.length; k++) ...[
                          if (k != 0) const SizedBox(width: 10),
                          Expanded(child: _action(_addActions[k])),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(_AddAction a) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Metrics.cornerLarge),
          onTap: () => onAction(a.id),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Square (rounded-rect) tile, border-less, in the "selected" fill.
              color: _barHighlight,
              borderRadius: BorderRadius.circular(Metrics.cornerLarge),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(a.icon, size: 26, color: _barOnColor),
                const SizedBox(height: 10),
                Text(
                  a.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      NoopType.footnote.copyWith(color: Palette.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
}

// ── Nav bar ─────────────────────────────────────────────────────────────────

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
  final bool addOpen;
  final ValueChanged<int> onTap;
  final VoidCallback onAdd;
  const _SlideBar({
    required this.tabs,
    required this.index,
    required this.collapsed,
    required this.addOpen,
    required this.onTap,
    required this.onAdd,
  });

  static const _fullH = 64.0;
  static const _collapsedH = 52.0;
  double get _height => collapsed ? _collapsedH : _fullH;
  static const _slide = Duration(milliseconds: 260);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: _bar(scheme),
      ),
    );
  }

  BoxDecoration _solid(ColorScheme scheme, BorderRadius radius) => BoxDecoration(
        // Lightly translucent, no glass, no outline (borders are out everywhere;
        // the soft shadow gives the lift).
        color: _barFill(scheme),
        borderRadius: radius,
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
    final total = n + 1; // tab slots + the centre "+" in its own slot
    final plusSlot = total ~/ 2; // dead centre
    int slotOf(int tab) => tab < plusSlot ? tab : tab + 1;
    // Slot-centre alignment for the sliding highlight over the ACTIVE tab,
    // skipping the "+" slot: -1 (first) … 1 (last).
    final alignX = total <= 1 ? 0.0 : -1 + 2 * slotOf(index) / (total - 1);
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
                widthFactor: 1 / total,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _barHighlight,
                    borderRadius: BorderRadius.circular(Metrics.cornerPill),
                  ),
                ),
              ),
            ),
            // Tabs + the centre "+"/"×" on top; the active tab rides the highlight.
            Row(
              children: [
                for (var s = 0; s < total; s++)
                  Expanded(
                    child: s == plusSlot
                        ? _plusButton(scheme)
                        : _tab(scheme, s < plusSlot ? s : s - 1),
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
                color: active ? _barOnColor : scheme.onSurfaceVariant,
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
                          color: active ? _barOnColor : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// The centre button — the translucent "selected"-looking circle that morphs
  /// between "+" (add) and "×" (close) as the quick-add panel opens. Sized to
  /// fill the bar's inner height, shrinking with it when the bar collapses.
  Widget _plusButton(ColorScheme scheme) {
    final d = _height - 6; // inner height minus the bar's 3px inset
    return Center(
      child: Material(
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
            width: d,
            height: d,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _barHighlight,
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
              duration: _slide,
              transitionBuilder: (child, a) => RotationTransition(
                turns: Tween<double>(begin: 0.6, end: 1).animate(a),
                child: FadeTransition(opacity: a, child: child),
              ),
              child: Icon(
                addOpen ? Icons.close_rounded : Icons.add_rounded,
                key: ValueKey<bool>(addOpen),
                size: 26,
                color: _barOnColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Weight entry ────────────────────────────────────────────────────────────

/// A frosted, translucent weight-entry sheet — a blurred glass panel (no
/// borders) with a big editable value flanked by ± steppers and a Save button.
class _WeightSheet extends StatefulWidget {
  final double initial;
  const _WeightSheet({required this.initial});

  @override
  State<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends State<_WeightSheet> {
  late double _kg = widget.initial.clamp(20.0, 400.0);
  late final TextEditingController _ctrl =
      TextEditingController(text: _fmt(_kg));

  static String _fmt(double v) => v.toStringAsFixed(1);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _bump(double d) {
    final v = double.tryParse(_ctrl.text.trim().replaceAll(',', '.')) ?? _kg;
    setState(() {
      _kg = (v + d).clamp(20.0, 400.0);
      _ctrl.text = _fmt(_kg);
      _ctrl.selection =
          TextSelection.collapsed(offset: _ctrl.text.length);
    });
  }

  void _save() {
    final v = double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    if (v != null && v >= 20 && v <= 400) Navigator.pop(context, v);
  }

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
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(Metrics.cornerSheet),
            ),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Log weight',
                    style: NoopType.headline.copyWith(color: onGlass)),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _StepBtn(
                        icon: Icons.remove_rounded,
                        onTap: () => _bump(-0.1),
                        onGlass: onGlass),
                    SizedBox(
                      width: 128,
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: NoopType.number(36).copyWith(color: onGlass),
                        cursorColor: Palette.accent,
                        onSubmitted: (_) => _save(),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text('kg',
                          style: NoopType.body
                              .copyWith(color: onGlass.withValues(alpha: 0.6))),
                    ),
                    _StepBtn(
                        icon: Icons.add_rounded,
                        onTap: () => _bump(0.1),
                        onGlass: onGlass),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Palette.accent,
                    borderRadius: BorderRadius.circular(Metrics.cornerLarge),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _save,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: _SaveLabel(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveLabel extends StatelessWidget {
  const _SaveLabel();
  @override
  Widget build(BuildContext context) => Text('Save',
      style: NoopType.subhead
          .copyWith(color: Colors.white, fontWeight: FontWeight.w700));
}

/// A round translucent ± stepper for the weight sheet (glass-on-glass, no border).
class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color onGlass;
  const _StepBtn(
      {required this.icon, required this.onTap, required this.onGlass});

  @override
  Widget build(BuildContext context) => Material(
        color: onGlass.withValues(alpha: 0.10),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: onGlass, size: 22),
          ),
        ),
      );
}
