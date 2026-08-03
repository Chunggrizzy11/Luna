import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood/domain/mood.dart';
import '../../symptom/domain/symptom.dart';

typedef UpdateMood = Future<void> Function(DateTime date, Mood mood);
typedef UpdateSymptoms =
    Future<void> Function(
      DateTime date,
      Set<Symptom> symptoms,
      int discomfortLevel,
    );
typedef UpdateNote = Future<void> Function(DateTime date, String note);
typedef DeleteNote = Future<void> Function(DateTime date);

class DailyLogController extends StateNotifier<AsyncValue<void>> {
  DailyLogController({
    required this.onUpdateMood,
    required this.onUpdateSymptoms,
    required this.onUpdateNote,
    required this.onDeleteNote,
    required this.onInvalidate,
  }) : super(const AsyncData(null));

  final UpdateMood onUpdateMood;
  final UpdateSymptoms onUpdateSymptoms;
  final UpdateNote onUpdateNote;
  final DeleteNote onDeleteNote;
  final void Function() onInvalidate;

  Future<void> save({
    required DateTime date,
    required Mood mood,
    required Set<Symptom> symptoms,
    required int discomfortLevel,
    required String note,
  }) => _mutate(() async {
    await Future.wait([
      onUpdateMood(date, mood),
      onUpdateSymptoms(date, symptoms, discomfortLevel),
      if (note.trim().isNotEmpty) onUpdateNote(date, note.trim()),
    ]);
  });

  Future<void> deleteNote(DateTime date) => _mutate(() => onDeleteNote(date));

  Future<void> _mutate(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await action();
      onInvalidate();
    });
  }
}
