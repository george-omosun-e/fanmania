import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Fanmania Design System - Typography
/// Clean sans-serif with bold headings and monospace for data
class AppTypography {
  AppTypography._();

  // ============================================
  // BASE FONT FAMILIES
  // ============================================

  /// Primary font family - Inter (clean sans-serif)
  static String get _fontFamily => GoogleFonts.inter().fontFamily!;

  /// Monospace font for technical data (mastery %, ranks)
  static String get _monoFontFamily => GoogleFonts.jetBrainsMono().fontFamily!;

  // ============================================
  // DISPLAY STYLES (Large headers)
  // ============================================

  /// Display Large - App title, splash screen
  static TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
    height: 1.2,
  );

  /// Display Medium - Section headers
  static TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.8,
    height: 1.25,
  );

  /// Display Small - Card titles
  static TextStyle displaySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // ============================================
  // HEADLINE STYLES
  // ============================================

  /// Headline Large - Page titles
  static TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
    height: 1.35,
  );

  /// Headline Medium - Section titles
  static TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
    height: 1.4,
  );

  /// Headline Small - Subsection titles
  static TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.15,
    height: 1.4,
  );

  // ============================================
  // BODY STYLES
  // ============================================

  /// Body Large - Primary content
  static TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0.15,
    height: 1.5,
  );

  /// Body Medium - Standard text
  static TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
    height: 1.5,
  );

  /// Body Small - Secondary text
  static TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
    height: 1.5,
  );

  // ============================================
  // LABEL STYLES
  // ============================================

  /// Label Large - Button text, emphasized labels
  static TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.4,
  );

  /// Label Medium - Standard labels
  static TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
    height: 1.4,
  );

  /// Label Small - Captions, hints
  static TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.5,
    height: 1.4,
  );

  // ============================================
  // SPECIAL STYLES
  // ============================================

  /// Monospace for numbers, percentages, ranks
  static TextStyle mono = TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  /// Large monospace for points display
  static TextStyle monoLarge = TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.0,
  );

  /// Extra large monospace for hero numbers
  static TextStyle monoHero = TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.electricCyan,
    letterSpacing: 1.5,
  );

  /// Neon accent text (for highlighted values)
  static TextStyle neonAccent = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.electricCyan,
    letterSpacing: 0.5,
  );

  /// Rank text style
  static TextStyle rank = TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.vividViolet,
    letterSpacing: 0.5,
  );

  /// Streak text style
  static TextStyle streak = TextStyle(
    fontFamily: _monoFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.magentaPop,
    letterSpacing: 0.5,
  );

  // ============================================
  // TEXT THEME FOR MATERIAL
  // ============================================

  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
