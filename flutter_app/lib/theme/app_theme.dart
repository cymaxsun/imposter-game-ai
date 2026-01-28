import 'package:flutter/material.dart';
import 'pastel_theme.dart';

/// Stitch-inspired pastel light theme palette (family-friendly).
///
/// Soft, playful colors inspired by the Stitch game settings design.
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
  static ThemeData get lightTheme {
    // --- Core Palette (Formerly LightPaletteClean) ---
    const Color surface = Color(0xFFF8FAFC); // iOS Background
    const Color onSurface = Color(0xFF455A64); // Text Main
    const Color cardColor = Colors.white;
    const Color cardShadow = Color(0x0A000000); // Pastel shadow
    const Color buttonBackground = Color(0xFF90CAF9); // Blue Accent
    const Color buttonForeground = Colors.white;
    const Color headlineColor = Color(0xFF455A64); // Text Main
    const Color bodyColor = Color(0xFF455A64); // Text Main
    const Color iconColor = Color(0xFF90CAF9); // Blue Accent
    const Color successColor = Color(0xFF80CBC4); // Mint Dark

    // --- Semantic Brand Colors ---
    const Color primaryBrand = Color(0xFF307DE8);
    const Color secondaryBrand = Color(0xFF8B7CF6);
    const Color accent = Color(0xFF6347EB);
    const Color heroYellow = Color(0xFFBDA02E);
    const Color offWhiteBackground = Color(0xFFFDFCF8);
    const Color softSurface = Color(0xFFF9FAFB);
    const Color deepCharcoal = Color(0xFF121118);
    const Color softLavender = Color(0xFFE6E1FF);
    const Color vibrantMint = Color(0xFFBBF7D0);
    const Color emeraldText = Color(0xFF065F46);
    const Color slateText = Color(0xFF718096);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryBrand,
        onPrimary: offWhiteBackground,
        secondary: secondaryBrand,
        onSecondary: offWhiteBackground,
        tertiary: accent,
        onTertiary: offWhiteBackground,
        error: Colors.redAccent,
        onError: offWhiteBackground,
        surface: offWhiteBackground,
        onSurface: deepCharcoal,
        // Detailed mappings
        primaryContainer: softLavender,
        onPrimaryContainer: primaryBrand,
        secondaryContainer: vibrantMint,
        onSecondaryContainer: emeraldText,
        tertiaryContainer: heroYellow,
        onTertiaryContainer: deepCharcoal, // readable on yellow?
        surfaceContainer: softSurface,
        outline: slateText,
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
        PastelTheme.light,

        AiStudioColors.light,
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

/// Specific colors for the AI Studio feature (Material Purple theme).
@immutable
class AiStudioColors extends ThemeExtension<AiStudioColors> {
  const AiStudioColors({
    required this.primary,
    required this.background,
    required this.border,
  });

  final Color primary;
  final Color background;
  final Color border;

  static const AiStudioColors lightTheme = AiStudioColors(
    primary: Color(0xFF9C27B0),
    background: Color(0xFFF3E5F5),
    border: Color(0xFFCE93D8),
  );

  // Alias for consistency with other extensions
  static const light = lightTheme;

  @override
  AiStudioColors copyWith({Color? primary, Color? background, Color? border}) {
    return AiStudioColors(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      border: border ?? this.border,
    );
  }

  @override
  AiStudioColors lerp(ThemeExtension<AiStudioColors>? other, double t) {
    if (other is! AiStudioColors) return this;
    return AiStudioColors(
      primary: Color.lerp(primary, other.primary, t)!,
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}
