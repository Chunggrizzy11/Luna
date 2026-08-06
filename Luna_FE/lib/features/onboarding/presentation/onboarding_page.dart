import 'package:flutter/material.dart';

import '../../../shared/entities/device_identity.dart';
import 'onboarding_controller.dart';
import 'onboarding_flow_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.controller, this.onReady, super.key});

  final OnboardingController controller;
  final ValueChanged<DeviceIdentity>? onReady;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  @override
  Widget build(BuildContext context) {
    return OnboardingFlowPage(
      controller: widget.controller,
      onComplete: () {
        if (widget.controller.identity != null) {
          widget.onReady?.call(widget.controller.identity!);
        }
      },
    );
  }
}
