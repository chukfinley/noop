import 'package:flutter/material.dart';

import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/shared/widgets/common.dart';

/// The Material 3 Expressive *connected* settings shapes, shared across the
/// Settings hub, its sub-screens and the Device screen so every grouped list
/// reads identically — same tonal tiles, same outer-large / inner-small corner
/// scheme, same hairline gap and the same coloured group headers.

/// An emphasised, coloured group header — the bold accent label that sits above
/// each connected group in the Expressive style.
class GroupHeader extends StatelessWidget {
  final String title;
  final Color color;
  const GroupHeader(this.title, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
            left: Metrics.space6, bottom: Metrics.space10),
        child: Text(
          title,
          style: NoopType.headline.copyWith(
              color: color, fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      );
}

/// A group = a coloured header above a [ConnectedGroup] of filled tiles.
class SettingsGroup extends StatelessWidget {
  final String title;
  final Color color;
  final List<Widget Function(BorderRadius radius)> tiles;
  const SettingsGroup(this.title, this.color, this.tiles, {super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GroupHeader(title, color),
          ConnectedGroup(tiles),
        ],
      );
}

/// A *connected* list: each tile builder is handed the [BorderRadius] it should
/// wear so the group's OUTER corners are extra-large and the INNER touching
/// corners are small, with a thin gap between rows — the Material 3 Expressive
/// grouped-list shape.
class ConnectedGroup extends StatelessWidget {
  final List<Widget Function(BorderRadius radius)> tiles;
  const ConnectedGroup(this.tiles, {super.key});

  static const double _outer = Metrics.cornerLarge;
  static const double _inner = Metrics.cornerBadge;
  static const double _gap = 3;

  @override
  Widget build(BuildContext context) {
    final n = tiles.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < n; i++) ...[
          tiles[i](BorderRadius.vertical(
            top: Radius.circular(i == 0 ? _outer : _inner),
            bottom: Radius.circular(i == n - 1 ? _outer : _inner),
          )),
          if (i != n - 1) const SizedBox(height: _gap),
        ],
      ],
    );
  }
}

/// A single filled setting tile: a leading tonal icon chip, a title (+ optional
/// detail line) and a trailing control. Its own filled surface, shaped by the
/// [radius] the connected group hands it. Tappable when [onTap] is supplied.
///
/// [below] hangs extra content (e.g. a live status row) under the title/detail
/// column, inside the same tile — used by the broadcast-HR card.
class SettingsTile extends StatelessWidget {
  final BorderRadius radius;
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? detail;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;
  const SettingsTile({
    super.key,
    required this.radius,
    this.icon,
    this.iconColor,
    required this.title,
    this.detail,
    this.trailing,
    this.below,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Palette.accent;
    final content = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Metrics.space14, vertical: Metrics.space10),
      child: Row(
        children: [
          if (icon != null) ...[
            IconChip(icon!, color: color),
            const SizedBox(width: Metrics.space12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: NoopType.body.copyWith(
                        color: Palette.textPrimary,
                        fontWeight: FontWeight.w500)),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail!,
                      style: NoopType.caption
                          .copyWith(color: Palette.textTertiary)),
                ],
                if (below != null) ...[
                  const SizedBox(height: Metrics.space8),
                  below!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: Metrics.space12),
            trailing!,
          ],
        ],
      ),
    );
    return Material(
      color: Palette.fillRaised,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
