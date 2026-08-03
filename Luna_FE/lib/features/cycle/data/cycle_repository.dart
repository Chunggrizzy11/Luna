import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoint.dart';
import '../../../core/utils/api_date.dart';
import '../domain/cycle.dart';

class CycleRepository {
  const CycleRepository(this._api);
  final ApiClient _api;

  Future<Cycle?> current() async => (await _api.get<Cycle?>(
    ApiEndpoint.currentCycle,
    decode: (value) =>
        value == null ? null : Cycle.fromJson(value as Map<String, dynamic>),
  )).data;

  Future<Cycle> start(DateTime date) => _mutate(ApiEndpoint.startCycle, date);
  Future<Cycle> end(DateTime date) => _mutate(ApiEndpoint.endCycle, date);

  Future<Cycle> _mutate(String path, DateTime date) async =>
      (await _api.post<Cycle>(
        path,
        data: {'date': ApiDate.date(date)},
        decode: (value) => Cycle.fromJson(value! as Map<String, dynamic>),
      )).data;
}
