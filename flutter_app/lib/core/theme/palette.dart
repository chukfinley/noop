import 'package:flutter/material.dart';
import 'package:noop/core/theme/tokens.dart';

/// Data-viz colour mode.
enum ChartStyle { titanium, classic }

/// Global palette. Mirrors `object Palette` in Theme.kt: one active token set,
/// swapped wholesale per scheme. Set by [NoopTheme] before the tree builds, so
/// every `Palette.x` read (widget or painter) resolves against the live scheme.
class Palette {
  Palette._();

  static PaletteTokens active = darkTokens;
  static ChartStyle chartStyle = ChartStyle.titanium;

  /// Set by the theme builder; drives the light/dark data-ramp choice.
  static bool lightMode = false;

  static bool get isLight => lightMode;
  static bool get isClassic => chartStyle == ChartStyle.classic;
  static ClassicRamp get _classic => isLight ? classicLight : classicDark;

  // Surfaces (opaque tokens — the raw scheme colours)
  static Color get surfaceBase => active.surfaceBase;
  static Color get surfaceRaised => active.surfaceRaised;
  static Color get surfaceOverlay => active.surfaceOverlay;
  static Color get surfaceInset => active.surfaceInset;
  static Color get hairline => active.hairline;
  static Color get hairlineStrong => active.hairlineStrong;

  // ── Global transparency — THE single editable knob ──────────────────────────
  // One place to tune how see-through every *chrome* surface is (cards, tiles,
  // pills, sheets, dialogs, controls). 1.0 = fully opaque; lower = more of the
  // scenic background shows through, exactly like the floating nav bar. Change
  // these two numbers (or set them at runtime) to restyle the whole app's
  // translucency — every surface reads them through [chrome] / the `fill*`
  // getters below, so nothing is styled one-off.
  //
  // Page/background fills (a full-screen [surfaceBase] canvas) must stay opaque
  // and keep using the raw `surface*` tokens — only floating chrome uses `fill*`.
  static double surfaceOpacityDark = 0.58;
  static double surfaceOpacityLight = 0.74;
  static double get surfaceOpacity =>
      isLight ? surfaceOpacityLight : surfaceOpacityDark;

  /// Make any solid surface colour translucent by the global [surfaceOpacity]
  /// (or an explicit [opacity]). Route EVERY chrome fill through this.
  static Color chrome(Color base, {double? opacity}) =>
      base.withValues(alpha: opacity ?? surfaceOpacity);

  /// Translucent variants of the surface tokens — the fills chrome should use
  /// instead of the raw opaque `surface*` getters.
  static Color get fillRaised => chrome(surfaceRaised);
  static Color get fillOverlay => chrome(surfaceOverlay);
  static Color get fillInset => chrome(surfaceInset);

  // Text
  static Color get textPrimary => active.textPrimary;
  static Color get textSecondary => active.textSecondary;
  static Color get textTertiary => active.textTertiary;

  static Color get glowAmbient => active.glowAmbient;

  // Accent
  static Color get accent => active.accent;
  static Color get accentHover => active.accentHover;
  static Color get accentMuted => active.accentMuted;
  static Color get focusRing => active.focusRing;
  static const double disabledOpacity = 0.45;

  // Recovery ramp
  static List<Stop> get recoveryStops => isClassic
      ? _classic.recovery
      : [
          Stop(0.00, active.recovery000),
          Stop(0.30, active.recovery030),
          Stop(0.55, active.recovery055),
          Stop(0.78, active.recovery078),
          Stop(1.00, active.recovery100),
        ];

  // Strain ramp
  static List<Stop> get strainStops => isClassic
      ? _classic.strain
      : [
          Stop(0.00, active.strain000),
          Stop(0.33, active.strain033),
          Stop(0.66, active.strain066),
          Stop(1.00, active.strain100),
        ];

  // Sleep stages
  static Color get sleepAwake => isClassic ? _classic.sleepAwake : active.sleepAwake;
  static Color get sleepLight => isClassic ? _classic.sleepLight : active.sleepLight;
  static Color get sleepDeep => isClassic ? _classic.sleepDeep : active.sleepDeep;
  static Color get sleepREM => isClassic ? _classic.sleepREM : active.sleepREM;

  // HR zones
  static Color get zone1 => isClassic ? _classic.zone1 : active.zone1;
  static Color get zone2 => isClassic ? _classic.zone2 : active.zone2;
  static Color get zone3 => isClassic ? _classic.zone3 : active.zone3;
  static Color get zone4 => isClassic ? _classic.zone4 : active.zone4;
  static Color get zone5 => isClassic ? _classic.zone5 : active.zone5;
  static List<Color> get hrZones => [zone1, zone1, zone2, zone3, zone4, zone5];

  // Status
  static Color get statusPositive => isClassic ? _classic.statusPositive : active.statusPositive;
  static Color get statusWarning => isClassic ? _classic.statusWarning : active.statusWarning;
  static Color get statusCritical => isClassic ? _classic.statusCritical : active.statusCritical;

  // Per-metric accents
  static Color get metricCyan => isClassic ? _classic.metricCyan : active.metricCyan;
  static Color get metricPurple => isClassic ? _classic.metricPurple : active.metricPurple;
  static Color get metricAmber => isClassic ? _classic.metricAmber : active.metricAmber;
  static Color get metricRose => isClassic ? _classic.metricRose : active.metricRose;

  // Domain colour worlds
  static Color get chargeColor => isClassic ? _classic.chargeColor : active.chargeColor;
  static Color get chargeDeep => isClassic ? _classic.chargeDeep : active.chargeDeep;
  static Color get chargeBright => isClassic ? _classic.chargeBright : active.chargeBright;
  static Color get chargeGlow => isClassic ? _classic.chargeColor : active.chargeGlow;

  static Color get effortColor => isClassic ? _classic.effortColor : active.effortColor;
  static Color get effortDeep => isClassic ? _classic.effortDeep : active.effortDeep;
  static Color get effortBright => isClassic ? _classic.effortBright : active.effortBright;
  static Color get effortGlow => isClassic ? _classic.effortColor : active.effortGlow;

  static Color get restColor => isClassic ? _classic.restColor : active.restColor;
  static Color get restDeep => isClassic ? _classic.restDeep : active.restDeep;
  static Color get restBright => isClassic ? _classic.restBright : active.restBright;
  static Color get restGlow => isClassic ? _classic.restColor : active.restGlow;

  static Color get stressColor => isClassic ? _classic.stressColor : active.stressColor;
  static Color get stressDeep => isClassic ? _classic.stressDeep : active.stressDeep;
  static Color get stressBright => isClassic ? _classic.stressBright : active.stressBright;
  static Color get stressGlow => isClassic ? _classic.stressColor : active.stressGlow;

  static List<Stop> get chargeGradientStops => [Stop(0, chargeDeep), Stop(1, chargeBright)];
  static List<Stop> get effortGradientStops => [Stop(0, effortDeep), Stop(1, effortBright)];
  static List<Stop> get restGradientStops => [Stop(0, restDeep), Stop(1, restBright)];
  static List<Stop> get stressGradientStops => isClassic
      ? _classic.stress
      : [Stop(0, stressDeep), Stop(0.5, stressColor), Stop(1, stressBright)];

  // Scenic
  static Color get scenicCenter => active.scenicCenter;
  static Color get scenicEdge => active.scenicEdge;
  static Color get scenicStar => active.scenicStar;

  static Color get cardFillTop => active.cardFillTop;
  static Color get cardFillBottom => active.cardFillBottom;

  // Gold & titanium ramps
  static Color get gold => active.gold;
  static Color get goldLight => active.goldLight;
  static Color get goldDeep => active.goldDeep;
  static Color get goldDeepText => active.goldDeepText;
  static Color get signalYellow => active.signalYellow;
  static List<Stop> get goldGradient => [Stop(0, goldLight), Stop(0.5, gold), Stop(1, goldDeep)];

  static Color get titaniumTop => active.titaniumTop;
  static Color get titaniumMid => active.titaniumMid;
  static Color get titaniumLow => active.titaniumLow;
  static Color get titaniumDeep => active.titaniumDeep;
  static List<Stop> get titaniumGradient =>
      [Stop(0, titaniumTop), Stop(0.40, titaniumMid), Stop(0.75, titaniumLow), Stop(1, titaniumDeep)];

  static Color get tipCore => active.tipCore;

  // Sampling helpers
  static Color _lerp(Color a, Color b, double t) => Color.lerp(a, b, t.clamp(0, 1))!;

  static Color sample(List<Stop> stops, double position) {
    if (stops.isEmpty) return Colors.transparent;
    if (stops.length == 1) return stops.first.color;
    final t = position.clamp(0.0, 1.0);
    var lower = stops.first;
    var upper = stops.last;
    for (var i = 0; i < stops.length - 1; i++) {
      final a = stops[i], b = stops[i + 1];
      if (t >= a.pos && t <= b.pos) {
        lower = a;
        upper = b;
        break;
      }
    }
    final span = upper.pos - lower.pos;
    final localT = span > 0 ? (t - lower.pos) / span : 0.0;
    return _lerp(lower.color, upper.color, localT);
  }

  static Color recoveryColor(double score) => sample(recoveryStops, score / 100.0);
  static Color strainColor(double strain) => sample(strainStops, strain / 100.0);
  static Color effortTint(double fraction) => sample(strainStops, fraction.clamp(0, 1));

  /// State word for a recovery score (spec §9.3).
  static String recoveryState(double score) {
    if (score < 25) return 'DEPLETED';
    if (score < 50) return 'LOW';
    if (score < 70) return 'MODERATE';
    if (score < 88) return 'PRIMED';
    return 'PEAK';
  }

  static Color hrZoneColor(int zone) => hrZones[zone.clamp(1, 5)];

  static List<Color> gradientColors(List<Stop> stops) => stops.map((s) => s.color).toList();
  static List<double> gradientPositions(List<Stop> stops) => stops.map((s) => s.pos).toList();
}

/// A (position, color) gradient stop.
@immutable
class Stop {
  final double pos;
  final Color color;
  const Stop(this.pos, this.color);
}

/// Per-scheme "Classic" throwback data ramps.
@immutable
class ClassicRamp {
  final List<Stop> recovery, strain, stress;
  final Color sleepAwake, sleepLight, sleepDeep, sleepREM;
  final Color zone1, zone2, zone3, zone4, zone5;
  final Color statusPositive, statusWarning, statusCritical;
  final Color metricCyan, metricPurple, metricAmber, metricRose;
  final Color chargeColor, chargeDeep, chargeBright;
  final Color effortColor, effortDeep, effortBright;
  final Color restColor, restDeep, restBright;
  final Color stressColor, stressDeep, stressBright;
  const ClassicRamp({
    required this.recovery,
    required this.strain,
    required this.stress,
    required this.sleepAwake,
    required this.sleepLight,
    required this.sleepDeep,
    required this.sleepREM,
    required this.zone1,
    required this.zone2,
    required this.zone3,
    required this.zone4,
    required this.zone5,
    required this.statusPositive,
    required this.statusWarning,
    required this.statusCritical,
    required this.metricCyan,
    required this.metricPurple,
    required this.metricAmber,
    required this.metricRose,
    required this.chargeColor,
    required this.chargeDeep,
    required this.chargeBright,
    required this.effortColor,
    required this.effortDeep,
    required this.effortBright,
    required this.restColor,
    required this.restDeep,
    required this.restBright,
    required this.stressColor,
    required this.stressDeep,
    required this.stressBright,
  });
}

const classicDark = ClassicRamp(
  recovery: [
    Stop(0.0, Color(0xFFE5483B)),
    Stop(0.30, Color(0xFFEE8B3C)),
    Stop(0.55, Color(0xFFF2C53D)),
    Stop(0.78, Color(0xFFA6D04E)),
    Stop(1.0, Color(0xFF46B45A)),
  ],
  strain: [
    Stop(0.0, Color(0xFF7FB2E8)),
    Stop(0.33, Color(0xFF4A90E2)),
    Stop(0.66, Color(0xFF2F6FCB)),
    Stop(1.0, Color(0xFF1E4FA0)),
  ],
  stress: [Stop(0.0, Color(0xFF46B45A)), Stop(0.5, Color(0xFFF2C53D)), Stop(1.0, Color(0xFFE5483B))],
  sleepAwake: Color(0xFFC9CCD6),
  sleepLight: Color(0xFF6FA8E8),
  sleepDeep: Color(0xFF2A4C8F),
  sleepREM: Color(0xFF8E6FD6),
  zone1: Color(0xFF9AA7B5),
  zone2: Color(0xFF46B45A),
  zone3: Color(0xFFF2C53D),
  zone4: Color(0xFFEE8B3C),
  zone5: Color(0xFFE5483B),
  statusPositive: Color(0xFF46B45A),
  statusWarning: Color(0xFFF2C53D),
  statusCritical: Color(0xFFE5483B),
  metricCyan: Color(0xFF3FA9C9),
  metricPurple: Color(0xFF8E6FD6),
  metricAmber: Color(0xFFF2C53D),
  metricRose: Color(0xFFE5483B),
  chargeColor: Color(0xFF46B45A),
  chargeDeep: Color(0xFF2E9E4F),
  chargeBright: Color(0xFF86D98E),
  effortColor: Color(0xFF4A90E2),
  effortDeep: Color(0xFF2F6FCB),
  effortBright: Color(0xFF7FB2E8),
  restColor: Color(0xFF6FA8E8),
  restDeep: Color(0xFF2A4C8F),
  restBright: Color(0xFF8E6FD6),
  stressColor: Color(0xFFF2C53D),
  stressDeep: Color(0xFF46B45A),
  stressBright: Color(0xFFE5483B),
);

const classicLight = ClassicRamp(
  recovery: [
    Stop(0.0, Color(0xFFCB3A2F)),
    Stop(0.30, Color(0xFFD87328)),
    Stop(0.55, Color(0xFFCFA528)),
    Stop(0.78, Color(0xFF74A53A)),
    Stop(1.0, Color(0xFF2E9E4F)),
  ],
  strain: [
    Stop(0.0, Color(0xFF5E92D6)),
    Stop(0.33, Color(0xFF3A74C4)),
    Stop(0.66, Color(0xFF284F9C)),
    Stop(1.0, Color(0xFF1C3E80)),
  ],
  stress: [Stop(0.0, Color(0xFF2E9E4F)), Stop(0.5, Color(0xFFCFA528)), Stop(1.0, Color(0xFFCB3A2F))],
  sleepAwake: Color(0xFF8C95A3),
  sleepLight: Color(0xFF3A80D6),
  sleepDeep: Color(0xFF203E73),
  sleepREM: Color(0xFF6A4FC0),
  zone1: Color(0xFF828D9B),
  zone2: Color(0xFF2E9E4F),
  zone3: Color(0xFFCFA528),
  zone4: Color(0xFFD87328),
  zone5: Color(0xFFCB3A2F),
  statusPositive: Color(0xFF2E9E4F),
  statusWarning: Color(0xFFCFA528),
  statusCritical: Color(0xFFCB3A2F),
  metricCyan: Color(0xFF2E92B4),
  metricPurple: Color(0xFF6A4FC0),
  metricAmber: Color(0xFFCFA528),
  metricRose: Color(0xFFCB3A2F),
  chargeColor: Color(0xFF2E9E4F),
  chargeDeep: Color(0xFF207A3C),
  chargeBright: Color(0xFF5FBE6E),
  effortColor: Color(0xFF3A74C4),
  effortDeep: Color(0xFF284F9C),
  effortBright: Color(0xFF5E92D6),
  restColor: Color(0xFF3A80D6),
  restDeep: Color(0xFF203E73),
  restBright: Color(0xFF6A4FC0),
  stressColor: Color(0xFFCFA528),
  stressDeep: Color(0xFF2E9E4F),
  stressBright: Color(0xFFCB3A2F),
);

/// Daily-score domain → its accent "colour world". Mirrors DomainTheme.
enum DomainTheme { charge, effort, rest, stress }

extension DomainThemeX on DomainTheme {
  Color get color => switch (this) {
        DomainTheme.charge => Palette.chargeColor,
        DomainTheme.effort => Palette.effortColor,
        DomainTheme.rest => Palette.restColor,
        DomainTheme.stress => Palette.stressColor,
      };
  Color get deep => switch (this) {
        DomainTheme.charge => Palette.chargeDeep,
        DomainTheme.effort => Palette.effortDeep,
        DomainTheme.rest => Palette.restDeep,
        DomainTheme.stress => Palette.stressDeep,
      };
  Color get bright => switch (this) {
        DomainTheme.charge => Palette.chargeBright,
        DomainTheme.effort => Palette.effortBright,
        DomainTheme.rest => Palette.restBright,
        DomainTheme.stress => Palette.stressBright,
      };
  Color get glow => switch (this) {
        DomainTheme.charge => Palette.chargeGlow,
        DomainTheme.effort => Palette.effortGlow,
        DomainTheme.rest => Palette.restGlow,
        DomainTheme.stress => Palette.stressGlow,
      };
  List<Stop> get gradientStops => switch (this) {
        DomainTheme.charge => Palette.chargeGradientStops,
        DomainTheme.effort => Palette.effortGradientStops,
        DomainTheme.rest => Palette.restGradientStops,
        DomainTheme.stress => Palette.stressGradientStops,
      };
  List<Stop> get dataStops =>
      this == DomainTheme.effort ? Palette.strainStops : Palette.recoveryStops;
  String get label => switch (this) {
        DomainTheme.charge => 'CHARGE',
        DomainTheme.effort => 'EFFORT',
        DomainTheme.rest => 'REST',
        DomainTheme.stress => 'STRESS',
      };
}
