import '../../features/onboarding/data/device_repository.dart';
import '../../features/onboarding/domain/register_device.dart';
import '../../features/onboarding/presentation/onboarding_controller.dart';
import '../network/api_client.dart';
import '../network/dio_client.dart';
import '../network/socket_service.dart';
import '../storage/secure_storage_service.dart';
import 'app_config.dart';
import 'app_identity_state.dart';
import 'env.dart';

export 'app_config.dart';

abstract final class AppInitializer {
  static Future<AppConfig> initialize({
    SecureStorageService? secureStorage,
    String? apiBaseUrl,
  }) async {
    final storage = secureStorage ?? SecureStorageService();
    final identityState = await AppIdentityState.initialize(storage);

    final dioClient = DioClient(
      tokenProvider: () async => identityState.identity?.token,
      onUnauthorized: identityState.revokeIdentity,
      baseUrl: apiBaseUrl ?? Env.apiBaseUrl,
    );
    final apiClient = ApiClient(dioClient.dio);
    final repository = DeviceRepository(apiClient: apiClient);
    final registerDevice = RegisterDevice(repository);
    final controller = OnboardingController(
      registerDevice: registerDevice,
      secureStorage: storage,
    );
    final socketService = SocketService(() async => identityState.identity?.token);
    socketService.connect();

    return AppConfig(
      secureStorage: storage,
      dioClient: dioClient,
      apiClient: apiClient,
      registerDevice: registerDevice,
      onboardingController: controller,
      identityState: identityState,
      socketService: socketService,
    );
  }
}
