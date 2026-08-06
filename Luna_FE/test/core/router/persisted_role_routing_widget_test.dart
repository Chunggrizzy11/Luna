import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luna_fe/core/config/app_initializer.dart';
import 'package:luna_fe/core/router/app_router.dart';
import 'package:luna_fe/core/storage/secure_storage_service.dart';
import 'package:luna_fe/features/calendar/domain/cycle_calendar.dart';
import 'package:luna_fe/features/cycle/presentation/cycle_controller.dart';
import 'package:luna_fe/features/health/domain/health_models.dart';
import 'package:luna_fe/features/health/presentation/health_providers.dart';
import 'package:luna_fe/features/health/presentation/journal_controller.dart';
import 'package:luna_fe/features/home/presentation/owner_shell.dart';
import 'package:luna_fe/features/partner/presentation/partner_shell.dart';
import 'package:luna_fe/shared/entities/device_identity.dart';
import 'package:luna_fe/shared/enums/device_role.dart';

void main() {
  setUpAll(() => initializeDateFormatting('vi'));

  testWidgets(
    'persisted partner identity starts at the safe partner destination',
    (tester) async {
      final config = await _config(DeviceRole.partner);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: AppRouter(config: config).router),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PartnerShell), findsOneWidget);
      expect(find.byType(OwnerShell), findsNothing);
    },
  );

  testWidgets('persisted owner identity starts at the owner destination', (
    tester,
  ) async {
    final config = await _config(DeviceRole.owner);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardProvider.overrideWith((ref) async => _dashboard),
          careTodayProvider.overrideWith((ref) async => null),
          journalProvider.overrideWith(
            (ref) => JournalController(
              loadPage: (_, limit) async => JournalBatch(
                items: const [],
                page: 1,
                limit: limit,
                hasMore: false,
              ),
            ),
          ),
          currentCycleProvider.overrideWith((ref) async => null),
          calendarProvider.overrideWith(
            (ref, month) async => CycleCalendar(month: month, days: const []),
          ),
          cycleControllerProvider.overrideWith(
            (ref) => CycleController(
              onStart: (date) async {},
              onEnd: (date) async {},
              onInvalidate: () {},
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: AppRouter(config: config).router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OwnerShell), findsOneWidget);
    expect(find.byType(PartnerShell), findsNothing);
  });
}

Future<AppConfig> _config(DeviceRole role) async {
  final storage = SecureStorageService(backend: _MemoryBackend());
  await storage.writeIdentity(
    DeviceIdentity(deviceId: role.wireValue, token: 'secret', role: role),
  );
  return AppInitializer.initialize(secureStorage: storage);
}

class _MemoryBackend implements SecureStorageBackend {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

final _dashboard = OwnerDashboard(
  date: DateTime(2026, 8, 3),
  cycle: const CycleSummary(
    currentCycleDay: null,
    isPeriodActive: false,
    daysUntilNextPeriod: null,
    averageCycleLength: 28,
    averagePeriodLength: 5,
    predictedPeriodStart: null,
    predictedPeriodEnd: null,
    ovulationDate: null,
  ),
  dailyLog: const DailyLog(),
);
