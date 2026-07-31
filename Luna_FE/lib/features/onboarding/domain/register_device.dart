import '../../../shared/entities/device_identity.dart';
import '../../../shared/enums/device_role.dart';
import '../data/device_repository.dart';

class RegisterDevice {
  const RegisterDevice(this._repository);

  final DeviceRegistrationRepository _repository;

  Future<DeviceIdentity> call(DeviceRole role) => _repository.register(role);
}
