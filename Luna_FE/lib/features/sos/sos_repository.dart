import '../../../core/network/api_client.dart';

class SosRepository {
  SosRepository(this._api);
  final ApiClient _api;

  Future<void> trigger() async {
    await _api.post<void>(
      '/sos/trigger',
      decode: (_) {},
    );
  }

  Future<void> acknowledge() async {
    await _api.post<void>(
      '/sos/acknowledge',
      decode: (_) {},
    );
  }
}
