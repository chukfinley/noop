import 'package:flutter/material.dart';

import 'package:noop/core/theme/metrics.dart';
import 'package:noop/core/theme/palette.dart';

/// The one page transition used for every push in the app: a subtle horizontal
/// glide + fade.
///
/// It is driven ONLY by the route's own [animation] — never the page
/// underneath's [secondaryAnimation]. The old shared-axis transition asked the
/// page below to co-animate, but tab roots (Home / Trends) don't drive that
/// while pushed sub-pages do, so a push off a tab looked different from a push
/// off a sub-screen. Being self-contained, this looks byte-for-byte identical
/// on every screen, on the way in and on the way back.
Route<T> noopRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondary) => page,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.18, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
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
    backgroundColor: Palette.fillRaised,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Metrics.cornerSheet)),
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
