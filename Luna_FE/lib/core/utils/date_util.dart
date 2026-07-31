abstract final class DateUtil {
  static DateTime startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static int cycleDay(DateTime cycleStart, DateTime date) {
    final days = startOfDay(date).difference(startOfDay(cycleStart)).inDays;
    if (days < 0) {
      throw ArgumentError.value(date, 'date', 'Date precedes cycle start');
    }
    return days + 1;
  }
}
