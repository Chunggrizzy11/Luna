import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../../health/domain/health_models.dart';
import '../../health/presentation/health_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({this.onOpenDailyLog, this.onOpenCycle, super.key});
  final VoidCallback? onOpenDailyLog;
  final VoidCallback? onOpenCycle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final care = ref.watch(careTodayProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Luna của bạn')),
      body: dashboard.when(
        loading: () => const AppLoading(label: 'Đang tải tổng quan'),
        error: (error, _) => AppError(
          message: error is Failure
              ? error.message
              : 'Không thể tải tổng quan.',
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (value) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            ref.invalidate(careTodayProvider);
            await ref.read(dashboardProvider.future);
          },
          child: LayoutBuilder(
            builder: (context, constraints) => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      children: [
                        _CycleOverview(
                          summary: value.cycle,
                          onTap: onOpenCycle,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (constraints.maxWidth >= 620)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _DailyCard(
                                  log: value.dailyLog,
                                  onTap: onOpenDailyLog,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(child: _CareCard(state: care)),
                            ],
                          )
                        else ...[
                          _DailyCard(
                            log: value.dailyLog,
                            onTap: onOpenDailyLog,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _CareCard(state: care),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onOpenDailyLog,
        icon: const Icon(Icons.edit_note),
        label: const Text('Ghi hôm nay'),
      ),
    );
  }
}

class _CycleOverview extends StatelessWidget {
  const _CycleOverview({required this.summary, required this.onTap});
  final CycleSummary summary;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Row(
      children: [
        CircleAvatar(
          radius: 34,
          child: Text(
            summary.currentCycleDay?.toString() ?? '—',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.currentCycleDay == null
                    ? 'Chưa bắt đầu chu kỳ'
                    : 'Ngày ${summary.currentCycleDay} của chu kỳ',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                summary.daysUntilNextPeriod == null
                    ? 'Ghi nhận kỳ kinh để nhận dự đoán.'
                    : 'Còn khoảng ${summary.daysUntilNextPeriod} ngày đến kỳ tiếp theo',
              ),
              if (summary.predictedPeriodStart != null)
                Text(
                  'Dự kiến ${DateFormat('dd/MM').format(summary.predictedPeriodStart!)}',
                ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    ),
  );
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.log, required this.onTap});
  final DailyLog log;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sức khỏe hôm nay',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${log.mood?.emoji ?? '📝'} ${log.mood?.label ?? 'Chưa ghi tâm trạng'}',
        ),
        Text(
          log.symptoms.isEmpty
              ? 'Chưa ghi triệu chứng'
              : log.symptoms.map((item) => item.label).join(' • '),
        ),
        if (log.discomfortLevel != null)
          Text('Mức khó chịu: ${log.discomfortLevel}/5'),
      ],
    ),
  );
}

class _CareCard extends StatelessWidget {
  const _CareCard({required this.state});
  final AsyncValue<CareSuggestion?> state;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chăm sóc mỗi ngày',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        state.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text('Chưa thể tải gợi ý lúc này.'),
          data: (care) => care == null
              ? const Text('Chưa có gợi ý hôm nay.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      care.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(care.description),
                  ],
                ),
        ),
      ],
    ),
  );
}
