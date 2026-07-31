import '../../features/onboarding/domain/register_device.dart';
import '../../features/onboarding/presentation/onboarding_controller.dart';
import '../network/api_client.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';
import 'app_identity_state.dart';

class AppConfig {
  const AppConfig({
    required this.secureStorage,
    required this.dioClient,
    required this.apiClient,
    required this.registerDevice,
    required this.onboardingController,
    required this.identityState,
  });

  final SecureStorageService secureStorage;
  final DioClient dioClient;
  final ApiClient apiClient;
  final RegisterDevice registerDevice;
  final OnboardingController onboardingController;
  final AppIdentityState identityState;
}
