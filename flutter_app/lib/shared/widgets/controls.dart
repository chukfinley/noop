import 'package:flutter/material.dart';

import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

/// One option in a [NoopSegmented] control: a value, a label and an optional
/// leading icon (the "connected button group" item).
class NoopSegment<T> {
  final T value;
  final String label;
  final IconData? icon;
  const NoopSegment(this.value, this.label, {this.icon});
}

/// The app-wide **segmented control** — the exact same material and behaviour
/// as the bottom nav bar: a translucent, fully-rounded pill track with ONE
/// subtle highlight that *glides* left↔right between the options (the bar's
/// `AnimatedAlign` slide, 260 ms easeOutCubic). The active option's label just
/// brightens; the highlight does the moving. Every choice-of-N uses this so the
/// selectors read as siblings of the nav bar — never hand-roll another:
///  * inline in a settings tile — [expand] off, the track hugs its widest label;
///  * as a full-width range selector at the top of a screen — [expand] on,
///    equal slots, a taller [height].
class NoopSegmented<T> extends StatelessWidget {
  final List<NoopSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  /// Fill the available width with equal slots (top-of-screen range selector).
  /// When false the track hugs its widest label (inline in a tile trailing).
  final bool expand;
  final double height;

  const NoopSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.expand = false,
    this.height = 32,
  });

  static const _slide = Duration(milliseconds: 260);
  static const _curve = Curves.easeOutCubic;

  // The nav bar's own "selected" tint and on-bar ink, mirrored so the sliding
  // highlight reads identically to the bar.
  Color get _highlight => Palette.isLight
      ? Colors.black.withValues(alpha: 0.06)
      : const Color(0x24FFFFFF);
  Color get _onColor => Palette.isLight ? Palette.textPrimary : Colors.white;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Metrics.cornerPill);
    final n = segments.length;
    final idx = segments.indexWhere((s) => s.value == value).clamp(0, n - 1);
    // Slot-centre alignment for the sliding highlight: -1 (first) … 1 (last).
    final alignX = n <= 1 ? 0.0 : -1 + 2 * idx / (n - 1);

    // Hugging variant: size every slot to the widest option so the highlight
    // glides over equal slots.
    var slotW = 0.0;
    if (!expand) {
      for (final s in segments) {
        final tp = TextPainter(
          text: TextSpan(text: s.label, style: NoopType.caption),
          textDirection: TextDirection.ltr,
        )..layout();
        var w = tp.width + Metrics.space12 * 2;
        if (s.icon != null) w += 22; // icon + gap allowance
        if (w > slotW) slotW = w;
      }
    }

    Widget slot(int i) {
      final s = segments[i];
      final active = i == idx;
      final color = active ? _onColor : Palette.textSecondary;
      return GestureDetector(
        onTap: () => onChanged(s.value),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (s.icon != null) Icon(s.icon, size: 16, color: color),
              if (s.icon != null && s.label.isNotEmpty)
                const SizedBox(width: 6),
              if (s.label.isNotEmpty)
                AnimatedDefaultTextStyle(
                  duration: _slide,
                  curve: _curve,
                  style: NoopType.caption.copyWith(
                      color: color,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500),
                  child: Text(s.label),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: Palette.fillInset, borderRadius: radius),
      child: SizedBox(
        height: height,
        width: expand ? double.infinity : slotW * n,
        child: Stack(
          children: [
            // The one highlight that glides between slots — the bar's mechanic.
            AnimatedAlign(
              alignment: Alignment(alignX, 0),
              duration: _slide,
              curve: _curve,
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration:
                      BoxDecoration(color: _highlight, borderRadius: radius),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  expand
                      ? Expanded(child: slot(i))
                      : SizedBox(width: slotW, child: slot(i)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The app-wide on/off toggle — a translucent pill (nav-bar family) with a knob
/// that *glides* between halves: grey when off, accent-tinted when on. Use this
/// everywhere a switch is needed so controls stay consistent.
class NoopToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const NoopToggle({super.key, required this.value, required this.onChanged});

  static const _width = 58.0;
  static const _height = 30.0;
  static const _slide = Duration(milliseconds: 340);
  static const _curve = Curves.easeOutCubic;
  static const _highlight = Color(0x24FFFFFF);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(Metrics.cornerPill);
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: _width,
        height: _height,
        decoration: BoxDecoration(
          color: Palette.fillRaised,
          borderRadius: radius,
          border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.34),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: AnimatedAlign(
            alignment: value ? const Alignment(1, 0) : const Alignment(-1, 0),
            duration: _slide,
            curve: _curve,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: AnimatedContainer(
                duration: _slide,
                curve: _curve,
                decoration: BoxDecoration(
                  color: value
                      ? Palette.accent.withValues(alpha: 0.60)
                      : (Palette.isLight
                          ? Colors.black.withValues(alpha: 0.10)
                          : _highlight),
                  borderRadius: radius,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
