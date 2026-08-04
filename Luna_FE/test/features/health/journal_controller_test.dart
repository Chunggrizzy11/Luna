import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luna_fe/core/error/failure.dart';
import 'package:luna_fe/features/health/domain/health_models.dart';
import 'package:luna_fe/features/health/presentation/journal_controller.dart';
import 'package:luna_fe/features/health/presentation/health_providers.dart';

void main() {
  test(
    'load more is single-flight and merges newest-first without duplicates',
    () async {
      final pendingSecondPage = Completer<JournalBatch>();
      final requestedPages = <int>[];
      final controller = JournalController(
        loadPage: (page, limit) {
          requestedPages.add(page);
          if (page == 1) {
            return Future.value(
              JournalBatch(
                items: List.generate(20, (index) => _entry(25 - index)),
                page: 1,
                limit: limit,
                hasMore: true,
              ),
            );
          }
          return pendingSecondPage.future;
        },
        loadImmediately: false,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      final first = controller.loadMore();
      final duplicate = controller.loadMore();
      expect(requestedPages, [1, 2]);
      pendingSecondPage.complete(
        JournalBatch(
          items: [
            _entry(3),
            _entry(5),
            _entry(6),
            _entry(4),
            _entry(2),
            _entry(1),
          ],
          page: 2,
          limit: 20,
          hasMore: false,
        ),
      );
      await Future.wait([first, duplicate]);

      expect(controller.state.items, hasLength(25));
      expect(
        controller.state.items.map((entry) => entry.date.day),
        List.generate(25, (index) => 25 - index),
      );
      expect(controller.state.hasMore, isFalse);
    },
  );

  test(
    'load-more failure is retryable without losing loaded entries',
    () async {
      var pageTwoAttempts = 0;
      final controller = JournalController(
        loadPage: (page, limit) async {
          if (page == 1) {
            return JournalBatch(
              items: List.generate(20, (index) => _entry(25 - index)),
              page: 1,
              limit: limit,
              hasMore: true,
            );
          }
          pageTwoAttempts += 1;
          if (pageTwoAttempts == 1) throw const NetworkFailure('offline');
          return JournalBatch(
            items: List.generate(5, (index) => _entry(5 - index)),
            page: 2,
            limit: limit,
            hasMore: false,
          );
        },
        loadImmediately: false,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.loadMore();
      expect(controller.state.items, hasLength(20));
      expect(controller.state.loadMoreError, isA<NetworkFailure>());

      await controller.loadMore();
      expect(pageTwoAttempts, 2);
      expect(controller.state.items, hasLength(25));
      expect(controller.state.loadMoreError, isNull);
    },
  );

  test('refresh wins over an older in-flight load-more response', () async {
    final stalePage = Completer<JournalBatch>();
    var firstPageRequests = 0;
    final controller = JournalController(
      loadPage: (page, limit) {
        if (page == 2) return stalePage.future;
        firstPageRequests += 1;
        return Future.value(
          JournalBatch(
            items: [firstPageRequests == 1 ? _entry(25) : _entry(26)],
            page: 1,
            limit: limit,
            hasMore: firstPageRequests == 1,
          ),
        );
      },
      loadImmediately: false,
    );
    addTearDown(controller.dispose);

    await controller.refresh();
    final loadMore = controller.loadMore();
    await controller.refresh();
    stalePage.complete(
      JournalBatch(items: [_entry(5)], page: 2, limit: 20, hasMore: false),
    );
    await loadMore;

    expect(controller.state.items.map((entry) => entry.date.day), [26]);
  });

  test(
    'provider invalidation creates a fresh paginated journal controller',
    () async {
      var controllersCreated = 0;
      var firstPageRequests = 0;
      final container = ProviderContainer(
        overrides: [
          journalProvider.overrideWith((ref) {
            controllersCreated += 1;
            return JournalController(
              loadPage: (page, limit) async {
                firstPageRequests += 1;
                return JournalBatch(
                  items: [_entry(controllersCreated)],
                  page: page,
                  limit: limit,
                  hasMore: false,
                );
              },
              loadImmediately: false,
            );
          }),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(journalProvider, (_, _) {});
      addTearDown(subscription.close);

      final first = container.read(journalProvider.notifier);
      await first.refresh();
      container.invalidate(journalProvider);
      await Future<void>.delayed(Duration.zero);
      final second = container.read(journalProvider.notifier);
      await second.refresh();

      expect(identical(first, second), isFalse);
      expect(controllersCreated, 2);
      expect(firstPageRequests, 2);
    },
  );
}

JournalEntry _entry(int day) => JournalEntry(date: DateTime(2026, 8, day));
