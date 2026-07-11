import 'package:flutter/material.dart';
import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/shared/widgets/cards.dart';
import 'package:noop/shared/widgets/charts.dart';

/// A metric tile — label, big value + unit, optional delta + inline sparkline.
/// Fixed [Metrics.tileHeight]. Mirrors the Compose metric tile.
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final String? delta;
  final Color? deltaColor;
  final List<double>? spark;
  final List<Stop>? sparkRamp;
  final Color? accent;
  final IconData? icon;
  final VoidCallback? onTap;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.delta,
    this.deltaColor,
    this.spark,
    this.sparkRamp,
    this.accent,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NoopCard(
      onTap: onTap,
      accent: accent,
      padding: const EdgeInsets.all(Metrics.space14),
      child: SizedBox(
        height: Metrics.tileHeight - Metrics.space14 * 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: Metrics.iconSmall, color: accent ?? Palette.textTertiary),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NoopType.overline.copyWith(color: Palette.textTertiary)),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: NoopType.tileValue.copyWith(color: Palette.textPrimary)),
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 3),
                  Text(unit!, style: NoopType.caption.copyWith(color: Palette.textTertiary)),
                ],
                const Spacer(),
                if (spark != null && spark!.length > 1)
                  Sparkline(values: spark!, ramp: sparkRamp, color: accent),
              ],
            ),
            if (delta != null)
              Text(delta!,
                  style: NoopType.captionNumber
                      .copyWith(color: deltaColor ?? Palette.textTertiary))
            else
              const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

/// A responsive 2-column grid of metric tiles.
class MetricGrid extends StatelessWidget {
  final List<Widget> tiles;
  final int columns;
  const MetricGrid(this.tiles, {super.key, this.columns = 2});

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: columns,
        crossAxisSpacing: Metrics.gap,
        mainAxisSpacing: Metrics.gap,
        childAspectRatio: 1.55,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: tiles,
      );
}
