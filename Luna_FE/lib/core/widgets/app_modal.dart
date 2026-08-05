import 'package:flutter/material.dart';

import '../theme/app_color.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_style.dart';
import 'app_button.dart';

/// Friendly Design System - Modal/Dialog
/// Spec: E:/DesignSkillAI/friendly/modals.md
///
/// Overlay: fixed full screen, 50% black with backdrop blur
/// Content: neutral-primary background, 24px radius, shadow-xl, 24px padding
/// Header: bottom border, title 20px bold, close button (ghost)
/// Body: 24px vertical padding, 16px/1.625 line-height
/// Footer: top border, action buttons

class AppModal {
  /// Information modal with primary/secondary actions
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Đóng',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) => _ModalWrapper(
        child: _ModalContent(
          title: title,
          content: content,
          actions: actions,
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Confirmation modal (popup variant)
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Xác nhận',
    String cancelLabel = 'Hủy',
    IconData? icon,
    Color? iconColor,
    bool isDestructive = false,
  }) async {
    final result = await show<bool>(
      context: context,
      title: _PopupTitle(
        title: title,
        icon: icon ?? (isDestructive ? Icons.warning_amber_rounded : Icons.help_outline),
        iconColor: iconColor ?? (isDestructive ? AppColor.dangerLight : AppColor.accentSky),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyle.bodyLarge.copyWith(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        AppButton(
          label: confirmLabel,
          variant: isDestructive ? ButtonVariant.danger : ButtonVariant.brand,
          size: ButtonSize.base,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    return result ?? false;
  }

  /// Form modal with inputs
  static Future<T?> showForm<T>({
    required BuildContext context,
    required Widget title,
    required Widget form,
    List<Widget>? actions,
  }) {
    return show<T>(
      context: context,
      title: title,
      content: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: form,
      ),
      actions: actions,
    );
  }
}

class _ModalWrapper extends StatelessWidget {
  final Widget child;

  const _ModalWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }
}

class _ModalContent extends StatelessWidget {
  final Widget title;
  final Widget content;
  final List<Widget>? actions;

  const _ModalContent({
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColor.neutralPrimaryDark : AppColor.neutralPrimarySoftLight;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000), // shadow-xl
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          _ModalHeader(title: title),
          // Body
          Flexible(child: SingleChildScrollView(child: content)),
          // Footer
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _ModalFooter(actions: actions!),
          ],
        ],
      ),
    );
  }
}

class _ModalHeader extends StatelessWidget {
  final Widget title;

  const _ModalHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColor.borderDefaultDark : AppColor.borderDefaultLight;

    return Row(
      children: [
        Expanded(
          child: DefaultTextStyle(
            style: AppTextStyle.heading6.copyWith(
              color: isDark ? AppColor.neutralPrimaryLight : AppColor.neutralPrimaryDark,
            ),
            child: title,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.close,
            color: isDark ? AppColor.neutralPrimaryLight : AppColor.neutralPrimaryDark,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: isDark
                ? AppColor.neutralPrimaryLight
                : AppColor.neutralPrimaryDark,
          ),
        ),
      ],
    );
  }
}

class _ModalFooter extends StatelessWidget {
  final List<Widget> actions;

  const _ModalFooter({required this.actions});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColor.borderDefaultDark : AppColor.borderDefaultLight;

    return Column(
      children: [
        Divider(
          color: borderColor,
          height: 1,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: actions,
        ),
      ],
    );
  }
}

class _PopupTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const _PopupTitle({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 48, color: iconColor),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyle.heading6,
        ),
      ],
    );
  }
}