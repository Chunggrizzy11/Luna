import 'package:flutter/material.dart';

import 'app_color.dart';
import 'app_radius.dart';
import 'app_text_style.dart';

abstract final class DarkTheme {
  static final data = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColor.menstrual,
      brightness: Brightness.dark,
      surface: AppColor.darkSurface,
    ),
    scaffoldBackgroundColor: AppColor.darkSurface,
    textTheme: const TextTheme(
      displaySmall: AppTextStyle.display,
      titleLarge: AppTextStyle.title,
      bodyLarge: AppTextStyle.body,
      labelLarge: AppTextStyle.label,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: AppRadius.card),
    ),
  );
}
