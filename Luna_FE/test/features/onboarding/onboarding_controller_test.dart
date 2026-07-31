import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/storage/secure_storage_service.dart';
import 'package:luna_fe/features/onboarding/data/device_repository.dart';
import 'package:luna_fe/features/onboarding/domain/register_device.dart';
import 'package:luna_fe/features/onboarding/presentation/onboarding_controller.dart';
import 'package:luna_fe/shared/entities/device_identity.dart';
import 'package:luna_fe/shared/enums/device_role.dart';

void main() {
  test('device identity string representation never reveals credentials', () {
    const identity = DeviceIdentity(
      deviceId: 'private-device-id',
      token: 'private-token',
      role: DeviceRole.owner,
    );

    expect(identity.toString(), isNot(contains('private-device-id')));
    expect(identity.toString(), isNot(contains('private-token')));
  });

  test(
    'first launch registers once and persists the issued identity',
    () async {
      final backend = _MemorySecureStorage();
      final storage = SecureStorageService(backend: backend);
      final repository = _FakeDeviceRepository();
      final controller = OnboardingController(
        registerDevice: RegisterDevice(repository),
        secureStorage: storage,
      );

      final identity = await controller.bootstrap(DeviceRole.owner);

      expect(repository.registrationCount, 1);
      expect(identity.deviceId, 'device-1');
      expect(await storage.readIdentity(), identity);
      expect(controller.state, OnboardingState.ready);
    },
  );

  test(
    'later launches reuse secure identity without registering again',
    () async {
      final backend = _MemorySecureStorage();
      final storage = SecureStorageService(backend: backend);
      const stored = DeviceIdentity(
        deviceId: 'stored-device',
        token: 'stored-token',
        role: DeviceRole.partner,
      );
      await storage.writeIdentity(stored);
      final repository = _FakeDeviceRepository();
      final controller = OnboardingController(
        registerDevice: RegisterDevice(repository),
        secureStorage: storage,
      );

      final identity = await controller.bootstrap(DeviceRole.owner);

      expect(identity, stored);
      expect(repository.registrationCount, 0);
      expect(controller.state, OnboardingState.ready);
    },
  );

  test('registration failure exposes retryable error state', () async {
    final controller = OnboardingController(
      registerDevice: RegisterDevice(_FakeDeviceRepository(fail: true)),
      secureStorage: SecureStorageService(backend: _MemorySecureStorage()),
    );

    await expectLater(
      controller.bootstrap(DeviceRole.owner),
      throwsA(isA<StateError>()),
    );

    expect(controller.state, OnboardingState.error);
    expect(controller.errorMessage, isNotEmpty);
  });
}

class _FakeDeviceRepository implements DeviceRegistrationRepository {
  _FakeDeviceRepository({this.fail = false});

  final bool fail;
  int registrationCount = 0;

  @override
  Future<DeviceIdentity> register(DeviceRole role) async {
    registrationCount += 1;
    if (fail) throw StateError('offline');
    return DeviceIdentity(
      deviceId: 'device-$registrationCount',
      token: 'issued-token',
      role: role,
    );
  }
}

class _MemorySecureStorage implements SecureStorageBackend {
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
