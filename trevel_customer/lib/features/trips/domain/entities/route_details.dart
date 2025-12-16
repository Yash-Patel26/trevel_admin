import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteDetails {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final String durationInTraffic;
  final String trafficStatus;
  final int trafficDelayMins;

  RouteDetails({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.durationInTraffic,
    required this.trafficStatus,
    required this.trafficDelayMins,
  });

  factory RouteDetails.fromJson(Map<String, dynamic> json, List<LatLng> points) {
    return RouteDetails(
      polylinePoints: points,
      distance: json['distance'] ?? '',
      duration: json['duration'] ?? '',
      durationInTraffic: json['duration_in_traffic'] ?? '',
      trafficStatus: json['traffic_status'] ?? 'Normal',
      trafficDelayMins: json['traffic_delay_mins'] ?? 0,
    );
  }
}
