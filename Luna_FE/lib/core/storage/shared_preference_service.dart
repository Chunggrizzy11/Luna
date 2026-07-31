import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceService {
  factory SharedPreferenceService({SharedPreferencesAsync? preferences}) =>
      SharedPreferenceService._(preferences);

  SharedPreferenceService._(this._preferences);

  final SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _store => _preferences ?? SharedPreferencesAsync();

  Future<String?> getString(String key) {
    _validateKey(key);
    return _store.getString(key);
  }

  Future<void> setString(String key, String value) {
    _validateKey(key);
    return _store.setString(key, value);
  }

  Future<bool?> getBool(String key) {
    _validateKey(key);
    return _store.getBool(key);
  }

  Future<void> setBool(String key, bool value) {
    _validateKey(key);
    return _store.setBool(key, value);
  }

  Future<void> remove(String key) {
    _validateKey(key);
    return _store.remove(key);
  }

  void _validateKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    const forbidden = ['token', 'deviceid', 'password', 'secret', 'credential'];
    if (forbidden.any(normalized.contains)) {
      throw ArgumentError.value(key, 'key', 'Secrets require secure storage');
    }
  }
}
