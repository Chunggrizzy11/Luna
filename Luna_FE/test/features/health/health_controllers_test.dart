import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/error/failure.dart';
import 'package:luna_fe/features/cycle/domain/cycle.dart';
import 'package:luna_fe/features/cycle/presentation/cycle_controller.dart';
import 'package:luna_fe/features/health/presentation/daily_log_controller.dart';
import 'package:luna_fe/features/health/presentation/health_providers.dart';
import 'package:luna_fe/features/mood/domain/mood.dart';
import 'package:luna_fe/features/symptom/domain/symptom.dart';

void main() {
  test(
    'cycle mutation invalidates all owner projections after success',
    () async {
      var invalidations = 0;
      final controller = CycleController(
        onStart: (date) async => Cycle(startDate: date),
        onEnd: (date) async => Cycle(startDate: date, endDate: date),
        onInvalidate: () => invalidations++,
      );

      await controller.start(DateTime(2026, 8, 3));

      expect(controller.state, isA<AsyncData<void>>());
      expect(invalidations, 1);
    },
  );

  test(
    'daily log provider keeps delayed mutation state without a UI listener',
    () async {
      final pending = Completer<void>();
      final controller = DailyLogController(
        onUpdateMood: (date, mood) => pending.future,
        onUpdateSymptoms: (date, symptoms, discomfort) async {},
        onUpdateNote: (date, note) async {},
        onDeleteNote: (date) async {},
        onInvalidate: () {},
      );
      final container = ProviderContainer(
        overrides: [
          dailyLogControllerProvider.overrideWith((ref) => controller),
        ],
      );
      addTearDown(container.dispose);

      final mutation = container
          .read(dailyLogControllerProvider.notifier)
          .save(
            date: DateTime(2026, 8, 3),
            mood: Mood.happy,
            symptoms: const {Symptom.cramps},
            discomfortLevel: 2,
            note: '',
          );
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(dailyLogControllerProvider.notifier),
        same(controller),
      );
      expect(container.read(dailyLogControllerProvider).isLoading, isTrue);
      pending.complete();
      await mutation;
      expect(
        container.read(dailyLogControllerProvider),
        isA<AsyncData<void>>(),
      );
    },
  );

  test(
    'partial daily log failure still invalidates every projection',
    () async {
      var moodSaved = false;
      var invalidations = 0;
      final controller = DailyLogController(
        onUpdateMood: (date, mood) async => moodSaved = true,
        onUpdateSymptoms: (date, symptoms, discomfort) async =>
            throw const NetworkFailure('Mất mạng giữa chừng'),
        onUpdateNote: (date, note) async {},
        onDeleteNote: (date) async {},
        onInvalidate: () => invalidations++,
      );

      await controller.save(
        date: DateTime(2026, 8, 3),
        mood: Mood.happy,
        symptoms: const {Symptom.cramps},
        discomfortLevel: 2,
        note: '',
      );

      expect(moodSaved, isTrue);
      expect(controller.state.error, isA<NetworkFailure>());
      expect(invalidations, 1);
    },
  );

  test(
    'controller preserves unauthorized and offline typed failures',
    () async {
      final controller = CycleController(
        onStart: (_) async => throw const UnauthorizedFailure('Hết phiên'),
        onEnd: (_) async => throw const NetworkFailure(),
        onInvalidate: () {},
      );

      await controller.start(DateTime(2026, 8, 3));
      expect(controller.state.error, isA<UnauthorizedFailure>());
      await controller.end(DateTime(2026, 8, 3));
      expect(controller.state.error, isA<NetworkFailure>());
    },
  );

  test(
    'daily log mutations invalidate dashboard calendar and journal',
    () async {
      var invalidations = 0;
      final controller = DailyLogController(
        onUpdateMood: (date, mood) async {},
        onUpdateSymptoms: (date, symptoms, discomfort) async {},
        onUpdateNote: (date, note) async {},
        onDeleteNote: (date) async {},
        onInvalidate: () => invalidations++,
      );

      final date = DateTime(2026, 8, 3);
      await controller.save(
        date: date,
        mood: Mood.happy,
        symptoms: {Symptom.cramps},
        discomfortLevel: 3,
        note: 'Ổn hơn',
      );
      await controller.deleteNote(date);

      expect(invalidations, 2);
      expect(controller.state, isA<AsyncData<void>>());
    },
  );
}
