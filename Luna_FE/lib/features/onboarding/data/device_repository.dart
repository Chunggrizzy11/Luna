import 'package:flutter/foundation.dart';

import '../../../core/error/error_mapper.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoint.dart';
import '../../../shared/entities/device_identity.dart';
import '../../../shared/enums/device_role.dart';

abstract interface class DeviceRegistrationRepository {
  Future<DeviceIdentity> register(DeviceRole role);
}

class DeviceRepository implements DeviceRegistrationRepository {
  factory DeviceRepository({required ApiClient apiClient, String? platform}) =>
      DeviceRepository._(apiClient, platform ?? _currentPlatform());

  DeviceRepository._(this._apiClient, this._platform);

  final ApiClient _apiClient;
  final String _platform;

  @override
  Future<DeviceIdentity> register(DeviceRole role) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoint.registerDevice,
        data: {'role': role.wireValue, 'platform': _platform},
        decode: (value) {
          if (value is! Map<String, dynamic>) {
            throw const FormatException('Invalid registration response');
          }
          return value;
        },
      );
      final deviceId = response.data['deviceId'];
      final token = response.data['token'];
      if (deviceId is! String ||
          deviceId.isEmpty ||
          token is! String ||
          token.isEmpty) {
        throw const FormatException(
          'Registration response omitted credentials',
        );
      }
      return DeviceIdentity(deviceId: deviceId, token: token, role: role);
    } on Failure {
      rethrow;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  static String _currentPlatform() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}
