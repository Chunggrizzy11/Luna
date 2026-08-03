import 'package:flutter/foundation.dart';

@immutable
class HealthNote {
  const HealthNote({required this.date, this.note});
  final DateTime date;
  final String? note;

  factory HealthNote.fromJson(Map<String, dynamic> json) => HealthNote(
    date: DateTime.parse(json['date'] as String),
    note: json['note'] as String?,
  );
}
