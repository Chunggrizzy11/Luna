import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef Clock = DateTime Function();
typedef CancelSchedule = void Function();
typedef DaySchedule =
    CancelSchedule Function(Duration delay, void Function() callback);

class LocalDayController extends StateNotifier<DateTime> {
  LocalDayController({required this.clock, DaySchedule? schedule})
    : _schedule = schedule ?? _timerSchedule,
      super(_dateOnly(clock())) {
    _scheduleNext();
  }

  final Clock clock;
  final DaySchedule _schedule;
  CancelSchedule? _cancel;

  void refresh() {
    state = _dateOnly(clock());
    _scheduleNext();
  }

  void _scheduleNext() {
    _cancel?.call();
    final now = clock();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _cancel = _schedule(tomorrow.difference(now), refresh);
  }

  @override
  void dispose() {
    _cancel?.call();
    super.dispose();
  }

  static CancelSchedule _timerSchedule(
    Duration delay,
    void Function() callback,
  ) {
    final timer = Timer(delay, callback);
    return timer.cancel;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
