import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_identity_state.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import 'partner_providers.dart';

class PartnerPendingPage extends ConsumerWidget {
  const PartnerPendingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(pairingStatusProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Đăng xuất',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Đăng xuất'),
                content: const Text('Bạn có chắc chắn muốn thoát và tạo tài khoản mới không?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              ref.read(appIdentityStateProvider).revokeIdentity();
            }
          },
        ),
        title: const Text('Luna đồng hành'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: statusAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_outline, size: 56),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Chưa ghép đôi với ai.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Nhập mã ghép đôi',
                  icon: Icons.link,
                  onPressed: () => context.push(AppRoutes.joinPairing),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => ref.invalidate(pairingStatusProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
            data: (status) {
              if (status.isPaired) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Đã ghép đôi thành công!',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Bạn đang đồng hành cùng ${status.partnerName ?? 'chủ tài khoản'}.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Trải nghiệm dành cho người đồng hành đang được chuẩn bị.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              }

              // Not paired yet - show join button
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_outline, size: 56),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Chưa ghép đôi với ai',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Hãy nhập mã ghép đôi 8 ký tự từ chủ tài khoản để bắt đầu đồng hành.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Nhập mã ghép đôi',
                    icon: Icons.link,
                    onPressed: () => context.push(AppRoutes.joinPairing),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
