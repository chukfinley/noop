import 'package:flutter/material.dart';

import '../theme/metrics.dart';
import '../theme/palette.dart';

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
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.93),
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
