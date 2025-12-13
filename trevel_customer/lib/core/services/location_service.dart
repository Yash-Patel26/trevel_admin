import 'package:geolocator/geolocator.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';

class LocationService {
  final ApiClient _apiClient = ApiClient();

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // Location services are disabled.
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; // Permissions are denied
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null; // Permissions are denied forever
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, dynamic>?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.reverseGeocode,
        queryParameters: {
            'lat': lat,
            'lng': lng
        }
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
         // data.results[0].formatted_address usually
         final results = response.data['data']['results'];
         if (results != null && results.isNotEmpty) {
             return results[0];
         }
      }
      return null;
    } catch (e) {
      print("Reverse Geocode Error: $e");
      return null;
    }
  }
}
