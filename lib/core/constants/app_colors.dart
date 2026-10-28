import 'package:flutter/material.dart';

class ThemePalette {
  final Color backgroundColor;
  final Color surfaceColor;
  final Color elevatedSurfaceColor;
  final Color accentColor;
  final Color secondaryAccentColor;
  final Color borderColor;

  const ThemePalette({
    required this.backgroundColor,
    required this.surfaceColor,
    required this.elevatedSurfaceColor,
    required this.accentColor,
    required this.secondaryAccentColor,
    required this.borderColor,
  });
}

enum AppThemeStyle {
  cosmicSlate(
    'COSMIC_SLATE',
    'Cosmic Slate',
    'Biru Kosmik & Emas RWC (Default)',
    Color(0xFF0D1117),
    Color(0xFF161B22),
    Color(0xFF1C2331),
    Color(0xFFF59E0B),
    Color(0xFF38BDF8),
  ),
  neonAmethyst(
    'NEON_AMETHYST',
    'Neon Amethyst',
    'Ungu Cyberpunk & Indigo Elektrik',
    Color(0xFF0F0A1C),
    Color(0xFF1A122E),
    Color(0xFF241940),
    Color(0xFFD946EF),
    Color(0xFF818CF8),
  ),
  forestEmerald(
    'FOREST_EMERALD',
    'Forest Emerald',
    'Hijau Zamrud & Emas Tropis',
    Color(0xFF061612),
    Color(0xFF0E241E),
    Color(0xFF15352C),
    Color(0xFF10B981),
    Color(0xFFFBBF24),
  ),
  auroraCyber(
    'AURORA_CYBER',
    'Aurora Cyber',
    'Sian Aurora & Violet Futuristik',
    Color(0xFF081420),
    Color(0xFF0F2236),
    Color(0xFF16304B),
    Color(0xFF06B6D4),
    Color(0xFFA855F7),
  ),
  sunsetCoral(
    'SUNSET_CORAL',
    'Sunset Coral',
    'Koral Hangat & Merah Delima',
    Color(0xFF180D0B),
    Color(0xFF271512),
    Color(0xFF361E1A),
    Color(0xFFF97316),
    Color(0xFFF43F5E),
  );

  // Uppercase aliases matching Android enum names
  static const AppThemeStyle COSMIC_SLATE = AppThemeStyle.cosmicSlate;
  static const AppThemeStyle NEON_AMETHYST = AppThemeStyle.neonAmethyst;
  static const AppThemeStyle FOREST_EMERALD = AppThemeStyle.forestEmerald;
  static const AppThemeStyle AURORA_CYBER = AppThemeStyle.auroraCyber;
  static const AppThemeStyle SUNSET_CORAL = AppThemeStyle.sunsetCoral;

  final String key;
  final String label;
  final String subtitle;
  final Color background;
  final Color surface;
  final Color card;
  final Color primary;
  final Color secondary;

  const AppThemeStyle(
    this.key,
    this.label,
    this.subtitle,
    this.background,
    this.surface,
    this.card,
    this.primary,
    this.secondary,
  );

  String get displayName => label;

  static AppThemeStyle fromKey(String? key) {
    if (key == null || key.trim().isEmpty) return AppThemeStyle.cosmicSlate;
    final clean = key.trim().toUpperCase();
    return AppThemeStyle.values.firstWhere(
      (e) => e.key.toUpperCase() == clean || e.name.toUpperCase() == clean,
      orElse: () => AppThemeStyle.cosmicSlate,
    );
  }
}

extension AppThemeStyleX on AppThemeStyle {
  static AppThemeStyle fromKey(String? key) => AppThemeStyle.fromKey(key);
}

class AppColors {
  // Brand & Primary
  static const Color primary = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF172554);
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentPrimary = Color(0xFF3B82F6);
  static const Color accentSecondary = Color(0xFF8B5CF6);
  static const Color rwcYellow = Color(0xFFFFE600);
  static const Color brandYellow = Color(0xFFFFE600);
  static const Color rwcDark = Color(0xFF2B2D42);
  static const Color brandDark = Color(0xFF111827);
  static const Color accentLight = Color(0xFFFDE68A);

  // GlowNavBar & Glassmorphic Accents
  static const Color glowBlue = Color(0xFF5B86FF);
  static const Color glowPurple = Color(0xFF7C5CFF);
  static const Color glowViolet = Color(0xFF9D4EDD);
  static const Color glowPillStart = Color(0xFF5B86FF);
  static const Color glowPillMid = Color(0xFF7C5CFF);
  static const Color glowPillEnd = Color(0xFF9D4EDD);
  static const Color glowBarBackground = Color(0xFF0E1322);
  static const Color glowBarBorder = Color(0xFF26304A);
  static const Color glowInactiveIcon = Color(0xFF94A3B8);
  static const Color navPillTop = Color(0xFF151933);
  static const Color navPillBottom = Color(0xFF0A0C18);

  // Background & Surface
  static const Color backgroundLight = Color(0xFFF4F6FA);
  static const Color surfaceLight = Colors.white;
  static const Color backgroundDark = Color(0xFF0D1117);
  static const Color surfaceDark = Color(0xFF161B22);
  static const Color cardDark = Color(0xFF1C2331);
  static const Color darkCardSurface = Color(0xFF161B22);
  static const Color darkElevatedSurface = Color(0xFF1C2331);

  // Status & Category Badges
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);
  static const Color statusDone = Color(0xFF10B981);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusUrgent = Color(0xFFEF4444);
  static const Color hotProperty = Color(0xFFFF5722);
  static const Color igPink = Color(0xFFE1306C);
  static const Color fotoUlangBlue = Color(0xFF2196F3);

  // Neutral & Text
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF30363D);

  static ThemePalette paletteFor(AppThemeStyle style) {
    return ThemePalette(
      backgroundColor: style.background,
      surfaceColor: style.surface,
      elevatedSurfaceColor: style.card,
      accentColor: style.primary,
      secondaryAccentColor: style.secondary,
      borderColor: Colors.white.withValues(alpha: 0.1),
    );
  }
}
