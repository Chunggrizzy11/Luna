import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/error/error_mapper.dart';
import 'package:luna_fe/core/error/failure.dart';
import 'package:luna_fe/core/network/api_response.dart';
import 'package:luna_fe/core/storage/cache_manager.dart';
import 'package:luna_fe/core/storage/local_database.dart';
import 'package:luna_fe/core/storage/shared_preference_service.dart';
import 'package:luna_fe/core/theme/app_color.dart';
import 'package:luna_fe/core/theme/dark_theme.dart';
import 'package:luna_fe/core/theme/light_theme.dart';
import 'package:luna_fe/core/utils/date_util.dart';
import 'package:luna_fe/core/utils/extension.dart';
import 'package:luna_fe/core/utils/helper.dart';
import 'package:luna_fe/core/utils/validator.dart';

void main() {
  test('API response decodes data but rejects a missing data field', () {
    final response = ApiResponse<String>.fromJson({
      'data': 'value',
      'timestamp': '2026-07-31T00:00:00.000Z',
    }, (value) => value! as String);

    expect(response.data, 'value');
    expect(
      () => ApiResponse<String>.fromJson({}, (value) => value! as String),
      throwsFormatException,
    );
  });

  test('error mapper distinguishes unauthorized and timeout failures', () {
    final unauthorized = DioException(
      requestOptions: RequestOptions(path: '/devices/me'),
      response: Response<void>(
        requestOptions: RequestOptions(path: '/devices/me'),
        statusCode: 401,
      ),
    );
    final timeout = DioException.connectionTimeout(
      timeout: const Duration(seconds: 15),
      requestOptions: RequestOptions(path: '/devices/me'),
    );

    expect(ErrorMapper.map(unauthorized), isA<UnauthorizedFailure>());
    expect(ErrorMapper.map(timeout), isA<NetworkFailure>());
  });

  test('cache expires values using its injected clock', () async {
    var now = DateTime(2026, 7, 31, 10);
    final cache = CacheManager(database: LocalDatabase(), now: () => now);
    await cache.put('forecast', 'fresh', ttl: const Duration(minutes: 5));

    expect(await cache.get<String>('forecast'), 'fresh');
    now = now.add(const Duration(minutes: 6));
    expect(await cache.get<String>('forecast'), isNull);
  });

  test('preferences reject secret-bearing keys before persistence', () {
    final preferences = SharedPreferenceService();

    expect(
      () => preferences.setString('deviceToken', 'secret'),
      throwsArgumentError,
    );
    expect(
      () => preferences.setString('deviceId', 'secret'),
      throwsArgumentError,
    );
  });

  test('date and validation helpers handle user-input boundaries', () {
    expect(
      DateUtil.startOfDay(DateTime(2026, 7, 31, 12, 30)),
      DateTime(2026, 7, 31),
    );
    expect(DateUtil.cycleDay(DateTime(2026, 7, 30), DateTime(2026, 7, 31)), 2);
    expect(Validator.required('   '), isNotNull);
    expect(Validator.email('invalid'), isNotNull);
    expect(Validator.email('luna@example.com'), isNull);
    expect(' luna '.trimmedOrNull, 'luna');
    expect(''.trimmedOrNull, isNull);
    expect(Helper.clampInt(11, min: 1, max: 10), 10);
  });

  test('light and dark themes retain Luna semantic colors', () {
    expect(LightTheme.data.brightness, Brightness.light);
    expect(DarkTheme.data.brightness, Brightness.dark);
    expect(AppColor.menstrual, const Color(0xFFC62848));
    expect(AppColor.prediction, const Color(0xFFF59E0B));
    expect(AppColor.ovulation, const Color(0xFF2E7D5B));
  });
}
