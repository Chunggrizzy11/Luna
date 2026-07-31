import 'package:flutter/widgets.dart';

import '../../features/onboarding/domain/register_device.dart';
import '../../features/onboarding/presentation/onboarding_controller.dart';
import '../../shared/entities/device_identity.dart';
import '../network/api_client.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';

class AppConfig {
  const AppConfig({
    required this.secureStorage,
    required this.dioClient,
    required this.apiClient,
    required this.registerDevice,
    required this.onboardingController,
    required this.initialIdentity,
    required this.homeBuilder,
  });

  final SecureStorageService secureStorage;
  final DioClient dioClient;
  final ApiClient apiClient;
  final RegisterDevice registerDevice;
  final OnboardingController onboardingController;
  final DeviceIdentity? initialIdentity;
  final WidgetBuilder homeBuilder;
}
