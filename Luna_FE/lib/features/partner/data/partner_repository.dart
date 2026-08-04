import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoint.dart';
import '../domain/partner_models.dart';

class PartnerRepository {
  const PartnerRepository(this._api);
  final ApiClient _api;

  /// Owner generates a pairing code.
  Future<GenerateCodeResponse> generateCode() async {
    return (await _api.post<GenerateCodeResponse>(
      ApiEndpoint.pairingCode,
      decode: (value) => GenerateCodeResponse.fromJson(_map(value)),
    )).data;
  }

  /// Partner joins using a pairing code.
  Future<JoinPairingResponse> join(String code) async {
    return (await _api.post<JoinPairingResponse>(
      ApiEndpoint.pairingJoin,
      data: {'code': code},
      decode: (value) => JoinPairingResponse.fromJson(_map(value)),
    )).data;
  }

  /// Unpair from current partner.
  Future<void> unpair() async {
    await _api.delete<void>(
      ApiEndpoint.pairingUnpair,
      decode: (_) => null,
    );
  }

  /// Get current pairing status.
  Future<PairingStatusResponse> getStatus() async {
    return (await _api.get<PairingStatusResponse>(
      ApiEndpoint.pairingStatus,
      decode: (value) => PairingStatusResponse.fromJson(_map(value)),
    )).data;
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid pairing response');
    }
    return value;
  }
}
