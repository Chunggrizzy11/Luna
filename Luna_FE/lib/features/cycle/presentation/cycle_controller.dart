import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/presentation/health_providers.dart';

typedef CycleMutation = Future<void> Function(DateTime date);

class CycleController extends StateNotifier<AsyncValue<void>> {
  CycleController({
    required this.onStart,
    required this.onEnd,
    required this.onInvalidate,
  }) : super(const AsyncData(null));

  final CycleMutation onStart;
  final CycleMutation onEnd;
  final void Function() onInvalidate;

  Future<void> start(DateTime date) => _mutate(() => onStart(date));
  Future<void> end(DateTime date) => _mutate(() => onEnd(date));

  Future<void> _mutate(Future<Object?> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await action();
      onInvalidate();
    });
  }
}

final cycleControllerProvider =
    StateNotifierProvider.autoDispose<CycleController, AsyncValue<void>>((ref) {
      final repository = ref.watch(cycleRepositoryProvider);
      return CycleController(
        onStart: (date) async => repository.start(date),
        onEnd: (date) async => repository.end(date),
        onInvalidate: () => invalidateOwnerData(ref),
      );
    });
