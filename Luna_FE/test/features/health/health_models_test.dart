import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/features/calendar/domain/cycle_calendar.dart';
import 'package:luna_fe/features/health/domain/health_models.dart';
import 'package:luna_fe/features/mood/domain/mood.dart';
import 'package:luna_fe/features/symptom/domain/symptom.dart';

void main() {
  test('dashboard maps the exact owner success envelope payload', () {
    final dashboard = OwnerDashboard.fromJson({
      'date': '2026-03-12',
      'relationship': 'owner',
      'cycle': {
        'currentCycleDay': 12,
        'isPeriodActive': true,
        'daysUntilNextPeriod': 17,
        'averageCycleLength': 28,
        'averagePeriodLength': 5,
        'predictedPeriodStart': '2026-03-29',
        'predictedPeriodEnd': '2026-04-02',
        'ovulationDate': '2026-03-15',
        'observedPeriods': [
          {'startDate': '2026-03-01', 'endDate': '2026-03-05'},
        ],
      },
      'dailyLog': {
        'mood': 'happy',
        'symptoms': ['cramps'],
        'discomfortLevel': 3,
        'note': 'Nghỉ ngơi nhiều hơn',
      },
    });

    expect(dashboard.cycle.currentCycleDay, 12);
    expect(dashboard.dailyLog.mood, Mood.happy);
    expect(dashboard.dailyLog.symptoms, [Symptom.cramps]);
  });

  test(
    'calendar preserves distinct observed predicted and ovulation states',
    () {
      final calendar = CycleCalendar.fromJson({
        'month': '2026-03',
        'days': [
          {
            'date': '2026-03-03',
            'status': 'observed-period',
            'isObservedPeriod': true,
            'isPredictedPeriod': false,
            'isOvulation': false,
          },
          {
            'date': '2026-03-29',
            'status': 'predicted-period',
            'isObservedPeriod': false,
            'isPredictedPeriod': true,
            'isOvulation': false,
          },
          {
            'date': '2026-03-15',
            'status': 'ovulation',
            'isObservedPeriod': false,
            'isPredictedPeriod': false,
            'isOvulation': true,
          },
        ],
      });

      expect(calendar.days.map((day) => day.status), [
        CalendarDayStatus.observedPeriod,
        CalendarDayStatus.predictedPeriod,
        CalendarDayStatus.ovulation,
      ]);
    },
  );

  test('wire enums expose exactly seven moods and ten symptoms', () {
    expect(Mood.values, hasLength(7));
    expect(Symptom.values, hasLength(10));
    expect(Mood.anxious.wireValue, 'anxious');
    expect(Symptom.breastTenderness.wireValue, 'breast_tenderness');
  });
}
