import 'package:flutter/material.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/shared/widgets/motion.dart';
import 'package:noop/shared/widgets/surface.dart';

/// A floating card in the nav-bar family: a lightly-raised tonal surface with a
/// hairline ring and a soft drop shadow, so every card reads like the bar. When
/// [accent] is set the container tints tonally toward that colour. Springs on
/// press. Expressive rounded corners.
class NoopCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accent;
  final VoidCallback? onTap;
  final double radius;

  /// When false the hairline ring is dropped (only the soft shadow lifts the
  /// card off the background) — a cleaner, borderless look.
  final bool bordered;

  /// When true the corners use an iOS-style continuous "squircle" (a rounded
  /// superellipse) instead of a plain circular arc.
  final bool squircle;

  /// Explicit surface fill. Overrides the default raised/accent-tinted fill —
  /// e.g. to recess a card closer to the background.
  final Color? fillColor;

  const NoopCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Metrics.cardPadding),
    this.accent,
    this.onTap,
    this.radius = Metrics.cardRadius,
    this.bordered = true,
    this.squircle = false,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final base = Palette.surfaceRaised;
    final fill = fillColor ??
        (accent == null
            ? base
            : Color.alphaBlend(accent!.withValues(alpha: 0.12), base));

    if (squircle) {
      final shape = RoundedSuperellipseBorder(
        borderRadius: r,
        side: bordered
            ? BorderSide(color: Palette.hairline.withValues(alpha: 0.5), width: 1)
            : BorderSide.none,
      );
      return Pressable(
        onTap: onTap,
        borderRadius: r,
        child: Container(
          decoration: ShapeDecoration(
            shape: shape,
            color: fill,
            shadows: [
              BoxShadow(
                color: Colors.black.withValues(alpha: Palette.isLight ? 0.10 : 0.24),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: shape),
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
    }

    return Pressable(
      onTap: onTap,
      borderRadius: r,
      child: DecoratedBox(
        decoration: floatingSurface(radius: radius, fill: fill, borderAlpha: bordered ? 0.5 : 0.0),
        child: ClipRRect(
          borderRadius: r,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A card wrapping a titled section: label header + content.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final Color? accent;
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.accent,
  });

  @override
  Widget build(BuildContext context) => NoopCard(
        accent: accent,
        padding: const EdgeInsets.all(Metrics.space18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: NoopType.overline.copyWith(
                          color: accent ?? Palette.textSecondary,
                          fontWeight: FontWeight.w700)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: Metrics.space14),
            child,
          ],
        ),
      );
}
