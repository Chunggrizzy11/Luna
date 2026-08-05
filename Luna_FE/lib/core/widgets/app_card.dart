import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_style.dart';

/// Friendly Design System - Card
/// Spec: E:/DesignSkillAI/friendly/cards.md
///
/// Background: pastel fills rotated across cards in a group
/// Border: none (colorful) or 1px border-default (neutral)
/// Radius: 48px
/// Shadow: NONE
/// Interactive hover: brightness filter (no shadow change)
/// Non-interactive: no hover styles

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(24),
    this.backgroundIndex,
    this.neutral = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final int? backgroundIndex;
  final bool neutral;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = neutral
        ? (isDark ? AppColor.neutralPrimarySoftDark : AppColor.neutralPrimarySoftLight)
        : AppColor.pastelCardColors[backgroundIndex ?? 0];

    final border = neutral
        ? Border.all(
            color: isDark ? AppColor.borderDefaultDark : AppColor.borderDefaultLight,
            width: 1,
          )
        : null;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(48),
        border: border,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) {
      return card;
    }

    return Semantics(
      button: true,
      label: 'Card',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(48),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(48),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            child: AnimatedBuilder(
              animation: AlwaysStoppedAnimation(onTap != null ? 1.0 : 0.0),
              builder: (context, _) {
                return ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.white.withValues(alpha: 0.03), // subtle brightness lift on hover
                    BlendMode.srcOver,
                  ),
                  child: card,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper to get the next pastel color in rotation
Color getPastelCardColor(int index) => AppColor.pastelCardColors[index % AppColor.pastelCardColors.length];