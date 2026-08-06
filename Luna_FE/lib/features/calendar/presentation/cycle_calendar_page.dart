import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_color.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../domain/cycle_calendar.dart';
import '../../health/presentation/health_providers.dart';

class CycleCalendarPage extends ConsumerStatefulWidget {
  const CycleCalendarPage({this.initialMonth, this.onDayTap, this.onGoHome, this.isPartner = false, super.key});
  final DateTime? initialMonth;
  final ValueChanged<DateTime>? onDayTap;
  final VoidCallback? onGoHome;
  final bool isPartner;

  @override
  ConsumerState<CycleCalendarPage> createState() => _CycleCalendarPageState();
}

class _CycleCalendarPageState extends ConsumerState<CycleCalendarPage> {
  late DateTime _focused;

  @override
  void initState() {
    super.initState();
    _focused = widget.initialMonth ?? ref.read(localDayProvider);
  }

  String get _month => DateFormat('yyyy-MM').format(_focused);

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(localDayProvider);
    final state = ref.watch(calendarProvider(_month));
    return Scaffold(
      appBar: AppBar(
        leading: widget.onGoHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onGoHome,
              )
            : null,
        title: const Text('Lịch chu kỳ'),
      ),
      body: state.when(
        loading: () => const AppLoading(label: 'Đang tải lịch'),
        error: (error, _) => AppError(
          message: error is Failure ? error.message : 'Không thể tải lịch.',
          onRetry: () => ref.invalidate(calendarProvider(_month)),
        ),
        data: (calendar) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: const [
                _Legend(color: AppColor.menstrual, label: 'Kỳ kinh thực tế'),
                _Legend(color: AppColor.prediction, label: 'Kỳ kinh dự đoán'),
                _Legend(color: AppColor.ovulation, label: 'Ngày rụng trứng'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TableCalendar<void>(
              locale: 'vi',
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: _focused,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              onPageChanged: (value) => setState(() => _focused = value),
              onDaySelected: (selected, _) => widget.onDayTap?.call(selected),
              calendarBuilders: CalendarBuilders(
                prioritizedBuilder: (context, day, focused) => _day(
                  day,
                  calendar,
                  today: isSameDay(day, today),
                  outside: day.month != focused.month,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Dự đoán chỉ mang tính tham khảo và có thể thay đổi theo dữ liệu thực tế.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _day(
    DateTime date,
    CycleCalendar calendar, {
    bool today = false,
    bool outside = false,
  }) {
    final status = calendar.days
        .where((item) => isSameDay(item.date, date))
        .map((item) => item.status)
        .firstOrNull;
    final color = switch (status) {
      CalendarDayStatus.observedPeriod => AppColor.menstrual,
      CalendarDayStatus.predictedPeriod => AppColor.prediction,
      CalendarDayStatus.ovulation => AppColor.ovulation,
      _ => Colors.transparent,
    };
    final label = switch (status) {
      CalendarDayStatus.observedPeriod => 'kỳ kinh thực tế',
      CalendarDayStatus.predictedPeriod => 'kỳ kinh dự đoán',
      CalendarDayStatus.ovulation => 'ngày rụng trứng',
      _ => 'không có ghi nhận',
    };
    return Semantics(
      key: ValueKey('calendar-day-${DateFormat('yyyy-MM-dd').format(date)}'),
      button: true,
      label: 'Ngày ${date.day}, $label',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => widget.onDayTap?.call(date),
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: today
                ? Border.all(
                    width: 2,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: color == Colors.transparent
                  ? (outside ? Theme.of(context).disabledColor : null)
                  : Colors.white,
              fontWeight: status == null ? null : FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: AppSpacing.xxs),
      Text(label),
    ],
  );
}
