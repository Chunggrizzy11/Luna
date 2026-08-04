import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/health_models.dart';

typedef LoadJournalPage = Future<JournalBatch> Function(int page, int limit);

@immutable
class JournalState {
  const JournalState({
    this.items = const [],
    this.isLoading = true,
    this.initialError,
    this.hasMore = false,
    this.nextPage = 1,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<JournalEntry> items;
  final bool isLoading;
  final Object? initialError;
  final bool hasMore;
  final int nextPage;
  final bool isLoadingMore;
  final Object? loadMoreError;
}

class JournalController extends StateNotifier<JournalState> {
  JournalController({required this.loadPage, bool loadImmediately = true})
    : super(const JournalState()) {
    if (loadImmediately) unawaited(Future<void>.microtask(refresh));
  }

  static const pageSize = 20;

  final LoadJournalPage loadPage;
  int _generation = 0;
  Future<void>? _loadMoreOperation;
  bool _disposed = false;

  Future<void> refresh() async {
    final generation = ++_generation;
    state = const JournalState();
    try {
      final batch = await loadPage(1, pageSize);
      if (_disposed || generation != _generation) return;
      state = JournalState(
        items: _merge(const [], batch.items),
        isLoading: false,
        hasMore: batch.hasMore,
        nextPage: batch.page + 1,
      );
    } catch (error) {
      if (_disposed || generation != _generation) return;
      state = JournalState(isLoading: false, initialError: error);
    }
  }

  Future<void> loadMore() {
    final inFlight = _loadMoreOperation;
    if (inFlight != null) return inFlight;
    if (state.isLoading || !state.hasMore) return Future<void>.value();

    late final Future<void> operation;
    operation = _loadMore().whenComplete(() {
      if (identical(_loadMoreOperation, operation)) {
        _loadMoreOperation = null;
      }
    });
    _loadMoreOperation = operation;
    return operation;
  }

  Future<void> _loadMore() async {
    final generation = _generation;
    final page = state.nextPage;
    state = JournalState(
      items: state.items,
      isLoading: false,
      hasMore: state.hasMore,
      nextPage: state.nextPage,
      isLoadingMore: true,
    );
    try {
      final batch = await loadPage(page, pageSize);
      if (_disposed || generation != _generation) return;
      state = JournalState(
        items: _merge(state.items, batch.items),
        isLoading: false,
        hasMore: batch.hasMore,
        nextPage: batch.page + 1,
      );
    } catch (error) {
      if (_disposed || generation != _generation) return;
      state = JournalState(
        items: state.items,
        isLoading: false,
        hasMore: state.hasMore,
        nextPage: state.nextPage,
        loadMoreError: error,
      );
    }
  }

  List<JournalEntry> _merge(
    List<JournalEntry> existing,
    List<JournalEntry> incoming,
  ) {
    final byDate = <String, JournalEntry>{};
    for (final entry in [...existing, ...incoming]) {
      byDate.putIfAbsent(_dateKey(entry.date), () => entry);
    }
    final merged = byDate.values.toList()
      ..sort((left, right) => right.date.compareTo(left.date));
    return List<JournalEntry>.unmodifiable(merged);
  }

  String _dateKey(DateTime value) =>
      '${value.year}-${value.month}-${value.day}';

  @override
  void dispose() {
    _disposed = true;
    _generation += 1;
    super.dispose();
  }
}
