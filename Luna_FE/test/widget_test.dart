import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/app.dart';
import 'package:luna_fe/core/config/app_initializer.dart';
import 'package:luna_fe/core/storage/secure_storage_service.dart';

void main() {
  testWidgets('shows the Luna application title', (WidgetTester tester) async {
    await tester.pumpWidget(LunaApp(config: await _config()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Luna'), findsWidgets);
  });

  testWidgets('uses Vietnamese as the default locale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(LunaApp(config: await _config()));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.locale, const Locale('vi'));
  });
}

Future<AppConfig> _config() => AppInitializer.initialize(
  secureStorage: SecureStorageService(backend: _MemorySecureStorage()),
);

class _MemorySecureStorage implements SecureStorageBackend {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
