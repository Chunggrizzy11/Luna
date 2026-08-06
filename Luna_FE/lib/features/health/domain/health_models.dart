import 'package:flutter/foundation.dart';

import '../../mood/domain/mood.dart';
import '../../symptom/domain/symptom.dart';

@immutable
class CycleSummary {
  const CycleSummary({
    required this.currentCycleDay,
    required this.isPeriodActive,
    required this.daysUntilNextPeriod,
    required this.averageCycleLength,
    required this.averagePeriodLength,
    required this.predictedPeriodStart,
    required this.predictedPeriodEnd,
    required this.ovulationDate,
  });
  final int? currentCycleDay;
  final bool isPeriodActive;
  final int? daysUntilNextPeriod;
  final int averageCycleLength;
  final int averagePeriodLength;
  final DateTime? predictedPeriodStart;
  final DateTime? predictedPeriodEnd;
  final DateTime? ovulationDate;

  factory CycleSummary.fromJson(Map<String, dynamic> json) => CycleSummary(
    currentCycleDay: json['currentCycleDay'] as int?,
    isPeriodActive: json['isPeriodActive'] as bool,
    daysUntilNextPeriod: json['daysUntilNextPeriod'] as int?,
    averageCycleLength: json['averageCycleLength'] as int,
    averagePeriodLength: json['averagePeriodLength'] as int,
    predictedPeriodStart: _optionalDate(json['predictedPeriodStart']),
    predictedPeriodEnd: _optionalDate(json['predictedPeriodEnd']),
    ovulationDate: _optionalDate(json['ovulationDate']),
  );
}

@immutable
class DailyLog {
  const DailyLog({
    this.mood,
    this.symptoms = const [],
    this.discomfortLevel,
    this.note,
  });
  final Mood? mood;
  final List<Symptom> symptoms;
  final int? discomfortLevel;
  final String? note;

  factory DailyLog.fromJson(Map<String, dynamic> json) => DailyLog(
    mood: json['mood'] == null ? null : Mood.fromWire(json['mood'] as String),
    symptoms: List.unmodifiable(
      (json['symptoms'] as List<Object?>? ?? const []).map(
        (item) => Symptom.fromWire(item! as String),
      ),
    ),
    discomfortLevel: json['discomfortLevel'] as int?,
    note: json['note'] as String?,
  );
}

@immutable
class OwnerDashboard {
  const OwnerDashboard({
    required this.date,
    required this.cycle,
    required this.dailyLog,
  });
  final DateTime date;
  final CycleSummary cycle;
  final DailyLog dailyLog;

  factory OwnerDashboard.fromJson(Map<String, dynamic> json) => OwnerDashboard(
    date: DateTime.parse(json['date'] as String),
    cycle: json['cycle'] == null ? const CycleSummary(
      currentCycleDay: null,
      isPeriodActive: false,
      daysUntilNextPeriod: null,
      averageCycleLength: 28,
      averagePeriodLength: 5,
      predictedPeriodStart: null,
      predictedPeriodEnd: null,
      ovulationDate: null,
    ) : CycleSummary.fromJson(json['cycle'] as Map<String, dynamic>),
    dailyLog: json['dailyLog'] == null ? const DailyLog() : DailyLog.fromJson(json['dailyLog'] as Map<String, dynamic>),
  );
}

@immutable
class CareSuggestion {
  const CareSuggestion({
    required this.id,
    required this.title,
    required this.description,
  });
  final String id;
  final String title;
  final String description;

  factory CareSuggestion.fromJson(Map<String, dynamic> json) => CareSuggestion(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
  );
}

@immutable
class JournalEntry {
  const JournalEntry({
    required this.date,
    this.mood,
    this.symptoms = const [],
    this.discomfortLevel,
    this.note,
  });
  final DateTime date;
  final Mood? mood;
  final List<Symptom> symptoms;
  final int? discomfortLevel;
  final String? note;

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    date: DateTime.parse(json['date'] as String),
    mood: json['mood'] == null ? null : Mood.fromWire(json['mood'] as String),
    symptoms: List.unmodifiable(
      (json['symptoms'] as List<Object?>? ?? const []).map(
        (item) => Symptom.fromWire(item! as String),
      ),
    ),
    discomfortLevel: json['discomfortLevel'] as int?,
    note: json['note'] as String?,
  );
}

@immutable
class JournalBatch {
  const JournalBatch({
    required this.items,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  final List<JournalEntry> items;
  final int page;
  final int limit;
  final bool hasMore;

  factory JournalBatch.fromJson(Map<String, dynamic> json) {
    final items = List<JournalEntry>.unmodifiable(
      (json['items'] as List<Object?>).map(
        (item) => JournalEntry.fromJson(item! as Map<String, dynamic>),
      ),
    );
    final limit = json['limit'] as int;
    return JournalBatch(
      items: items,
      page: json['page'] as int,
      limit: limit,
      hasMore: json['hasMore'] as bool? ?? items.length >= limit,
    );
  }
}

DateTime? _optionalDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
