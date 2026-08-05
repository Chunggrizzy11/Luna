import 'package:flutter/material.dart';

/// Friendly Design System - Color Tokens
/// Based on: E:/DesignSkillAI/friendly/colors.md
/// Supports automatic light/dark mode via CSS custom properties approach

abstract final class AppColor {
  // ============================================
  // NEUTRAL BACKGROUND TOKENS
  // ============================================

  // Primary surfaces
  static const Color neutralPrimarySoftLight = Color(0xFFFFFFFF);
  static const Color neutralPrimarySoftDark = Color(0xFF101828);
  static const Color neutralPrimaryLight = Color(0xFFFFFFFF);
  static const Color neutralPrimaryDark = Color(0xFF030712);
  static const Color neutralPrimaryMediumLight = Color(0xFFFFFFFF);
  static const Color neutralPrimaryMediumDark = Color(0xFF1E2939);
  static const Color neutralPrimaryStrongLight = Color(0xFFFFFFFF);
  static const Color neutralPrimaryStrongDark = Color(0xFF333E4F);

  // Secondary surfaces
  static const Color neutralSecondarySoftLight = Color(0xFFF9FAFB);
  static const Color neutralSecondarySoftDark = Color(0xFF101828);
  static const Color neutralSecondaryLight = Color(0xFFF9FAFB);
  static const Color neutralSecondaryDark = Color(0xFF030712);
  static const Color neutralSecondaryMediumLight = Color(0xFFF9FAFB);
  static const Color neutralSecondaryMediumDark = Color(0xFF1E2939);
  static const Color neutralSecondaryStrongLight = Color(0xFFF9FAFB);
  static const Color neutralSecondaryStrongDark = Color(0xFF333E4F);

  // Tertiary surfaces
  static const Color neutralTertiarySoftLight = Color(0xFFF3F4F6);
  static const Color neutralTertiarySoftDark = Color(0xFF101828);
  static const Color neutralTertiaryLight = Color(0xFFF3F4F6);
  static const Color neutralTertiaryDark = Color(0xFF1E2939);
  static const Color neutralTertiaryMediumLight = Color(0xFFF3F4F6);
  static const Color neutralTertiaryMediumDark = Color(0xFF333E4F);

  // Quaternary
  static const Color neutralQuaternaryLight = Color(0xFFE5E7EB);
  static const Color neutralQuaternaryDark = Color(0xFF333E4F);
  static const Color quaternaryMediumLight = Color(0xFFE5E7EB);
  static const Color quaternaryMediumDark = Color(0xFF4A5565);
  static const Color grayLight = Color(0xFFD1D5DC);
  static const Color grayDark = Color(0xFF4A5565);

  // ============================================
  // BRAND TOKENS (Warm amber/gold palette)
  // ============================================
  static const Color brandSofterLight = Color(0xFFFDF6EC);
  static const Color brandSofterDark = Color(0xFF3D2E10);
  static const Color brandSoftLight = Color(0xFFFAECDA);
  static const Color brandSoftDark = Color(0xFF5C4520);
  static const Color brandLight = Color(0xFFF5DFBB);
  static const Color brandDark = Color(0xFFF5DFBB); // Same both modes
  static const Color brandMediumLight = Color(0xFFEDD1A3);
  static const Color brandMediumDark = Color(0xFF5C4520);
  static const Color brandStrongLight = Color(0xFFD4A96E);
  static const Color brandStrongDark = Color(0xFFF5DFBB);

  // ============================================
  // STATUS TOKENS
  // ============================================

  // Success (Green)
  static const Color successSoftLight = Color(0xFFECFDF5);
  static const Color successSoftDark = Color(0xFF002C22);
  static const Color successLight = Color(0xFF007A55);
  static const Color successDark = Color(0xFF009966);
  static const Color successMediumLight = Color(0xFFD0FAE5);
  static const Color successMediumDark = Color(0xFF004F3B);
  static const Color successStrongLight = Color(0xFF006045);
  static const Color successStrongDark = Color(0xFF007A55);

  // Danger (Red/Pink)
  static const Color dangerSoftLight = Color(0xFFFEF0F2);
  static const Color dangerSoftDark = Color(0xFF4D0218);
  static const Color dangerLight = Color(0xFFC70036);
  static const Color dangerDark = Color(0xFFC70036); // Same both modes
  static const Color dangerMediumLight = Color(0xFFFFE4E6);
  static const Color dangerMediumDark = Color(0xFF8B0836);
  static const Color dangerStrongLight = Color(0xFFA50036);
  static const Color dangerStrongDark = Color(0xFFA50036);

  // Warning (Orange)
  static const Color warningSoftLight = Color(0xFFFFF7ED);
  static const Color warningSoftDark = Color(0xFF7C2D12);
  static const Color warningLight = Color(0xFFF97316);
  static const Color warningDark = Color(0xFFF97316); // Same both modes
  static const Color warningMediumLight = Color(0xFFFFEDD5);
  static const Color warningMediumDark = Color(0xFF7C2D12);
  static const Color warningStrongLight = Color(0xFFC2410C);
  static const Color warningStrongDark = Color(0xFFC2410C);

  // ============================================
  // UTILITY TOKENS
  // ============================================
  static const Color darkLight = Color(0xFF1F2937);
  static const Color darkDark = Color(0xFF1F2937);
  static const Color darkStrongLight = Color(0xFF111827);
  static const Color darkStrongDark = Color(0xFF374151);
  static const Color disabledLight = Color(0xFFF3F4F6);
  static const Color disabledDark = Color(0xFF1F2937);

  // ============================================
  // ACCENT TOKENS (Same both modes)
  // ============================================
  static const Color accentPurple = Color(0xFF8474FE);
  static const Color accentSky = Color(0xFF38BDF8);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color accentPink = Color(0xFFF472B6);
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color accentFuchsia = Color(0xFFD946EF);
  static const Color accentIndigo = Color(0xFF818CF8);
  static const Color accentOrange = Color(0xFFFB923C);

  // ============================================
  // LEGACY APP COLORS (Preserved for migration)
  // ============================================
  static const Color menstrual = Color(0xFFC62848);
  static const Color prediction = Color(0xFFF59E0B);
  static const Color ovulation = Color(0xFF2E7D5B);

  // ============================================
  // RESOLVERS (Light/Dark aware)
  // ============================================

  /// Resolve neutral primary soft based on brightness
  static Color neutralPrimarySoft(Brightness brightness) =>
      brightness == Brightness.light ? neutralPrimarySoftLight : neutralPrimarySoftDark;

  /// Resolve neutral primary based on brightness
  static Color neutralPrimary(Brightness brightness) =>
      brightness == Brightness.light ? neutralPrimaryLight : neutralPrimaryDark;

  /// Resolve neutral secondary soft based on brightness
  static Color neutralSecondarySoft(Brightness brightness) =>
      brightness == Brightness.light ? neutralSecondarySoftLight : neutralSecondarySoftDark;

  /// Resolve neutral secondary based on brightness
  static Color neutralSecondary(Brightness brightness) =>
      brightness == Brightness.light ? neutralSecondaryLight : neutralSecondaryDark;

  /// Resolve neutral secondary medium based on brightness
  static Color neutralSecondaryMedium(Brightness brightness) =>
      brightness == Brightness.light ? neutralSecondaryMediumLight : neutralSecondaryMediumDark;

  /// Resolve neutral tertiary soft based on brightness
  static Color neutralTertiarySoft(Brightness brightness) =>
      brightness == Brightness.light ? neutralTertiarySoftLight : neutralTertiarySoftDark;

  /// Resolve neutral tertiary based on brightness
  static Color neutralTertiary(Brightness brightness) =>
      brightness == Brightness.light ? neutralTertiaryLight : neutralTertiaryDark;

  /// Resolve neutral tertiary medium based on brightness
  static Color neutralTertiaryMedium(Brightness brightness) =>
      brightness == Brightness.light ? neutralTertiaryMediumLight : neutralTertiaryMediumDark;

  /// Resolve brand softer based on brightness
  static Color brandSofter(Brightness brightness) =>
      brightness == Brightness.light ? brandSofterLight : brandSofterDark;

  /// Resolve brand soft based on brightness
  static Color brandSoft(Brightness brightness) =>
      brightness == Brightness.light ? brandSoftLight : brandSoftDark;

  /// Brand is same both modes
  static const Color brand = brandLight;

  /// Resolve brand medium based on brightness
  static Color brandMedium(Brightness brightness) =>
      brightness == Brightness.light ? brandMediumLight : brandMediumDark;

  /// Resolve brand strong based on brightness
  static Color brandStrong(Brightness brightness) =>
      brightness == Brightness.light ? brandStrongLight : brandStrongDark;

  /// Resolve success based on brightness
  static Color success(Brightness brightness) =>
      brightness == Brightness.light ? successLight : successDark;

  /// Resolve danger based on brightness
  static Color danger(Brightness brightness) =>
      brightness == Brightness.light ? dangerLight : dangerDark;

  /// Resolve warning based on brightness
  static Color warning(Brightness brightness) =>
      brightness == Brightness.light ? warningLight : warningDark;

  /// Resolve disabled based on brightness
  static Color disabled(Brightness brightness) =>
      brightness == Brightness.light ? disabledLight : disabledDark;

  /// Resolve dark based on brightness
  static Color dark(Brightness brightness) =>
      brightness == Brightness.light ? darkLight : darkDark;

  /// Resolve dark strong based on brightness
  static Color darkStrong(Brightness brightness) =>
      brightness == Brightness.light ? darkStrongLight : darkStrongDark;

  // ============================================
  // SURFACE COLORS (For scaffold backgrounds)
  // ============================================
  static const Color lightSurface = Color(0xFFFFFFFF); // White for all sections
  static const Color darkSurface = Color(0xFF030712);  // Near black for dark

  static Color surface(Brightness brightness) =>
      brightness == Brightness.light ? lightSurface : darkSurface;

  // ============================================
  // PASTEL CARD COLORS (For card rotation)
  // ============================================
  static const Color cardRose = Color(0xFFF2D9DC);
  static const Color cardMint = Color(0xFFD9F2D8);
  static const Color cardLavender = Color(0xFFE0D9F1);
  static const Color cardSky = Color(0xFFDAEFF8);

  static const List<Color> pastelCardColors = [
    cardRose,
    cardMint,
    cardLavender,
    cardSky,
  ];

  // ============================================
  // BRAND GRADIENT (For primary buttons)
  // ============================================
  /// Purple gradient: linear-gradient(0deg, rgba(77, 54, 208, 1) 0%, rgba(132, 116, 254, 1) 100%)
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF4D36D0), // rgba(77, 54, 208, 1)
      Color(0xFF8474FE), // rgba(132, 116, 254, 1)
    ],
  );

  /// Menstrual gradient (legacy brand) - for cycle-specific UI
  static const LinearGradient menstrualGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFB01D3D),
      Color(0xFFC62848),
    ],
  );

  // ============================================
  // PAGE-LEVEL GRADIENT (Subtle warm-to-cool diagonal)
  // ============================================
  static const LinearGradient pageGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF8F0), // Very soft peach
      Color(0xFFF8F5FF), // Very soft lavender
    ],
    stops: [0.0, 1.0],
  );

  static const LinearGradient pageGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1520), // Dark warm
      Color(0xFF151825), // Dark cool
    ],
    stops: [0.0, 1.0],
  );

  static LinearGradient pageGradient(Brightness brightness) =>
      brightness == Brightness.light ? pageGradientLight : pageGradientDark;
}