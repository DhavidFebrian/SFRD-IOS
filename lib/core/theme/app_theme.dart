import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData buildTheme({
    AppThemeStyle? style,
    String? themeStyleKey,
    bool isDark = true,
  }) {
    if (!isDark) {
      return lightTheme;
    }
    final resolvedStyle =
        style ?? AppThemeStyle.fromKey(themeStyleKey ?? 'COSMIC_SLATE');
    return _buildDarkStyleTheme(resolvedStyle);
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      cardColor: Colors.white,
      dividerColor: AppColors.borderLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        tertiary: AppColors.glowPurple,
        surface: AppColors.surfaceLight,
        surfaceContainerHighest: const Color(0xFFEEF2F6),
        outline: AppColors.borderLight,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E2235),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme =>
      _buildDarkStyleTheme(AppThemeStyle.cosmicSlate);

  static ThemeData _buildDarkStyleTheme(AppThemeStyle style) {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      brightness: Brightness.dark,
      primaryColor: style.primary,
      scaffoldBackgroundColor: style.background,
      cardColor: style.card,
      dividerColor: Colors.white.withValues(alpha: 0.08),
      colorScheme: ColorScheme.fromSeed(
        seedColor: style.primary,
        brightness: Brightness.dark,
        primary: style.primary,
        secondary: style.secondary,
        tertiary: AppColors.glowPurple,
        surface: style.surface,
        surfaceContainerHighest: style.card,
        onSurface: AppColors.textPrimaryDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        outline: Colors.white.withValues(alpha: 0.14),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: style.surface,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: style.surface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: style.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: style.card,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: style.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: style.primary, width: 2),
        ),
      ),
    );
  }
}
