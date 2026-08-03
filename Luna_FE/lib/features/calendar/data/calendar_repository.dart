import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoint.dart';
import '../../../core/utils/api_date.dart';
import '../domain/cycle_calendar.dart';

class CalendarRepository {
  const CalendarRepository(this._api);
  final ApiClient _api;

  Future<CycleCalendar> month(DateTime month) async =>
      (await _api.get<CycleCalendar>(
        ApiEndpoint.calendar,
        queryParameters: {'month': ApiDate.month(month)},
        decode: (value) =>
            CycleCalendar.fromJson(value! as Map<String, dynamic>),
      )).data;
}
