import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luna_fe/app.dart';
import 'package:luna_fe/core/config/app_initializer.dart';
import 'package:luna_fe/core/config/app_identity_state.dart';
import 'package:luna_fe/core/storage/secure_storage_service.dart';
import 'package:luna_fe/features/home/presentation/owner_shell.dart';
import 'package:luna_fe/features/onboarding/presentation/onboarding_page.dart';
import 'package:luna_fe/shared/entities/device_identity.dart';
import 'package:luna_fe/shared/enums/device_role.dart';

void main() {
  setUpAll(() => initializeDateFormatting('vi'));

  testWidgets('revoked startup token clears identity and routes onboarding', (
    tester,
  ) async {
    final backend = _MemoryBackend();
    final config = await _ownerConfig(backend, status: 401);

    await tester.pumpWidget(LunaApp(config: config));
    await tester.pumpAndSettle();

    expect(config.identityState.status, AppIdentityStatus.missing);
    expect(config.identityState.identity, isNull);
    expect(backend.deleteCalls, 1);
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(OwnerShell), findsNothing);
  });

  testWidgets('403 keeps identity signed in and renders forbidden feedback', (
    tester,
  ) async {
    final backend = _MemoryBackend();
    final config = await _ownerConfig(backend, status: 403);

    await tester.pumpWidget(LunaApp(config: config));
    await tester.pumpAndSettle();

    expect(config.identityState.status, AppIdentityStatus.present);
    expect(config.identityState.identity, isNotNull);
    expect(backend.deleteCalls, 0);
    expect(find.byType(OwnerShell), findsOneWidget);
    expect(find.text('Không được phép.'), findsWidgets);
  });
}

Future<AppConfig> _ownerConfig(
  _MemoryBackend backend, {
  required int status,
}) async {
  final storage = SecureStorageService(backend: backend);
  await storage.writeIdentity(
    const DeviceIdentity(
      deviceId: 'owner-device',
      token: 'device-token',
      role: DeviceRole.owner,
    ),
  );
  final config = await AppInitializer.initialize(
    secureStorage: storage,
    apiBaseUrl: 'http://luna.test/api/v1',
  );
  config.dioClient.dio.httpClientAdapter = _StatusAdapter(status);
  return config;
}

class _MemoryBackend implements SecureStorageBackend {
  final values = <String, String>{};
  int deleteCalls = 0;

  @override
  Future<void> delete(String key) async {
    deleteCalls += 1;
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status);

  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({
      'code': status == 401 ? 'UNAUTHORIZED' : 'FORBIDDEN',
      'message': status == 401 ? 'Token revoked.' : 'Không được phép.',
      'details': null,
      'timestamp': '2026-08-03T00:00:00.000Z',
      'path': options.path,
    }),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
