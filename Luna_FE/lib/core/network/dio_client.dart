import 'package:dio/dio.dart';

import '../config/app_constant.dart';
import '../config/env.dart';
import '../utils/logger.dart';
import 'api_endpoint.dart';
import 'logging_interceptor.dart';

typedef TokenProvider = Future<String?> Function();
typedef UnauthorizedHandler = Future<void> Function();

class DioClient {
  DioClient({
    required TokenProvider tokenProvider,
    UnauthorizedHandler? onUnauthorized,
    String baseUrl = Env.apiBaseUrl,
    LogSink? logSink,
    bool enableLogging = true,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: AppConstant.networkTimeout,
           receiveTimeout: AppConstant.networkTimeout,
           sendTimeout: AppConstant.networkTimeout,
           responseType: ResponseType.json,
           headers: const {
             Headers.acceptHeader: Headers.jsonContentType,
             Headers.contentTypeHeader: Headers.jsonContentType,
           },
         ),
       ) {
    dio.interceptors.add(
      _AuthInterceptor(tokenProvider, onUnauthorized: onUnauthorized),
    );
    if (enableLogging) {
      dio.interceptors.add(
        SafeLoggingInterceptor(sink: logSink ?? AppLogger().info),
      );
    }
  }

  final Dio dio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokenProvider, {this.onUnauthorized});

  final TokenProvider _tokenProvider;
  final UnauthorizedHandler? onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!ApiEndpoint.publicPaths.contains(options.path)) {
      final token = await _tokenProvider();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401 && onUnauthorized != null) {
      try {
        await onUnauthorized!();
      } catch (_) {
        // Preserve the original typed HTTP failure if local cleanup fails.
      }
    }
    handler.next(error);
  }
}
