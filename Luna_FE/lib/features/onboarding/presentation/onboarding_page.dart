import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_error.dart';
import '../../../shared/entities/device_identity.dart';
import '../../../shared/enums/device_role.dart';
import 'onboarding_controller.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.controller, this.onReady, super.key});

  final OnboardingController controller;
  final ValueChanged<DeviceIdentity>? onReady;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  DeviceRole _selectedRole = DeviceRole.owner;

  Future<void> _continue() async {
    try {
      final identity = await widget.controller.bootstrap(_selectedRole);
      if (mounted) widget.onReady?.call(identity);
    } on Object {
      // The controller exposes a safe, user-facing error state for retry.
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final isLoading = widget.controller.state == OnboardingState.loading;
      return Scaffold(
        appBar: AppBar(title: const Text('Chào mừng đến Luna')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Bạn sử dụng Luna với vai trò nào?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<DeviceRole>(
                segments: const [
                  ButtonSegment(
                    value: DeviceRole.owner,
                    label: Text('Theo dõi chu kỳ'),
                    icon: Icon(Icons.favorite_outline),
                  ),
                  ButtonSegment(
                    value: DeviceRole.partner,
                    label: Text('Đồng hành'),
                    icon: Icon(Icons.people_outline),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: isLoading
                    ? null
                    : (roles) => setState(() => _selectedRole = roles.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (widget.controller.state == OnboardingState.error)
                AppError(
                  message:
                      widget.controller.errorMessage ??
                      'Không thể đăng ký thiết bị.',
                ),
              AppButton(
                label: 'Tiếp tục',
                isLoading: isLoading,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      );
    },
  );
}
