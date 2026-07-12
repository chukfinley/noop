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
  const Reveal({super.key, required this.child, this.index = 0, this.shift = 46});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: kEmphasizedDecelerate);

  @override
  void initState() {
    super.initState();
    // Stagger: cap the delay so long lists still finish promptly.
    final delayMs = (widget.index.clamp(0, 12)) * 68;
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
        builder: (context, child) {
          final t = _t.value;
          // Enters from the right (+x) with a slight lift and scale-up, settling
          // to rest — a touch more life than a flat slide.
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset((1 - t) * widget.shift, (1 - t) * 14),
              child: Transform.scale(
                scale: 0.965 + 0.035 * t,
                alignment: Alignment.centerLeft,
                child: child,
              ),
            ),
          );
        },
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
