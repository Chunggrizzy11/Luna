import 'package:flutter/foundation.dart';

typedef LogSink = void Function(String message);

class AppLogger {
  AppLogger({LogSink? sink}) : _sink = sink ?? debugPrint;

  final LogSink _sink;

  void info(String message) => _sink(_sanitize(message));

  void warning(String message) => _sink(_sanitize(message));

  String _sanitize(String value) => value
      .replaceAll(
        RegExp(r'Bearer\s+[^\s,]+', caseSensitive: false),
        'Bearer [REDACTED]',
      )
      .replaceAll(
        RegExp(
          r'(token|password|secret|deviceId)\s*[:=]\s*[^,\s}]+',
          caseSensitive: false,
        ),
        r'$1=[REDACTED]',
      );
}
