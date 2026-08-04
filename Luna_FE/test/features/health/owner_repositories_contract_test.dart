import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/network/api_client.dart';
import 'package:luna_fe/features/calendar/data/calendar_repository.dart';
import 'package:luna_fe/features/calendar/domain/cycle_calendar.dart';
import 'package:luna_fe/features/cycle/data/cycle_repository.dart';
import 'package:luna_fe/features/health/data/health_repository.dart';
import 'package:luna_fe/features/mood/data/mood_repository.dart';
import 'package:luna_fe/features/mood/domain/mood.dart';
import 'package:luna_fe/features/note/data/note_repository.dart';
import 'package:luna_fe/features/symptom/data/symptom_repository.dart';
import 'package:luna_fe/features/symptom/domain/symptom.dart';

void main() {
  test(
    'cycle repository sends exact endpoints and decodes nullable envelopes',
    () async {
      final harness = _Harness(
        (request) => switch ((request.method, request.path)) {
          ('GET', '/cycles/current') => _envelope(null),
          ('POST', '/cycles/start') => _envelope({
            'startDate': '2026-08-03',
            'endDate': null,
            'source': 'manual',
          }),
          ('POST', '/cycles/end') => _envelope({
            'startDate': '2026-08-03',
            'endDate': '2026-11-05',
            'periodLength': null,
            'source': 'manual',
          }),
          _ => throw StateError('${request.method} ${request.path}'),
        },
      );
      final repository = CycleRepository(harness.api);

      expect(await repository.current(), isNull);
      final started = await repository.start(DateTime(2026, 8, 3));
      final ended = await repository.end(DateTime(2026, 8, 5));

      expect(started.startDate, DateTime(2026, 8, 3));
      expect(ended.endDate, DateTime(2026, 11, 5));
      expect(ended.periodLength, isNull);
      expect(harness.requests.map((value) => value.path), [
        '/cycles/current',
        '/cycles/start',
        '/cycles/end',
      ]);
      expect(harness.requests.map((value) => value.method), [
        'GET',
        'POST',
        'POST',
      ]);
      expect(harness.requests[1].data, {'date': '2026-08-03'});
      expect(harness.requests[2].data, {'date': '2026-08-05'});
    },
  );

  test(
    'calendar repository sends yyyy-MM and decodes all day states',
    () async {
      final harness = _Harness(
        (request) => switch ((request.method, request.path)) {
          ('GET', '/calendar') => _envelope({
            'month': '2026-08',
            'days': [
              {
                'date': '2026-08-03',
                'status': 'observed-period',
                'isObservedPeriod': true,
                'isPredictedPeriod': false,
                'isOvulation': false,
              },
            ],
          }),
          _ => throw StateError('${request.method} ${request.path}'),
        },
      );

      final result = await CalendarRepository(
        harness.api,
      ).month(DateTime(2026, 8));

      expect(harness.requests.single.path, '/calendar');
      expect(harness.requests.single.method, 'GET');
      expect(harness.requests.single.queryParameters, {'month': '2026-08'});
      expect(result.days.single.status, CalendarDayStatus.observedPeriod);
    },
  );

  test(
    'mood symptom and note repositories preserve exact payload contracts',
    () async {
      final harness = _Harness((request) {
        final date = request.path.split('/').last;
        if (request.path.startsWith('/moods/')) {
          if (request.method != 'GET' && request.method != 'PUT') {
            throw StateError('${request.method} ${request.path}');
          }
          return _envelope({
            'date': date,
            'mood': request.method == 'GET' ? null : 'happy',
          });
        }
        if (request.path.startsWith('/symptoms/')) {
          if (request.method != 'GET' && request.method != 'PUT') {
            throw StateError('${request.method} ${request.path}');
          }
          return _envelope({
            'date': date,
            'symptoms': request.method == 'GET' ? [] : ['cramps', 'headache'],
            'discomfortLevel': request.method == 'GET' ? null : 4,
          });
        }
        if (request.path.startsWith('/notes/')) {
          if (!const {'GET', 'PUT', 'DELETE'}.contains(request.method)) {
            throw StateError('${request.method} ${request.path}');
          }
          return _envelope({
            'date': date,
            'note': request.method == 'DELETE'
                ? null
                : request.method == 'GET'
                ? 'Cũ'
                : 'Đã sửa',
          });
        }
        throw StateError(request.path);
      });
      final date = DateTime(2026, 8, 3);
      final moods = MoodRepository(harness.api);
      final symptoms = SymptomRepository(harness.api);
      final notes = NoteRepository(harness.api);

      expect(await moods.get(date), isNull);
      expect(await moods.update(date, Mood.happy), Mood.happy);
      expect((await symptoms.get(date)).symptoms, isEmpty);
      final symptomLog = await symptoms.update(date, {
        Symptom.cramps,
        Symptom.headache,
      }, 4);
      expect(symptomLog.discomfortLevel, 4);
      expect((await notes.get(date)).note, 'Cũ');
      expect((await notes.update(date, 'Đã sửa')).note, 'Đã sửa');
      expect((await notes.delete(date)).note, isNull);

      expect(harness.requests[1].data, {'mood': 'happy'});
      expect(harness.requests[3].data, {
        'symptoms': ['cramps', 'headache'],
        'discomfortLevel': 4,
      });
      expect(harness.requests[5].data, {'note': 'Đã sửa'});
      expect(harness.requests[6].method, 'DELETE');
      expect(harness.requests.map((value) => value.method), [
        'GET',
        'PUT',
        'GET',
        'PUT',
        'GET',
        'PUT',
        'DELETE',
      ]);
      expect(harness.requests.map((value) => value.path).toSet(), {
        '/moods/2026-08-03',
        '/symptoms/2026-08-03',
        '/notes/2026-08-03',
      });
    },
  );

  test(
    'health repository decodes dashboard care and paginated journal envelopes',
    () async {
      final harness = _Harness(
        (request) => switch ((request.method, request.path)) {
          ('GET', '/health/dashboard') => _envelope({
            'date': '2026-08-03',
            'relationship': 'owner',
            'cycle': {
              'currentCycleDay': null,
              'isPeriodActive': false,
              'daysUntilNextPeriod': null,
              'averageCycleLength': 28,
              'averagePeriodLength': 5,
              'predictedPeriodStart': null,
              'predictedPeriodEnd': null,
              'ovulationDate': null,
              'observedPeriods': [],
            },
            'dailyLog': {
              'mood': null,
              'symptoms': [],
              'discomfortLevel': null,
              'note': null,
            },
          }),
          ('GET', '/health/care/today') => _envelope({
            'date': '2026-08-03',
            'relationship': 'owner',
            'suggestion': {
              'id': 'owner-drink',
              'title': 'Uống đủ nước',
              'description': 'Nhấp từng ngụm nhỏ.',
            },
          }),
          ('GET', '/health/journal') => _envelope({
            'items': [
              {'date': '2026-08-03', 'mood': 'happy'},
            ],
            'page': 1,
            'limit': 20,
            'hasMore': false,
          }),
          _ => throw StateError('${request.method} ${request.path}'),
        },
      );
      final repository = HealthRepository(harness.api);

      final dashboard = await repository.dashboard(DateTime(2026, 8, 3));
      final care = await repository.careToday();
      final journal = await repository.journal();

      expect(dashboard.date, DateTime(2026, 8, 3));
      expect(care?.id, 'owner-drink');
      expect(journal.items.single.mood, Mood.happy);
      expect(journal.hasMore, isFalse);
      expect(harness.requests.first.queryParameters, {'date': '2026-08-03'});
      expect(harness.requests.last.queryParameters, {'page': 1, 'limit': 20});
      expect(harness.requests.map((value) => value.method), [
        'GET',
        'GET',
        'GET',
      ]);
    },
  );
}

class _Harness {
  _Harness(this.handler) {
    final dio = Dio();
    dio.httpClientAdapter = _Adapter((request) {
      requests.add(request);
      return handler(request);
    });
    api = ApiClient(dio);
  }

  final Map<String, Object?> Function(RequestOptions request) handler;
  final requests = <RequestOptions>[];
  late final ApiClient api;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final Map<String, Object?> Function(RequestOptions request) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(handler(options)),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _envelope(Object? data) => {
  'data': data,
  'timestamp': '2026-08-03T00:00:00.000Z',
};
