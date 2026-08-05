import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/presentation/health_providers.dart';
import '../data/partner_repository.dart';
import '../domain/partner_models.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>(
  (ref) => PartnerRepository(ref.watch(apiClientProvider)),
);

final pairingStatusProvider = FutureProvider.autoDispose<PairingStatusResponse>((ref) {
  final repo = ref.watch(partnerRepositoryProvider);
  return repo.getStatus();
});
