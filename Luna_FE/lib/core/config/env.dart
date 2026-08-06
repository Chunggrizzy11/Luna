import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

abstract final class Env {
  static const _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get apiBaseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    if (kDebugMode && kIsWeb) return 'http://localhost:3000/api/v1';
    if (kIsWeb) return 'https://luna-7tkq.onrender.com/api/v1';
    return 'http://10.0.2.2:3000/api/v1';
  }
}
