import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_color.dart';
import '../../../core/utils/api_date.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../../calendar/presentation/cycle_calendar_page.dart';
import '../../cycle/presentation/cycle_page.dart';
import '../../health/presentation/daily_log_sheet.dart';
import '../../health/presentation/health_journal_page.dart';
import '../../health/presentation/health_providers.dart';
import '../../home/presentation/home_page.dart';
import '../../notification/presentation/notification_page.dart';
import '../../notification/presentation/notification_providers.dart';
import 'partner_providers.dart';
import 'partner_pending_page.dart';

class PartnerShell extends ConsumerStatefulWidget {
  const PartnerShell({super.key});
  @override
  ConsumerState<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends ConsumerState<PartnerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(pairingStatusProvider);
    
    return statusAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => const PartnerPendingPage(),
      data: (status) {
        if (!status.isPaired) {
          return const PartnerPendingPage();
        }

        final unreadCount = ref.watch(unreadCountProvider);
        void goHome() => setState(() => _index = 0);
        
        final pages = [
          HomePage(
            onOpenDailyLog: () =>
                _openLog(ref.read(businessDateClockProvider).today()),
            onOpenCycle: () => setState(() => _index = 3),
            isPartner: true,
          ),
          CycleCalendarPage(onDayTap: _openLog, onGoHome: goHome, isPartner: true),
          HealthJournalPage(onEntryTap: _openLog, onGoHome: goHome, isPartner: true),
          CyclePage(onGoHome: goHome, isPartner: true),
          NotificationPage(onGoHome: goHome),
        ];
        
        return Scaffold(
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
        );
      },
    );
  }

  Future<void> _openLog(DateTime date) async {
    await AppBottomSheet.show<void>(
      context,
      child: _DailyLogLoader(date: date),
    );
  }
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
            isReadOnly: true,
          ),
        );
  }
}
