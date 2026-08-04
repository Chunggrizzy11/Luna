import 'package:equatable/equatable.dart';

export class CycleStatistics extends Equatable {
  const CycleStatistics({
    required this.totalCycles,
    required this.averageCycleLength,
    required this.shortestCycle,
    required this.longestCycle,
    required this.averagePeriodLength,
    required this.cycleLengthHistory,
    required this.periodLengthHistory,
  });

  final int totalCycles;
  final double? averageCycleLength;
  final int? shortestCycle;
  final int? longestCycle;
  final double? averagePeriodLength;
  final List<CycleHistoryItem> cycleLengthHistory;
  final List<CycleHistoryItem> periodLengthHistory;

  factory CycleStatistics.fromJson(Map<String, dynamic> json) {
    return CycleStatistics(
      totalCycles: json['totalCycles'] as int,
      averageCycleLength: (json['averageCycleLength'] as num?)?.toDouble(),
      shortestCycle: json['shortestCycle'] as int?,
      longestCycle: json['longestCycle'] as int?,
      averagePeriodLength: (json['averagePeriodLength'] as num?)?.toDouble(),
      cycleLengthHistory: (json['cycleLengthHistory'] as List? ?? [])
          .map((e) => CycleHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      periodLengthHistory: (json['periodLengthHistory'] as List? ?? [])
          .map((e) => CycleHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    totalCycles,
    averageCycleLength,
    shortestCycle,
    longestCycle,
    averagePeriodLength,
    cycleLengthHistory,
    periodLengthHistory,
  ];
}

export class CycleHistoryItem extends Equatable {
  const CycleHistoryItem({
    required this.cycleNumber,
    required this.length,
  });

  final int cycleNumber;
  final int length;

  factory CycleHistoryItem.fromJson(Map<String, dynamic> json) {
    return CycleHistoryItem(
      cycleNumber: json['cycleNumber'] as int,
      length: json['length'] as int,
    );
  }

  @override
  List<Object?> get props => [cycleNumber, length];
}

export class MoodStatistics extends Equatable {
  const MoodStatistics({
    required this.moodCounts,
    required this.averageDiscomfort,
    required this.totalEntries,
  });

  final List<MoodCount> moodCounts;
  final double? averageDiscomfort;
  final int totalEntries;

  factory MoodStatistics.fromJson(Map<String, dynamic> json) {
    return MoodStatistics(
      moodCounts: (json['moodCounts'] as List? ?? [])
          .map((e) => MoodCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      averageDiscomfort: (json['averageDiscomfort'] as num?)?.toDouble(),
      totalEntries: json['totalEntries'] as int,
    );
  }

  @override
  List<Object?> get props => [moodCounts, averageDiscomfort, totalEntries];
}

export class MoodCount extends Equatable {
  const MoodCount({
    required this.mood,
    required this.count,
  });

  final String mood;
  final int count;

  factory MoodCount.fromJson(Map<String, dynamic> json) {
    return MoodCount(
      mood: json['mood'] as String,
      count: json['count'] as int,
    );
  }

  @override
  List<Object?> get props => [mood, count];
}

export class UserDataExport extends Equatable {
  const UserDataExport({
    required this.device,
    required this.cycles,
    required this.dailyLogs,
  });

  final Map<String, dynamic> device;
  final List<dynamic> cycles;
  final List<dynamic> dailyLogs;

  factory UserDataExport.fromJson(Map<String, dynamic> json) {
    return UserDataExport(
      device: json['device'] as Map<String, dynamic>,
      cycles: json['cycles'] as List? ?? [],
      dailyLogs: json['dailyLogs'] as List? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': device,
      'cycles': cycles,
      'dailyLogs': dailyLogs,
    };
  }

  @override
  List<Object?> get props => [device, cycles, dailyLogs];
}

export class ImportResult extends Equatable {
  const ImportResult({
    required this.imported,
    required this.cyclesCount,
    required this.dailyLogsCount,
  });

  final bool imported;
  final int cyclesCount;
  final int dailyLogsCount;

  factory ImportResult.fromJson(Map<String, dynamic> json) {
    return ImportResult(
      imported: json['imported'] as bool,
      cyclesCount: json['cyclesCount'] as int,
      dailyLogsCount: json['dailyLogsCount'] as int,
    );
  }

  @override
  List<Object?> get props => [imported, cyclesCount, dailyLogsCount];
}

export class DeviceInfo extends Equatable {
  const DeviceInfo({
    required this.id,
    required this.role,
    required this.platform,
    required this.deviceName,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String role;
  final String platform;
  final String? deviceName;
  final String status;
  final DateTime createdAt;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'] as String,
      role: json['role'] as String,
      platform: json['platform'] as String,
      deviceName: json['deviceName'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, role, platform, deviceName, status, createdAt];
}