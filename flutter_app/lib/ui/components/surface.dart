import 'package:flutter/material.dart';

import '../theme/metrics.dart';
import '../theme/palette.dart';

/// The "floating pill" look shared with the nav bar: a lightly-raised tonal
/// surface, a hairline ring, and a soft drop shadow. Every chrome surface in the
/// app draws with this so cards, sheets and the bar all read as one family —
/// the bar is the reference, this is how the rest matches it.
BoxDecoration floatingSurface({
  double radius = Metrics.cardRadius,
  Color? fill,
  double borderAlpha = 0.5,
  double shadowAlpha = 0.24,
  double blur = 24,
  double dy = 8,
}) =>
    BoxDecoration(
      color: fill ?? Palette.surfaceRaised,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: Palette.hairline.withValues(alpha: borderAlpha),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: shadowAlpha),
          blurRadius: blur,
          offset: Offset(0, dy),
        ),
      ],
    );
