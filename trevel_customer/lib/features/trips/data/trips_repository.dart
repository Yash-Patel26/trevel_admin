import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class TripsRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>?> getTripEstimate({
    required double distanceKm,
    required String pickupTime,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.miniTripEstimate,
        data: {
          'distance_km': distanceKm,
          'pickup_time': pickupTime,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print("Estimate Error: $e");
      return null;
    }
  }

  Future<bool> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.miniTripBook,
        data: bookingData,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      print("Booking Error: $e");
      return false;
    }
  }
  Future<List<dynamic>> getBookings() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.myBookings);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("Get Bookings Error: $e");
      return [];
    }
  }
}
