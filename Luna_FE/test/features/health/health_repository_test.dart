import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/error/failure.dart';
import 'package:luna_fe/core/network/api_client.dart';
import 'package:luna_fe/features/health/data/health_repository.dart';

void main() {
  test('repository maps an offline Dio failure to NetworkFailure', () async {
    final dio = Dio()..httpClientAdapter = _OfflineAdapter();
    final repository = HealthRepository(ApiClient(dio));

    await expectLater(
      repository.dashboard(DateTime(2026, 8, 3)),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('repository preserves unauthorized state', () async {
    final dio = Dio()..httpClientAdapter = _UnauthorizedAdapter();
    final repository = HealthRepository(ApiClient(dio));

    await expectLater(
      repository.journal(),
      throwsA(isA<UnauthorizedFailure>()),
    );
  });
}

class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) => throw DioException.connectionError(
    requestOptions: options,
    reason: 'offline',
  );

  @override
  void close({bool force = false}) {}
}

class _UnauthorizedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"code":"UNAUTHORIZED","message":"Phiên đã hết hạn"}',
    401,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
