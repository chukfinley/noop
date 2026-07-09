import 'package:flutter/material.dart';
import '../theme/palette.dart';

/// Clean app backdrop — a near-black canvas with a whisper of vertical depth,
/// no colour cast and no starfield, so the content reads first.
class ScenicBackground extends StatelessWidget {
  final Widget child;

  /// Optional accent glow. Kept for call-site compatibility but intentionally
  /// very subtle; pass null for a flat canvas.
  final Color? glow;

  const ScenicBackground({super.key, required this.child, this.glow});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(Palette.surfaceBase, Palette.surfaceOverlay, 0.5)!,
            Palette.surfaceBase,
          ],
          stops: const [0.0, 0.55],
        ),
      ),
      child: glow == null
          ? child
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.7),
                  radius: 1.1,
                  colors: [glow!.withValues(alpha: 0.06), Colors.transparent],
                ),
              ),
              child: child,
            ),
    );
  }
}
