typedef InstantClock = DateTime Function();

abstract interface class BusinessDateClock {
  DateTime today();
  DateTime dateAt(DateTime instant);
  Duration untilNextDay();
  String formatDate(DateTime value);
  String formatMonth(DateTime value);
}

class BangkokBusinessDateClock implements BusinessDateClock {
  BangkokBusinessDateClock({InstantClock? instantClock})
    : _instantClock = instantClock ?? DateTime.now;

  static const _offset = Duration(hours: 7);

  final InstantClock _instantClock;

  @override
  DateTime today() => dateAt(_instantClock());

  @override
  DateTime dateAt(DateTime instant) {
    final bangkok = instant.toUtc().add(_offset);
    return DateTime(bangkok.year, bangkok.month, bangkok.day);
  }

  @override
  Duration untilNextDay() {
    final instant = _instantClock().toUtc();
    final bangkok = instant.add(_offset);
    final nextMidnightUtc = DateTime.utc(
      bangkok.year,
      bangkok.month,
      bangkok.day + 1,
    ).subtract(_offset);
    final delay = nextMidnightUtc.difference(instant);
    return delay.isNegative ? Duration.zero : delay;
  }

  @override
  String formatDate(DateTime value) =>
      '${_four(value.year)}-${_two(value.month)}-${_two(value.day)}';

  @override
  String formatMonth(DateTime value) =>
      '${_four(value.year)}-${_two(value.month)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
  static String _four(int value) => value.toString().padLeft(4, '0');
}
