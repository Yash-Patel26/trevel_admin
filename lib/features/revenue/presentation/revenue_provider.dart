import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/revenue_repository.dart';
import '../data/pricing_config.dart';

final pricingConfigsProvider = FutureProvider<List<PricingConfig>>((ref) async {
  final repo = ref.read(revenueRepositoryProvider);
  return repo.getPricingConfigs();
});

final revenueControllerProvider = StateNotifierProvider<RevenueController, AsyncValue<void>>((ref) {
  return RevenueController(ref.read(revenueRepositoryProvider), ref);
});

class RevenueController extends StateNotifier<AsyncValue<void>> {
  final RevenueRepository _repo;
  final Ref _ref;

  RevenueController(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> updateConfig(String serviceType, Map<String, dynamic> newConfig) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updatePricingConfig(serviceType, newConfig);
      // Invalidate fetching provider to refresh data
      _ref.invalidate(pricingConfigsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
