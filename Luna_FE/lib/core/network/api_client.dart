import 'package:dio/dio.dart';

import '../error/error_mapper.dart';
import 'api_response.dart';

class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, Object?>? queryParameters,
    required T Function(Object? value) decode,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return _decode(response.data, decode);
    } on DioException catch (error) {
      throw ErrorMapper.map(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    required T Function(Object? value) decode,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return _decode(response.data, decode);
    } on DioException catch (error) {
      throw ErrorMapper.map(error);
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  ApiResponse<T> _decode<T>(
    Map<String, dynamic>? body,
    T Function(Object? value) decode,
  ) {
    if (body == null) throw const FormatException('API response was empty');
    return ApiResponse<T>.fromJson(body, decode);
  }
}
