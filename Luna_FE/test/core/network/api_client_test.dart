import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/config/env.dart';
import 'package:luna_fe/core/error/failure.dart';
import 'package:luna_fe/core/network/api_client.dart';
import 'package:luna_fe/core/network/dio_client.dart';
import 'package:luna_fe/features/onboarding/data/device_repository.dart';
import 'package:luna_fe/shared/enums/device_role.dart';

void main() {
  test('uses the Android-emulator API URL when no dart-define is supplied', () {
    expect(Env.apiBaseUrl, 'http://10.0.2.2:3000/api/v1');
  });

  test('configures JSON and fifteen-second network timeouts', () {
    final client = DioClient(tokenProvider: () async => null);

    expect(client.dio.options.connectTimeout, const Duration(seconds: 15));
    expect(client.dio.options.receiveTimeout, const Duration(seconds: 15));
    expect(client.dio.options.sendTimeout, const Duration(seconds: 15));
    expect(
      client.dio.options.headers[Headers.acceptHeader],
      'application/json',
    );
    expect(
      client.dio.options.headers[Headers.contentTypeHeader],
      'application/json',
    );
  });

  test('puts a stored token only in the Authorization header', () async {
    late RequestOptions recorded;
    final client = DioClient(
      tokenProvider: () async => 'top-secret-token',
      enableLogging: false,
    );
    client.dio.httpClientAdapter = _StubAdapter((options) {
      recorded = options;
      return _jsonResponse({
        'data': {'ok': true},
      });
    });

    await client.dio.get<Map<String, dynamic>>('/devices/me');

    expect(recorded.headers['Authorization'], 'Bearer top-secret-token');
    expect(recorded.data, isNull);
    expect(recorded.uri.toString(), isNot(contains('top-secret-token')));
    expect(
      recorded.queryParameters.values,
      isNot(contains('top-secret-token')),
    );
  });

  test(
    'sanitized HTTP logs exclude authorization and request bodies',
    () async {
      final logs = <String>[];
      final client = DioClient(
        tokenProvider: () async => 'top-secret-token',
        logSink: logs.add,
      );
      client.dio.httpClientAdapter = _StubAdapter(
        (_) => _jsonResponse({
          'data': {'token': 'response-secret'},
        }),
      );

      await client.dio.post<Map<String, dynamic>>(
        '/devices/register',
        data: {'token': 'request-secret', 'password': 'private'},
      );

      expect(logs.join('\n'), contains('POST /devices/register'));
      expect(logs.join('\n'), isNot(contains('top-secret-token')));
      expect(logs.join('\n'), isNot(contains('request-secret')));
      expect(logs.join('\n'), isNot(contains('response-secret')));
      expect(logs.join('\n'), isNot(contains('private')));
    },
  );

  test(
    'register sends role and platform and decodes the global envelope',
    () async {
      late RequestOptions recorded;
      final dioClient = DioClient(
        tokenProvider: () async => 'stored-private-token',
        enableLogging: false,
      );
      dioClient.dio.httpClientAdapter = _StubAdapter((options) {
        recorded = options;
        return _jsonResponse({
          'data': {'deviceId': 'device-1', 'token': 'issued-token'},
          'timestamp': '2026-07-31T00:00:00.000Z',
        });
      });
      final repository = DeviceRepository(
        apiClient: ApiClient(dioClient.dio),
        platform: 'android',
      );

      final identity = await repository.register(DeviceRole.owner);

      expect(recorded.path, '/devices/register');
      expect(recorded.headers, isNot(contains('Authorization')));
      expect(recorded.data, {'role': 'owner', 'platform': 'android'});
      expect(identity.deviceId, 'device-1');
      expect(identity.token, 'issued-token');
      expect(identity.role, DeviceRole.owner);
    },
  );

  test('malformed API envelopes surface as typed failures', () async {
    final dioClient = DioClient(
      tokenProvider: () async => null,
      enableLogging: false,
    );
    dioClient.dio.httpClientAdapter = _StubAdapter(
      (_) => _jsonResponse({'timestamp': '2026-07-31T00:00:00.000Z'}),
    );

    await expectLater(
      ApiClient(
        dioClient.dio,
      ).get<String>('/malformed', decode: (value) => value! as String),
      throwsA(isA<UnknownFailure>()),
    );
  });

  test(
    'put and delete decode global envelopes with the intended verbs',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio()
        ..httpClientAdapter = _StubAdapter((options) {
          requests.add(options);
          return _jsonResponse({
            'data': {
              'date': '2026-08-03',
              'note': options.method == 'DELETE' ? null : 'Đã sửa',
            },
          });
        });
      final api = ApiClient(dio);

      await api.put<Map<String, dynamic>>(
        '/notes/2026-08-03',
        data: {'note': 'Đã sửa'},
        decode: (value) => value! as Map<String, dynamic>,
      );
      await api.delete<Map<String, dynamic>>(
        '/notes/2026-08-03',
        decode: (value) => value! as Map<String, dynamic>,
      );

      expect(requests.map((request) => request.method), ['PUT', 'DELETE']);
    },
  );

  test(
    'real 401 revokes identity while 403 remains a forbidden failure',
    () async {
      var revocations = 0;
      final unauthorizedClient = DioClient(
        tokenProvider: () async => 'revoked-token',
        onUnauthorized: () async => revocations += 1,
        enableLogging: false,
      );
      unauthorizedClient.dio.httpClientAdapter = _StubAdapter(
        (_) => _errorResponse(401, 'Token revoked'),
      );

      await expectLater(
        ApiClient(
          unauthorizedClient.dio,
        ).get<Object?>('/health/dashboard', decode: (value) => value),
        throwsA(isA<UnauthorizedFailure>()),
      );
      expect(revocations, 1);

      final forbiddenClient = DioClient(
        tokenProvider: () async => 'valid-token',
        onUnauthorized: () async => revocations += 1,
        enableLogging: false,
      );
      forbiddenClient.dio.httpClientAdapter = _StubAdapter(
        (_) => _errorResponse(403, 'Owner only'),
      );
      await expectLater(
        ApiClient(
          forbiddenClient.dio,
        ).get<Object?>('/cycles', decode: (value) => value),
        throwsA(isA<ForbiddenFailure>()),
      );
      expect(revocations, 1);
    },
  );

  test(
    'malformed registration credentials surface as typed failures',
    () async {
      final dioClient = DioClient(
        tokenProvider: () async => null,
        enableLogging: false,
      );
      dioClient.dio.httpClientAdapter = _StubAdapter(
        (_) => _jsonResponse({
          'data': {'deviceId': 'device-1'},
        }),
      );
      final repository = DeviceRepository(
        apiClient: ApiClient(dioClient.dio),
        platform: 'android',
      );

      await expectLater(
        repository.register(DeviceRole.owner),
        throwsA(isA<UnknownFailure>()),
      );
    },
  );
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, Object?> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ResponseBody _errorResponse(int status, String message) =>
    ResponseBody.fromString(
      jsonEncode({
        'code': status == 401 ? 'UNAUTHORIZED' : 'FORBIDDEN',
        'message': message,
      }),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
