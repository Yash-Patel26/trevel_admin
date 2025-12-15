import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  return BookingsRepository(dio);
});

class BookingsRepository {
  BookingsRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getBookingSummary() async {
    final response = await _dio.get('/customers/dashboard/summary');
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getBookings({
    int? page,
    int? pageSize,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? type,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (pageSize != null) queryParams['pageSize'] = pageSize;
    if (status != null) queryParams['status'] = status;
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
    if (search != null) queryParams['search'] = search;
    if (type != null) queryParams['type'] = type;

    final response =
        await _dio.get('/customers/bookings', queryParameters: queryParams);
    final data = response.data['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getBooking(int bookingId) async {
    final response = await _dio.get('/bookings/$bookingId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> assignBooking({
    required int bookingId,
    required String vehicleId,
    String? driverId,
  }) async {
    final response = await _dio.post('/bookings/$bookingId/assign', data: {
      'vehicleId': vehicleId,
      if (driverId != null) 'driverId': driverId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> validateOtp({
    required int bookingId,
    required String otpCode,
  }) async {
    final response =
        await _dio.post('/bookings/$bookingId/validate-otp', data: {
      'otpCode': otpCode,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBookingStatus({
    required int bookingId,
    required String status,
    DateTime? destinationTime,
    double? distanceKm,
  }) async {
    final response = await _dio.patch('/bookings/$bookingId/status', data: {
      'status': status,
      if (destinationTime != null)
        'destinationTime': destinationTime.toIso8601String(),
      if (distanceKm != null) 'distanceKm': distanceKm,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeBooking({
    required int bookingId,
    DateTime? destinationTime,
    double? distanceKm,
  }) async {
    final response = await _dio.post('/bookings/$bookingId/complete', data: {
      if (destinationTime != null)
        'destinationTime': destinationTime.toIso8601String(),
      if (distanceKm != null) 'distanceKm': distanceKm,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelBooking({
    required int bookingId,
    String? reason,
  }) async {
    final response = await _dio.post('/bookings/$bookingId/cancel', data: {
      if (reason != null) 'reason': reason,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBookingLocations({
    required int bookingId,
    String? pickupLocation,
    String? destinationLocation,
    double? pickupLatitude,
    double? pickupLongitude,
    double? destinationLatitude,
    double? destinationLongitude,
  }) async {
    final response = await _dio.patch('/bookings/$bookingId/locations', data: {
      if (pickupLocation != null) 'pickupLocation': pickupLocation,
      if (destinationLocation != null)
        'destinationLocation': destinationLocation,
      if (pickupLatitude != null) 'pickupLatitude': pickupLatitude,
      if (pickupLongitude != null) 'pickupLongitude': pickupLongitude,
      if (destinationLatitude != null)
        'destinationLatitude': destinationLatitude,
      if (destinationLongitude != null)
        'destinationLongitude': destinationLongitude,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCustomer(int customerId) async {
    final response = await _dio.get('/customers/$customerId');
    return response.data as Map<String, dynamic>;
  }
}
