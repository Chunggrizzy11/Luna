import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoint.dart';
import '../../../core/utils/api_date.dart';
import '../domain/note.dart';

class NoteRepository {
  const NoteRepository(this._api);
  final ApiClient _api;

  Future<HealthNote> get(DateTime date) => _request(date);
  Future<HealthNote> update(DateTime date, String note) =>
      _request(date, note: note);

  Future<HealthNote> delete(DateTime date) async =>
      (await _api.delete<HealthNote>(
        ApiEndpoint.note(ApiDate.date(date)),
        decode: (value) => HealthNote.fromJson(value! as Map<String, dynamic>),
      )).data;

  Future<HealthNote> _request(DateTime date, {String? note}) async {
    HealthNote decode(Object? value) =>
        HealthNote.fromJson(value! as Map<String, dynamic>);
    if (note == null) {
      return (await _api.get<HealthNote>(
        ApiEndpoint.note(ApiDate.date(date)),
        decode: decode,
      )).data;
    }
    return (await _api.put<HealthNote>(
      ApiEndpoint.note(ApiDate.date(date)),
      data: {'note': note},
      decode: decode,
    )).data;
  }
}
