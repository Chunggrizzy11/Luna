import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_text_style.dart';

/// Friendly Design System - Badge (replaces AppChip)
/// Spec: E:/DesignSkillAI/friendly/badges.md
///
/// Pill shape (9999px), 1px border, variants for brand/neutral/danger/success/warning/dark
/// Dismissible badges with close button
/// Notification dot badges

enum BadgeVariant { brand, neutral, danger, success, warning, dark }
enum BadgeSize { small, large }

class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.variant = BadgeVariant.neutral,
    this.size = BadgeSize.small,
    this.icon,
    this.dismissible = false,
    this.onDismissed,
    this.isNotification = false,
    super.key,
  });

  final String label;
  final BadgeVariant variant;
  final BadgeSize size;
  final IconData? icon;
  final bool dismissible;
  final VoidCallback? onDismissed;
  final bool isNotification;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spec = _BadgeSpec.fromVariant(variant, isDark);
    final horizontal = size == BadgeSize.small ? 6.0 : 8.0;
    final vertical = size == BadgeSize.small ? 2.0 : 4.0;
    final fontSize = size == BadgeSize.small ? 12.0 : 14.0;
    final iconSize = size == BadgeSize.small ? 12.0 : 14.0;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: spec.textColor),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: AppTextStyle.caption.copyWith(
            fontSize: fontSize,
            color: spec.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (dismissible) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDismissed,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: spec.dismissHoverBg,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Icon(
                Icons.close,
                size: iconSize,
                color: spec.textColor,
              ),
            ),
          ),
        ],
      ],
    );

    if (isNotification) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColor.dangerLight,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: isDark ? AppColor.neutralPrimarySoftDark : AppColor.neutralPrimarySoftLight,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        color: spec.background,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: spec.border, width: 1),
      ),
      child: content,
    );
  }
}

class _BadgeSpec {
  const _BadgeSpec({
    required this.background,
    required this.border,
    required this.textColor,
    required this.dismissHoverBg,
  });

  final Color background;
  final Color border;
  final Color textColor;
  final Color dismissHoverBg;

  factory _BadgeSpec.fromVariant(BadgeVariant variant, bool isDark) {
    switch (variant) {
      case BadgeVariant.brand:
        return _BadgeSpec(
          background: isDark ? AppColor.brandSoftDark : AppColor.brandSofterLight,
          border: isDark ? AppColor.borderBrandSubtleDark : AppColor.borderBrandSubtleLight,
          textColor: isDark ? AppColor.brandMediumDark : AppColor.brandStrongLight,
          dismissHoverBg: isDark ? AppColor.brandSoftDark : AppColor.brandSoftLight,
        );
      case BadgeVariant.neutral:
        return _BadgeSpec(
          background: isDark ? AppColor.neutralPrimarySoftDark : AppColor.neutralPrimarySoftLight,
          border: isDark ? AppColor.borderDefaultDark : AppColor.borderDefaultLight,
          textColor: isDark ? AppColor.neutralPrimaryLight : AppColor.neutralPrimaryDark,
          dismissHoverBg: isDark ? AppColor.neutralTertiaryMediumDark : AppColor.neutralTertiaryMediumLight,
        );
      case BadgeVariant.danger:
        return _BadgeSpec(
          background: isDark ? AppColor.dangerMediumDark : AppColor.dangerSoftLight,
          border: isDark ? AppColor.borderDangerSubtleDark : AppColor.borderDangerSubtleLight,
          textColor: isDark ? AppColor.fgDangerStrong : AppColor.fgDangerStrong,
          dismissHoverBg: isDark ? AppColor.dangerMediumDark : AppColor.dangerMediumLight,
        );
      case BadgeVariant.success:
        return _BadgeSpec(
          background: isDark ? AppColor.successMediumDark : AppColor.successSoftLight,
          border: isDark ? AppColor.borderSuccessSubtleDark : AppColor.borderSuccessSubtleLight,
          textColor: isDark ? AppColor.fgSuccessStrong : AppColor.fgSuccessStrong,
          dismissHoverBg: isDark ? AppColor.successMediumDark : AppColor.successMediumLight,
        );
      case BadgeVariant.warning:
        return _BadgeSpec(
          background: isDark ? AppColor.warningMediumDark : AppColor.warningSoftLight,
          border: isDark ? AppColor.borderWarningSubtleDark : AppColor.borderWarningSubtleLight,
          textColor: isDark ? AppColor.fgWarning : AppColor.fgWarning,
          dismissHoverBg: isDark ? AppColor.warningMediumDark : AppColor.warningMediumLight,
        );
      case BadgeVariant.dark:
        return _BadgeSpec(
          background: isDark ? AppColor.darkStrongDark : AppColor.darkLight,
          border: Colors.transparent,
          textColor: Colors.white,
          dismissHoverBg: isDark ? AppColor.neutralTertiaryMediumDark : AppColor.neutralTertiaryMediumLight,
        );
    }
  }
}

/// Notification badge for icons (small red dot)
class NotificationBadge extends StatelessWidget {
  const NotificationBadge({
    required this.child,
    this.count,
    this.show = true,
    super.key,
  });

  final Widget child;
  final int? count;
  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) return child;

    final displayCount = count ?? 0;
    final showDot = displayCount == 0;
    final label = displayCount > 99 ? '99+' : displayCount.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -4,
          child: AnimatedScale(
            scale: show ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: showDot
                ? Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColor.dangerLight,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColor.neutralPrimarySoftDark
                            : AppColor.neutralPrimarySoftLight,
                        width: 2,
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColor.dangerLight,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColor.neutralPrimarySoftDark
                            : AppColor.neutralPrimarySoftLight,
                        width: 2,
                      ),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}