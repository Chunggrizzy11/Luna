import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoint.dart';
import '../domain/statistics_models.dart';

class StatisticsRepository {
  const StatisticsRepository(this._api);
  final ApiClient _api;

  Future<CycleStatistics> getCycleStats() async {
    return (await _api.get<CycleStatistics>(
      '/statistics/cycles',
      decode: (value) => CycleStatistics.fromJson(_map(value)),
    )).data;
  }

  Future<MoodStatistics> getMoodStats({String? from, String? to}) async {
    return (await _api.get<MoodStatistics>(
      '/statistics/mood',
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
      decode: (value) => MoodStatistics.fromJson(_map(value)),
    )).data;
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid statistics response');
    }
    return value;
  }
}
