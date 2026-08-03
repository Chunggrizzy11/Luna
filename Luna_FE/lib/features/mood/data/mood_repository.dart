import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoint.dart';
import '../../../core/utils/api_date.dart';
import '../domain/mood.dart';

class MoodRepository {
  const MoodRepository(this._api);
  final ApiClient _api;

  Future<Mood?> get(DateTime date) async => (await _api.get<Mood?>(
    ApiEndpoint.mood(ApiDate.date(date)),
    decode: (value) {
      final mood = (value! as Map<String, dynamic>)['mood'];
      return mood == null ? null : Mood.fromWire(mood as String);
    },
  )).data;

  Future<Mood> update(DateTime date, Mood mood) async => (await _api.put<Mood>(
    ApiEndpoint.mood(ApiDate.date(date)),
    data: {'mood': mood.wireValue},
    decode: (value) =>
        Mood.fromWire((value! as Map<String, dynamic>)['mood'] as String),
  )).data;
}
