import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import 'health_providers.dart';
import 'journal_controller.dart';

class HealthJournalPage extends ConsumerWidget {
  const HealthJournalPage({this.onEntryTap, this.onGoHome, this.isPartner = false, super.key});
  final ValueChanged<DateTime>? onEntryTap;
  final VoidCallback? onGoHome;
  final bool isPartner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(journalProvider);
    return Scaffold(
      appBar: AppBar(
        leading: onGoHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onGoHome,
              )
            : null,
        title: const Text('Nhật ký sức khỏe'),
      ),
      body: _body(context, ref, journal),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, JournalState journal) {
    if (journal.isLoading) {
      return const AppLoading(label: 'Đang tải nhật ký');
    }
    if (journal.initialError != null) {
      final error = journal.initialError!;
      return AppError(
        message: error is Failure ? error.message : 'Không thể tải nhật ký.',
        onRetry: () => ref.read(journalProvider.notifier).refresh(),
      );
    }
    if (journal.items.isEmpty) {
      return const AppEmpty(message: 'Chưa có ghi nhận sức khỏe nào.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: journal.items.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == journal.items.length) {
          return _LoadMoreFooter(state: journal);
        }
        final item = journal.items[index];
        final card = Semantics(
          button: onEntryTap != null,
          label: 'Nhật ký ngày ${DateFormat('dd/MM/yyyy').format(item.date)}',
          child: AppCard(
            onTap: onEntryTap == null ? null : () => onEntryTap!(item.date),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(item.date),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${item.mood?.emoji ?? '—'} ${item.mood?.label ?? 'Chưa ghi tâm trạng'}',
                      ),
                      if (item.symptoms.isNotEmpty)
                        Text(item.symptoms.map((value) => value.label).join(' • ')),
                      if (item.discomfortLevel != null)
                        Text('Mức khó chịu: ${item.discomfortLevel}/5'),
                      if (item.note?.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(item.note!),
                      ],
                    ],
                  ),
                ),
                if (!isPartner)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                    tooltip: 'Xóa nhật ký',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Xóa nhật ký'),
                          content: Text(
                            'Bạn có chắc muốn xóa nhật ký ngày ${DateFormat('dd/MM/yyyy').format(item.date)}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Xóa'),
                            ),
                          ],
                        ),
                      ) ?? false;
                      if (confirmed && context.mounted) {
                        await ref.read(dailyLogControllerProvider.notifier).deleteEntry(item.date);
                        ref.read(journalProvider.notifier).removeEntry(item.date);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✅ Đã xóa nhật ký ngày ${DateFormat('dd/MM/yyyy').format(item.date)}',
                              ),
                              backgroundColor: const Color(0xFF007A55),
                            ),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
        );

        if (isPartner) return card;

        return Dismissible(
          key: ValueKey('journal-${item.date.toIso8601String()}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Xóa nhật ký'),
                content: Text(
                  'Bạn có chắc muốn xóa nhật ký ngày ${DateFormat('dd/MM/yyyy').format(item.date)}?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Xóa'),
                  ),
                ],
              ),
            ) ?? false;
          },
          onDismissed: (_) async {
            await ref.read(dailyLogControllerProvider.notifier).deleteEntry(item.date);
            ref.read(journalProvider.notifier).removeEntry(item.date);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✅ Đã xóa nhật ký ngày ${DateFormat('dd/MM/yyyy').format(item.date)}',
                  ),
                  backgroundColor: const Color(0xFF007A55),
                ),
              );
            }
          },
          child: card,
        );
      },
    );
  }
}

class _LoadMoreFooter extends ConsumerWidget {
  const _LoadMoreFooter({required this.state});

  final JournalState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(journalProvider.notifier);
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.sm),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreError != null) {
      final error = state.loadMoreError!;
      return Column(
        children: [
          Text(
            error is Failure ? error.message : 'Không thể tải thêm nhật ký.',
          ),
          TextButton(
            onPressed: controller.loadMore,
            child: const Text('Thử tải lại'),
          ),
        ],
      );
    }
    if (!state.hasMore) return const SizedBox.shrink();
    return Center(
      child: OutlinedButton(
        onPressed: controller.loadMore,
        child: const Text('Tải thêm'),
      ),
    );
  }
}
