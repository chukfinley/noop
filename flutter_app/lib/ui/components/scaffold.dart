import 'package:flutter/material.dart';

import '../theme/metrics.dart';
import '../theme/palette.dart';
import 'backgrounds.dart';
import 'motion.dart';

/// Standard screen scaffold — a scenic backdrop, a large title + optional
/// subtitle header, and a scrolling body of rows on the screen rhythm.
/// Mirrors ScreenScaffold / LazyScreenScaffold.
class ScreenScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> headerActions;
  final Widget? leadingHeader;
  final Color? glow;
  final EdgeInsets padding;
  final Future<void> Function()? onRefresh;

  const ScreenScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.headerActions = const [],
    this.leadingHeader,
    this.glow,
    this.padding = const EdgeInsets.symmetric(horizontal: Metrics.screenPadding),
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return ScenicBackground(
      glow: glow,
      child: RefreshIndicator(
        color: Palette.accent,
        backgroundColor: Palette.surfaceRaised,
        onRefresh:
            onRefresh ?? () => Future<void>.delayed(const Duration(milliseconds: 700)),
        child: ListView(
        key: PageStorageKey<String>('screen:$title'),
        padding: EdgeInsets.only(
          top: media.padding.top + Metrics.space16,
          bottom: media.padding.bottom + 96,
        ),
        children: [
          Reveal(
            index: 0,
            child: Padding(
              padding: padding,
              child: leadingHeader ??
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (subtitle != null)
                              Text(subtitle!.toUpperCase(),
                                  style: NoopType.overline
                                      .copyWith(color: Palette.textTertiary)),
                            const SizedBox(height: 2),
                            Text(title,
                                style:
                                    NoopType.title1.copyWith(color: Palette.textPrimary)),
                          ],
                        ),
                      ),
                      ...headerActions,
                    ],
                  ),
            ),
          ),
          const SizedBox(height: Metrics.sectionGap - 6),
          for (var i = 0; i < children.length; i++) ...[
            Reveal(
              index: i + 1,
              child: Padding(padding: padding, child: children[i]),
            ),
            if (i != children.length - 1)
              const SizedBox(height: Metrics.screenRowSpacing),
          ],
        ],
        ),
      ),
    );
  }
}

/// A circular icon button used in screen headers.
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  const HeaderIconButton(this.icon, {super.key, this.onTap, this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: Metrics.space8),
        child: Material(
          color: Palette.surfaceOverlay.withValues(alpha: 0.55),
          shape: CircleBorder(
            side: BorderSide(
              color: Palette.hairline.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: Metrics.iconButton,
              height: Metrics.iconButton,
              child: Icon(icon, size: Metrics.iconSmall, color: color ?? Palette.textSecondary),
            ),
          ),
        ),
      );
}
