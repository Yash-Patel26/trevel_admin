import 'package:flutter/material.dart';

class Vehicle {
  final int id;
  final String vehicleNumber;
  final String make;
  final String model;
  final int year;
  final String color; // Always "Black" - constant value
  final String licensePlate;
  final VehicleStatus status;
  final DateTime createdAt;
  final DateTime? lastMaintenanceDate;
  final String? notes;
  // Insurance fields (PRD requirement)
  final String? insuranceDetails;
  final String? insurancePolicyNumber;
  final DateTime? insuranceExpiryDate;
  // Access keys (PRD requirement)
  final String? liveLocationAccessKey;
  final String? dashcamAccessKey;
  // Driver assignment
  final int? assignedDriverId;
  final String? assignedDriverName;
  final String? assignedDriverStatus; // 'active', 'inactive', etc.

  Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.make,
    required this.model,
    required this.year,
    String? color, // Optional, defaults to "Black"
    required this.licensePlate,
    required this.status,
    required this.createdAt,
    this.lastMaintenanceDate,
    this.notes,
    this.insuranceDetails,
    this.insurancePolicyNumber,
    this.insuranceExpiryDate,
    this.liveLocationAccessKey,
    this.dashcamAccessKey,
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedDriverStatus,
  }) : color = color ?? 'Black'; // Default to "Black" if not provided

  Vehicle copyWith({
    int? id,
    String? vehicleNumber,
    String? make,
    String? model,
    int? year,
    String? color,
    String? licensePlate,
    VehicleStatus? status,
    DateTime? createdAt,
    DateTime? lastMaintenanceDate,
    String? notes,
    String? insuranceDetails,
    String? insurancePolicyNumber,
    DateTime? insuranceExpiryDate,
    String? liveLocationAccessKey,
    String? dashcamAccessKey,
    int? assignedDriverId,
    String? assignedDriverName,
    String? assignedDriverStatus,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      licensePlate: licensePlate ?? this.licensePlate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      notes: notes ?? this.notes,
      insuranceDetails: insuranceDetails ?? this.insuranceDetails,
      insurancePolicyNumber:
          insurancePolicyNumber ?? this.insurancePolicyNumber,
      insuranceExpiryDate: insuranceExpiryDate ?? this.insuranceExpiryDate,
      liveLocationAccessKey:
          liveLocationAccessKey ?? this.liveLocationAccessKey,
      dashcamAccessKey: dashcamAccessKey ?? this.dashcamAccessKey,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      assignedDriverStatus: assignedDriverStatus ?? this.assignedDriverStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleNumber': vehicleNumber,
      'make': make,
      'model': model,
      'year': year,
      'color': color, // Always "Black"
      'licensePlate': licensePlate,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'lastMaintenanceDate': lastMaintenanceDate?.toIso8601String(),
      'notes': notes,
      'insuranceDetails': insuranceDetails,
      'insurancePolicyNumber': insurancePolicyNumber,
      'insuranceExpiryDate': insuranceExpiryDate?.toIso8601String(),
      'liveLocationAccessKey': liveLocationAccessKey,
      'dashcamAccessKey': dashcamAccessKey,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int,
      vehicleNumber: json['vehicleNumber'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      color: json['color'] as String? ?? 'Black', // Default to "Black"
      licensePlate: json['licensePlate'] as String,
      status: VehicleStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => VehicleStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastMaintenanceDate: json['lastMaintenanceDate'] != null
          ? DateTime.parse(json['lastMaintenanceDate'] as String)
          : null,
      notes: json['notes'] as String?,
      insuranceDetails: json['insuranceDetails'] as String?,
      insurancePolicyNumber: json['insurancePolicyNumber'] as String?,
      insuranceExpiryDate: json['insuranceExpiryDate'] != null
          ? DateTime.parse(json['insuranceExpiryDate'] as String)
          : null,
      liveLocationAccessKey: json['liveLocationAccessKey'] as String?,
      dashcamAccessKey: json['dashcamAccessKey'] as String?,
      assignedDriverId: json['assignments'] != null &&
              (json['assignments'] as List).isNotEmpty
          ? ((json['assignments'] as List).first['driver'] != null
              ? (json['assignments'] as List).first['driver']['id'] as int?
              : null)
          : null,
      assignedDriverName: json['assignments'] != null &&
              (json['assignments'] as List).isNotEmpty
          ? ((json['assignments'] as List).first['driver'] != null
              ? (json['assignments'] as List).first['driver']['name']
              : null)
          : null,
      assignedDriverStatus: json['assignments'] != null &&
              (json['assignments'] as List).isNotEmpty
          ? ((json['assignments'] as List).first['driver'] != null
              ? (json['assignments'] as List).first['driver']['status'] as String?
              : null)
          : null,
    );
  }
}

enum VehicleStatus {
  pending,
  active,
  maintenance,
  retired,
}

extension VehicleStatusExtension on VehicleStatus {
  String get displayName {
    switch (this) {
      case VehicleStatus.pending:
        return 'Pending';
      case VehicleStatus.active:
        return 'Active';
      case VehicleStatus.maintenance:
        return 'Maintenance';
      case VehicleStatus.retired:
        return 'Retired';
    }
  }

  Color get color {
    switch (this) {
      case VehicleStatus.pending:
        return Colors.orange;
      case VehicleStatus.active:
        return Colors.green;
      case VehicleStatus.maintenance:
        return Colors.red;
      case VehicleStatus.retired:
        return Colors.grey;
    }
  }
}
