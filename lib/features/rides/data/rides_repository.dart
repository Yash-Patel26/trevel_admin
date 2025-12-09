import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final ridesRepositoryProvider = Provider<RidesRepository>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  return RidesRepository(dio);
});

class RidesRepository {
  RidesRepository(this._dio);

  final Dio _dio;

  /// Get list of rides with optional filtering
  Future<List<Map<String, dynamic>>> getRides({
    int? page,
    int? pageSize,
    int? vehicleId,
    int? driverId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (pageSize != null) queryParams['pageSize'] = pageSize;
    if (vehicleId != null) queryParams['vehicleId'] = vehicleId;
    if (driverId != null) queryParams['driverId'] = driverId;
    if (status != null) queryParams['status'] = status;
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    final response = await _dio.get('/rides', queryParameters: queryParams);
    final data = response.data['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  /// Get a single ride by ID
  Future<Map<String, dynamic>> getRide(int rideId) async {
    final response = await _dio.get('/rides/$rideId');
    return response.data as Map<String, dynamic>;
  }

  /// Create a new ride
  Future<Map<String, dynamic>> createRide({
    required int vehicleId,
    int? driverId,
    required DateTime startedAt,
    DateTime? endedAt,
    double? distanceKm,
    String? status, // 'in_progress', 'completed', 'canceled'
  }) async {
    final response = await _dio.post('/rides', data: {
      'vehicleId': vehicleId,
      if (driverId != null) 'driverId': driverId,
      'startedAt': startedAt.toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt.toIso8601String(),
      if (distanceKm != null) 'distanceKm': distanceKm,
      if (status != null) 'status': status,
    });
    return response.data as Map<String, dynamic>;
  }

  /// Update an existing ride
  Future<Map<String, dynamic>> updateRide({
    required int rideId,
    DateTime? endedAt,
    double? distanceKm,
    String? status, // 'in_progress', 'completed', 'canceled'
  }) async {
    final data = <String, dynamic>{};
    if (endedAt != null) data['endedAt'] = endedAt.toIso8601String();
    if (distanceKm != null) data['distanceKm'] = distanceKm;
    if (status != null) data['status'] = status;

    final response = await _dio.patch('/rides/$rideId', data: data);
    return response.data as Map<String, dynamic>;
  }
}
