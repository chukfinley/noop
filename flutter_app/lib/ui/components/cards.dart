import 'package:flutter/material.dart';
import '../theme/metrics.dart';
import '../theme/palette.dart';
import 'motion.dart';
import 'surface.dart';

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

  const NoopCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Metrics.cardPadding),
    this.accent,
    this.onTap,
    this.radius = Metrics.cardRadius,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final base = Palette.surfaceRaised;
    final fill = accent == null
        ? base
        : Color.alphaBlend(accent!.withValues(alpha: 0.12), base);
    return Pressable(
      onTap: onTap,
      borderRadius: r,
      child: DecoratedBox(
        decoration: floatingSurface(radius: radius, fill: fill),
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
