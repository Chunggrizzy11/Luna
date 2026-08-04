import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/config/app_identity_state.dart';
import 'package:luna_fe/core/config/app_initializer.dart';
import 'package:luna_fe/core/storage/secure_storage_service.dart';
import 'package:luna_fe/shared/entities/device_identity.dart';
import 'package:luna_fe/shared/enums/device_role.dart';

void main() {
  test('initializer models a definitely missing secure identity', () async {
    final config = await AppInitializer.initialize(
      secureStorage: SecureStorageService(backend: _ControlledBackend()),
    );

    expect(config.identityState.status, AppIdentityStatus.missing);
    expect(config.identityState.identity, isNull);
  });

  test('initializer models a present secure identity', () async {
    final backend = _ControlledBackend();
    final storage = SecureStorageService(backend: backend);
    const identity = DeviceIdentity(
      deviceId: 'device-1',
      token: 'secret',
      role: DeviceRole.owner,
    );
    await storage.writeIdentity(identity);

    final config = await AppInitializer.initialize(secureStorage: storage);

    expect(config.identityState.status, AppIdentityStatus.present);
    expect(config.identityState.identity, identity);
  });

  test(
    'initializer preserves secure storage errors as an error state',
    () async {
      final backend = _ControlledBackend()..throwOnRead = true;

      final config = await AppInitializer.initialize(
        secureStorage: SecureStorageService(backend: backend),
      );

      expect(config.identityState.status, AppIdentityStatus.error);
      expect(config.identityState.identity, isNull);
    },
  );

  test(
    'retry resolves an error state without recreating app dependencies',
    () async {
      final backend = _ControlledBackend();
      final storage = SecureStorageService(backend: backend);
      const identity = DeviceIdentity(
        deviceId: 'device-1',
        token: 'secret',
        role: DeviceRole.partner,
      );
      await storage.writeIdentity(identity);
      backend.throwOnRead = true;
      final config = await AppInitializer.initialize(secureStorage: storage);
      backend.throwOnRead = false;

      await config.identityState.retry();

      expect(config.identityState.status, AppIdentityStatus.present);
      expect(config.identityState.identity, identity);
      expect(config.identityState.isRetrying, isFalse);
    },
  );

  test(
    'revoked token clears secure identity and publishes missing state',
    () async {
      final backend = _ControlledBackend();
      final storage = SecureStorageService(backend: backend);
      const identity = DeviceIdentity(
        deviceId: 'device-1',
        token: 'revoked-token',
        role: DeviceRole.owner,
      );
      await storage.writeIdentity(identity);
      final state = await AppIdentityState.initialize(storage);

      await state.revokeIdentity();

      expect(state.status, AppIdentityStatus.missing);
      expect(state.identity, isNull);
      expect(await storage.readIdentity(), isNull);
    },
  );
}

class _ControlledBackend implements SecureStorageBackend {
  final Map<String, String> values = {};
  bool throwOnRead = false;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async {
    if (throwOnRead) throw StateError('platform storage unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
