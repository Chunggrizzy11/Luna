import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../data/notification_repository.dart';
import '../domain/notification_models.dart';
import 'notification_providers.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({this.onGoHome, super.key});
  final VoidCallback? onGoHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(notificationRepositoryProvider);
    final notificationsAsync = ref.watch(notificationListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: onGoHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onGoHome,
              )
            : null,
        title: const Text('Trung tâm thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đánh dấu tất cả đã đọc.')),
              );
              ref.read(notificationListProvider.notifier).markAllAsRead();
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: AppSpacing.md),
              Text('Lỗi khi tải thông báo: \${error.toString()}'),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationListProvider),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (data) => _NotificationList(data: data, repository: repository),
      ),
    );
  }
}


class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.data,
    required this.repository,
  });

  final NotificationListResponse data;
  final NotificationRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (data.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            const SizedBox(height: AppSpacing.md),
            const Text('Bạn không có thông báo nào.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: data.items.length,
      itemBuilder: (context, index) {
        final notification = data.items[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          color: notification.read
              ? null
              : colorScheme.primaryContainer.withOpacity(0.3),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: notification.read
                  ? colorScheme.surfaceVariant
                  : colorScheme.primary,
              child: Icon(
                Icons.notifications_active,
                color: notification.read
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onPrimary,
              ),
            ),
            title: Text(
              notification.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: notification.read
                    ? FontWeight.normal
                    : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _formatDate(notification.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            trailing: !notification.read
                ? const Icon(Icons.fiber_new, color: Colors.blue)
                : null,
            onTap: () async {
              if (!notification.read) {
                await repository.markAsRead(notification.id);
              }
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
