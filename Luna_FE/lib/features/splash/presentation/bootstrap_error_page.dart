import 'package:flutter/material.dart';

import '../../../core/config/app_identity_state.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_loading.dart';

class BootstrapErrorPage extends StatelessWidget {
  const BootstrapErrorPage({required this.identityState, super.key});

  final AppIdentityState identityState;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Luna')),
    body: AnimatedBuilder(
      animation: identityState,
      builder: (context, _) {
        if (identityState.isRetrying ||
            identityState.status != AppIdentityStatus.error) {
          return const AppLoading(label: 'Đang thử lại');
        }
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.security_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Không thể truy cập danh tính bảo mật của thiết bị.',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(label: 'Thử lại', onPressed: identityState.retry),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
