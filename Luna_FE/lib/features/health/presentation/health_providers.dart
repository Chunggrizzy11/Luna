import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/time/business_date_clock.dart';
import '../../calendar/data/calendar_repository.dart';
import '../../calendar/domain/cycle_calendar.dart';
import '../../cycle/data/cycle_repository.dart';
import '../../cycle/domain/cycle.dart';
import '../../mood/data/mood_repository.dart';
import '../../mood/domain/mood.dart';
import '../../note/data/note_repository.dart';
import '../../note/domain/note.dart';
import '../../symptom/data/symptom_repository.dart';
import '../data/health_repository.dart';
import '../domain/health_models.dart';
import 'daily_log_controller.dart';
import 'journal_controller.dart';
import 'local_day_controller.dart';

final apiClientProvider = Provider<ApiClient>(
  (ref) => throw StateError('apiClientProvider must be overridden at root'),
);
final businessDateClockProvider = Provider<BusinessDateClock>(
  (ref) => BangkokBusinessDateClock(),
);
final localDayProvider = StateNotifierProvider<LocalDayController, DateTime>(
  (ref) => LocalDayController(
    businessDateClock: ref.watch(businessDateClockProvider),
  ),
);

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepository(ref.watch(apiClientProvider)),
);
final cycleRepositoryProvider = Provider<CycleRepository>(
  (ref) => CycleRepository(ref.watch(apiClientProvider)),
);
final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => CalendarRepository(ref.watch(apiClientProvider)),
);
final moodRepositoryProvider = Provider<MoodRepository>(
  (ref) => MoodRepository(ref.watch(apiClientProvider)),
);
final symptomRepositoryProvider = Provider<SymptomRepository>(
  (ref) => SymptomRepository(ref.watch(apiClientProvider)),
);
final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(ref.watch(apiClientProvider)),
);

final dashboardProvider = FutureProvider.autoDispose<OwnerDashboard>(
  (ref) => ref
      .watch(healthRepositoryProvider)
      .dashboard(ref.watch(localDayProvider)),
);
final careTodayProvider = FutureProvider.autoDispose<CareSuggestion?>((ref) {
  ref.watch(localDayProvider);
  return ref.watch(healthRepositoryProvider).careToday();
});
final journalProvider =
    StateNotifierProvider.autoDispose<JournalController, JournalState>(
      (ref) => JournalController(
        loadPage: (page, limit) => ref
            .watch(healthRepositoryProvider)
            .journal(page: page, limit: limit),
      ),
    );
final currentCycleProvider = FutureProvider.autoDispose<Cycle?>(
  (ref) => ref.watch(cycleRepositoryProvider).current(),
);
final calendarProvider = FutureProvider.autoDispose
    .family<CycleCalendar, String>((ref, month) {
      ref.watch(localDayProvider);
      return ref
          .watch(calendarRepositoryProvider)
          .month(DateTime.parse('$month-01'));
    });

final dailyLogForDateProvider = FutureProvider.autoDispose
    .family<DailyLog, String>((ref, date) async {
      final parsed = DateTime.parse(date);
      final values = await Future.wait<Object?>([
        ref.watch(moodRepositoryProvider).get(parsed),
        ref.watch(symptomRepositoryProvider).get(parsed),
        ref.watch(noteRepositoryProvider).get(parsed),
      ]);
      final symptoms = values[1]! as DailyLog;
      return DailyLog(
        mood: values[0] as Mood?,
        symptoms: symptoms.symptoms,
        discomfortLevel: symptoms.discomfortLevel,
        note: (values[2]! as HealthNote).note,
      );
    });

void invalidateOwnerData(Ref ref) {
  ref.invalidate(dashboardProvider);
  ref.invalidate(calendarProvider);
  ref.invalidate(journalProvider);
  ref.invalidate(currentCycleProvider);
}

final dailyLogControllerProvider =
    StateNotifierProvider<DailyLogController, AsyncValue<void>>((ref) {
      final moods = ref.watch(moodRepositoryProvider);
      final symptoms = ref.watch(symptomRepositoryProvider);
      final notes = ref.watch(noteRepositoryProvider);
      return DailyLogController(
        onUpdateMood: (date, mood) async => moods.update(date, mood),
        onUpdateSymptoms: (date, values, discomfort) async =>
            symptoms.update(date, values, discomfort),
        onUpdateNote: (date, note) async => notes.update(date, note),
        onDeleteNote: (date) async => notes.delete(date),
        onInvalidate: () => invalidateOwnerData(ref),
      );
    });
