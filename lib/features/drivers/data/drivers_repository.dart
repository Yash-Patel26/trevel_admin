import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import 'driver_model.dart';
import 'driver_document.dart';

final driversRepositoryProvider = Provider<DriversRepository>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  return DriversRepository(dio);
});

class DriversRepository {
  DriversRepository(this._dio);

  final Dio _dio;

  Future<List<Driver>> getDrivers({
    int? page,
    int? pageSize,
    String? status,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (pageSize != null) queryParams['pageSize'] = pageSize;
    if (status != null) queryParams['status'] = status;
    if (search != null) queryParams['search'] = search;

    final response = await _dio.get('/drivers', queryParameters: queryParams);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => _driverFromBackendJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Driver> createDriver({
    required String name,
    required String mobile,
    String? email,
    Map<String, dynamic>? onboardingData,
    Map<String, dynamic>? contactPreferences,
  }) async {
    final response = await _dio.post('/drivers', data: {
      'name': name,
      'mobile': mobile,
      if (email != null) 'email': email,
      if (onboardingData != null) 'onboardingData': onboardingData,
      if (contactPreferences != null) 'contactPreferences': contactPreferences,
    });
    return _driverFromBackendJson(response.data as Map<String, dynamic>);
  }

  Future<void> backgroundCheck({
    required int driverId,
    required String status,
    String? notes,
  }) async {
    await _dio.post('/drivers/$driverId/background', data: {
      'status': status,
      if (notes != null) 'notes': notes,
    });
  }

  Future<void> assignTraining({
    required int driverId,
    required String module,
    required String status,
  }) async {
    await _dio.post('/drivers/$driverId/training', data: {
      'module': module,
      'status': status,
    });
  }

  Future<void> approveDriver({
    required int driverId,
    required String decision,
  }) async {
    await _dio.post('/drivers/$driverId/approve', data: {
      'decision': decision,
    });
  }

  Future<Map<String, dynamic>> getAuditTrail(int driverId) async {
    final response = await _dio.get('/drivers/$driverId/audit-trail');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkMobileExists(String mobile) async {
    final response = await _dio.get('/drivers/check-mobile', queryParameters: {
      'mobile': mobile,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> assignVehicle({
    required int driverId,
    required int vehicleId,
  }) async {
    await _dio.post('/drivers/$driverId/assign-vehicle', data: {
      'vehicleId': vehicleId,
    });
  }

  Future<List<Map<String, dynamic>>> getDriverLogs(int driverId) async {
    final response = await _dio.get('/drivers/$driverId/logs');
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<DriverDocument>> getDriverDocuments(int driverId) async {
    final response = await _dio.get('/drivers/$driverId/documents');
    final data = response.data as List<dynamic>;
    return data.map((json) {
      final docJson = json as Map<String, dynamic>;
      // Backend doesn't return createdAt, so use current time or a default
      return DriverDocument(
        id: docJson['id'] as int,
        name: docJson['type'] as String? ?? 'Document',
        type: docJson['type'] as String? ?? '',
        fileUrl: docJson['url'] as String?,
        uploadedAt: DateTime.now(), // Backend doesn't provide createdAt
      );
    }).toList();
  }

  Future<DriverDocument> uploadDriverDocument({
    required int driverId,
    required String filePath,
    required String type,
  }) async {
    // Handle both web and mobile file uploads
    List<int> fileBytes;
    String fileName;
    String? mimeType;

    if (kIsWeb) {
      // On web, filePath should work with XFile
      final xFile = XFile(filePath);
      fileBytes = await xFile.readAsBytes();
      fileName = xFile.name;
      mimeType = xFile.mimeType;
    } else {
      // On mobile, use File
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }
      fileBytes = await file.readAsBytes();
      fileName = file.path.split('/').last.split('\\').last;
    }

    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType ?? _getMimeType(fileName)),
      ),
      'type': type,
    });
    final response = await _dio.post(
      '/drivers/$driverId/documents',
      data: formData,
    );
    final docJson = response.data as Map<String, dynamic>;
    return DriverDocument(
      id: docJson['id'] as int,
      name: docJson['type'] as String? ?? 'Document',
      type: docJson['type'] as String? ?? '',
      fileUrl: docJson['url'] as String?,
      uploadedAt: DateTime.now(),
    );
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> deleteDriverDocument({
    required int driverId,
    required int documentId,
  }) async {
    await _dio.delete('/drivers/$driverId/documents/$documentId');
  }

  Future<DriverDocument> verifyDriverDocument({
    required int driverId,
    required int documentId,
    required String status,
  }) async {
    final response = await _dio.post(
      '/drivers/$driverId/documents/$documentId/verify',
      data: {'status': status},
    );
    final docJson = response.data as Map<String, dynamic>;
    return DriverDocument(
      id: docJson['id'] as int,
      name: docJson['type'] as String? ?? 'Document',
      type: docJson['type'] as String? ?? '',
      fileUrl: docJson['url'] as String?,
      uploadedAt: docJson['createdAt'] != null
          ? DateTime.parse(docJson['createdAt'] as String)
          : DateTime.now(),
    );
  }

  // Map backend response to Driver model
  Driver _driverFromBackendJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as int,
      fullName: json['name'] as String? ?? json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      licenseNumber: json['licenseNumber'] as String?,
      status: _mapStatus(json['status'] as String? ?? 'pending'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      backgroundCheckDate: json['backgroundCheckDate'] != null
          ? DateTime.parse(json['backgroundCheckDate'] as String)
          : null,
      backgroundCheckStatus: json['backgroundCheckStatus'] != null
          ? _mapBackgroundCheckStatus(json['backgroundCheckStatus'] as String)
          : null,
      trainingCompleted: json['trainingCompleted'] as bool? ?? false,
      assignedVehicleNumber: json['assignedVehicleNumber'] as String?,
      notes: json['notes'] as String?,
      profileImageUrl: json['profileImageUrl'] as String? ??
          (json['onboardingData'] != null
              ? ((json['onboardingData']
                  as Map<String, dynamic>)['profileImageUrl'] as String?)
              : null),
      documents: (json['documents'] as List<dynamic>?)
              ?.map((d) => DriverDocument.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      contactPreferences: json['contactPreferences'] != null
          ? ContactPreferences.fromJson(
              json['contactPreferences'] as Map<String, dynamic>)
          : ContactPreferences(),
    );
  }

  DriverStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return DriverStatus.pending;
      case 'verified':
        return DriverStatus.verified;
      case 'vehicle_assigned':
        return DriverStatus.vehicle_assigned;
      case 'training_completed':
        return DriverStatus.training_completed;
      case 'approved':
        return DriverStatus.approved;
      case 'rejected':
        return DriverStatus.rejected;
      case 'active':
        return DriverStatus.active;
      case 'inactive':
      case 'suspended':
        return DriverStatus.suspended;
      default:
        return DriverStatus.pending;
    }
  }

  BackgroundCheckStatus _mapBackgroundCheckStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BackgroundCheckStatus.pending;
      case 'in_progress':
        return BackgroundCheckStatus.inProgress;
      case 'clear':
      case 'passed':
        return BackgroundCheckStatus.passed;
      case 'flagged':
      case 'failed':
        return BackgroundCheckStatus.failed;
      default:
        return BackgroundCheckStatus.pending;
    }
  }
}
