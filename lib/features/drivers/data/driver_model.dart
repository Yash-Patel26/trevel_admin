import 'package:flutter/material.dart';
import 'driver_document.dart';

class Driver {
  final String id;
  final String fullName;
  final String email;
  final String mobile;
  final String? licenseNumber;
  final DriverStatus status;
  final DateTime createdAt;
  final DateTime? backgroundCheckDate;
  final BackgroundCheckStatus? backgroundCheckStatus;
  final bool trainingCompleted;
  final String? assignedVehicleNumber;
  final String? notes;
  final String? profileImageUrl;
  // PRD requirements
  final List<DriverDocument> documents;
  final ContactPreferences contactPreferences;

  Driver({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobile,
    this.licenseNumber,
    required this.status,
    required this.createdAt,
    this.backgroundCheckDate,
    this.backgroundCheckStatus,
    this.trainingCompleted = false,
    this.assignedVehicleNumber,
    this.notes,
    this.profileImageUrl,
    this.documents = const [],
    ContactPreferences? contactPreferences,
  }) : contactPreferences = contactPreferences ?? ContactPreferences();

  Driver copyWith({
    String? id,
    String? fullName,
    String? email,
    String? mobile,
    String? licenseNumber,
    DriverStatus? status,
    DateTime? createdAt,
    DateTime? backgroundCheckDate,
    BackgroundCheckStatus? backgroundCheckStatus,
    bool? trainingCompleted,
    String? assignedVehicleNumber,
    String? notes,
    String? profileImageUrl,
    List<DriverDocument>? documents,
    ContactPreferences? contactPreferences,
  }) {
    return Driver(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      backgroundCheckDate: backgroundCheckDate ?? this.backgroundCheckDate,
      backgroundCheckStatus:
          backgroundCheckStatus ?? this.backgroundCheckStatus,
      trainingCompleted: trainingCompleted ?? this.trainingCompleted,
      assignedVehicleNumber:
          assignedVehicleNumber ?? this.assignedVehicleNumber,
      notes: notes ?? this.notes,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      documents: documents ?? this.documents,
      contactPreferences: contactPreferences ?? this.contactPreferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'mobile': mobile,
      'licenseNumber': licenseNumber,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'backgroundCheckDate': backgroundCheckDate?.toIso8601String(),
      'backgroundCheckStatus': backgroundCheckStatus?.name,
      'trainingCompleted': trainingCompleted,
      'assignedVehicleNumber': assignedVehicleNumber,
      'notes': notes,
      'profileImageUrl': profileImageUrl,
      'documents': documents.map((d) => d.toJson()).toList(),
      'contactPreferences': contactPreferences.toJson(),
    };
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'].toString(), // Ensure String
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '', // Handle name/fullName mismatch
      email: json['email'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      licenseNumber: json['licenseNumber'] as String?,
      status: DriverStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DriverStatus.pending,
      ),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
      backgroundCheckDate: json['backgroundCheckDate'] != null
          ? DateTime.parse(json['backgroundCheckDate'] as String)
          : null,
      backgroundCheckStatus: json['backgroundCheckStatus'] != null
          ? BackgroundCheckStatus.values.firstWhere(
              (e) => e.name == json['backgroundCheckStatus'],
              orElse: () => BackgroundCheckStatus.pending,
            )
          : null,
      trainingCompleted: json['trainingCompleted'] as bool? ?? false,
      assignedVehicleNumber: json['assignedVehicleNumber'] as String? ??
          (json['assignments'] != null &&
                  (json['assignments'] as List).isNotEmpty
              ? ((json['assignments'] as List).first['vehicle'] != null
                  ? (json['assignments'] as List).first['vehicle']
                      ['numberPlate']
                  : null)
              : null),
      notes: json['notes'] as String?,
      documents: (json['documents'] as List<dynamic>?)
              ?.map((d) => DriverDocument.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      profileImageUrl: json['profileImageUrl'] as String?,
      
      contactPreferences: json['contactPreferences'] != null
          ? ContactPreferences.fromJson(
              json['contactPreferences'] as Map<String, dynamic>)
          : ContactPreferences(),
    );
  }
}

enum DriverStatus {
  pending,
  verified,
  vehicle_assigned,
  training_completed,
  approved,
  rejected,
  active,
  suspended,
}

enum BackgroundCheckStatus {
  pending,
  inProgress,
  passed,
  failed,
}

extension DriverStatusExtension on DriverStatus {
  String get displayName {
    switch (this) {
      case DriverStatus.pending:
        return 'Pending';
      case DriverStatus.verified:
        return 'Verified';
      case DriverStatus.vehicle_assigned:
        return 'Vehicle Assigned';
      case DriverStatus.training_completed:
        return 'Training Completed';
      case DriverStatus.approved:
        return 'Approved';
      case DriverStatus.rejected:
        return 'Rejected';
      case DriverStatus.active:
        return 'Active';
      case DriverStatus.suspended:
        return 'Suspended';
    }
  }

  Color get color {
    switch (this) {
      case DriverStatus.pending:
        return Colors.orange;
      case DriverStatus.verified:
        return Colors.blue;
      case DriverStatus.vehicle_assigned:
        return Colors.purple;
      case DriverStatus.training_completed:
        return Colors.teal;
      case DriverStatus.approved:
        return Colors.green;
      case DriverStatus.rejected:
        return Colors.red;
      case DriverStatus.active:
        return Colors.blue;
      case DriverStatus.suspended:
        return Colors.grey;
    }
  }
}

extension BackgroundCheckStatusExtension on BackgroundCheckStatus {
  String get displayName {
    switch (this) {
      case BackgroundCheckStatus.pending:
        return 'Pending';
      case BackgroundCheckStatus.inProgress:
        return 'In Progress';
      case BackgroundCheckStatus.passed:
        return 'Passed';
      case BackgroundCheckStatus.failed:
        return 'Failed';
    }
  }

  Color get color {
    switch (this) {
      case BackgroundCheckStatus.pending:
        return Colors.orange;
      case BackgroundCheckStatus.inProgress:
        return Colors.blue;
      case BackgroundCheckStatus.passed:
        return Colors.green;
      case BackgroundCheckStatus.failed:
        return Colors.red;
    }
  }
}
