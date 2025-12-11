class Ride {
  final int id;
  final String driverName;
  final String vehicleInfo;
  final DateTime pickupTime;
  final DateTime? dropTime;
  final String pickupLocation;
  final String dropLocation;
  final String status;

  Ride({
    required this.id,
    required this.driverName,
    required this.vehicleInfo,
    required this.pickupTime,
    this.dropTime,
    required this.pickupLocation,
    required this.dropLocation,
    required this.status,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] as int,
      driverName: json['driverName'] as String? ?? 'Not Assigned',
      vehicleInfo: json['vehicleInfo'] as String? ?? 'Not Assigned',
      pickupTime: DateTime.parse(json['pickupTime'] as String),
      dropTime: json['dropTime'] != null
          ? DateTime.parse(json['dropTime'] as String)
          : null,
      pickupLocation: json['pickupLocation'] as String,
      dropLocation: json['dropLocation'] as String,
      status: json['status'] as String,
    );
  }
}

class RideDetail {
  final int id;
  final String customerName;
  final String customerMobile;
  final String driverName;
  final String driverMobile;
  final String vehicleInfo;
  final String vehicleNumberPlate;
  final DateTime pickupTime;
  final DateTime? dropTime;
  final String pickupLocation;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String dropLocation;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String status;
  final String? otpCode;
  final DateTime createdAt;

  RideDetail({
    required this.id,
    required this.customerName,
    required this.customerMobile,
    required this.driverName,
    required this.driverMobile,
    required this.vehicleInfo,
    required this.vehicleNumberPlate,
    required this.pickupTime,
    this.dropTime,
    required this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    required this.dropLocation,
    this.destinationLatitude,
    this.destinationLongitude,
    required this.status,
    this.otpCode,
    required this.createdAt,
  });

  factory RideDetail.fromJson(Map<String, dynamic> json) {
    return RideDetail(
      id: json['id'] as int,
      customerName: json['customerName'] as String,
      customerMobile: json['customerMobile'] as String,
      driverName: json['driverName'] as String? ?? 'Not Assigned',
      driverMobile: json['driverMobile'] as String? ?? '',
      vehicleInfo: json['vehicleInfo'] as String? ?? 'Not Assigned',
      vehicleNumberPlate: json['vehicleNumberPlate'] as String? ?? '',
      pickupTime: DateTime.parse(json['pickupTime'] as String),
      dropTime: json['dropTime'] != null
          ? DateTime.parse(json['dropTime'] as String)
          : null,
      pickupLocation: json['pickupLocation'] as String,
      pickupLatitude: json['pickupLatitude'] as double?,
      pickupLongitude: json['pickupLongitude'] as double?,
      dropLocation: json['dropLocation'] as String,
      destinationLatitude: json['destinationLatitude'] as double?,
      destinationLongitude: json['destinationLongitude'] as double?,
      status: json['status'] as String,
      otpCode: json['otpCode'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
