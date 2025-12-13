import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class BookingsRepository {
  final ApiClient _apiClient = ApiClient();

  /// Fetch booking details by ID with driver and vehicle information
  Future<Map<String, dynamic>?> getBookingDetails(String bookingId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.bookingDetails(bookingId),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching booking details: $e');
      return null;
    }
  }

  /// Fetch all bookings for authenticated customer
  Future<List<Map<String, dynamic>>> getMyBookings({String? status}) async {
    try {
      final queryParams = status != null ? {'status': status} : null;
      
      final response = await _apiClient.dio.get(
        ApiConstants.myBookings,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }
}
