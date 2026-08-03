import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:luna_fe/app.dart';
import 'package:luna_fe/core/config/app_initializer.dart';
import 'package:luna_fe/core/storage/secure_storage_service.dart';
import 'package:luna_fe/features/health/presentation/health_providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'owner startup persists identity and refreshes the cycle journal flow',
    (tester) async {
      final server = await _CycleJournalFakeServer.start(
        platform: _platformName(),
      );
      addTearDown(server.close);
      final backend = _MemorySecureStorage();
      final storage = SecureStorageService(backend: backend);
      final config = await AppInitializer.initialize(
        secureStorage: storage,
        apiBaseUrl: server.baseUrl,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(() => DateTime(2025, 2, 14)),
          ],
          child: LunaApp(config: config),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chào mừng đến Luna'), findsOneWidget);

      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(server.count('POST /devices/register'), 1);
      expect(
        (await storage.readIdentity())?.token,
        _CycleJournalFakeServer.token,
      );
      expect(config.identityState.identity?.role.wireValue, 'owner');
      expect(find.text('Luna của bạn'), findsOneWidget);

      await tester.tap(find.text('Chu kỳ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu kỳ kinh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(server.count('POST /cycles/start'), 1);
      expect(find.text('Kỳ kinh đang diễn ra'), findsOneWidget);

      await tester.tap(find.text('Tổng quan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ghi hôm nay'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vui vẻ'));
      await tester.tap(find.text('Đau bụng'));
      await tester.enterText(
        find.bySemanticsLabel('Ghi chú sức khỏe'),
        'Đã lưu qua fake server.',
      );
      await tester.ensureVisible(find.text('Lưu nhật ký'));
      await tester.tap(find.text('Lưu nhật ký'));
      await tester.pumpAndSettle();
      expect(server.count('PUT /moods/2025-02-14'), 1);
      expect(server.count('PUT /symptoms/2025-02-14'), 1);
      expect(server.count('PUT /notes/2025-02-14'), 1);
      expect(find.textContaining('Vui vẻ'), findsWidgets);

      await tester.tap(find.text('Lịch'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Ngày 14, kỳ kinh thực tế'), findsOneWidget);
      expect(server.count('GET /calendar'), greaterThanOrEqualTo(1));

      await tester.tap(find.text('Chu kỳ'));
      await tester.pumpAndSettle();
      final dashboardBeforeEnd = server.count('GET /health/dashboard');
      final calendarBeforeEnd = server.count('GET /calendar');
      final journalBeforeEnd = server.count('GET /health/journal');
      await tester.tap(find.text('Kết thúc kỳ kinh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();
      expect(server.count('POST /cycles/end'), 1);
      expect(
        server.count('GET /health/dashboard'),
        greaterThan(dashboardBeforeEnd),
      );
      expect(server.count('GET /calendar'), greaterThan(calendarBeforeEnd));
      expect(
        server.count('GET /health/journal'),
        greaterThan(journalBeforeEnd),
      );
      expect(find.text('Chưa có kỳ kinh đang diễn ra'), findsOneWidget);

      await tester.tap(find.text('Nhật ký'));
      await tester.pumpAndSettle();
      expect(find.text('Đã lưu qua fake server.'), findsOneWidget);
      expect(server.contractFailures, isEmpty);
    },
  );
}

String _platformName() => switch (defaultTargetPlatform) {
  TargetPlatform.android => 'android',
  TargetPlatform.iOS => 'ios',
  TargetPlatform.macOS => 'macos',
  TargetPlatform.windows => 'windows',
  TargetPlatform.linux => 'linux',
  TargetPlatform.fuchsia => 'fuchsia',
};

class _MemorySecureStorage implements SecureStorageBackend {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}

class _CycleJournalFakeServer {
  _CycleJournalFakeServer._(this._server, this._platform);

  static const token = 'integration-owner-token';

  final HttpServer _server;
  final String _platform;
  final List<String> requests = <String>[];
  final List<String> contractFailures = <String>[];
  static const _date = '2025-02-14';
  bool _started = false;
  bool _active = false;
  String? _mood;
  List<String> _symptoms = <String>[];
  int? _discomfortLevel;
  String? _note;

  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  static Future<_CycleJournalFakeServer> start({
    required String platform,
  }) async {
    final server = _CycleJournalFakeServer._(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
      platform,
    );
    unawaited(server._serve());
    return server;
  }

  Future<void> close() => _server.close(force: true);

  int count(String request) => requests.where((item) => item == request).length;

  Future<void> _serve() async {
    await for (final request in _server) {
      final requestName = '${request.method} ${request.uri.path}';
      requests.add(requestName);
      try {
        final data = await _route(request);
        await _respond(request, 200, data);
      } catch (error) {
        contractFailures.add('$requestName: $error');
        await _respond(request, 400, <String, Object?>{'error': '$error'});
      }
    }
  }

  Future<Object?> _route(HttpRequest request) async {
    final body = await _body(request);
    return switch ((request.method, request.uri.path)) {
      ('POST', '/devices/register') => _register(request, body),
      ('GET', '/cycles/current') => _current(request, body),
      ('POST', '/cycles/start') => _start(request, body),
      ('POST', '/cycles/end') => _end(request, body),
      ('GET', '/health/dashboard') => _dashboard(request, body),
      ('GET', '/health/care/today') => _careToday(request, body),
      ('GET', '/calendar') => _calendar(request, body),
      ('GET', '/health/journal') => _journal(request, body),
      ('GET', '/moods/2025-02-14') => _moodForDate(request, body),
      ('GET', '/symptoms/2025-02-14') => _symptomsForDate(request, body),
      ('GET', '/notes/2025-02-14') => _noteForDate(request, body),
      ('PUT', '/moods/2025-02-14') => _saveMood(request, body),
      ('PUT', '/symptoms/2025-02-14') => _saveSymptoms(request, body),
      ('PUT', '/notes/2025-02-14') => _saveNote(request, body),
      _ => throw StateError(
        'Unexpected route ${request.method} ${request.uri}',
      ),
    };
  }

  Map<String, Object?> _register(
    HttpRequest request,
    Map<String, Object?> body,
  ) {
    _expectRequest(
      request,
      body: body,
      authenticated: false,
      expectedBody: <String, Object?>{'role': 'owner', 'platform': _platform},
    );
    return <String, Object?>{'deviceId': 'owner-device-id', 'token': token};
  }

  Object? _current(HttpRequest request, Map<String, Object?> body) {
    _expectRequest(request, body: body);
    return _active ? _cycle() : null;
  }

  Map<String, Object?> _start(HttpRequest request, Map<String, Object?> body) {
    _expectRequest(
      request,
      body: body,
      expectedBody: const <String, Object?>{'date': _date},
    );
    _started = true;
    _active = true;
    return _cycle();
  }

  Map<String, Object?> _end(HttpRequest request, Map<String, Object?> body) {
    _expectRequest(
      request,
      body: body,
      expectedBody: const <String, Object?>{'date': _date},
    );
    _active = false;
    return _cycle(endDate: _date);
  }

  Map<String, Object?> _dashboard(
    HttpRequest request,
    Map<String, Object?> body,
  ) {
    _expectRequest(
      request,
      body: body,
      expectedQuery: const <String, String>{'date': _date},
    );
    return <String, Object?>{
      'date': _date,
      'relationship': 'owner',
      'cycle': <String, Object?>{
        'currentCycleDay': _active ? 1 : null,
        'isPeriodActive': _active,
        'daysUntilNextPeriod': null,
        'averageCycleLength': 28,
        'averagePeriodLength': 5,
        'predictedPeriodStart': null,
        'predictedPeriodEnd': null,
        'ovulationDate': null,
      },
      'dailyLog': <String, Object?>{
        'mood': _mood,
        'symptoms': _symptoms,
        'discomfortLevel': _discomfortLevel,
        'note': _note,
      },
    };
  }

  Map<String, Object?> _careToday(
    HttpRequest request,
    Map<String, Object?> body,
  ) {
    _expectRequest(request, body: body);
    return <String, Object?>{'suggestion': null};
  }

  Map<String, Object?> _calendar(
    HttpRequest request,
    Map<String, Object?> body,
  ) {
    _expectRequest(
      request,
      body: body,
      expectedQuery: const <String, String>{'month': '2025-02'},
    );
    return <String, Object?>{
      'month': '2025-02',
      'days': <Map<String, Object?>>[
        if (_started)
          const <String, Object?>{'date': _date, 'status': 'observed-period'},
      ],
    };
  }

  Map<String, Object?> _journal(
    HttpRequest request,
    Map<String, Object?> body,
  ) {
    _expectRequest(
      request,
      body: body,
      expectedQuery: const <String, String>{'page': '1', 'limit': '20'},
    );
    return <String, Object?>{
      'page': 1,
      'limit': 20,
      'items': <Map<String, Object?>>[
        if (_mood != null || _symptoms.isNotEmpty || _note != null)
          <String, Object?>{
            'date': _date,
            'mood': _mood,
            'symptoms': _symptoms,
            'discomfortLevel': _discomfortLevel,
            'note': _note,
          },
      ],
    };
  }

  Map<String, Object?> _moodForDate(
    HttpRequest request,
    Map<String, Object?> body,
  ) {
    _expectRequest(request, body: body);
    return <String, Object?>{'date': _date, 'mood': _mood};
  }

  Map<String, Object?> _symptomsForDate(
    HttpRequest request,
    Map<String, Object?> body,
  ) {
    _expectRequest(request, body: body);
    return <String, Object?>{
      'date': _date,
      'symptoms': _symptoms,
      'discomfortLevel': _discomfortLevel,
    };
  }

  Map<String, Object?> _noteForDate(
    HttpRequest request,
    Map<String, Object?> body,
  ) {
    _expectRequest(request, body: body);
    return <String, Object?>{'date': _date, 'note': _note};
  }

  Map<String, Object?> _saveMood(
    HttpRequest request,
    Map<String, Object?> body,
  ) {
    _expectRequest(
      request,
      body: body,
      expectedBody: const <String, Object?>{'mood': 'happy'},
    );
    _mood = 'happy';
    return <String, Object?>{'date': _date, 'mood': _mood};
  }

  Map<String, Object?> _saveSymptoms(
    HttpRequest request,
    Map<String, Object?> body,
  ) {
    _expectRequest(
      request,
      body: body,
      expectedBody: const <String, Object?>{
        'symptoms': <String>['cramps'],
        'discomfortLevel': 0,
      },
    );
    _symptoms = <String>['cramps'];
    _discomfortLevel = 0;
    return <String, Object?>{
      'date': _date,
      'symptoms': _symptoms,
      'discomfortLevel': _discomfortLevel,
    };
  }

  Map<String, Object?> _saveNote(
    HttpRequest request,
    Map<String, Object?> body,
  ) {
    _expectRequest(
      request,
      body: body,
      expectedBody: const <String, Object?>{'note': 'Đã lưu qua fake server.'},
    );
    _note = 'Đã lưu qua fake server.';
    return <String, Object?>{'date': _date, 'note': _note};
  }

  void _expectRequest(
    HttpRequest request, {
    required Map<String, Object?> body,
    Map<String, Object?>? expectedBody,
    Map<String, String> expectedQuery = const <String, String>{},
    bool authenticated = true,
  }) {
    final expectedAuthorization = authenticated ? 'Bearer $token' : null;
    if (request.headers.value(HttpHeaders.authorizationHeader) !=
        expectedAuthorization) {
      throw StateError('Unexpected Authorization header.');
    }
    if (request.headers.value(HttpHeaders.acceptHeader) != 'application/json') {
      throw StateError('Unexpected Accept header.');
    }
    if (request.headers.contentType?.mimeType != 'application/json') {
      throw StateError('Unexpected Content-Type header.');
    }
    if (!_sameJson(request.uri.queryParameters, expectedQuery)) {
      throw StateError('Unexpected query parameters: ${request.uri.query}.');
    }
    if (!_sameJson(body, expectedBody ?? const <String, Object?>{})) {
      throw StateError('Unexpected request body: $body.');
    }
  }

  Future<Map<String, Object?>> _body(HttpRequest request) async {
    final raw = await utf8.decoder.bind(request).join();
    if (raw.isEmpty) return <String, Object?>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<Object?, Object?>) {
      throw const FormatException('Request body must be a JSON object.');
    }
    return decoded.cast<String, Object?>();
  }

  Future<void> _respond(HttpRequest request, int status, Object? data) async {
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.write(
      jsonEncode(<String, Object?>{
        'data': data,
        'timestamp': '2025-02-14T00:00:00.000Z',
      }),
    );
    await request.response.close();
  }

  Map<String, Object?> _cycle({String? endDate}) => <String, Object?>{
    'startDate': _date,
    'endDate': endDate,
    'periodLength': endDate == null ? null : 1,
    'cycleLength': null,
    'source': 'manual',
  };
}

bool _sameJson(Object? actual, Object? expected) {
  if (actual is Map && expected is Map) {
    return actual.length == expected.length &&
        actual.entries.every(
          (entry) =>
              expected.containsKey(entry.key) &&
              _sameJson(expected[entry.key], entry.value),
        );
  }
  if (actual is List && expected is List) {
    return actual.length == expected.length &&
        actual.indexed.every(
          (entry) => _sameJson(entry.$2, expected[entry.$1]),
        );
  }
  return actual == expected;
}
