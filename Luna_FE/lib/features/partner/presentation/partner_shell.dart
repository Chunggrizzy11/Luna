import 'dart:async';

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
import '../../../core/network/network_providers.dart';
import 'partner_providers.dart';
import '../../sos/sos_provider.dart';
import '../../sos/sos_alert_overlay.dart';
import '../../../core/config/app_identity_state.dart';

class PartnerShell extends ConsumerStatefulWidget {
  const PartnerShell({super.key});
  @override
  ConsumerState<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends ConsumerState<PartnerShell> {
  int _index = 0;
  bool _isListeningSocket = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(pairingStatusProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _listenSos() {
    if (_isListeningSocket) return;
    _isListeningSocket = true;
    
    // Initialize push notifications for partner as well
    ref.read(pushNotificationServiceProvider).initialize();
    
    final socketService = ref.read(socketServiceProvider);
    socketService.onSosAlert.listen((_) {
      if (mounted) {
        SosAlertOverlay.show(context, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(pairingStatusProvider);
    
    return statusAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text('Lỗi tải trạng thái: $error', textAlign: TextAlign.center),
        ),
      ),
      data: (status) {
        // TEMPORARY FOR TESTING: Luôn bật socket lắng nghe SOS (kể cả khi chưa Pairing)
        _listenSos();

        if (!status.isPaired) {
          return _PartnerWaitingScreen(
            onRetry: () => ref.invalidate(pairingStatusProvider),
          );
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

class _PartnerWaitingScreen extends ConsumerStatefulWidget {
  const _PartnerWaitingScreen({required this.onRetry});
  final VoidCallback onRetry;

  @override
  ConsumerState<_PartnerWaitingScreen> createState() =>
      _PartnerWaitingScreenState();
}

class _PartnerWaitingScreenState
    extends ConsumerState<_PartnerWaitingScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        ref.invalidate(pairingStatusProvider);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Đăng xuất',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Đăng xuất'),
                content: const Text(
                  'Bạn có chắc chắn muốn thoát và tạo tài khoản mới không?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              ref.read(appIdentityStateProvider).revokeIdentity();
            }
          },
        ),
        title: const Text('Luna đồng hành'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                size: 72,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 24),
              Text(
                'Đang chờ kết nối...',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Hệ thống sẽ tự động kết nối khi bạn gái mở ứng dụng. '
                'Bạn không cần làm gì cả 💙',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Kiểm tra lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
