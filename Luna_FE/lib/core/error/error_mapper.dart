import 'package:dio/dio.dart';

import '../network/api_exception.dart';
import 'failure.dart';

abstract final class ErrorMapper {
  static Failure map(Object error) {
    if (error is Failure) return error;
    if (error is DioException) return _fromDio(error);
    if (error is ApiException) {
      return _fromStatus(
        error.statusCode,
        message: error.message,
        code: error.code,
      );
    }
    return const UnknownFailure();
  }

  static Failure _fromDio(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      final message = data is Map<String, dynamic> && data['message'] is String
          ? data['message']! as String
          : 'Yêu cầu không thành công.';
      final code = data is Map<String, dynamic> && data['code'] is String
          ? data['code']! as String
          : null;
      return _fromStatus(
        error.response?.statusCode,
        message: message,
        code: code,
      );
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        return const ServerFailure('Yêu cầu không thành công.');
      case DioExceptionType.cancel:
        return const NetworkFailure('Yêu cầu đã bị hủy.');
      case DioExceptionType.badCertificate:
        return const NetworkFailure('Không thể xác minh kết nối an toàn.');
      case DioExceptionType.unknown:
        return const UnknownFailure();
    }
  }

  static Failure _fromStatus(
    int? status, {
    required String message,
    String? code,
  }) {
    if (status == 401) return UnauthorizedFailure(message);
    if (status == 403) return ForbiddenFailure(message);
    if (status != null && status >= 400 && status < 500) {
      return ValidationFailure(message, code: code);
    }
    return ServerFailure(message, code: code);
  }
}
