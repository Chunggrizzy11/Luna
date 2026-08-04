import 'dart:convert';
import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoint.dart';
import '../../statistics/domain/statistics_models.dart';

class SettingsRepository {
  const SettingsRepository(this._api);
  final ApiClient _api;

  Future<DeviceInfo> getDeviceInfo() async {
    return (await _api.get<DeviceInfo>(
      '/settings/device',
      decode: (value) => DeviceInfo.fromJson(_map(value)),
    )).data;
  }

  Future<UserDataExport> exportData() async {
    return (await _api.get<UserDataExport>(
      '/settings/export',
      decode: (value) => UserDataExport.fromJson(_map(value)),
    )).data;
  }

  Future<ImportResult> importData(UserDataExport data) async {
    return (await _api.post<ImportResult>(
      '/settings/import',
      data: data.toJson(),
      decode: (value) => ImportResult.fromJson(_map(value)),
    )).data;
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid settings response');
    }
    return value;
  }
}
