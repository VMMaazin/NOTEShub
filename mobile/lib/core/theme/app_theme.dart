import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'royal_design_system.dart';

export 'app_colors.dart';
export 'royal_design_system.dart';
export 'animated_glass_background.dart';
export 'theme_controller.dart';

/// Material 3 theme configurations for NOTEShub implementing Royal Academic Glassmorphism.
class AppTheme {
  AppTheme._();

  /// Light theme for NOTEShub featuring warm ivory, royal navy, and antique gold.
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: RoyalColors.royalGold,
      onPrimary: RoyalColors.midnightNavy,
      primaryContainer: RoyalColors.paleGold,
      onPrimaryContainer: RoyalColors.midnightNavy,
      secondary: RoyalColors.midnightNavy,
      onSecondary: RoyalColors.pearlWhite,
      secondaryContainer: Color(0xFFF0EBE1),
      onSecondaryContainer: RoyalColors.midnightNavy,
      surface: RoyalColors.creamCard,
      onSurface: RoyalColors.textNavy,
      surfaceContainerLowest: RoyalColors.pearlWhite,
      surfaceContainerLow: RoyalColors.warmIvory,
      surfaceContainer: Color(0xFFF2ECE1),
      outline: RoyalColors.ivoryBorder,
      outlineVariant: Color(0xFFDCD5C3),
      error: Color(0xFFDC2626),
      onError: RoyalColors.pearlWhite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: RoyalColors.warmIvory,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: RoyalColors.textNavy,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: RoyalColors.textNavy,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: RoyalColors.textNavy,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: RoyalColors.textNavy,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: RoyalColors.textNavy,
          fontSize: 15,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: RoyalColors.textNavyMuted,
          fontSize: 13.5,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: RoyalColors.textNavySubtle,
          fontSize: 12,
        ),
      ),
      cardTheme: const CardThemeData(
        color: RoyalColors.creamCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: RoyalColors.ivoryBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xF2F7F3E9),
        foregroundColor: RoyalColors.midnightNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: RoyalColors.midnightNavy,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RoyalColors.royalGold,
          foregroundColor: RoyalColors.midnightNavy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: RoyalColors.royalGold,
          foregroundColor: RoyalColors.midnightNavy,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: RoyalColors.paleGold,
        labelStyle: const TextStyle(
          color: RoyalColors.midnightNavy,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xF7FAF7F0),
        elevation: 20,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0x33C5A04A), width: 1.2),
        ),
      ),
    );
  }

  /// Dark theme for NOTEShub featuring deep royal midnight navy and metallic gold.
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    final colorScheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: RoyalColors.champagne,
      onPrimary: RoyalColors.midnightNavy,
      primaryContainer: RoyalColors.midnightNavySurface,
      onPrimaryContainer: RoyalColors.champagne,
      secondary: RoyalColors.pearlWhite,
      onSecondary: RoyalColors.midnightNavy,
      secondaryContainer: RoyalColors.midnightNavySubtle,
      onSecondaryContainer: RoyalColors.pearlWhite,
      surface: RoyalColors.midnightNavySurface,
      onSurface: RoyalColors.textWhite,
      surfaceContainerLowest: RoyalColors.midnightNavyDark,
      surfaceContainerLow: RoyalColors.midnightNavy,
      surfaceContainer: RoyalColors.midnightNavySurface,
      outline: RoyalColors.glassGoldBorder,
      outlineVariant: Color(0xFF283B6A),
      error: Color(0xFFEF4444),
      onError: RoyalColors.pearlWhite,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: RoyalColors.midnightNavyDark,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: RoyalColors.pearlWhite,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: RoyalColors.pearlWhite,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: RoyalColors.pearlWhite,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: RoyalColors.pearlWhite,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: RoyalColors.pearlWhite,
          fontSize: 15,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: RoyalColors.textMutedDark,
          fontSize: 13.5,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: RoyalColors.textSlateMuted,
          fontSize: 12,
        ),
      ),
      cardTheme: const CardThemeData(
        color: RoyalColors.midnightNavySurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: RoyalColors.glassGoldBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xE60A1124),
        foregroundColor: RoyalColors.pearlWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: RoyalColors.pearlWhite,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RoyalColors.royalGold,
          foregroundColor: RoyalColors.midnightNavy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: RoyalColors.royalGold,
          foregroundColor: RoyalColors.midnightNavy,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0x33C5A04A),
        labelStyle: const TextStyle(
          color: RoyalColors.champagne,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xF2101B3B),
        elevation: 20,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: RoyalColors.glassGoldBorder, width: 1.2),
        ),
      ),
    );
  }
}
