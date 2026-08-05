import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Friendly Design System - Typography Tokens
/// Based on: E:/DesignSkillAI/friendly/typography.md
/// Font: Public Sans (using google_fonts)

abstract final class AppTextStyle {
  static String? get fontFamily => GoogleFonts.publicSans().fontFamily;

  // ============================================
  // HEADING SCALE (Desktop values)
  // ============================================

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 64, // h1
    height: 1.05,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 48, // h2
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36, // h3
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30, // h4
    height: 1.25,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle heading5 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24, // h5
    height: 1.4,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle heading6 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20, // h6
    height: 1.3,
    fontWeight: FontWeight.w700,
  );

  // ============================================
  // PARAGRAPHS
  // ============================================

  static const TextStyle leadingParagraph = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.6,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.6,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.6,
    fontWeight: FontWeight.normal,
  );

  // ============================================
  // UI LABELS
  // ============================================

  static const TextStyle buttonLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.0, // Control labels shouldn't use paragraph line height
    fontWeight: FontWeight.w500,
  );

  static const TextStyle inputLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.0,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.0,
    fontWeight: FontWeight.w500,
  );

  // ============================================
  // EMPHASIS
  // ============================================
  static const TextStyle strong = TextStyle(
    fontFamily: fontFamily,
    fontWeight: FontWeight.w700,
  );

  // Helper for responsive font sizes (simplified implementation)
  static TextStyle responsiveHeading1(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 768) {
      return displaySmall.copyWith(fontSize: 44);
    }
    return displaySmall.copyWith(fontSize: 36);
  }
}
