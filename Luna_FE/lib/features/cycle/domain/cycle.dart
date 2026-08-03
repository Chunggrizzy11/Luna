import 'package:flutter/foundation.dart';

@immutable
class Cycle {
  const Cycle({
    required this.startDate,
    this.endDate,
    this.periodLength,
    this.cycleLength,
    this.source = 'manual',
  });
  final DateTime startDate;
  final DateTime? endDate;
  final int? periodLength;
  final int? cycleLength;
  final String source;

  bool get isActive => endDate == null;

  factory Cycle.fromJson(Map<String, dynamic> json) => Cycle(
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: json['endDate'] == null
        ? null
        : DateTime.parse(json['endDate'] as String),
    periodLength: json['periodLength'] as int?,
    cycleLength: json['cycleLength'] as int?,
    source: json['source'] as String? ?? 'manual',
  );
}
