import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final dashboardsRepositoryProvider = Provider<DashboardsRepository>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  return DashboardsRepository(dio);
});

class DashboardsRepository {
  DashboardsRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getFleetDashboard() async {
    final response = await _dio.get('/dashboards/fleet');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getVehicleDashboard(int vehicleId) async {
    final response = await _dio.get('/dashboards/vehicle/$vehicleId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDriversDashboard() async {
    final response = await _dio.get('/dashboards/drivers');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDriverDashboard(int driverId) async {
    final response = await _dio.get('/dashboards/driver/$driverId');
    return response.data as Map<String, dynamic>;
  }
}
