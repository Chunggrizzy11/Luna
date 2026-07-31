import 'package:equatable/equatable.dart';

import '../enums/device_role.dart';

class DeviceIdentity extends Equatable {
  const DeviceIdentity({
    required this.deviceId,
    required this.token,
    required this.role,
  });

  final String deviceId;
  final String token;
  final DeviceRole role;

  factory DeviceIdentity.fromJson(Map<String, Object?> json) {
    final deviceId = json['deviceId'];
    final token = json['token'];
    final role = json['role'];
    if (deviceId is! String ||
        deviceId.isEmpty ||
        token is! String ||
        token.isEmpty ||
        role is! String) {
      throw const FormatException('Invalid secure device identity');
    }
    return DeviceIdentity(
      deviceId: deviceId,
      token: token,
      role: DeviceRole.fromWire(role),
    );
  }

  Map<String, String> toJson() => {
    'deviceId': deviceId,
    'token': token,
    'role': role.wireValue,
  };

  @override
  List<Object> get props => [deviceId, token, role];

  @override
  String toString() =>
      'DeviceIdentity(role: ${role.wireValue}, credentials: [REDACTED])';
}
