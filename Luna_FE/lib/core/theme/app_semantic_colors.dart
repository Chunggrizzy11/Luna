import 'package:flutter/material.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.menstrualForeground,
    required this.menstrualBackground,
    required this.predictionForeground,
    required this.predictionBackground,
    required this.ovulationForeground,
    required this.ovulationBackground,
  });

  static const light = AppSemanticColors(
    menstrualForeground: Color(0xFF7A1230),
    menstrualBackground: Color(0xFFFCE8ED),
    predictionForeground: Color(0xFF5C3A00),
    predictionBackground: Color(0xFFFFF3D6),
    ovulationForeground: Color(0xFF0F5132),
    ovulationBackground: Color(0xFFE1F4EA),
  );

  static const dark = AppSemanticColors(
    menstrualForeground: Color(0xFFFFD9E2),
    menstrualBackground: Color(0xFF4A1724),
    predictionForeground: Color(0xFFFFE7AD),
    predictionBackground: Color(0xFF493608),
    ovulationForeground: Color(0xFFC4F5DB),
    ovulationBackground: Color(0xFF123D2C),
  );

  final Color menstrualForeground;
  final Color menstrualBackground;
  final Color predictionForeground;
  final Color predictionBackground;
  final Color ovulationForeground;
  final Color ovulationBackground;

  @override
  AppSemanticColors copyWith({
    Color? menstrualForeground,
    Color? menstrualBackground,
    Color? predictionForeground,
    Color? predictionBackground,
    Color? ovulationForeground,
    Color? ovulationBackground,
  }) => AppSemanticColors(
    menstrualForeground: menstrualForeground ?? this.menstrualForeground,
    menstrualBackground: menstrualBackground ?? this.menstrualBackground,
    predictionForeground: predictionForeground ?? this.predictionForeground,
    predictionBackground: predictionBackground ?? this.predictionBackground,
    ovulationForeground: ovulationForeground ?? this.ovulationForeground,
    ovulationBackground: ovulationBackground ?? this.ovulationBackground,
  );

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      menstrualForeground: Color.lerp(
        menstrualForeground,
        other.menstrualForeground,
        t,
      )!,
      menstrualBackground: Color.lerp(
        menstrualBackground,
        other.menstrualBackground,
        t,
      )!,
      predictionForeground: Color.lerp(
        predictionForeground,
        other.predictionForeground,
        t,
      )!,
      predictionBackground: Color.lerp(
        predictionBackground,
        other.predictionBackground,
        t,
      )!,
      ovulationForeground: Color.lerp(
        ovulationForeground,
        other.ovulationForeground,
        t,
      )!,
      ovulationBackground: Color.lerp(
        ovulationBackground,
        other.ovulationBackground,
        t,
      )!,
    );
  }
}
