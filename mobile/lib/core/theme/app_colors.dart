import 'package:flutter/material.dart';

/// Fanmania Design System - Color Palette
/// Based on the "Digital Neon" system
class AppColors {
  AppColors._();

  // ============================================
  // PRIMARY COLORS
  // ============================================

  /// Deep Space - Primary app background for "Dark Mode" feel
  static const Color deepSpace = Color(0xFF0D1127);

  /// Electric Cyan - Selection states, active buttons, competitive highlights
  static const Color electricCyan = Color(0xFF00F2FF);

  /// Vivid Violet - High-rank indicators, "Contemporary Fusion" swirls
  static const Color vividViolet = Color(0xFF8A2BE2);

  /// Magenta Pop - Notifications, "Skill Under Threat" alerts, urgency
  static const Color magentaPop = Color(0xFFFF00FF);

  /// Pure White - Primary typography for maximum legibility
  static const Color pureWhite = Color(0xFFFFFFFF);

  // ============================================
  // SURFACE COLORS
  // ============================================

  /// Card background - Glassmorphic overlay
  static const Color cardBackground = Color(0x26FFFFFF); // 15% white

  /// Card border - Subtle glass edge
  static const Color cardBorder = Color(0x33FFFFFF); // 20% white

  /// Elevated surface - Slightly lighter than deep space
  static const Color surfaceElevated = Color(0xFF151A30);

  /// Inactive/ghost button border
  static const Color ghostBorder = Color(0xFF333B58);

  // ============================================
  // TEXT COLORS
  // ============================================

  /// Primary text
  static const Color textPrimary = pureWhite;

  /// Secondary text - Slightly dimmed
  static const Color textSecondary = Color(0xB3FFFFFF); // 70% white

  /// Tertiary text - More dimmed
  static const Color textTertiary = Color(0x80FFFFFF); // 50% white

  /// Hint text
  static const Color textHint = Color(0x4DFFFFFF); // 30% white

  // ============================================
  // STATUS COLORS
  // ============================================

  /// Success - Correct answers, achievements
  static const Color success = Color(0xFF00E676);

  /// Error - Wrong answers, failures
  static const Color error = Color(0xFFFF5252);

  /// Warning - Streak at risk, rank threat
  static const Color warning = Color(0xFFFFAB00);

  // ============================================
  // DIFFICULTY TIER COLORS
  // ============================================

  /// Tier 1 - Easy (Green)
  static const Color tier1 = Color(0xFF00E676);

  /// Tier 2 - Medium (Cyan)
  static const Color tier2 = electricCyan;

  /// Tier 3 - Hard (Violet)
  static const Color tier3 = vividViolet;

  /// Tier 4 - Expert (Magenta)
  static const Color tier4 = magentaPop;

  /// Tier 5 - Master (Gold)
  static const Color tier5 = Color(0xFFFFD700);

  /// Get color for difficulty tier
  static Color getTierColor(int tier) {
    switch (tier) {
      case 1:
        return tier1;
      case 2:
        return tier2;
      case 3:
        return tier3;
      case 4:
        return tier4;
      case 5:
        return tier5;
      default:
        return tier1;
    }
  }

  // ============================================
  // GRADIENTS
  // ============================================

  /// Primary gradient (Violet → Cyan)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [vividViolet, electricCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Progress bar gradient (Violet → Blue → Cyan)
  static const LinearGradient progressGradient = LinearGradient(
    colors: [vividViolet, Color(0xFF4169E1), electricCyan],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Neon glow gradient for buttons
  static const LinearGradient neonGlowGradient = LinearGradient(
    colors: [electricCyan, vividViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Rank threat gradient (warning state)
  static const LinearGradient warningGradient = LinearGradient(
    colors: [magentaPop, warning],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================
  // SHADOWS & GLOWS
  // ============================================

  /// Cyan neon glow
  static List<BoxShadow> get cyanGlow => [
        BoxShadow(
          color: electricCyan.withOpacity(0.6),
          blurRadius: 12,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: electricCyan.withOpacity(0.3),
          blurRadius: 24,
          spreadRadius: 4,
        ),
      ];

  /// Violet neon glow
  static List<BoxShadow> get violetGlow => [
        BoxShadow(
          color: vividViolet.withOpacity(0.6),
          blurRadius: 12,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: vividViolet.withOpacity(0.3),
          blurRadius: 24,
          spreadRadius: 4,
        ),
      ];

  /// Magenta neon glow
  static List<BoxShadow> get magentaGlow => [
        BoxShadow(
          color: magentaPop.withOpacity(0.6),
          blurRadius: 12,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: magentaPop.withOpacity(0.3),
          blurRadius: 24,
          spreadRadius: 4,
        ),
      ];

  /// Subtle card shadow
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
}
