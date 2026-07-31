import '../../features/onboarding/data/device_repository.dart';
import '../../features/onboarding/domain/register_device.dart';
import '../../features/onboarding/presentation/onboarding_controller.dart';
import '../../shared/entities/device_identity.dart';
import '../error/exception.dart';
import '../network/api_client.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';
import 'app_config.dart';
import 'env.dart';

export 'app_config.dart';

abstract final class AppInitializer {
  static Future<AppConfig> initialize({
    SecureStorageService? secureStorage,
    String? apiBaseUrl,
  }) async {
    final storage = secureStorage ?? SecureStorageService();
    DeviceIdentity? identity;
    try {
      identity = await storage.readIdentity();
    } on StorageException {
      identity = null;
    }

    final dioClient = DioClient(
      tokenProvider: () async => (await storage.readIdentity())?.token,
      baseUrl: apiBaseUrl ?? Env.apiBaseUrl,
    );
    final apiClient = ApiClient(dioClient.dio);
    final repository = DeviceRepository(apiClient: apiClient);
    final registerDevice = RegisterDevice(repository);
    final controller = OnboardingController(
      registerDevice: registerDevice,
      secureStorage: storage,
    );
    return AppConfig(
      secureStorage: storage,
      dioClient: dioClient,
      apiClient: apiClient,
      registerDevice: registerDevice,
      onboardingController: controller,
      initialIdentity: identity,
    );
  }
}
