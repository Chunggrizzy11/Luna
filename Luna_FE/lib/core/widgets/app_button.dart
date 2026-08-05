import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_text_style.dart';

/// Friendly Design System - Button
/// Spec: E:/DesignSkillAI/friendly/buttons.md
///
/// All buttons are pill-shaped (9999px), 1px border, medium weight labels.
/// Brand variant uses the purple gradient. Ghost/disabled have no shadow.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ButtonVariant.brand,
    this.size = ButtonSize.base,
    this.disabled = false,
    this.fullWidth = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool disabled;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spec = _ButtonSpec.fromVariant(variant, isDark);
    final effectiveDisabled = disabled || (isLoading && onPressed == null);
    final effectiveOnPressed = isLoading || effectiveDisabled ? null : onPressed;

    final horizontal = switch (size) {
      ButtonSize.extraSmall => 16.0,
      ButtonSize.small => 16.0,
      ButtonSize.base => 20.0,
      ButtonSize.large => 24.0,
      ButtonSize.extraLarge => 28.0,
    };
    final vertical = switch (size) {
      ButtonSize.extraSmall => 6.0,
      ButtonSize.small => 8.0,
      ButtonSize.base => 10.0,
      ButtonSize.large => 12.0,
      ButtonSize.extraLarge => 14.0,
    };
    final fontSize = switch (size) {
      ButtonSize.extraSmall => 12.0,
      ButtonSize.small => 14.0,
      ButtonSize.base => 14.0,
      ButtonSize.large => 16.0,
      ButtonSize.extraLarge => 16.0,
    };

    final labelStyle = AppTextStyle.buttonLabel.copyWith(
      fontSize: fontSize,
      color: effectiveDisabled
          ? AppColor.disabled(isDark ? Brightness.dark : Brightness.light)
          : spec.textColor,
    );

    return Semantics(
      button: true,
      enabled: effectiveOnPressed != null,
      label: label,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 200),
          child: Material(
            color: Colors.transparent,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                gradient: spec.gradient,
                color: spec.background,
                borderRadius: BorderRadius.circular(9999),
                border: spec.border == null
                    ? null
                    : Border.all(color: spec.border!),
                boxShadow: spec.hasShadow
                    ? const [
                        BoxShadow(
                          color: Color(0x0D000000), // subtle shadow-xs
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: InkWell(
                onTap: effectiveOnPressed,
                splashColor: Colors.white.withValues(alpha: 0.2),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontal,
                    vertical: vertical,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading) ...[
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: spec.textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else if (icon != null) ...[
                        Icon(icon, size: 16, color: spec.textColor),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          style: labelStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonSpec {
  const _ButtonSpec({
    this.gradient,
    this.background,
    this.border,
    required this.textColor,
    this.hasShadow = true,
  });

  final LinearGradient? gradient;
  final Color? background;
  final Color? border;
  final Color textColor;
  final bool hasShadow;

  factory _ButtonSpec.fromVariant(ButtonVariant variant, bool isDark) {
    switch (variant) {
      case ButtonVariant.brand:
        return _ButtonSpec(
          gradient: AppColor.brandGradient,
          textColor: Colors.white,
        );
      case ButtonVariant.secondary:
        return _ButtonSpec(
          background: isDark
              ? AppColor.neutralSecondaryMediumDark
              : AppColor.neutralSecondaryMediumLight,
          border: isDark
              ? AppColor.neutralTertiaryMediumDark
              : AppColor.neutralTertiaryMediumLight,
          textColor: isDark
              ? AppColor.neutralPrimaryLight
              : AppColor.neutralPrimaryDark,
        );
      case ButtonVariant.tertiary:
        return _ButtonSpec(
          background: isDark
              ? AppColor.neutralPrimarySoftDark
              : AppColor.neutralPrimarySoftLight,
          border: isDark
              ? AppColor.neutralTertiaryMediumDark
              : AppColor.neutralTertiaryMediumLight,
          textColor: isDark
              ? AppColor.neutralPrimaryLight
              : AppColor.neutralPrimaryDark,
        );
      case ButtonVariant.success:
        return _ButtonSpec(
          background: isDark ? AppColor.successDark : AppColor.successLight,
          textColor: Colors.white,
        );
      case ButtonVariant.danger:
        return _ButtonSpec(
          background: isDark ? AppColor.dangerDark : AppColor.dangerLight,
          textColor: Colors.white,
        );
      case ButtonVariant.warning:
        return _ButtonSpec(
          background: isDark ? AppColor.warningDark : AppColor.warningLight,
          textColor: Colors.white,
        );
      case ButtonVariant.dark:
        return _ButtonSpec(
          background: isDark ? AppColor.darkStrongDark : AppColor.darkLight,
          textColor: Colors.white,
        );
      case ButtonVariant.ghost:
        return _ButtonSpec(
          background: Colors.transparent,
          textColor: isDark
              ? AppColor.neutralPrimaryLight
              : AppColor.neutralPrimaryDark,
          hasShadow: false,
        );
    }
  }
}

enum ButtonVariant { brand, secondary, tertiary, success, danger, warning, dark, ghost }
enum ButtonSize { extraSmall, small, base, large, extraLarge }
