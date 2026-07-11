import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';
import 'package:noop/shared/widgets/common.dart';

/// Shared-axis (horizontal) page route — the signature Plane transition: the new
/// page fades+scales in while the old one fades+scales out along the x-axis.
Route<T> noopRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondary) => page,
    transitionsBuilder: (context, animation, secondary, child) =>
        SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondary,
      transitionType: SharedAxisTransitionType.horizontal,
      fillColor: Colors.transparent,
      child: child,
    ),
  );
}

/// A keyboard-aware, scroll-controlled modal sheet with 30px top corners and an
/// X-close header (no drag handle) — Plane's dominant interaction pattern.
Future<T?> showNoopSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Palette.surfaceRaised,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: NoopType.title2.copyWith(color: Palette.textPrimary)),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: Palette.textTertiary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: child,
            ),
          ),
        ],
      ),
    ),
  );
}

/// A 6px bordered, tinted floating toast — Plane's confirmation style (not a
/// Material SnackBar look).
enum ToastKind { info, success, warning, error }

void noopToast(BuildContext context, String message, {ToastKind kind = ToastKind.info}) {
  final (color, icon, fill) = switch (kind) {
    ToastKind.success => (Palette.statusPositive, Icons.check_circle_rounded, const Color(0xFF0A331B)),
    ToastKind.warning => (Palette.statusWarning, Icons.warning_amber_rounded, const Color(0xFF481F07)),
    ToastKind.error => (Palette.statusCritical, Icons.error_rounded, const Color(0xFF5F1515)),
    ToastKind.info => (Palette.accent, Icons.info_rounded, const Color(0xFF101C3C)),
  };
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Palette.isLight ? Palette.surfaceRaised : fill,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 90),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Metrics.cornerBadge),
        side: BorderSide(color: color.withValues(alpha: 0.6), width: 1),
      ),
      content: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: NoopType.subhead.copyWith(color: Palette.textPrimary)),
          ),
        ],
      ),
    ));
}

/// An empty-state block — icon, title, body, optional CTA. Mirrors Plane's
/// EmptyPlaceholder (illustration + H5 + body + primary CTA).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? ctaLabel;
  final VoidCallback? onCta;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Palette.surfaceOverlay.withValues(alpha: 0.6),
              border: Border.all(color: Palette.hairline, width: 1),
            ),
            child: Icon(icon, size: 34, color: Palette.textTertiary),
          ),
          const SizedBox(height: Metrics.space18),
          Text(title,
              textAlign: TextAlign.center,
              style: NoopType.title2.copyWith(color: Palette.textPrimary)),
          const SizedBox(height: Metrics.space8),
          Text(body,
              textAlign: TextAlign.center,
              style: NoopType.subhead.copyWith(color: Palette.textTertiary)),
          if (ctaLabel != null) ...[
            const SizedBox(height: Metrics.space18),
            NoopButton(ctaLabel!, onPressed: onCta, icon: Icons.add_rounded),
          ],
        ],
      ),
    );
  }
}
