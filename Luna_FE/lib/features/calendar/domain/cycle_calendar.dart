import 'package:flutter/foundation.dart';

enum CalendarDayStatus {
  none('none'),
  observedPeriod('observed-period'),
  predictedPeriod('predicted-period'),
  ovulation('ovulation');

  const CalendarDayStatus(this.wireValue);
  final String wireValue;
  static CalendarDayStatus fromWire(String value) =>
      values.firstWhere((item) => item.wireValue == value);
}

@immutable
class CycleCalendarDay {
  const CycleCalendarDay({required this.date, required this.status});
  final DateTime date;
  final CalendarDayStatus status;

  factory CycleCalendarDay.fromJson(Map<String, dynamic> json) =>
      CycleCalendarDay(
        date: DateTime.parse(json['date'] as String),
        status: CalendarDayStatus.fromWire(json['status'] as String),
      );
}

@immutable
class CycleCalendar {
  const CycleCalendar({required this.month, required this.days});
  final String month;
  final List<CycleCalendarDay> days;

  factory CycleCalendar.fromJson(Map<String, dynamic> json) => CycleCalendar(
    month: json['month'] as String,
    days: List.unmodifiable(
      (json['days'] as List<Object?>).map(
        (item) => CycleCalendarDay.fromJson(item! as Map<String, dynamic>),
      ),
    ),
  );
}
