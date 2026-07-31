import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../shared/entities/device_identity.dart';
import '../error/exception.dart';

abstract interface class SecureStorageBackend {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureStorageBackend implements SecureStorageBackend {
  FlutterSecureStorageBackend({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class SecureStorageService {
  SecureStorageService({SecureStorageBackend? backend})
    : _backend = backend ?? FlutterSecureStorageBackend();

  static const _identityKey = 'luna.secure.device_identity.v1';

  final SecureStorageBackend _backend;

  Future<DeviceIdentity?> readIdentity() async {
    try {
      final encoded = await _backend.read(_identityKey);
      if (encoded == null) return null;
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Secure identity is not an object');
      }
      return DeviceIdentity.fromJson(decoded);
    } on FormatException catch (error) {
      await _backend.delete(_identityKey);
      throw StorageException('Secure device identity is corrupt.', error);
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException('Could not read secure device identity.', error);
    }
  }

  Future<void> writeIdentity(DeviceIdentity identity) async {
    try {
      await _backend.write(_identityKey, jsonEncode(identity.toJson()));
    } catch (error) {
      throw StorageException(
        'Could not persist secure device identity.',
        error,
      );
    }
  }

  Future<void> clearIdentity() async {
    try {
      await _backend.delete(_identityKey);
    } catch (error) {
      throw StorageException('Could not clear secure device identity.', error);
    }
  }
}
