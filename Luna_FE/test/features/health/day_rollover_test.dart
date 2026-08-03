import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/network/api_client.dart';
import 'package:luna_fe/features/health/presentation/health_providers.dart';
import 'package:luna_fe/features/health/presentation/local_day_controller.dart';

void main() {
  test(
    'local day controller refreshes after the scheduled midnight boundary',
    () {
      var now = DateTime(2026, 8, 3, 23, 59, 59);
      void Function()? scheduled;
      Duration? delay;
      final controller = LocalDayController(
        clock: () => now,
        schedule: (value, callback) {
          delay = value;
          scheduled = callback;
          return () {};
        },
      );
      addTearDown(controller.dispose);

      expect(controller.state, DateTime(2026, 8, 3));
      expect(delay, const Duration(seconds: 1));
      now = DateTime(2026, 8, 4);
      scheduled!();
      expect(controller.state, DateTime(2026, 8, 4));
    },
  );

  test(
    'dashboard query refreshes with the new local date at midnight',
    () async {
      var now = DateTime(2026, 8, 3, 23, 59, 59);
      void Function()? scheduled;
      final day = LocalDayController(
        clock: () => now,
        schedule: (_, callback) {
          scheduled = callback;
          return () {};
        },
      );
      final dates = <String>[];
      final dio = Dio()
        ..httpClientAdapter = _DashboardAdapter((request) {
          dates.add(request.queryParameters['date']! as String);
          return _dashboardEnvelope(dates.last);
        });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(dio)),
          localDayProvider.overrideWith((ref) => day),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        dashboardProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await container.read(dashboardProvider.future);
      now = DateTime(2026, 8, 4);
      scheduled!();
      await container.read(dashboardProvider.future);

      expect(dates, ['2026-08-03', '2026-08-04']);
    },
  );
}

class _DashboardAdapter implements HttpClientAdapter {
  _DashboardAdapter(this.handler);
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

Map<String, Object?> _dashboardEnvelope(String date) => {
  'data': {
    'date': date,
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
  },
  'timestamp': '2026-08-03T00:00:00.000Z',
};
