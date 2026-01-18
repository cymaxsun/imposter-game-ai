import 'package:flutter/material.dart';

/// Original color palette for the Imposter Finder app (classic warm tones).
///
/// Provides a consistent set of brand colors used throughout the application.
class AppPalette {
  static const Color inkBlack = Color(0xFF0d1821);
  static const Color yaleBlue = Color(0xFF344966);
  static const Color powderBlue = Color(0xFFb4cded);
  static const Color porcelain = Color(0xFFf0f4ef);
  static const Color drySage = Color(0xFFbfcc94);
}

/// Classic light theme palette (original colors).
///
/// To revert to this palette, set `AppTheme.useClassicLightPalette = true`.
class LightPaletteClassic {
  static const Color primary = Color(0xFF344966); // Yale Blue
  static const Color secondary = Color(0xFFbfcc94); // Dry Sage
  static const Color tertiary = Color(0xFFb4cded); // Powder Blue
  static const Color surface = Color(0xFFf0f4ef); // Porcelain
  static const Color onSurface = Color(0xFF0d1821); // Ink Black
  static const Color cardColor = Colors.white;
  static const Color cardShadow = Color(0x22344966);
  static const Color buttonBackground = Color(0xFF344966);
  static const Color buttonForeground = Color(0xFFf0f4ef);
  static const Color headlineColor = Color(0xFF344966);
  static const Color bodyColor = Color(0xFF0d1821);
  static const Color iconColor = Color(0xFF344966);
  static const Color successColor = Color(0xFFbfcc94);
}

/// Stitch-inspired pastel light theme palette (family-friendly).
///
/// Soft, playful colors inspired by the Stitch game settings design.
class LightPaletteClean {
  static const Color primary = Color(0xFF90CAF9); // Blue Accent
  static const Color secondary = Color(0xFF80CBC4); // Mint Dark
  static const Color tertiary = Color(0xFFFFF59D); // Yellow Accent
  static const Color surface = Color(0xFFF8FAFC); // iOS Background
  static const Color onSurface = Color(0xFF455A64); // Text Main
  static const Color cardColor = Colors.white;
  static const Color cardShadow = Color(0x0A000000); // Pastel shadow
  static const Color buttonBackground = Color(0xFF90CAF9); // Blue Accent
  static const Color buttonForeground = Colors.white;
  static const Color headlineColor = Color(0xFF455A64); // Text Main
  static const Color bodyColor = Color(0xFF455A64); // Text Main
  static const Color iconColor = Color(0xFF90CAF9); // Blue Accent
  static const Color successColor = Color(0xFF80CBC4); // Mint Dark
}

/// Custom colors for semantic use throughout the app.
///
/// Defines success and warning colors that can be accessed via
/// `Theme.of(context).extension<CustomColors>()`.
@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  /// Creates custom colors with required success and warning colors.
  const CustomColors({required this.succeed, required this.warn});

  /// Color used to indicate success states.
  final Color? succeed;

  /// Color used to indicate warning or error states.
  final Color? warn;

  @override
  CustomColors copyWith({Color? succeed, Color? warn}) {
    return CustomColors(
      succeed: succeed ?? this.succeed,
      warn: warn ?? this.warn,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      succeed: Color.lerp(succeed, other.succeed, t),
      warn: Color.lerp(warn, other.warn, t),
    );
  }
}

/// Centralized theme configuration for the Imposter Finder app.
///
/// Provides both light and dark themes using Material 3 design principles.
class AppTheme {
  /// Set to `true` to use the original warm-toned color palette.
  /// Set to `false` to use the new white/grey with blue highlights palette.
  static bool useClassicLightPalette = false;

  /// Light theme configuration.
  ///
  /// Colors are determined by [useClassicLightPalette].
  /// - `false` (default): Clean white/grey with blue highlights
  /// - `true`: Original warm-toned Yale Blue/Porcelain palette
  static ThemeData get lightTheme {
    // Select palette based on toggle
    final primary = useClassicLightPalette
        ? LightPaletteClassic.primary
        : LightPaletteClean.primary;
    final secondary = useClassicLightPalette
        ? LightPaletteClassic.secondary
        : LightPaletteClean.secondary;
    final tertiary = useClassicLightPalette
        ? LightPaletteClassic.tertiary
        : LightPaletteClean.tertiary;
    final surface = useClassicLightPalette
        ? LightPaletteClassic.surface
        : LightPaletteClean.surface;
    final onSurface = useClassicLightPalette
        ? LightPaletteClassic.onSurface
        : LightPaletteClean.onSurface;
    final cardColor = useClassicLightPalette
        ? LightPaletteClassic.cardColor
        : LightPaletteClean.cardColor;
    final cardShadow = useClassicLightPalette
        ? LightPaletteClassic.cardShadow
        : LightPaletteClean.cardShadow;
    final buttonBackground = useClassicLightPalette
        ? LightPaletteClassic.buttonBackground
        : LightPaletteClean.buttonBackground;
    final buttonForeground = useClassicLightPalette
        ? LightPaletteClassic.buttonForeground
        : LightPaletteClean.buttonForeground;
    final headlineColor = useClassicLightPalette
        ? LightPaletteClassic.headlineColor
        : LightPaletteClean.headlineColor;
    final bodyColor = useClassicLightPalette
        ? LightPaletteClassic.bodyColor
        : LightPaletteClean.bodyColor;
    final iconColor = useClassicLightPalette
        ? LightPaletteClassic.iconColor
        : LightPaletteClean.iconColor;
    final successColor = useClassicLightPalette
        ? LightPaletteClassic.successColor
        : LightPaletteClean.successColor;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        onSurface: onSurface,
        outline: tertiary,
      ),
      scaffoldBackgroundColor: surface,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 4,
        shadowColor: cardShadow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackground,
          foregroundColor: buttonForeground,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
          elevation: 2,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: headlineColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: bodyColor,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: bodyColor, height: 1.5),
      ),
      iconTheme: IconThemeData(color: iconColor),
      extensions: <ThemeExtension<dynamic>>[
        CustomColors(succeed: successColor, warn: Colors.redAccent),
      ],
    );
  }

  /// Dark theme configuration - Stitch-inspired Pastel Dark.
  ///
  /// Soft pastel accents on a warm dark background, maintaining the
  /// family-friendly feel in dark mode.
  static ThemeData get darkTheme {
    return lightTheme;
  }
}
