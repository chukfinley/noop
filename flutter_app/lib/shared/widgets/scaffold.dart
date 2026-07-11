import 'package:flutter/material.dart';

import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/shared/widgets/backgrounds.dart';
import 'package:noop/shared/widgets/motion.dart';

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
    // Show a back button automatically when this screen was pushed (Linux/desktop
    // has no system back gesture); tab roots can't pop, so they get none.
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    // A transparent Material ancestor: pushed routes (via noopRoute) aren't
    // under the shell's Scaffold, and Text without one renders with the debug
    // yellow underline. This also gives InkWells a surface to ripple on.
    return Material(
      type: MaterialType.transparency,
      child: ScenicBackground(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (canPop)
                        Padding(
                          padding: const EdgeInsets.only(right: Metrics.space12),
                          child: NoopBackButton(onTap: () => Navigator.of(context).maybePop()),
                        ),
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
      ),
    );
  }
}

/// The app-wide back button — a bare rounded back arrow in a circular tap
/// target. Use this everywhere a screen needs a back affordance so it stays
/// consistent; never hand-roll another.
class NoopBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const NoopBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.arrow_back_rounded, size: 24, color: Palette.textPrimary),
          ),
        ),
      );
}

/// The one centred detail header — a back button (auto-shown when the route can
/// pop), a centred title, and a right-hand slot the same width as the back
/// button so the title stays optically centred. This is the ONLY header for
/// pushed metric/sleep detail screens, so the back affordance is byte-for-byte
/// identical everywhere: you physically can't place it anywhere else.
class CenteredHeader extends StatelessWidget {
  final String title;

  /// Optional top-right widget (e.g. an info button). Occupies a fixed 40×40
  /// slot mirroring the back button, present or not, so the title never shifts.
  final Widget? trailing;
  const CenteredHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: canPop
              ? NoopBackButton(onTap: () => Navigator.of(context).maybePop())
              : null,
        ),
        Expanded(
          child: Text(title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NoopType.title2.copyWith(
                  color: Palette.textPrimary, fontWeight: FontWeight.w700)),
        ),
        SizedBox(width: 40, height: 40, child: Center(child: trailing)),
      ],
    );
  }
}

/// The shared day pager — a centred label (TODAY / weekday) with its date under
/// it, flanked by prev/next chevrons. The same affordance the home header uses,
/// so every screen changes day the same way (never a dropdown). Chevrons dim at
/// the ends.
class DayNavStrip extends StatelessWidget {
  final String label;
  final String sub;
  final bool canPrev;
  final bool canNext;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  const DayNavStrip({
    super.key,
    required this.label,
    required this.sub,
    required this.canPrev,
    required this.canNext,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Metrics.space6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NavArrow(
              icon: Icons.chevron_left_rounded, enabled: canPrev, onTap: onPrev),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label.toUpperCase(),
                  style: NoopType.overline.copyWith(
                      color: Palette.textSecondary, letterSpacing: 1.4)),
              Text(sub,
                  style: NoopType.footnote
                      .copyWith(color: Palette.textTertiary)),
            ],
          ),
          _NavArrow(
              icon: Icons.chevron_right_rounded,
              enabled: canNext,
              onTap: onNext),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  const _NavArrow({required this.icon, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: enabled ? onTap : null,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon,
            size: 22,
            color: enabled
                ? Palette.textSecondary
                : Palette.textTertiary.withValues(alpha: 0.4)),
      );
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
