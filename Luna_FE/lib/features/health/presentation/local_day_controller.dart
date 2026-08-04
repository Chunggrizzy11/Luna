import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/business_date_clock.dart';

typedef CancelSchedule = void Function();
typedef DaySchedule =
    CancelSchedule Function(Duration delay, void Function() callback);

class LocalDayController extends StateNotifier<DateTime> {
  LocalDayController({required this.businessDateClock, DaySchedule? schedule})
    : _schedule = schedule ?? _timerSchedule,
      super(businessDateClock.today()) {
    _scheduleNext();
  }

  final BusinessDateClock businessDateClock;
  final DaySchedule _schedule;
  CancelSchedule? _cancel;

  void refresh() {
    state = businessDateClock.today();
    _scheduleNext();
  }

  void _scheduleNext() {
    _cancel?.call();
    _cancel = _schedule(businessDateClock.untilNextDay(), refresh);
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
}
