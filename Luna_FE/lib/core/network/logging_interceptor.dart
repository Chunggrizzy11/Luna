import 'package:dio/dio.dart';

import '../utils/logger.dart';

class SafeLoggingInterceptor extends Interceptor {
  SafeLoggingInterceptor({required LogSink sink})
    : _logger = AppLogger(sink: sink);

  final AppLogger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.info('[HTTP] --> ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    _logger.info(
      '[HTTP] <-- ${response.statusCode ?? '-'} '
      '${response.requestOptions.method} ${response.requestOptions.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.warning(
      '[HTTP] xx ${err.response?.statusCode ?? '-'} '
      '${err.requestOptions.method} ${err.requestOptions.path} '
      'type=${err.type.name}',
    );
    handler.next(err);
  }
}
