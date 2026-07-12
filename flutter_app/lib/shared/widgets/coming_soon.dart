import 'package:flutter/material.dart';

import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/shared/widgets/cards.dart';

/// Placeholders for metrics that have no real capture source yet. These stamp a
/// clear, on-brand "Coming soon" treatment in place of fabricated numbers, so an
/// empty metric reads as *planned* rather than broken.
///
/// Three building blocks:
/// * [ComingSoonBadge]   — a small pill to overlay on any tile/row.
/// * [ComingSoonTile]    — a full placeholder tile that drops into the metric
///                         grids in place of a real [MetricTile].
/// * [ComingSoonOverlay] — dims a child and stamps the badge over it (large
///                         cards / whole sections).
///
/// [ComingSoonView] is a centred full-screen state for screens whose whole body
/// has no data yet (Workouts, Journal).

/// A small "COMING SOON" pill. Muted tonal fill + hairline ring, tertiary text —
/// reads as an inert status chip, never as a live value.
class ComingSoonBadge extends StatelessWidget {
  /// Pill text. Defaults to `COMING SOON`; pass `SOON` for tight corners.
  final String label;

  /// A compact variant with a shorter default label and tighter padding, sized
  /// to sit in the corner of a metric tile.
  final bool compact;

  /// Optional colour the badge sits *on* (e.g. white on a frosted-glass sheet).
  /// When null it uses [Palette] tokens and reads on standard surfaces.
  final Color? onColor;

  const ComingSoonBadge({
    super.key,
    this.label = 'COMING SOON',
    this.compact = false,
    this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    final base = onColor ?? Palette.textTertiary;
    final text = compact && label == 'COMING SOON' ? 'SOON' : label;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Metrics.space6 : Metrics.space8,
        vertical: compact ? 2 : Metrics.space4,
      ),
      decoration: BoxDecoration(
        color: base.withValues(alpha: onColor != null ? 0.14 : 0.10),
        borderRadius: BorderRadius.circular(Metrics.cornerPill),
        border: Border.all(color: base.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded,
              size: compact ? 10 : 12, color: base.withValues(alpha: 0.85)),
          const SizedBox(width: 4),
          Text(
            text,
            style: NoopType.overline.copyWith(
              color: base.withValues(alpha: 0.9),
              fontSize: compact ? 8.5 : 9.5,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

/// A full placeholder metric tile — same silhouette as [MetricTile] (a
/// [NoopCard] with a label header) so it drops straight into [MetricGrid] and
/// the Trends grid without disturbing the layout. Muted, with a "Coming soon"
/// line in place of the value.
class ComingSoonTile extends StatelessWidget {
  final String label;
  final IconData? icon;

  /// When true the tile matches the home surfaces' iOS-style continuous corners.
  final bool squircle;

  /// Corner radius — match the grid this tile drops into.
  final double radius;

  /// When set the placeholder becomes tappable (e.g. to open an estimated
  /// preview screen for a metric whose real source isn't wired up yet).
  final VoidCallback? onTap;

  const ComingSoonTile({
    super.key,
    required this.label,
    this.icon,
    this.squircle = false,
    this.radius = Metrics.cardRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // A hair recessed toward the background so it reads quieter than a live tile.
    final recessed = Color.lerp(Palette.surfaceBase, Palette.surfaceRaised, 0.55)!;
    return NoopCard(
      squircle: squircle,
      radius: radius,
      fillColor: recessed,
      onTap: onTap,
      padding: const EdgeInsets.all(Metrics.space14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: Metrics.tileHeight - Metrics.space14 * 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: Metrics.iconSmall,
                      color: Palette.textTertiary.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NoopType.overline
                        .copyWith(color: Palette.textTertiary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Metrics.space8),
            Row(
              children: [
                Icon(Icons.hourglass_empty_rounded,
                    size: 14, color: Palette.textTertiary.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Coming soon',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NoopType.subhead.copyWith(
                        color: Palette.textTertiary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dims [child] and stamps a centred [ComingSoonBadge] over it — for large
/// cards or whole sections whose real content isn't wired up yet. The child is
/// kept (so the layout/size is preserved) but faded and made non-interactive.
class ComingSoonOverlay extends StatelessWidget {
  final Widget child;

  /// Badge label passed through to [ComingSoonBadge].
  final String label;

  /// How much of the underlying child shows through.
  final double childOpacity;

  const ComingSoonOverlay({
    super.key,
    required this.child,
    this.label = 'COMING SOON',
    this.childOpacity = 0.28,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Keep the child for sizing, but fade it and swallow all pointer input.
        IgnorePointer(child: Opacity(opacity: childOpacity, child: child)),
        ComingSoonBadge(label: label),
      ],
    );
  }
}

/// A centred, full-body "coming soon" state — an icon, a title and a short
/// explanatory line — for screens with no real data yet (Workouts, Journal).
class ComingSoonView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  /// Optional colour to render on (e.g. white over a coloured hero). Defaults to
  /// [Palette] tokens for the standard dark/light surfaces.
  final Color? onColor;

  const ComingSoonView({
    super.key,
    this.icon = Icons.hourglass_empty_rounded,
    this.title = 'Coming soon',
    this.message,
    this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = onColor ?? Palette.textSecondary;
    final secondary = onColor?.withValues(alpha: 0.7) ?? Palette.textTertiary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Metrics.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (onColor ?? Palette.textTertiary).withValues(alpha: 0.10),
                border: Border.all(
                    color: (onColor ?? Palette.hairlineStrong)
                        .withValues(alpha: 0.4),
                    width: 1),
              ),
              child: Icon(icon, size: 30, color: primary),
            ),
            const SizedBox(height: Metrics.space18),
            Text(title,
                textAlign: TextAlign.center,
                style: NoopType.title2.copyWith(color: primary)),
            const SizedBox(height: Metrics.space10),
            const ComingSoonBadge(),
            if (message != null) ...[
              const SizedBox(height: Metrics.space16),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: NoopType.body
                      .copyWith(color: secondary, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}
