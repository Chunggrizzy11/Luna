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

class HealthJournalPage extends ConsumerWidget {
  const HealthJournalPage({this.onEntryTap, super.key});
  final ValueChanged<DateTime>? onEntryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journal = ref.watch(journalProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nhật ký sức khỏe')),
      body: journal.when(
        loading: () => const AppLoading(label: 'Đang tải nhật ký'),
        error: (error, _) => AppError(
          message: error is Failure ? error.message : 'Không thể tải nhật ký.',
          onRetry: () => ref.invalidate(journalProvider),
        ),
        data: (items) => items.isEmpty
            ? const AppEmpty(message: 'Chưa có ghi nhận sức khỏe nào.')
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Semantics(
                    button: onEntryTap != null,
                    label:
                        'Nhật ký ngày ${DateFormat('dd/MM/yyyy').format(item.date)}',
                    child: AppCard(
                      onTap: onEntryTap == null
                          ? null
                          : () => onEntryTap!(item.date),
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
                            Text(
                              item.symptoms
                                  .map((value) => value.label)
                                  .join(' • '),
                            ),
                          if (item.discomfortLevel != null)
                            Text('Mức khó chịu: ${item.discomfortLevel}/5'),
                          if (item.note?.isNotEmpty == true) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(item.note!),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
