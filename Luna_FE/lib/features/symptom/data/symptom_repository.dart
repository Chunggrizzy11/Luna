import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoint.dart';
import '../../../core/utils/api_date.dart';
import '../../health/domain/health_models.dart';
import '../domain/symptom.dart';

class SymptomRepository {
  const SymptomRepository(this._api);
  final ApiClient _api;

  Future<DailyLog> get(DateTime date) => _request(date);

  Future<DailyLog> update(
    DateTime date,
    Set<Symptom> symptoms,
    int discomfortLevel,
  ) => _request(
    date,
    data: {
      'symptoms': symptoms.map((item) => item.wireValue).toList(),
      'discomfortLevel': discomfortLevel,
    },
  );

  Future<DailyLog> _request(DateTime date, {Object? data}) async {
    DailyLog decode(Object? value) =>
        DailyLog.fromJson(value! as Map<String, dynamic>);
    if (data == null) {
      return (await _api.get<DailyLog>(
        ApiEndpoint.symptoms(ApiDate.date(date)),
        decode: decode,
      )).data;
    }
    return (await _api.put<DailyLog>(
      ApiEndpoint.symptoms(ApiDate.date(date)),
      data: data,
      decode: decode,
    )).data;
  }
}
