import 'package:flutter/material.dart';
import 'royal_design_system.dart';

export 'royal_design_system.dart';

/// Centralized color tokens for NOTEShub reflecting the Royal Academic Glassmorphism design system.
/// Bridges existing tokens to Midnight Royal Navy, Antique Metallic Gold, Warm Ivory, and Pearl White.
class AppColors {
  AppColors._();

  // Midnight Royal Navy Spectrum
  static const Color midnightNavy = RoyalColors.midnightNavy;
  static const Color midnightNavyDark = RoyalColors.midnightNavyDark;
  static const Color midnightNavySurface = RoyalColors.midnightNavySurface;
  static const Color midnightNavySubtle = RoyalColors.midnightNavySubtle;

  // Antique and Metallic Gold Spectrum
  static const Color royalGold = RoyalColors.royalGold;
  static const Color antiqueGold = RoyalColors.antiqueGold;
  static const Color metallicGold = RoyalColors.metallicGold;
  static const Color lightGold = RoyalColors.lightGold;
  static const Color champagne = RoyalColors.champagne;
  static const Color champagneLight = RoyalColors.champagneLight;
  static const Color paleGold = RoyalColors.paleGold;
  static const Color goldAccentDark = RoyalColors.goldAccentDark;

  // Warm Ivory & Pearl White Spectrum
  static const Color warmIvory = RoyalColors.warmIvory;
  static const Color creamCard = RoyalColors.creamCard;
  static const Color pearlWhite = RoyalColors.pearlWhite;
  static const Color ivoryBorder = RoyalColors.ivoryBorder;
  static const Color ivoryBorderSubtle = RoyalColors.ivoryBorderSubtle;

  // Base Structural Surfaces (Mapped to Royal Tokens)
  static const Color background = RoyalColors.midnightNavyDark;
  static const Color surface = RoyalColors.midnightNavySurface;
  static const Color surfaceElevated = RoyalColors.midnightNavySubtle;
  static const Color surfaceLight = RoyalColors.midnightNavySubtle;
  static const Color surfaceBorder = RoyalColors.glassGoldBorder;
  static const Color surfaceBorderLight = Color(0x33C5A04A);

  // Brand Accents (Mapped to Royal Metallic Gold)
  static const Color primaryBlue = RoyalColors.royalGold;
  static const Color primaryBlueHover = RoyalColors.antiqueGold;
  static const Color accentViolet = RoyalColors.metallicGold;
  static const Color accentCyan = RoyalColors.cyanInteractive;

  // Common Aliases
  static const Color primary = RoyalColors.royalGold;
  static const Color secondary = RoyalColors.champagne;
  static const Color primaryLight = RoyalColors.champagne;

  // Status & Interactive Accents
  static const Color success = RoyalColors.emeraldActive;
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = RoyalColors.errorRedDark;

  // Typography Palette
  static const Color textPrimary = RoyalColors.pearlWhite;
  static const Color textSecondary = RoyalColors.textMutedDark;
  static const Color textMuted = RoyalColors.textSlateMuted;
  static const Color textDisabled = Color(0xFF5A667A);

  // Category Specific Tag Accents
  static const Color tagNotes = RoyalColors.royalGold;
  static const Color tagQbank = RoyalColors.champagne;
  static const Color tagExtra = RoyalColors.emeraldActive;

  // Gradients
  static const LinearGradient brandGradient = RoyalGradients.metallicGold;
  static const LinearGradient cardGlowGradient = RoyalGradients.midnightHero;
}
