import 'package:flutter/material.dart';

import '../../../core/config/app_identity_state.dart';
import '../../../core/theme/app_color.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_error.dart';
import '../../../shared/enums/device_role.dart';

class OnboardingCompletePage extends StatelessWidget {
  const OnboardingCompletePage({required this.identityState, super.key});

  final AppIdentityState identityState;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Luna')),
    body: AnimatedBuilder(
      animation: identityState,
      builder: (context, _) {
        final identity = identityState.identity;
        if (identity == null ||
            identityState.status != AppIdentityStatus.present) {
          return const AppError(
            message: 'Không thể xác minh danh tính thiết bị.',
          );
        }
        final roleLabel = switch (identity.role) {
          DeviceRole.owner => 'Theo dõi chu kỳ',
          DeviceRole.partner => 'Đồng hành',
        };
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 64,
                    color: AppColor.ovulation,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Thiết bị đã được kết nối an toàn',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(roleLabel),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
