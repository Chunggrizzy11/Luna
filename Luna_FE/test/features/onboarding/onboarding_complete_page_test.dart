import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/storage/secure_storage_service.dart';
import 'package:luna_fe/features/onboarding/presentation/onboarding_complete_page.dart';
import 'package:luna_fe/shared/entities/device_identity.dart';
import 'package:luna_fe/shared/enums/device_role.dart';

void main() {
  testWidgets('shows a real secure-registration completion state', (
    tester,
  ) async {
    final storage = SecureStorageService(backend: _MemorySecureStorage());
    await storage.writeIdentity(
      const DeviceIdentity(
        deviceId: 'device-1',
        token: 'secret',
        role: DeviceRole.owner,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: OnboardingCompletePage(secureStorage: storage)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thiết bị đã được kết nối an toàn'), findsOneWidget);
    expect(find.text('Theo dõi chu kỳ'), findsOneWidget);
    expect(find.textContaining('device-1'), findsNothing);
    expect(find.textContaining('secret'), findsNothing);
  });
}

class _MemorySecureStorage implements SecureStorageBackend {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
