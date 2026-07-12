import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/state/providers.dart';
import 'package:noop/core/theme/palette.dart';

/// Marks the subtree (the tab pager) whose page backgrounds should be
/// TRANSPARENT, so the app shell can paint ONE shared, parallax wallpaper behind
/// every tab instead of each tab re-drawing its own copy.
class ShellWallpaperScope extends InheritedWidget {
  const ShellWallpaperScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellWallpaperScope>() != null;

  @override
  bool updateShouldNotify(ShellWallpaperScope oldWidget) => false;
}

/// The wallpaper photo. A user-supplied image URL when one is set (downloaded &
/// cached by [Image.network]); otherwise the bundled asset. A broken/unreachable
/// URL falls back to the asset, so a bad link never leaves a blank screen.
class WallpaperImage extends ConsumerWidget {
  final BoxFit fit;
  const WallpaperImage({super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(wallpaperUrlProvider);
    if (url != null && url.trim().isNotEmpty) {
      return Image.network(
        url.trim(),
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/images/wallpaper.jpg', fit: fit),
      );
    }
    return Image.asset('assets/images/wallpaper.jpg', fit: fit);
  }
}

/// App backdrop. Normally a flat solid canvas so the content reads first. When
/// the user turns on the home wallpaper (Settings → Appearance), EVERY screen
/// that uses this shows the photo behind a translucent scrim.
///
/// Inside the tab pager ([ShellWallpaperScope]) the page is instead left
/// transparent: the shell paints a single shared wallpaper that pans as you
/// swipe between tabs, so it reads as one continuous backdrop.
class ScenicBackground extends ConsumerWidget {
  final Widget child;

  /// Optional accent glow. Kept for call-site compatibility but intentionally
  /// very subtle; pass null for a flat canvas.
  final Color? glow;

  const ScenicBackground({super.key, required this.child, this.glow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallpaper = ref.watch(wallpaperProvider);

    // Tab pages: transparent, so the shell's shared parallax wallpaper shows.
    if (wallpaper && ShellWallpaperScope.of(context)) {
      return child;
    }

    if (wallpaper) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const WallpaperImage(),
          // Translucent scrim so the photo shows through yet content stays legible.
          ColoredBox(color: Palette.surfaceBase.withValues(alpha: 0.45)),
          child,
        ],
      );
    }
    // Flat solid canvas — no background gradient, no accent glow.
    return ColoredBox(color: Palette.surfaceBase, child: child);
  }
}
