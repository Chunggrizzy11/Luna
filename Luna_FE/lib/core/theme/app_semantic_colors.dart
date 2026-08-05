import 'package:flutter/material.dart';

/// Friendly Design System - Semantic Colors
/// Based on: E:/DesignSkillAI/friendly/colors.md
/// Extends ThemeExtension

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    // Status
    required this.success,
    required this.successStrong,
    required this.danger,
    required this.dangerStrong,
    required this.warning,
    required this.warningSubtle,

    // Text Semantic
    required this.fgSuccess,
    required this.fgSuccessStrong,
    required this.fgDanger,
    required this.fgDangerStrong,
    required this.fgWarning,
    required this.fgWarningSubtle,
  });

  static const light = AppSemanticColors(
    success: Color(0xFF047857),
    successStrong: Color(0xFF065F46),
    danger: Color(0xFFBE123C),
    dangerStrong: Color(0xFF881337),
    warning: Color(0xFF7C2D12),
    warningSubtle: Color(0xFFEA580C),

    fgSuccess: Color(0xFF047857),
    fgSuccessStrong: Color(0xFF065F46),
    fgDanger: Color(0xFFBE123C),
    fgDangerStrong: Color(0xFF881337),
    fgWarning: Color(0xFF7C2D12),
    fgWarningSubtle: Color(0xFFEA580C),
  );

  static const dark = AppSemanticColors(
    success: Color(0xFF065F46),
    successStrong: Color(0xFF10B981),
    danger: Color(0xFFF43F5E),
    dangerStrong: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    warningSubtle: Color(0xFFF97316),

    fgSuccess: Color(0xFF065F46),
    fgSuccessStrong: Color(0xFF10B981),
    fgDanger: Color(0xFFF43F5E),
    fgDangerStrong: Color(0xFFF87171),
    fgWarning: Color(0xFFFBBF24),
    fgWarningSubtle: Color(0xFFF97316),
  );

  final Color success;
  final Color successStrong;
  final Color danger;
  final Color dangerStrong;
  final Color warning;
  final Color warningSubtle;

  final Color fgSuccess;
  final Color fgSuccessStrong;
  final Color fgDanger;
  final Color fgDangerStrong;
  final Color fgWarning;
  final Color fgWarningSubtle;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? successStrong,
    Color? danger,
    Color? dangerStrong,
    Color? warning,
    Color? warningSubtle,
    Color? fgSuccess,
    Color? fgSuccessStrong,
    Color? fgDanger,
    Color? fgDangerStrong,
    Color? fgWarning,
    Color? fgWarningSubtle,
  }) => AppSemanticColors(
    success: success ?? this.success,
    successStrong: successStrong ?? this.successStrong,
    danger: danger ?? this.danger,
    dangerStrong: dangerStrong ?? this.dangerStrong,
    warning: warning ?? this.warning,
    warningSubtle: warningSubtle ?? this.warningSubtle,
    fgSuccess: fgSuccess ?? this.fgSuccess,
    fgSuccessStrong: fgSuccessStrong ?? this.fgSuccessStrong,
    fgDanger: fgDanger ?? this.fgDanger,
    fgDangerStrong: fgDangerStrong ?? this.fgDangerStrong,
    fgWarning: fgWarning ?? this.fgWarning,
    fgWarningSubtle: fgWarningSubtle ?? this.fgWarningSubtle,
  );

  @override
  AppSemanticColors lerp(covariant ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      successStrong: Color.lerp(successStrong, other.successStrong, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerStrong: Color.lerp(dangerStrong, other.dangerStrong, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSubtle: Color.lerp(warningSubtle, other.warningSubtle, t)!,
      fgSuccess: Color.lerp(fgSuccess, other.fgSuccess, t)!,
      fgSuccessStrong: Color.lerp(fgSuccessStrong, other.fgSuccessStrong, t)!,
      fgDanger: Color.lerp(fgDanger, other.fgDanger, t)!,
      fgDangerStrong: Color.lerp(fgDangerStrong, other.fgDangerStrong, t)!,
      fgWarning: Color.lerp(fgWarning, other.fgWarning, t)!,
      fgWarningSubtle: Color.lerp(fgWarningSubtle, other.fgWarningSubtle, t)!,
    );
  }
}
