import 'package:flutter/material.dart';

class AppColors {
  // Brand Red ASKLIN
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color primaryDarkRed = Color(0xFFB71C1C);
  static const Color primaryLightRed = Color(0xFFEF5350);
  
  // Tints & Backgrounds
  static const Color softRed = Color(0xFFFEE2E2);
  static const Color softRedLight = Color(0xFFFFEBEE);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  
  // Neutral Typography
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  
  // Semantic Status
  static const Color statusGreen = Color(0xFF16A34A);
  static const Color statusGreenBg = Color(0xFFDCFCE7);
  static const Color statusYellow = Color(0xFFD97706);
  static const Color statusYellowBg = Color(0xFFFEF3C7);
  static const Color statusBlue = Color(0xFF2563EB);
  static const Color statusBlueBg = Color(0xFFDBEAFE);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryRed,
        primary: AppColors.primaryRed,
        surface: AppColors.surfaceWhite,
        background: AppColors.backgroundLight,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      fontFamily: 'Inter',
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          elevation: 2,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceWhite,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderSubtle, width: 0.8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.5),
        ),
      ),
    );
  }
}

