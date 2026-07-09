import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette.dart';
import 'tokens.dart';

/// Appearance mode. Mirrors AppearanceMode.
enum AppearanceMode { system, light, dark }

extension AppearanceModeX on AppearanceMode {
  String get label => switch (this) {
        AppearanceMode.system => 'System',
        AppearanceMode.light => 'Light',
        AppearanceMode.dark => 'Dark',
      };
}

/// The Material You seed — NOOP's own WHOOP-blue accent (`#60A0E0`, from
/// `Palette.swift`), so the generated scheme's primary/containers read blue like
/// the real Noop iOS app instead of Plane's indigo.
const noopSeed = Color(0xFF60A0E0);

/// NOOP's real dark surface ramp (sampled from `Palette.swift`): a blue-grey
/// canvas with a lighter `#25292C` card fill. Applied over the tonal scheme so
/// dark mode matches the shipping Noop app exactly, not seed-tinted greys.
const _noopSurfaces = (
  surfaceLowest: Color(0xFF0E1013),
  surface: Color(0xFF121518), // surfaceBase
  surfaceLow: Color(0xFF17191D),
  surface1: Color(0xFF1C1F26), // surfaceOverlay
  surfaceHigh: Color(0xFF25292C), // surfaceRaised — cards + the nav bar
  surfaceHighest: Color(0xFF2E3236),
);

/// Build a Material 3 Expressive [ThemeData]. The chrome (surfaces, text, accent,
/// nav, buttons, sheets) is a tonal scheme generated from [noopSeed]; the data
/// colours (recovery/strain ramps, sleep stages, HR zones, domain worlds) stay
/// brand-fixed and are merged into the global [Palette] so every screen inherits
/// the MD3 look without touching its data encodings.
ThemeData buildNoopTheme(PaletteTokens brand, Brightness brightness) {
  var scheme = ColorScheme.fromSeed(
    seedColor: noopSeed,
    brightness: brightness,
  );
  // Dark mode → NOOP's real surface ramp + WHOOP-blue accent, so Material
  // widgets (buttons, sheets, the nav bar) sit on the exact Noop colours.
  if (brightness == Brightness.dark) {
    scheme = scheme.copyWith(
      surface: _noopSurfaces.surface,
      onSurface: brand.textPrimary,
      onSurfaceVariant: brand.textSecondary,
      primary: brand.accent,
      onPrimary: const Color(0xFF00121F),
      secondaryContainer: brand.accentMuted,
      onSecondaryContainer: brand.accentHover,
      outlineVariant: brand.hairline,
      outline: brand.hairlineStrong,
      surfaceContainerLowest: _noopSurfaces.surfaceLowest,
      surfaceContainerLow: _noopSurfaces.surfaceLow,
      surfaceContainer: _noopSurfaces.surface1,
      surfaceContainerHigh: _noopSurfaces.surfaceHigh,
      surfaceContainerHighest: _noopSurfaces.surfaceHighest,
    );
  }
  // The brand tokens ARE the Noop design (chrome + data) — use them directly for
  // every custom widget/painter; the scheme above only dresses Material widgets.
  Palette.active = brand;
  Palette.lightMode = brightness == Brightness.light;

  final text = _expressiveTextTheme(scheme);
  final shapeM = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
  final shapeL = RoundedRectangleBorder(borderRadius: BorderRadius.circular(28));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      elevation: 0,
      shape: shapeM,
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.secondaryContainer,
      elevation: 3,
      height: 76,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          )),
      labelTextStyle: WidgetStateProperty.all(
        text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: const StadiumBorder(),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: shapeL,
      modalBarrierColor: Colors.black.withValues(alpha: 0.5),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      selectedColor: scheme.secondaryContainer,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: text.labelLarge,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? scheme.onPrimary : scheme.outline),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerHighest),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: scheme.onSurface,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// Expressive type scale on Inter — emphasized weights, tight display tracking.
TextTheme _expressiveTextTheme(ColorScheme s) {
  final base = GoogleFonts.interTextTheme();
  TextStyle f(TextStyle? st, double size, FontWeight w, {double? spacing, double? height}) =>
      (st ?? const TextStyle()).copyWith(
        fontSize: size,
        fontWeight: w,
        letterSpacing: spacing,
        height: height,
        color: s.onSurface,
      );
  return base.copyWith(
    displayLarge: f(base.displayLarge, 57, FontWeight.w700, spacing: -1),
    displayMedium: f(base.displayMedium, 45, FontWeight.w700, spacing: -0.5),
    displaySmall: f(base.displaySmall, 36, FontWeight.w700),
    headlineLarge: f(base.headlineLarge, 32, FontWeight.w700),
    headlineMedium: f(base.headlineMedium, 28, FontWeight.w700),
    headlineSmall: f(base.headlineSmall, 24, FontWeight.w600),
    titleLarge: f(base.titleLarge, 22, FontWeight.w700),
    titleMedium: f(base.titleMedium, 16, FontWeight.w600, spacing: 0.1),
    titleSmall: f(base.titleSmall, 14, FontWeight.w600, spacing: 0.1),
    bodyLarge: f(base.bodyLarge, 16, FontWeight.w400, height: 1.4),
    bodyMedium: f(base.bodyMedium, 14, FontWeight.w400, height: 1.4),
    bodySmall: f(base.bodySmall, 12, FontWeight.w400),
    labelLarge: f(base.labelLarge, 15, FontWeight.w600, spacing: 0.1),
    labelMedium: f(base.labelMedium, 12, FontWeight.w600, spacing: 0.5),
    labelSmall: f(base.labelSmall, 11, FontWeight.w600, spacing: 0.5),
  );
}

/// Resolve the brand data-token set for an appearance mode + platform brightness.
PaletteTokens tokensFor(AppearanceMode mode, Brightness platform) {
  final dark = switch (mode) {
    AppearanceMode.light => false,
    AppearanceMode.dark => true,
    AppearanceMode.system => platform == Brightness.dark,
  };
  return dark ? darkTokens : lightTokens;
}

/// Brightness an appearance mode resolves to.
Brightness brightnessFor(AppearanceMode mode, Brightness platform) => switch (mode) {
      AppearanceMode.light => Brightness.light,
      AppearanceMode.dark => Brightness.dark,
      AppearanceMode.system => platform,
    };
