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
    // Flat solid canvas — no background gradient, no accent glow.
    return ColoredBox(color: Palette.surfaceBase, child: child);
  }
}
