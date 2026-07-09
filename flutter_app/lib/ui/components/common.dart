import 'package:flutter/material.dart';
import '../theme/metrics.dart';
import '../theme/palette.dart';

/// ALL-CAPS overline label. Mirrors the NoopType.overline usage.
class Overline extends StatelessWidget {
  final String text;
  final Color? color;
  const Overline(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: NoopType.overline.copyWith(color: color ?? Palette.textTertiary),
      );
}

/// Section header: overline + optional trailing.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Metrics.space8),
        child: Row(
          children: [
            Expanded(child: Overline(title)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// A thin hairline divider using the palette hairline.
class Hairline extends StatelessWidget {
  const Hairline({super.key});
  @override
  Widget build(BuildContext context) =>
      Container(height: Metrics.divider, color: Palette.hairline);
}

/// Small rounded pill badge (status / tag).
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  const Pill(this.text, {super.key, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: StrandAlpha.selectedFill),
          borderRadius: BorderRadius.circular(Metrics.cornerPill),
          border: Border.all(color: color.withValues(alpha: StrandAlpha.selectedBorder), width: 1),
        ),
        child: Text(text.toUpperCase(),
            style: NoopType.footnote.copyWith(
                color: color, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
      );
}

/// MD3 filled primary button (styled by the theme's FilledButtonTheme).
class NoopButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const NoopButton(this.label, {super.key, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
      );
    }
    return FilledButton(onPressed: onPressed, child: Text(label));
  }
}
