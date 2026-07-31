import 'package:flutter/foundation.dart';

import '../../../core/error/error_mapper.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../shared/entities/device_identity.dart';
import '../../../shared/enums/device_role.dart';
import '../domain/register_device.dart';

enum OnboardingState { idle, loading, ready, error }

class OnboardingController extends ChangeNotifier {
  factory OnboardingController({
    required RegisterDevice registerDevice,
    required SecureStorageService secureStorage,
  }) => OnboardingController._(registerDevice, secureStorage);

  OnboardingController._(this._registerDevice, this._secureStorage);

  final RegisterDevice _registerDevice;
  final SecureStorageService _secureStorage;

  OnboardingState state = OnboardingState.idle;
  DeviceIdentity? identity;
  String? errorMessage;
  Future<DeviceIdentity>? _inFlight;

  Future<DeviceIdentity> bootstrap(DeviceRole role) {
    return _inFlight ??= _bootstrap(role).whenComplete(() => _inFlight = null);
  }

  Future<DeviceIdentity> _bootstrap(DeviceRole role) async {
    state = OnboardingState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final stored = await _secureStorage.readIdentity();
      final result = stored ?? await _registerDevice(role);
      if (stored == null) await _secureStorage.writeIdentity(result);
      identity = result;
      state = OnboardingState.ready;
      notifyListeners();
      return result;
    } catch (error) {
      state = OnboardingState.error;
      errorMessage = ErrorMapper.map(error).message;
      notifyListeners();
      rethrow;
    }
  }
}
