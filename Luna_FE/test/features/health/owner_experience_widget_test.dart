import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:luna_fe/core/error/failure.dart';
import 'package:luna_fe/core/time/business_date_clock.dart';
import 'package:luna_fe/core/widgets/app_button.dart';
import 'package:luna_fe/features/calendar/domain/cycle_calendar.dart';
import 'package:luna_fe/features/calendar/presentation/cycle_calendar_page.dart';
import 'package:luna_fe/features/cycle/domain/cycle.dart';
import 'package:luna_fe/features/cycle/presentation/cycle_controller.dart';
import 'package:luna_fe/features/cycle/presentation/cycle_page.dart';
import 'package:luna_fe/features/health/domain/health_models.dart';
import 'package:luna_fe/features/health/presentation/daily_log_sheet.dart';
import 'package:luna_fe/features/health/presentation/health_journal_page.dart';
import 'package:luna_fe/features/health/presentation/health_providers.dart';
import 'package:luna_fe/features/health/presentation/journal_controller.dart';
import 'package:luna_fe/features/mood/domain/mood.dart';
import 'package:luna_fe/features/symptom/domain/symptom.dart';

void main() {
  setUpAll(() => initializeDateFormatting('vi'));

  testWidgets('cycle start requires confirmation and shows disclaimer', (
    tester,
  ) async {
    DateTime? started;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          businessDateClockProvider.overrideWithValue(
            BangkokBusinessDateClock(
              instantClock: () => DateTime.utc(2026, 8, 3),
            ),
          ),
          currentCycleProvider.overrideWith((ref) async => null),
          cycleControllerProvider.overrideWith(
            (ref) => CycleController(
              onStart: (date) async => started = date,
              onEnd: (_) async {},
              onInvalidate: () {},
            ),
          ),
        ],
        child: const MaterialApp(home: CyclePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('chỉ mang tính tham khảo'), findsOneWidget);
    await tester.tap(find.text('Bắt đầu kỳ kinh'));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận bắt đầu kỳ kinh?'), findsOneWidget);
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    expect(started, DateTime(2026, 8, 3));
  });

  testWidgets('cycle end requires confirmation', (tester) async {
    DateTime? ended;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          businessDateClockProvider.overrideWithValue(
            BangkokBusinessDateClock(
              instantClock: () => DateTime.utc(2026, 8, 5),
            ),
          ),
          currentCycleProvider.overrideWith(
            (ref) async => Cycle(startDate: DateTime(2026, 8, 1)),
          ),
          cycleControllerProvider.overrideWith(
            (ref) => CycleController(
              onStart: (_) async {},
              onEnd: (date) async => ended = date,
              onInvalidate: () {},
            ),
          ),
        ],
        child: const MaterialApp(home: CyclePage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kết thúc kỳ kinh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(ended, DateTime(2026, 8, 5));
  });

  testWidgets('calendar renders legend and opens selected day', (tester) async {
    DateTime? selected;
    final calendar = CycleCalendar(
      month: '2026-08',
      days: [
        CycleCalendarDay(
          date: DateTime(2026, 8, 3),
          status: CalendarDayStatus.observedPeriod,
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calendarProvider.overrideWith((ref, month) async => calendar),
        ],
        child: MaterialApp(
          home: CycleCalendarPage(
            initialMonth: DateTime(2026, 8),
            onDayTap: (date) => selected = date,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kỳ kinh thực tế'), findsOneWidget);
    expect(find.text('Kỳ kinh dự đoán'), findsOneWidget);
    expect(find.text('Ngày rụng trứng'), findsOneWidget);
    final day = find.byKey(const ValueKey('calendar-day-2026-08-03'));
    expect(
      tester.widget<Semantics>(day).properties.label,
      'Ngày 3, kỳ kinh thực tế',
    );
    await tester.tap(day);
    expect(DateUtils.isSameDay(selected, DateTime(2026, 8, 3)), isTrue);
  });

  testWidgets(
    'calendar defaults its focused month from the injected local day',
    (tester) async {
      String? requestedMonth;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            businessDateClockProvider.overrideWithValue(
              BangkokBusinessDateClock(
                instantClock: () => DateTime.utc(2025, 2, 14),
              ),
            ),
            calendarProvider.overrideWith((ref, month) async {
              requestedMonth = month;
              return CycleCalendar(month: month, days: const []);
            }),
          ],
          child: const MaterialApp(home: CycleCalendarPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(requestedMonth, '2025-02');
    },
  );

  testWidgets('daily log supports mood symptom note edit and delete', (
    tester,
  ) async {
    Mood? mood;
    Set<Symptom>? symptoms;
    String? note;
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyLogSheet(
            date: DateTime(2026, 8, 3),
            initial: const DailyLog(note: 'Ghi chú cũ'),
            onSave: (valueMood, valueSymptoms, _, valueNote) async {
              mood = valueMood;
              symptoms = valueSymptoms;
              note = valueNote;
            },
            onDeleteNote: () async => deleted = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Vui vẻ'));
    await tester.tap(find.text('Đau bụng'));
    await tester.enterText(find.bySemanticsLabel('Ghi chú sức khỏe'), 'Đã sửa');
    await tester.ensureVisible(find.text('Lưu nhật ký'));
    await tester.tap(find.text('Lưu nhật ký'));
    await tester.pump();
    expect(mood, Mood.happy);
    expect(symptoms, {Symptom.cramps});
    expect(note, 'Đã sửa');
    final deleteButton = find.byTooltip('Xóa ghi chú');
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('daily log displays the selected historical date', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyLogSheet(
            date: DateTime(2026, 7, 20),
            initial: const DailyLog(),
            onSave: (_, _, _, _) async {},
            onDeleteNote: () async {},
          ),
        ),
      ),
    );

    expect(find.text('Nhật ký ngày 20/07/2026'), findsOneWidget);
    expect(find.text('Nhật ký hôm nay'), findsNothing);
  });

  testWidgets('daily log ignores delete confirmation after disposal', (
    tester,
  ) async {
    var deleted = false;
    final hostKey = GlobalKey<_DailyLogHostState>();
    await tester.pumpWidget(
      MaterialApp(
        home: _DailyLogHost(key: hostKey, onDelete: () async => deleted = true),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    hostKey.currentState!.hideSheet();
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
  });

  testWidgets('save failure stops loading and renders typed feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyLogSheet(
            date: DateTime(2026, 8, 3),
            initial: const DailyLog(),
            errorMessage:
                'Không thể kết nối mạng. Một số dữ liệu có thể đã được lưu.',
            onSave: (_, _, _, _) async => throw const NetworkFailure(),
            onDeleteNote: () async {},
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Lưu nhật ký'));
    await tester.tap(find.text('Lưu nhật ký'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Một số dữ liệu'), findsOneWidget);
    final button = tester.widget<AppButton>(
      find.ancestor(
        of: find.text('Lưu nhật ký'),
        matching: find.byType(AppButton),
      ),
    );
    expect(button.isLoading, isFalse);
  });

  testWidgets('health journal renders newest-first timeline content', (
    tester,
  ) async {
    final controller = JournalController(
      loadPage: (page, limit) async => JournalBatch(
        items: [
          JournalEntry(
            date: DateTime(2026, 8, 3),
            mood: Mood.happy,
            symptoms: const [Symptom.cramps],
            discomfortLevel: 2,
            note: 'Hôm nay ổn hơn',
          ),
          JournalEntry(date: DateTime(2026, 8, 1), note: 'Bản ghi cũ'),
        ],
        page: 1,
        limit: limit,
        hasMore: false,
      ),
      loadImmediately: false,
    );
    await controller.refresh();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: HealthJournalPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nhật ký sức khỏe'), findsOneWidget);
    expect(find.text('Hôm nay ổn hơn'), findsOneWidget);
    expect(find.text('Bản ghi cũ'), findsOneWidget);
    expect(find.textContaining('Vui vẻ'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('03/08/2026')).dy,
      lessThan(tester.getTopLeft(find.text('01/08/2026')).dy),
    );
  });

  testWidgets('health journal loads entries beyond the first twenty', (
    tester,
  ) async {
    final controller = JournalController(
      loadPage: (page, limit) async => JournalBatch(
        items: page == 1
            ? List.generate(
                20,
                (index) => JournalEntry(date: DateTime(2026, 8, 25 - index)),
              )
            : List.generate(
                5,
                (index) => JournalEntry(date: DateTime(2026, 8, 5 - index)),
              ),
        page: page,
        limit: limit,
        hasMore: page == 1,
      ),
      loadImmediately: false,
    );
    await controller.refresh();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalProvider.overrideWith((ref) => controller)],
        child: const MaterialApp(home: HealthJournalPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Tải thêm'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tải thêm'));
    await tester.pumpAndSettle();

    expect(controller.state.items, hasLength(25));
    await tester.scrollUntilVisible(
      find.text('01/08/2026'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('01/08/2026'), findsOneWidget);
  });
}

class _DailyLogHost extends StatefulWidget {
  const _DailyLogHost({required this.onDelete, super.key});

  final Future<void> Function() onDelete;

  @override
  State<_DailyLogHost> createState() => _DailyLogHostState();
}

class _DailyLogHostState extends State<_DailyLogHost> {
  var _showSheet = true;

  void hideSheet() => setState(() => _showSheet = false);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _showSheet
        ? DailyLogSheet(
            date: DateTime(2026, 8, 3),
            initial: const DailyLog(note: 'existing note'),
            onSave: (_, _, _, _) async {},
            onDeleteNote: widget.onDelete,
          )
        : const SizedBox.shrink(),
  );
}
