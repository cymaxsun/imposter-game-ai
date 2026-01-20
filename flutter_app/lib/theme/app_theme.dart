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

/// Custom typography for specialized text styles not in standard Material TextTheme.
@immutable
class CustomTypography extends ThemeExtension<CustomTypography> {
  const CustomTypography({required this.extraSmallLabel});

  final TextStyle? extraSmallLabel;

  @override
  CustomTypography copyWith({TextStyle? extraSmallLabel}) {
    return CustomTypography(
      extraSmallLabel: extraSmallLabel ?? this.extraSmallLabel,
    );
  }

  @override
  CustomTypography lerp(ThemeExtension<CustomTypography>? other, double t) {
    if (other is! CustomTypography) {
      return this;
    }
    return CustomTypography(
      extraSmallLabel: TextStyle.lerp(
        extraSmallLabel,
        other.extraSmallLabel,
        t,
      ),
    );
  }
}

/// Game screen specific colors for cards and UI elements.
@immutable
class GameScreenColors extends ThemeExtension<GameScreenColors> {
  const GameScreenColors({
    // Card Front colors
    required this.cardFrontPrimary,
    required this.cardFrontBackground,
    required this.cardFrontTextDark,
    required this.cardFrontTextMuted,
    // Card Back - Innocent colors
    required this.innocentBackground,
    required this.innocentAccent,
    required this.innocentText,
    required this.innocentMuted,
    // Card Back - Imposter colors
    required this.imposterBackground,
    required this.imposterAccent,
    required this.imposterText,
    required this.imposterMuted,
    // Button colors
    required this.buttonPrimary,
    required this.buttonText,
    // Header colors
    required this.headerText,
    required this.headerSubtext,
  });

  // Card Front
  final Color cardFrontPrimary;
  final Color cardFrontBackground;
  final Color cardFrontTextDark;
  final Color cardFrontTextMuted;

  // Card Back - Innocent
  final Color innocentBackground;
  final Color innocentAccent;
  final Color innocentText;
  final Color innocentMuted;

  // Card Back - Imposter
  final Color imposterBackground;
  final Color imposterAccent;
  final Color imposterText;
  final Color imposterMuted;

  // Button
  final Color buttonPrimary;
  final Color buttonText;

  // Header
  final Color headerText;
  final Color headerSubtext;

  /// Default light theme colors for game screen
  static const light = GameScreenColors(
    // Card Front - Navy Blue theme
    cardFrontPrimary: Color(0xFF0A2472),
    cardFrontBackground: Color(0xFFFFFFF8),
    cardFrontTextDark: Color(0xFF181811),
    cardFrontTextMuted: Color(0xFF7889A9),
    // Innocent - Green theme
    innocentBackground: Color(0xFFFFFFFF),
    innocentAccent: Color(0xFF10B981),
    innocentText: Color(0xFF064E3B),
    innocentMuted: Color(0xFF3B6E58),
    // Imposter - Red theme
    imposterBackground: Color(0xFFFFFFFF),
    imposterAccent: Color(0xFFEF4444),
    imposterText: Color(0xFF7F1D1D),
    imposterMuted: Color(0xFF991B1B),
    // Button
    buttonPrimary: Color(0xFF0A2472),
    buttonText: Color(0xFFFFFFFF),
    // Header
    headerText: Color(0xFF181811),
    headerSubtext: Color(0xFF898961),
  );

  @override
  GameScreenColors copyWith({
    Color? cardFrontPrimary,
    Color? cardFrontBackground,
    Color? cardFrontTextDark,
    Color? cardFrontTextMuted,
    Color? innocentBackground,
    Color? innocentAccent,
    Color? innocentText,
    Color? innocentMuted,
    Color? imposterBackground,
    Color? imposterAccent,
    Color? imposterText,
    Color? imposterMuted,
    Color? buttonPrimary,
    Color? buttonText,
    Color? headerText,
    Color? headerSubtext,
  }) {
    return GameScreenColors(
      cardFrontPrimary: cardFrontPrimary ?? this.cardFrontPrimary,
      cardFrontBackground: cardFrontBackground ?? this.cardFrontBackground,
      cardFrontTextDark: cardFrontTextDark ?? this.cardFrontTextDark,
      cardFrontTextMuted: cardFrontTextMuted ?? this.cardFrontTextMuted,
      innocentBackground: innocentBackground ?? this.innocentBackground,
      innocentAccent: innocentAccent ?? this.innocentAccent,
      innocentText: innocentText ?? this.innocentText,
      innocentMuted: innocentMuted ?? this.innocentMuted,
      imposterBackground: imposterBackground ?? this.imposterBackground,
      imposterAccent: imposterAccent ?? this.imposterAccent,
      imposterText: imposterText ?? this.imposterText,
      imposterMuted: imposterMuted ?? this.imposterMuted,
      buttonPrimary: buttonPrimary ?? this.buttonPrimary,
      buttonText: buttonText ?? this.buttonText,
      headerText: headerText ?? this.headerText,
      headerSubtext: headerSubtext ?? this.headerSubtext,
    );
  }

  @override
  GameScreenColors lerp(ThemeExtension<GameScreenColors>? other, double t) {
    if (other is! GameScreenColors) {
      return this;
    }
    return GameScreenColors(
      cardFrontPrimary: Color.lerp(
        cardFrontPrimary,
        other.cardFrontPrimary,
        t,
      )!,
      cardFrontBackground: Color.lerp(
        cardFrontBackground,
        other.cardFrontBackground,
        t,
      )!,
      cardFrontTextDark: Color.lerp(
        cardFrontTextDark,
        other.cardFrontTextDark,
        t,
      )!,
      cardFrontTextMuted: Color.lerp(
        cardFrontTextMuted,
        other.cardFrontTextMuted,
        t,
      )!,
      innocentBackground: Color.lerp(
        innocentBackground,
        other.innocentBackground,
        t,
      )!,
      innocentAccent: Color.lerp(innocentAccent, other.innocentAccent, t)!,
      innocentText: Color.lerp(innocentText, other.innocentText, t)!,
      innocentMuted: Color.lerp(innocentMuted, other.innocentMuted, t)!,
      imposterBackground: Color.lerp(
        imposterBackground,
        other.imposterBackground,
        t,
      )!,
      imposterAccent: Color.lerp(imposterAccent, other.imposterAccent, t)!,
      imposterText: Color.lerp(imposterText, other.imposterText, t)!,
      imposterMuted: Color.lerp(imposterMuted, other.imposterMuted, t)!,
      buttonPrimary: Color.lerp(buttonPrimary, other.buttonPrimary, t)!,
      buttonText: Color.lerp(buttonText, other.buttonText, t)!,
      headerText: Color.lerp(headerText, other.headerText, t)!,
      headerSubtext: Color.lerp(headerSubtext, other.headerSubtext, t)!,
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
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: bodyColor.withValues(alpha: 0.8),
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: bodyColor.withValues(alpha: 0.6),
        ),
      ),
      iconTheme: IconThemeData(color: iconColor),
      extensions: <ThemeExtension<dynamic>>[
        CustomColors(succeed: successColor, warn: Colors.redAccent),
        CustomTypography(
          extraSmallLabel: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: onSurface.withValues(alpha: 0.6),
            letterSpacing: 1.2,
            fontFamily: 'Outfit',
          ),
        ),
        GameScreenColors.light,
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
