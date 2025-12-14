import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';

class DirectionsService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch route from backend and decode polyline
  Future<List<LatLng>> getRoute(String origin, String destination) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.directions,
        queryParameters: {
          'origin': origin,
          'destination': destination,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final String encodedPolyline = response.data['data']['polyline'];
        return _decodePolyline(encodedPolyline);
      }
      return [];
    } catch (e) {
      print('Directions error: $e');
      return [];
    }
  }

  /// Decode Google's encoded polyline format to List<LatLng>
  /// Based on: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}
