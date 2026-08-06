import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/health/presentation/health_providers.dart';
import 'sos_repository.dart';

final sosRepositoryProvider = Provider<SosRepository>((ref) {
  return SosRepository(ref.watch(apiClientProvider));
});

class SosState {
  const SosState({this.isSending = false, this.cooldownSeconds = 0});
  final bool isSending;
  final int cooldownSeconds;

  bool get canTrigger => !isSending && cooldownSeconds == 0;

  SosState copyWith({bool? isSending, int? cooldownSeconds}) {
    return SosState(
      isSending: isSending ?? this.isSending,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
    );
  }
}

class SosNotifier extends StateNotifier<SosState> {
  SosNotifier(this._repository) : super(const SosState());
  
  final SosRepository _repository;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<bool> trigger() async {
    if (!state.canTrigger) return false;

    state = state.copyWith(isSending: true);
    try {
      await _repository.trigger();
      
      // Start cooldown
      state = state.copyWith(isSending: false, cooldownSeconds: 60);
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.cooldownSeconds > 0) {
          state = state.copyWith(cooldownSeconds: state.cooldownSeconds - 1);
        } else {
          timer.cancel();
        }
      });
      return true;
    } catch (e) {
      state = state.copyWith(isSending: false);
      return false;
    }
  }

  Future<void> acknowledge() async {
    try {
      await _repository.acknowledge();
    } catch (e) {
      // Ignore
    }
  }
}

final sosProvider = StateNotifierProvider<SosNotifier, SosState>((ref) {
  return SosNotifier(ref.watch(sosRepositoryProvider));
});
