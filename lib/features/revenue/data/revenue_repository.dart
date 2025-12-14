import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'pricing_config.dart';

final revenueRepositoryProvider = Provider<RevenueRepository>((ref) {
  return RevenueRepository(ref.read(apiClientProvider));
});

class RevenueRepository {
  final ApiClient _apiClient;

  RevenueRepository(this._apiClient);

  Future<List<PricingConfig>> getPricingConfigs() async {
    try {
      final response = await _apiClient.client.get('/revenue/pricing');
      final list = (response.data as List).map((e) => PricingConfig.fromJson(e)).toList();
      return list;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PricingConfig> updatePricingConfig(String serviceType, Map<String, dynamic> config) async {
    try {
      final response = await _apiClient.client.put(
        '/revenue/pricing/$serviceType',
        data: {'config': config},
      );
      return PricingConfig.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      return Exception(error.response?.data['message'] ?? 'Network error');
    }
    return Exception(error.toString());
  }
}
