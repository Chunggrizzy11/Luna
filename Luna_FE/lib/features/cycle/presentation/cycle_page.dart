import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_modal.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../../health/presentation/health_providers.dart';
import 'cycle_controller.dart';

class CyclePage extends ConsumerWidget {
  const CyclePage({this.onGoHome, this.isPartner = false, super.key});
  final VoidCallback? onGoHome;
  final bool isPartner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentCycleProvider);
    final mutation = ref.watch(cycleControllerProvider);
    ref.listen(cycleControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage(next.error!))));
      }
    });
    return Scaffold(
      appBar: AppBar(
        leading: onGoHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onGoHome,
              )
            : null,
        title: const Text('Chu kỳ của bạn'),
      ),
      body: current.when(
        loading: () => const AppLoading(label: 'Đang tải chu kỳ'),
        error: (error, _) => AppError(
          message: _errorMessage(error),
          onRetry: () => ref.invalidate(currentCycleProvider),
        ),
        data: (cycle) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cycle == null
                        ? 'Chưa có kỳ kinh đang diễn ra'
                        : 'Kỳ kinh đang diễn ra',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    cycle == null
                        ? 'Ghi nhận ngày bắt đầu để Luna hỗ trợ theo dõi.'
                        : 'Bắt đầu ${DateFormat('dd/MM/yyyy').format(cycle.startDate)}',
                  ),
                ],
              ),
            ),
            if (!isPartner) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: cycle == null ? 'Bắt đầu kỳ kinh' : 'Kết thúc kỳ kinh',
                icon: cycle == null
                    ? Icons.water_drop_outlined
                    : Icons.stop_circle_outlined,
                isLoading: mutation.isLoading,
                onPressed: () => _confirm(context, ref, start: cycle == null),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              label: 'Lưu ý về dự đoán chu kỳ',
              child: const Text(
                'Dự đoán chu kỳ và ngày rụng trứng chỉ mang tính tham khảo, không thay thế tư vấn y tế.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref, {
    required bool start,
  }) async {
    final confirmed = await AppModal.confirm(
      context: context,
      title: start ? 'Xác nhận bắt đầu kỳ kinh?' : 'Xác nhận kết thúc kỳ kinh?',
      message: start
          ? 'Luna sẽ dùng hôm nay làm ngày đầu chu kỳ.'
          : 'Luna sẽ dùng hôm nay làm ngày kết thúc.',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    final date = ref.read(businessDateClockProvider).today();
    final controller = ref.read(cycleControllerProvider.notifier);
    if (start) {
      await controller.start(date);
    } else {
      await controller.end(date);
    }
  }
}

String _errorMessage(Object error) =>
    error is Failure ? error.message : 'Không thể cập nhật chu kỳ.';
