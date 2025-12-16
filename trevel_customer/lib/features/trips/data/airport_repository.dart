import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class AirportData {
  final String id;
  final String airportName;
  final String airportCode;
  final String city;
  final List<String> terminals;

  AirportData({
    required this.id,
    required this.airportName,
    required this.airportCode,
    required this.city,
    required this.terminals,
  });

  factory AirportData.fromJson(Map<String, dynamic> json) {
    return AirportData(
      id: json['id'],
      airportName: json['airportName'],
      airportCode: json['airportCode'],
      city: json['city'],
      terminals: json['terminal'] != null 
          ? (json['terminal'] as String).split(',').map((e) => e.trim()).toList() 
          : [],
    );
  }
}

class AirportRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<AirportData>> getAirports() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.clearAirports);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => AirportData.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Fetch Airports Error: $e");
      return [];
    }
  }
  Future<List<dynamic>?> getAirportEstimate({
    required bool isPickup,
    required String time,
    String? userLocation,
    String? airportId,
    String? terminal,
  }) async {
      try {
        final response = await _apiClient.dio.post(
          ApiConstants.AirportEstimate,
          data: {
            'type': isPickup ? 'pickup' : 'drop',
            'pickup_time': time, // Send full date-time ideally
            'user_location': userLocation,
            'airport_id': airportId,
            'terminal': terminal
          },
        );
        
        if (response.statusCode == 200 && response.data['success'] == true) {
          return List<dynamic>.from(response.data['data']);
        }
        return null;
      } catch (e) {
        print("Fetch Estimate Error: $e");
        return [];
      }
    }

  Future<List<String>> getPlacePredictions(String input) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.locationAutocomplete,
        queryParameters: {"input": input}
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> predictions = response.data['data'];
        return predictions.map((e) => e['description'] as String).toList();
      }
      return [];
    } catch (e) {
      print("Fetch Predictions Error: $e");
      return []; 
    }
  }
}
