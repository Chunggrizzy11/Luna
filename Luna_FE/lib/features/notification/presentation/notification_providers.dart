import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/presentation/health_providers.dart';
import '../../../core/network/api_client.dart';
import '../data/notification_repository.dart';
import '../domain/notification_models.dart';

/// Provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return NotificationRepository(api);
});

/// StateNotifier for notification list with pagination
final notificationListProvider = StateNotifierProvider<
    NotificationListNotifier, AsyncValue<NotificationListResponse>>((ref) {
  return NotificationListNotifier(ref.read(notificationRepositoryProvider));
});

/// Unread count provider
final unreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationListProvider);
  return state.valueOrNull?.unreadCount ?? 0;
});

class NotificationListNotifier
    extends StateNotifier<AsyncValue<NotificationListResponse>> {
  final NotificationRepository _repository;
  NotificationListNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({int page = 1, int limit = 20}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _repository.list(page: page, limit: limit);
      state = AsyncValue.data(response);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      load();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      load();
    } catch (e) {
      // Handle error
    }
  }
}
