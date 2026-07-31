import 'package:flutter/material.dart';

import 'app_color.dart';
import 'app_radius.dart';
import 'app_text_style.dart';

abstract final class LightTheme {
  static final data = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColor.menstrual,
      brightness: Brightness.light,
      surface: AppColor.lightSurface,
    ),
    scaffoldBackgroundColor: AppColor.lightSurface,
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
