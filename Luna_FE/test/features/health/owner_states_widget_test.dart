import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luna_fe/core/error/failure.dart';
import 'package:luna_fe/core/time/business_date_clock.dart';
import 'package:luna_fe/features/calendar/domain/cycle_calendar.dart';
import 'package:luna_fe/features/cycle/presentation/cycle_controller.dart';
import 'package:luna_fe/features/health/domain/health_models.dart';
import 'package:luna_fe/features/health/presentation/daily_log_controller.dart';
import 'package:luna_fe/features/health/presentation/daily_log_sheet.dart';
import 'package:luna_fe/features/health/presentation/health_journal_page.dart';
import 'package:luna_fe/features/health/presentation/health_providers.dart';
import 'package:luna_fe/features/health/presentation/journal_controller.dart';
import 'package:luna_fe/features/home/presentation/home_page.dart';
import 'package:luna_fe/features/home/presentation/owner_shell.dart';

void main() {
  setUpAll(() => initializeDateFormatting('vi'));

  testWidgets('journal exposes loading and empty states', (tester) async {
    final pending = Completer<JournalBatch>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalProvider.overrideWith(
            (ref) => JournalController(loadPage: (_, _) => pending.future),
          ),
        ],
        child: const MaterialApp(home: HealthJournalPage()),
      ),
    );
    await tester.pump();
    expect(find.text('Đang tải nhật ký'), findsOneWidget);

    pending.complete(
      const JournalBatch(items: [], page: 1, limit: 20, hasMore: false),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa có ghi nhận sức khỏe nào.'), findsOneWidget);
  });

  for (final failure in <Failure>[
    const NetworkFailure('Không thể kết nối mạng.'),
    const UnauthorizedFailure('Phiên thiết bị không hợp lệ.'),
    const ServerFailure('Máy chủ tạm thời không phản hồi.'),
  ]) {
    testWidgets('journal renders ${failure.runtimeType} feedback', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            journalProvider.overrideWith(
              (ref) =>
                  JournalController(loadPage: (_, _) async => throw failure),
            ),
          ],
          child: const MaterialApp(home: HealthJournalPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(failure.message), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });
  }

  testWidgets(
    'owner bottom navigation switches among safe owner destinations',
    (tester) async {
      await _pumpOwner(tester);
      expect(find.text('Tổng quan'), findsOneWidget);
      expect(find.text('Lịch'), findsOneWidget);
      expect(find.text('Nhật ký'), findsOneWidget);
      expect(find.text('Chu kỳ'), findsOneWidget);

      await tester.tap(find.text('Lịch'));
      await tester.pumpAndSettle();
      expect(find.text('Lịch chu kỳ'), findsOneWidget);
      await tester.tap(find.text('Nhật ký'));
      await tester.pumpAndSettle();
      expect(find.text('Nhật ký sức khỏe'), findsOneWidget);
    },
  );

  testWidgets(
    'dashboard renders overdue predictions without a negative day count',
    (tester) async {
      final overdueDashboard = OwnerDashboard(
        date: DateTime(2026, 8, 3),
        cycle: const CycleSummary(
          currentCycleDay: 32,
          isPeriodActive: false,
          daysUntilNextPeriod: -3,
          averageCycleLength: 28,
          averagePeriodLength: 5,
          predictedPeriodStart: null,
          predictedPeriodEnd: null,
          ovulationDate: null,
        ),
        dailyLog: const DailyLog(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardProvider.overrideWith((ref) async => overdueDashboard),
            careTodayProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      final prediction = tester.widget<Text>(
        find.byKey(const ValueKey('next-period-status')),
      );
      expect(prediction.data, contains('3'));
      expect(prediction.data, isNot(contains('-3')));
    },
  );



  for (final failure in <Failure>[
    const NetworkFailure('Không thể kết nối mạng.'),
    const UnauthorizedFailure('Phiên thiết bị không hợp lệ.'),
    const ServerFailure('Máy chủ tạm thời không phản hồi.'),
  ]) {
    testWidgets('daily log observes ${failure.runtimeType} without closing', (
      tester,
    ) async {
      final controller = DailyLogController(
        onUpdateMood: (date, mood) async => throw failure,
        onUpdateSymptoms: (date, symptoms, discomfort) async {},
        onUpdateNote: (date, note) async {},
        onDeleteNote: (date) async {},
        onInvalidate: () {},
      );
      await _pumpOwner(
        tester,
        extraOverrides: [
          dailyLogControllerProvider.overrideWith((ref) => controller),
          dailyLogForDateProvider.overrideWith(
            (ref, date) async => const DailyLog(),
          ),
        ],
      );
      await tester.tap(find.text('Ghi hôm nay'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lưu nhật ký'));
      await tester.tap(find.text('Lưu nhật ký'));
      await tester.pumpAndSettle();

      expect(find.text('Lưu nhật ký'), findsOneWidget);
      if (failure is UnauthorizedFailure) {
        expect(find.textContaining('đăng ký lại thiết bị'), findsOneWidget);
      }
      expect(
        find.textContaining('Một số dữ liệu có thể đã được lưu'),
        findsOneWidget,
      );
    });
  }

  testWidgets(
    'new date clears stale failure while a later delayed save remains safe',
    (tester) async {
      var now = DateTime(2026, 8, 3, 10);
      var attempts = 0;
      final delayed = Completer<void>();
      final controller = DailyLogController(
        onUpdateMood: (date, mood) {
          attempts += 1;
          if (attempts == 1) {
            throw const ServerFailure('Lỗi ngày A');
          }
          return delayed.future;
        },
        onUpdateSymptoms: (date, symptoms, discomfort) async {},
        onUpdateNote: (date, note) async {},
        onDeleteNote: (date) async {},
        onInvalidate: () {},
      );
      await _pumpOwner(
        tester,
        clock: () => now,
        extraOverrides: [
          dailyLogControllerProvider.overrideWith((ref) => controller),
          dailyLogForDateProvider.overrideWith(
            (ref, date) async => const DailyLog(),
          ),
        ],
      );

      await tester.tap(find.text('Ghi hôm nay'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lưu nhật ký'));
      await tester.tap(find.text('Lưu nhật ký'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Lỗi ngày A'), findsOneWidget);

      Navigator.of(tester.element(find.byType(DailyLogSheet))).pop();
      await tester.pumpAndSettle();
      now = DateTime(2026, 8, 4, 10);
      await tester.tap(find.text('Ghi hôm nay'));
      await tester.pumpAndSettle();
      expect(find.text('Nhật ký ngày 04/08/2026'), findsOneWidget);
      expect(find.textContaining('Lỗi ngày A'), findsNothing);

      await tester.ensureVisible(find.text('Lưu nhật ký'));
      await tester.tap(find.text('Lưu nhật ký'));
      await tester.pump();
      expect(controller.state.isLoading, isTrue);
      delayed.complete();
      await tester.pumpAndSettle();
      expect(find.byType(DailyLogSheet), findsNothing);
    },
  );
}

Future<void> _pumpOwner(
  WidgetTester tester, {
  DateTime Function()? clock,
  List<Override> extraOverrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        businessDateClockProvider.overrideWithValue(
          BangkokBusinessDateClock(
            instantClock: clock ?? () => DateTime.utc(2026, 8, 3, 3),
          ),
        ),
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
        cycleControllerProvider.overrideWith(
          (ref) => CycleController(
            onStart: (date) async {},
            onEnd: (date) async {},
            onInvalidate: () {},
          ),
        ),
        calendarProvider.overrideWith(
          (ref, month) async => CycleCalendar(month: month, days: const []),
        ),
        ...extraOverrides,
      ],
      child: const MaterialApp(home: OwnerShell()),
    ),
  );
  await tester.pumpAndSettle();
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
