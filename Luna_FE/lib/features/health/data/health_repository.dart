import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoint.dart';
import '../../../core/utils/api_date.dart';
import '../domain/health_models.dart';

class HealthRepository {
  const HealthRepository(this._api);
  final ApiClient _api;

  Future<OwnerDashboard> dashboard(DateTime date) async =>
      (await _api.get<OwnerDashboard>(
        ApiEndpoint.dashboard,
        queryParameters: {'date': ApiDate.date(date)},
        decode: (value) => OwnerDashboard.fromJson(_map(value)),
      )).data;

  Future<CareSuggestion?> careToday() async => (await _api.get<CareSuggestion?>(
    ApiEndpoint.careToday,
    decode: (value) {
      final suggestion = _map(value)['suggestion'];
      return suggestion == null
          ? null
          : CareSuggestion.fromJson(suggestion as Map<String, dynamic>);
    },
  )).data;

  Future<List<JournalEntry>> journal({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 20,
  }) async => (await _api.get<List<JournalEntry>>(
    ApiEndpoint.journal,
    queryParameters: {
      if (from != null) 'from': ApiDate.date(from),
      if (to != null) 'to': ApiDate.date(to),
      'page': page,
      'limit': limit,
    },
    decode: (value) => List.unmodifiable(
      (_map(value)['items'] as List<Object?>).map(
        (item) => JournalEntry.fromJson(item! as Map<String, dynamic>),
      ),
    ),
  )).data;
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid health response');
  }
  return value;
}
