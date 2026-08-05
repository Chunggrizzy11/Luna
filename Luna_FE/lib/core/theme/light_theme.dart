import 'package:flutter/material.dart';

import 'app_color.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_text_style.dart';

abstract final class LightTheme {
  static final data = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // ============================================
    // COLOR SCHEME (Friendly Design System)
    // ============================================
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColor.menstrual, // Keep legacy seed for cycle app
      brightness: Brightness.light,
      surface: AppColor.lightSurface,
      // Override seed colors with Friendly palette
      primary: AppColor.brandStrongLight, // Purple gradient
      secondary: AppColor.accentSky,
      background: AppColor.lightSurface,
      error: AppColor.dangerLight,
      onPrimary: AppColor.white,
      onSecondary: AppColor.black,
      onBackground: AppColor.neutralPrimaryDark,
      onError: AppColor.white,
    ),

    // ============================================
    // SURFACE
    // ============================================
    scaffoldBackgroundColor: AppColor.lightSurface,

    // ============================================
    // EXTENSIONS
    // ============================================
    extensions: const [AppSemanticColors.light],

    // ============================================
    // TEXT THEME (Friendly Typography)
    // ============================================
    textTheme: const TextTheme(
      displaySmall: AppTextStyle.displaySmall,
      titleLarge: AppTextStyle.titleLarge,
      bodyLarge: AppTextStyle.bodyLarge,
      labelLarge: AppTextStyle.buttonLabel,
      titleMedium: AppTextStyle.titleMedium,
      titleSmall: AppTextStyle.titleSmall,
    ),

    // ============================================
    // CARD THEME (Friendly Card)
    // ============================================
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(48))),
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
      backgroundColor: AppColor.lightSurface,
      foregroundColor: AppColor.neutralPrimaryDark,
      elevation: 0,
    ),

    // ============================================
    // BUTTON THEME
    // ============================================
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.brandStrongLight,
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
      backgroundColor: AppColor.neutralSecondarySoftLight,
      selectedColor: AppColor.brandSofterLight,
      labelStyle: AppTextStyle.buttonLabel.copyWith(color: AppColor.neutralPrimaryDark),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(9999))),
    ),
  );
}