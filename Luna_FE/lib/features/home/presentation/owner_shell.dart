import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/api_date.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../../calendar/presentation/cycle_calendar_page.dart';
import '../../cycle/presentation/cycle_page.dart';
import '../../health/presentation/daily_log_sheet.dart';
import '../../health/presentation/health_journal_page.dart';
import '../../health/presentation/health_providers.dart';
import 'home_page.dart';

class OwnerShell extends ConsumerStatefulWidget {
  const OwnerShell({super.key});
  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onOpenDailyLog: () => _openLog(ref.read(nowProvider)),
        onOpenCycle: () => setState(() => _index = 3),
      ),
      CycleCalendarPage(onDayTap: _openLog),
      HealthJournalPage(onEntryTap: _openLog),
      const CyclePage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Lịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Nhật ký',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Chu kỳ',
          ),
        ],
      ),
    );
  }

  Future<void> _openLog(DateTime date) =>
      AppBottomSheet.show<void>(context, child: _DailyLogLoader(date: date));
}

class _DailyLogLoader extends ConsumerWidget {
  const _DailyLogLoader({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = ApiDate.date(date);
    return ref
        .watch(dailyLogForDateProvider(key))
        .when(
          loading: () => const SizedBox(
            height: 260,
            child: AppLoading(label: 'Đang tải nhật ký ngày'),
          ),
          error: (error, _) => SizedBox(
            height: 260,
            child: AppError(
              message: error is Failure
                  ? error.message
                  : 'Không thể tải nhật ký ngày.',
              onRetry: () => ref.invalidate(dailyLogForDateProvider(key)),
            ),
          ),
          data: (log) => DailyLogSheet(
            date: date,
            initial: log,
            onSave: (mood, symptoms, discomfort, note) async {
              await ref
                  .read(dailyLogControllerProvider.notifier)
                  .save(
                    date: date,
                    mood: mood,
                    symptoms: symptoms,
                    discomfortLevel: discomfort,
                    note: note,
                  );
              final state = ref.read(dailyLogControllerProvider);
              if (!state.hasError && context.mounted) Navigator.pop(context);
            },
            onDeleteNote: () async {
              await ref
                  .read(dailyLogControllerProvider.notifier)
                  .deleteNote(date);
              final state = ref.read(dailyLogControllerProvider);
              if (!state.hasError && context.mounted) Navigator.pop(context);
            },
          ),
        );
  }
}
