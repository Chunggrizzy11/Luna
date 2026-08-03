import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:luna_fe/core/network/api_client.dart';
import 'package:luna_fe/features/health/presentation/health_providers.dart';
import 'package:luna_fe/features/home/presentation/owner_shell.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('owner cycle and journal flow refreshes each persisted view', (
    tester,
  ) async {
    final server = await _CycleJournalFakeServer.start();
    addTearDown(server.close);
    final api = ApiClient(Dio(BaseOptions(baseUrl: server.baseUrl)));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          clockProvider.overrideWithValue(() => DateTime(2026, 8, 3)),
        ],
        child: const MaterialApp(home: OwnerShell()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chu kỳ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bắt đầu kỳ kinh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(server.requests, contains('POST /cycles/start'));
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
    expect(
      server.requests,
      containsAll(<String>[
        'PUT /moods/2026-08-03',
        'PUT /symptoms/2026-08-03',
        'PUT /notes/2026-08-03',
      ]),
    );
    expect(find.textContaining('Vui vẻ'), findsWidgets);

    await tester.tap(find.text('Lịch'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Ngày 3, kỳ kinh thực tế'), findsOneWidget);

    await tester.tap(find.text('Chu kỳ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kết thúc kỳ kinh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(server.requests, contains('POST /cycles/end'));

    await tester.tap(find.text('Nhật ký'));
    await tester.pumpAndSettle();
    expect(find.text('Đã lưu qua fake server.'), findsOneWidget);
    expect(server.count('GET /health/dashboard'), greaterThanOrEqualTo(2));
    expect(server.count('GET /calendar'), greaterThanOrEqualTo(2));
    expect(server.count('GET /health/journal'), greaterThanOrEqualTo(2));
  });
}

class _CycleJournalFakeServer {
  _CycleJournalFakeServer._(this._server);

  final HttpServer _server;
  final List<String> requests = <String>[];
  final String _date = '2026-08-03';
  bool _started = false;
  bool _active = false;
  String? _mood;
  List<String> _symptoms = <String>[];
  int? _discomfortLevel;
  String? _note;

  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  static Future<_CycleJournalFakeServer> start() async {
    final server = _CycleJournalFakeServer._(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
    );
    unawaited(server._serve());
    return server;
  }

  Future<void> close() => _server.close(force: true);

  int count(String request) => requests.where((item) => item == request).length;

  Future<void> _serve() async {
    await for (final request in _server) {
      final path = request.uri.path;
      requests.add('${request.method} $path');
      final payload = await _body(request);
      final data = switch ((request.method, path)) {
        ('GET', '/cycles/current') => _active ? _cycle() : null,
        ('POST', '/cycles/start') => _start(payload),
        ('POST', '/cycles/end') => _end(payload),
        ('GET', '/health/dashboard') => _dashboard(),
        ('GET', '/health/care/today') => <String, Object?>{'suggestion': null},
        ('GET', '/calendar') => _calendar(request.uri.queryParameters['month']),
        ('GET', '/health/journal') => _journal(),
        ('GET', '/moods/2026-08-03') => <String, Object?>{
          'date': _date,
          'mood': _mood,
        },
        ('GET', '/symptoms/2026-08-03') => <String, Object?>{
          'date': _date,
          'symptoms': _symptoms,
          'discomfortLevel': _discomfortLevel,
        },
        ('GET', '/notes/2026-08-03') => <String, Object?>{
          'date': _date,
          'note': _note,
        },
        ('PUT', '/moods/2026-08-03') => _saveMood(payload),
        ('PUT', '/symptoms/2026-08-03') => _saveSymptoms(payload),
        ('PUT', '/notes/2026-08-03') => _saveNote(payload),
        _ => <String, Object?>{},
      };
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, Object?>{
          'data': data,
          'timestamp': '2026-08-03T00:00:00.000Z',
        }),
      );
      await request.response.close();
    }
  }

  Future<Map<String, Object?>> _body(HttpRequest request) async {
    final raw = await utf8.decoder.bind(request).join();
    if (raw.isEmpty) return <String, Object?>{};
    return (jsonDecode(raw) as Map<Object?, Object?>).cast<String, Object?>();
  }

  Map<String, Object?> _start(Map<String, Object?> payload) {
    _started = true;
    _active = true;
    return _cycle(startDate: payload['date'] as String);
  }

  Map<String, Object?> _end(Map<String, Object?> payload) {
    _active = false;
    return _cycle(endDate: payload['date'] as String);
  }

  Map<String, Object?> _cycle({String? startDate, String? endDate}) =>
      <String, Object?>{
        'startDate': startDate ?? _date,
        'endDate': endDate,
        'periodLength': endDate == null ? null : 1,
        'cycleLength': null,
        'source': 'manual',
      };

  Map<String, Object?> _dashboard() => <String, Object?>{
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

  Map<String, Object?> _calendar(String? month) => <String, Object?>{
    'month': month ?? '2026-08',
    'days': <Map<String, Object?>>[
      if (_started)
        <String, Object?>{'date': _date, 'status': 'observed-period'},
    ],
  };

  Map<String, Object?> _journal() => <String, Object?>{
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

  Map<String, Object?> _saveMood(Map<String, Object?> payload) {
    _mood = payload['mood'] as String;
    return <String, Object?>{'date': _date, 'mood': _mood};
  }

  Map<String, Object?> _saveSymptoms(Map<String, Object?> payload) {
    _symptoms = (payload['symptoms']! as List<Object?>).cast<String>();
    _discomfortLevel = payload['discomfortLevel'] as int;
    return <String, Object?>{
      'date': _date,
      'symptoms': _symptoms,
      'discomfortLevel': _discomfortLevel,
    };
  }

  Map<String, Object?> _saveNote(Map<String, Object?> payload) {
    _note = payload['note'] as String;
    return <String, Object?>{'date': _date, 'note': _note};
  }
}
