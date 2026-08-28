import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final bodyTextTheme = GoogleFonts.workSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.cream,
      displayColor: AppColors.cream,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.nightBlue,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.gold,
        secondary: AppColors.teal,
        surface: AppColors.surface,
        onPrimary: AppColors.nightBlue,
        onSurface: AppColors.cream,
        error: const Color(0xFFCF6679),
      ),
      textTheme: bodyTextTheme.copyWith(
        headlineLarge: GoogleFonts.amiri(
          textStyle: bodyTextTheme.headlineLarge,
          color: AppColors.goldLight,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.amiri(
          textStyle: bodyTextTheme.headlineMedium,
          color: AppColors.goldLight,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.amiri(
          textStyle: bodyTextTheme.titleLarge,
          color: AppColors.cream,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.amiri(
          textStyle: bodyTextTheme.titleMedium,
          color: AppColors.cream,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.nightBlue,
        foregroundColor: AppColors.cream,
        elevation: 0,
        titleTextStyle: GoogleFonts.amiri(
          fontSize: 22,
          color: AppColors.cream,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.nightBlue),
        side: const BorderSide(color: AppColors.goldLight, width: 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.cream,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.teal
              : Colors.white24,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.cream,
        ),
      ),
      dividerColor: Colors.white12,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.nightBlue,
          textStyle: GoogleFonts.workSans(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.goldLight,
          side: const BorderSide(color: AppColors.goldLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }
}
