import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_color.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_text_style.dart';

abstract final class DarkTheme {
  static final data = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // ============================================
    // COLOR SCHEME (Friendly Design System)
    // ============================================
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColor.menstrual, // Keep legacy seed for cycle app
      brightness: Brightness.dark,
      surface: AppColor.darkSurface,
      // Override seed colors with Friendly palette
      primary: AppColor.brandStrongDark, // Purple gradient
      secondary: AppColor.accentSky,
      background: AppColor.darkSurface,
      error: AppColor.dangerDark,
      onPrimary: AppColor.white,
      onSecondary: AppColor.black,
      onBackground: AppColor.neutralPrimaryLight,
      onError: AppColor.white,
    ),

    // ============================================
    // SURFACE
    // ============================================
    scaffoldBackgroundColor: Colors.transparent,

    // ============================================
    // EXTENSIONS
    // ============================================
    extensions: const [AppSemanticColors.dark],

    // ============================================
    // TEXT THEME (Friendly Typography)
    // ============================================
    textTheme: GoogleFonts.publicSansTextTheme(const TextTheme(
      displaySmall: AppTextStyle.displaySmall,
      titleLarge: AppTextStyle.titleLarge,
      bodyLarge: AppTextStyle.bodyLarge,
      labelLarge: AppTextStyle.buttonLabel,
      titleMedium: AppTextStyle.titleMedium,
      titleSmall: AppTextStyle.titleSmall,
    )),

    // ============================================
    // CARD THEME (Friendly Card)
    // ============================================
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(48))),
      color: AppColor.neutralPrimarySoftDark,
    ),

    // ============================================
    // INPUT DECORATION THEME (Friendly Input)
    // ============================================
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(9999))),
    ),

    // ============================================
    // APP BAR THEME
    // ============================================
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColor.neutralPrimaryLight,
      elevation: 0,
    ),

    // ============================================
    // BUTTON THEME
    // ============================================
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.brandStrongDark,
        foregroundColor: AppColor.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(9999))),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    ),

    // ============================================
    // CHIPS / BADGES THEME
    // ============================================
    chipTheme: ChipThemeData(
      backgroundColor: AppColor.neutralSecondarySoftDark,
      selectedColor: AppColor.brandSofterDark,
      labelStyle: AppTextStyle.buttonLabel.copyWith(color: AppColor.neutralPrimaryLight),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(9999))),
    ),
  );
}