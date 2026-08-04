import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luna_fe/core/network/api_client.dart';
import 'package:luna_fe/core/time/business_date_clock.dart';
import 'package:luna_fe/features/health/presentation/health_providers.dart';
import 'package:luna_fe/features/health/presentation/local_day_controller.dart';

void main() {
  test('business day controller refreshes after Bangkok midnight', () {
    var now = DateTime.utc(2026, 8, 3, 16, 59, 59);
    void Function()? scheduled;
    Duration? delay;
    final businessDate = BangkokBusinessDateClock(instantClock: () => now);
    final controller = LocalDayController(
      businessDateClock: businessDate,
      schedule: (value, callback) {
        delay = value;
        scheduled = callback;
        return () {};
      },
    );
    addTearDown(controller.dispose);

    expect(controller.state, DateTime(2026, 8, 3));
    expect(delay, const Duration(seconds: 1));
    now = DateTime.utc(2026, 8, 3, 17);
    scheduled!();
    expect(controller.state, DateTime(2026, 8, 4));
  });

  test(
    'dashboard query refreshes with the new Bangkok date at midnight',
    () async {
      var now = DateTime.utc(2026, 8, 3, 16, 59, 59);
      void Function()? scheduled;
      final day = LocalDayController(
        businessDateClock: BangkokBusinessDateClock(instantClock: () => now),
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
      now = DateTime.utc(2026, 8, 3, 17);
      scheduled!();
      await container.read(dashboardProvider.future);

      expect(dates, ['2026-08-03', '2026-08-04']);
    },
  );

  test(
    'calendar provider refetches the observed active range after rollover',
    () async {
      var now = DateTime.utc(2026, 8, 3, 16, 59, 59);
      void Function()? scheduled;
      final day = LocalDayController(
        businessDateClock: BangkokBusinessDateClock(instantClock: () => now),
        schedule: (_, callback) {
          scheduled = callback;
          return () {};
        },
      );
      var requests = 0;
      final dio = Dio()
        ..httpClientAdapter = _DashboardAdapter((request) {
          requests += 1;
          return _calendarEnvelope(requests == 1 ? '2026-08-03' : '2026-08-04');
        });
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(dio)),
          localDayProvider.overrideWith((ref) => day),
        ],
      );
      addTearDown(container.dispose);
      final provider = calendarProvider('2026-08');
      final subscription = container.listen(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final before = await container.read(provider.future);
      now = DateTime.utc(2026, 8, 3, 17);
      scheduled!();
      final after = await container.read(provider.future);

      expect(requests, 2);
      expect(before.days.map((day) => day.date), [DateTime(2026, 8, 3)]);
      expect(after.days.map((day) => day.date), [DateTime(2026, 8, 4)]);
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

Map<String, Object?> _calendarEnvelope(String lastObservedDate) => {
  'data': {
    'month': '2026-08',
    'days': [
      {
        'date': lastObservedDate,
        'status': 'observed-period',
        'isObservedPeriod': true,
        'isPredictedPeriod': false,
        'isOvulation': false,
      },
    ],
  },
  'timestamp': '2026-08-03T00:00:00.000Z',
};
