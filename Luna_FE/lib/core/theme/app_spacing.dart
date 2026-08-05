/// Friendly Design System - Spacing Tokens
/// Based on: E:/DesignSkillAI/friendly/layout.md
/// Base unit: 8px

abstract final class AppSpacing {
  static const double unit = 8.0;

  static const double xxs = 4.0;
  static const double xs = 8.0;   // unit
  static const double sm = 12.0;
  static const double md = 16.0;  // 2 * unit
  static const double lg = 24.0;  // 3 * unit (Container horizontal padding)
  static const double xl = 32.0;  // 4 * unit
  static const double xxl = 48.0; // 6 * unit (Section header content)
  static const double huge = 64.0; // 8 * unit
  static const double section = 96.0; // 12 * unit (Section vertical padding)

  // Contextual aliases
  static const double containerHorizontalPadding = lg;
  static const double cardGridGap = lg;
  static const double rowGap = md;
  static const double sectionHeaderMargin = xxl;
}
