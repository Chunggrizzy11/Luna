import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/time/business_date_clock.dart';

void main() {
  test('Bangkok business date changes exactly at 17:00 UTC', () {
    final before = BangkokBusinessDateClock(
      instantClock: () => DateTime.parse('2026-08-03T16:59:59.999Z'),
    );
    final after = BangkokBusinessDateClock(
      instantClock: () => DateTime.parse('2026-08-03T17:00:00.000Z'),
    );

    expect(before.today(), DateTime(2026, 8, 3));
    expect(after.today(), DateTime(2026, 8, 4));
  });

  test('business date ignores the source instant device offset', () {
    final clock = BangkokBusinessDateClock(
      instantClock: () => DateTime.parse('2026-08-04T00:30:00+09:00'),
    );

    expect(clock.today(), DateTime(2026, 8, 3));
    expect(clock.formatDate(clock.today()), '2026-08-03');
    expect(clock.formatMonth(clock.today()), '2026-08');
  });

  test('next rollover delay targets Bangkok midnight', () {
    final clock = BangkokBusinessDateClock(
      instantClock: () => DateTime.parse('2026-08-03T16:59:59.000Z'),
    );

    expect(clock.untilNextDay(), const Duration(seconds: 1));
  });
}
