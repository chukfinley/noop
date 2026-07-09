import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette.dart';

/// Spacing / sizing tokens. Mirrors `object Metrics`.
class Metrics {
  Metrics._();
  static const space2 = 2.0;
  static const space4 = 4.0;
  static const space6 = 6.0;
  static const space8 = 8.0;
  static const space10 = 10.0;
  static const space12 = 12.0;
  static const space14 = 14.0;
  static const space16 = 16.0;
  static const space18 = 18.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const cardRadius = 22.0;
  static const cornerXs = 2.0;
  static const cornerSm = 12.0;
  static const cornerBadge = 6.0;
  static const cornerPill = 50.0;
  static const cardPadding = 16.0;
  static const gap = 12.0;
  static const sectionGap = 28.0;
  static const screenRowSpacing = 20.0;
  static const screenPadding = 24.0;
  static const tileHeight = 108.0;
  static const chartHeight = 220.0;
  static const divider = 1.0;
  static const compactChartHeight = chartHeight - 90.0;
  static const iconButton = 36.0;
  static const iconSmall = 18.0;
  static const selectorPadding = 10.0;
  static const selectorSpacing = 8.0;
  static const sparkWidthWide = 48.0;
  static const sparkWidth = 58.0;
  static const sparkHeight = 22.0;
  static const stageStripHeight = 34.0;
  static const motionStripHeight = 40.0;
  static const trendStripHeight = 120.0;
  static const sparklineHeight = 28.0;
  static const segmentBarHeight = 18.0;
  static const legendSwatch = 9.0;
  static const legendLineWidth = 14.0;
  static const legendLineHeight = 3.0;
  static const progressHeight = 10.0;
}

/// Chart-fill alpha tokens. Mirrors `object StrandAlpha`.
class StrandAlpha {
  StrandAlpha._();
  static const subtleLine = 0.60;
  static const selectedFill = 0.12;
  static const selectedBorder = 0.55;
  static const chartFillStrong = 0.28;
  static const chartFillSoft = 0.04;
  static const chartMarker = 0.35;
  static const chartShadow = 0.28;
  static const chartLabel = 0.95;
  static const unselectedBar = 0.88;
  static const warningFill = 0.12;
  static const warningBorder = 0.40;
}

/// Physiological motion tokens. Mirrors `object Motion`.
class Motion {
  Motion._();
  static const durationFast = Duration(milliseconds: 180);
  static const durationStandard = Duration(milliseconds: 300);
  static const durationSlow = Duration(milliseconds: 900);
  static const breathPeriod = Duration(milliseconds: 3200);
  static const easeOut = Curves.easeOutCubic;
  static const easeInOut = Curves.easeInOut;
  static const interactive = Cubic(0.2, 0.0, 0.0, 1.0);
}

/// Typography. Mirrors `object NoopType` — Helvetica Neue → platform grotesque.
/// We use Inter (bundled via google_fonts) as a clean grotesque substitute with
/// tabular figures for live numbers.
class NoopType {
  NoopType._();

  static const _feat = [FontFeature.tabularFigures()];

  static TextStyle _sans(double size, FontWeight w,
          {double? spacing, List<FontFeature>? feats}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: w,
        letterSpacing: spacing,
        fontFeatures: feats,
        color: Palette.textPrimary,
      );

  static TextStyle _mono(double size, FontWeight w) => GoogleFonts.robotoMono(
        fontSize: size,
        fontWeight: w,
        color: Palette.textPrimary,
      );

  /// Big display number (recovery ring). Tight tracking, tabular figures.
  static TextStyle display([double size = 72]) =>
      _sans(size, FontWeight.bold, spacing: -size * 0.04, feats: _feat);
  static double displayTracking([double size = 72]) => -size * 0.04;

  static TextStyle get title1 => _sans(28, FontWeight.bold);
  static TextStyle get title2 => _sans(22, FontWeight.w600);
  static TextStyle get headline => _sans(17, FontWeight.w600);
  static TextStyle get body => _sans(15, FontWeight.normal);
  static TextStyle get subhead => _sans(13, FontWeight.normal);
  static TextStyle get caption => _sans(12, FontWeight.normal);
  static TextStyle get footnote => _sans(11, FontWeight.normal);
  static TextStyle get overline => _sans(11, FontWeight.bold, spacing: 1.4);
  static TextStyle get mono => _mono(13, FontWeight.normal);

  static TextStyle number(double size, {FontWeight weight = FontWeight.w600}) =>
      _sans(size, weight, feats: _feat);
  static TextStyle monoAt(double size, {FontWeight weight = FontWeight.normal}) =>
      _mono(size, weight);

  static TextStyle get bodyNumber => _sans(15, FontWeight.w500, feats: _feat);
  static TextStyle get captionNumber => _sans(12, FontWeight.w500, feats: _feat);
  static TextStyle get metricInline => number(15);
  static TextStyle get chartValue => number(18);
  static TextStyle get chartValueLarge => number(22);
  static TextStyle get tileValue => number(24);
  static TextStyle get tileValueLarge => number(26);

  static const overlineTracking = 1.4;
}
