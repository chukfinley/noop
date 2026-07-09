import 'package:flutter/material.dart';

/// MD3-Expressive motion helpers, tuned to the same feel as the nav bar's
/// gliding highlight: emphasized-decelerate entrances and a soft spring on press.

/// Emphasized-decelerate curve — quick to start, long gentle settle. Matches the
/// bar's `easeOutCubic` glide but a touch more expressive.
const Curve kEmphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

/// Fade + horizontal glide entrance: each card slides in from the right (moving
/// right→left into place), delayed by [index] so a column cascades in the same
/// left-right direction as the nav bar's sliding highlight. Plays once.
class Reveal extends StatefulWidget {
  final Widget child;
  final int index;
  final double shift;
  const Reveal({super.key, required this.child, this.index = 0, this.shift = 34});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: kEmphasizedDecelerate);

  @override
  void initState() {
    super.initState();
    // Stagger: cap the delay so long lists still finish promptly.
    final delayMs = (widget.index.clamp(0, 10)) * 55;
    Future<void>.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _t,
        builder: (context, child) => Opacity(
          opacity: _t.value,
          child: Transform.translate(
            // Enters from the right (+x) and slides left to rest at 0.
            offset: Offset((1 - _t.value) * widget.shift, 0),
            child: child,
          ),
        ),
        child: widget.child,
      );
}

/// Wraps a tappable surface so it springs down slightly while pressed, then
/// settles back — the tactile counterpart to the bar's sliding selection.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double pressedScale;
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.pressedScale = 0.97,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: kEmphasizedDecelerate,
        child: widget.child,
      ),
    );
  }
}

/// An [IndexedStack] that slides horizontally each time the selected index
/// changes — the new page glides in from the right when moving to a later tab,
/// from the left when moving back — matching the nav bar's left-right highlight.
/// State of every page is preserved (IndexedStack keeps them all mounted).
class FadeThroughStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  const FadeThroughStack({super.key, required this.index, required this.children});

  @override
  State<FadeThroughStack> createState() => _FadeThroughStackState();
}

class _FadeThroughStackState extends State<FadeThroughStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: kEmphasizedDecelerate);
  // +1 → entered from the right (later tab); -1 → from the left (earlier tab).
  double _dir = 1;

  @override
  void didUpdateWidget(FadeThroughStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _dir = widget.index > old.index ? 1 : -1;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: _t,
          builder: (context, child) => Opacity(
            opacity: 0.25 + 0.75 * _t.value,
            child: Transform.translate(
              offset: Offset(_dir * (1 - _t.value) * constraints.maxWidth * 0.12, 0),
              child: child,
            ),
          ),
          child: IndexedStack(index: widget.index, children: widget.children),
        ),
      );
}
