enum DeviceRole {
  owner('owner'),
  partner('partner');

  const DeviceRole(this.wireValue);

  final String wireValue;

  static DeviceRole fromWire(String value) => values.firstWhere(
    (role) => role.wireValue == value,
    orElse: () => throw FormatException('Unknown device role: $value'),
  );
}
