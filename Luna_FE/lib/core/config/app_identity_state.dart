import 'package:flutter/foundation.dart';

import '../../shared/entities/device_identity.dart';
import '../error/exception.dart';
import '../storage/secure_storage_service.dart';

enum AppIdentityStatus { missing, present, error }

class AppIdentityState extends ChangeNotifier {
  AppIdentityState._(this._secureStorage);

  final SecureStorageService _secureStorage;

  AppIdentityStatus status = AppIdentityStatus.missing;
  DeviceIdentity? identity;
  StorageFailureReason? errorReason;
  bool isRetrying = false;

  static Future<AppIdentityState> initialize(
    SecureStorageService secureStorage,
  ) async {
    final state = AppIdentityState._(secureStorage);
    await state._load();
    return state;
  }

  Future<void> retry() async {
    if (isRetrying) return;
    isRetrying = true;
    notifyListeners();
    await _load();
    isRetrying = false;
    notifyListeners();
  }

  void setPresent(DeviceIdentity value) {
    identity = value;
    status = AppIdentityStatus.present;
    errorReason = null;
    notifyListeners();
  }

  Future<void> _load() async {
    try {
      final stored = await _secureStorage.readIdentity();
      identity = stored;
      status = stored == null
          ? AppIdentityStatus.missing
          : AppIdentityStatus.present;
      errorReason = null;
    } on StorageException catch (error) {
      identity = null;
      status = AppIdentityStatus.error;
      errorReason = error.reason;
    }
  }
}
