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
import '../../notification/presentation/notification_providers.dart';
import '../../notification/presentation/notification_page.dart';
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
    final unreadCount = ref.watch(unreadCountProvider);
    void goHome() => setState(() => _index = 0);
    final pages = [
      HomePage(
        onOpenDailyLog: () =>
            _openLog(ref.read(businessDateClockProvider).today()),
        onOpenCycle: () => setState(() => _index = 3),
      ),
      CycleCalendarPage(onDayTap: _openLog, onGoHome: goHome),
      HealthJournalPage(onEntryTap: _openLog, onGoHome: goHome),
      CyclePage(onGoHome: goHome),
      NotificationPage(onGoHome: goHome),
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: AppColor.pageGradient(Theme.of(context).brightness),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Tổng quan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Lịch',
          ),
          const NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Nhật ký',
          ),
          const NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Chu kỳ',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Thông báo',
          ),
        ],
      ),
    ));
  }

  Future<void> _openLog(DateTime date) async {
    final controller = ref.read(dailyLogControllerProvider.notifier);
    controller.startFeedbackSession();
    try {
      await AppBottomSheet.show<void>(
        context,
        child: _DailyLogLoader(date: date),
      );
    } finally {
      controller.endFeedbackSession();
    }
  }
}

class _DailyLogLoader extends ConsumerWidget {
  const _DailyLogLoader({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = ApiDate.date(date);
    final mutation = ref.watch(dailyLogControllerProvider);
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
            errorMessage: _mutationFeedback(mutation),
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

String? _mutationFeedback(AsyncValue<void> state) {
  if (!state.hasError) return null;
  final error = state.error;
  if (error is UnauthorizedFailure) {
    return '${error.message} Một số dữ liệu có thể đã được lưu. '
        'Vui lòng đăng ký lại thiết bị để tiếp tục.';
  }
  if (error is NetworkFailure) {
    return '${error.message} Không thể lưu đầy đủ. Một số dữ liệu có thể đã được lưu.';
  }
  if (error is Failure) {
    return '${error.message} Một số dữ liệu có thể đã được lưu.';
  }
  return 'Không thể lưu đầy đủ. Một số dữ liệu có thể đã được lưu.';
}
