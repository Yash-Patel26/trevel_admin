import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'vehicle_model.dart';

final vehiclesRepositoryProvider = Provider<VehiclesRepository>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  return VehiclesRepository(dio);
});

class VehiclesRepository {
  VehiclesRepository(this._dio);

  final Dio _dio;

  Future<List<Vehicle>> getVehicles({
    int? page,
    int? pageSize,
    String? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (pageSize != null) queryParams['pageSize'] = pageSize;
    if (status != null) queryParams['status'] = status;
    if (search != null) queryParams['search'] = search;

    final response = await _dio.get('/vehicles', queryParameters: queryParams);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => _vehicleFromBackendJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get available vehicle makes and models from backend
  Future<Map<String, List<String>>> getMakesAndModels() async {
    final response = await _dio.get('/vehicles/makes-models');
    final data = response.data as Map<String, dynamic>;
    return data.map((key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((e) => e.toString()).toList(),
        ));
  }

  /// Get available vehicles by make (for allocation)
  Future<List<Vehicle>> getAvailableVehicles({
    String? make,
    String? shiftTiming,
  }) async {
    final queryParams = <String, dynamic>{};
    if (make != null) queryParams['make'] = make;
    if (shiftTiming != null) queryParams['shiftTiming'] = shiftTiming;

    final response =
        await _dio.get('/vehicles/available', queryParameters: queryParams);
    final data = response.data as List<dynamic>;
    return data
        .map((json) => _vehicleFromBackendJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle> createVehicle({
    required String numberPlate,
    String? make,
    String? model,
    String? insurancePolicyNumber,
    DateTime? insuranceExpiry,
    String? liveLocationKey,
    String? dashcamKey,
  }) async {
    final response = await _dio.post('/vehicles', data: {
      'numberPlate': numberPlate,
      if (make != null) 'make': make,
      if (model != null) 'model': model,
      if (insurancePolicyNumber != null)
        'insurancePolicyNumber': insurancePolicyNumber,
      if (insuranceExpiry != null)
        'insuranceExpiry': insuranceExpiry.toIso8601String(),
      if (liveLocationKey != null) 'liveLocationKey': liveLocationKey,
      if (dashcamKey != null) 'dashcamKey': dashcamKey,
    });
    return _vehicleFromBackendJson(response.data as Map<String, dynamic>);
  }

  Future<void> reviewVehicle({
    required int vehicleId,
    required String status,
    String? comments,
  }) async {
    await _dio.post('/vehicles/$vehicleId/review', data: {
      'status': status,
      if (comments != null) 'comments': comments,
    });
  }

  Future<void> assignDriver({
    required int vehicleId,
    required int driverId,
  }) async {
    await _dio.post('/vehicles/$vehicleId/assign-driver', data: {
      'driverId': driverId,
    });
  }

  Future<List<Map<String, dynamic>>> getVehicleLogs(int vehicleId) async {
    final response = await _dio.get('/vehicles/$vehicleId/logs');
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getVehicleMetrics(int vehicleId) async {
    final response = await _dio.get('/vehicles/$vehicleId/metrics');
    return response.data as Map<String, dynamic>;
  }

  // Map backend response to Vehicle model
  Vehicle _vehicleFromBackendJson(Map<String, dynamic> json) {
    // Backend uses: id, numberPlate, make, model, status, createdAt, etc.
    // Frontend model expects: id, vehicleNumber, make, model, year, color, licensePlate, status, type, etc.
    return Vehicle(
      id: json['id'] as int,
      vehicleNumber: json['numberPlate'] as String? ??
          json['vehicleNumber'] as String? ??
          '',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: DateTime.now().year, // Backend doesn't provide year
      color: 'Black', // Constant color - always Black
      licensePlate: json['numberPlate'] as String? ?? '',
      status: _mapStatus(json['status'] as String? ?? 'pending'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      insurancePolicyNumber: json['insurancePolicyNumber'] as String?,
      insuranceExpiryDate: json['insuranceExpiry'] != null
          ? DateTime.parse(json['insuranceExpiry'] as String)
          : null,
      liveLocationAccessKey: json['liveLocationKey'] as String?,
      dashcamAccessKey: json['dashcamKey'] as String?,
    );
  }

  VehicleStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return VehicleStatus.pending;
      case 'approved':
      case 'active':
        return VehicleStatus.active;
      case 'rejected':
      case 'inactive':
        return VehicleStatus.retired;
      default:
        return VehicleStatus.pending;
    }
  }
}
