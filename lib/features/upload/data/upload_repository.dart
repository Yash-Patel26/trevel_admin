import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';

final uploadRepositoryProvider = Provider<UploadRepository>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  return UploadRepository(dio);
});

/// Represents an uploaded file response from the backend
class UploadedFile {
  final String filename;
  final String originalName;
  final String mimetype;
  final int size;
  final String url;
  final String path;

  UploadedFile({
    required this.filename,
    required this.originalName,
    required this.mimetype,
    required this.size,
    required this.url,
    required this.path,
  });

  factory UploadedFile.fromJson(Map<String, dynamic> json) {
    return UploadedFile(
      filename: json['filename'] as String,
      originalName: json['originalName'] as String,
      mimetype: json['mimetype'] as String,
      size: json['size'] as int,
      url: json['url'] as String,
      path: json['path'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'originalName': originalName,
      'mimetype': mimetype,
      'size': size,
      'url': url,
      'path': path,
    };
  }
}

class UploadRepository {
  UploadRepository(this._dio);

  final Dio _dio;

  /// Upload a file - works on both web and mobile
  /// Accepts either File (mobile) or XFile (web/mobile)
  /// Optional entityType, entityId, and documentType for organized S3 folder structure
  /// Structure: {entityType}/{entityId}/{documentType}/file.ext
  /// Example: drivers/9876543210/PAN_Card/pan_image.jpg
  Future<UploadedFile> uploadFile(
    dynamic file, {
    String? entityType,    // e.g., "drivers"
    String? entityId,      // e.g., mobile number
    String? documentType,  // e.g., "PAN_Card", "Aadhar_Card", "Driving_License", "Police_Verification"
  }) async {
    String fileName;
    List<int> fileBytes;
    String? mimeType;

    if (kIsWeb) {
      // Web: file must be XFile
      if (file is! XFile) {
        throw Exception('On web, file must be XFile, not File');
      }
      final xFile = file;
      fileName = xFile.name;
      fileBytes = await xFile.readAsBytes();
      mimeType = xFile.mimeType;
    } else {
      // Mobile: file can be File or XFile
      if (file is File) {
        fileName = file.path
            .split('/')
            .last
            .split('\\')
            .last; // Handle both Unix and Windows paths
        fileBytes = await file.readAsBytes();
      } else if (file is XFile) {
        fileName = file.name;
        fileBytes = await file.readAsBytes();
        mimeType = file.mimeType;
      } else {
        throw Exception('File must be either File or XFile');
      }
    }

    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType ?? _getMimeType(fileName)),
      ),
      if (entityType != null) 'entityType': entityType,
      if (entityId != null) 'entityId': entityId,
      if (documentType != null) 'documentType': documentType,
    });

    final response = await _dio.post('/upload', data: formData);
    final fileData = response.data['file'] as Map<String, dynamic>;
    return UploadedFile.fromJson(fileData);
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


  /// Upload a file from a file path (mobile only)
  Future<UploadedFile> uploadFileFromPath(String filePath) async {
    if (kIsWeb) {
      throw Exception(
          'uploadFileFromPath is not supported on web. Use uploadFile with XFile instead.');
    }
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File does not exist: $filePath');
    }
    return uploadFile(file);
  }

  /// Upload multiple files - works on both web and mobile
  Future<List<UploadedFile>> uploadMultipleFiles(List<dynamic> files) async {
    final formData = FormData();

    for (var file in files) {
      String fileName;
      List<int> fileBytes;
      String? mimeType;

      if (kIsWeb) {
        if (file is! XFile) {
          throw Exception('On web, files must be XFile, not File');
        }
        final xFile = file;
        fileName = xFile.name;
        fileBytes = await xFile.readAsBytes();
        mimeType = xFile.mimeType;
      } else {
        if (file is File) {
          fileName = file.path.split('/').last.split('\\').last;
          fileBytes = await file.readAsBytes();
        } else if (file is XFile) {
          fileName = file.name;
          fileBytes = await file.readAsBytes();
          mimeType = file.mimeType;
        } else {
          throw Exception('Files must be either File or XFile');
        }
      }

      formData.files.add(
        MapEntry(
          'images',
          MultipartFile.fromBytes(
            fileBytes,
            filename: fileName,
            contentType: DioMediaType.parse(mimeType ?? _getMimeType(fileName)),
          ),
        ),
      );
    }

    final response = await _dio.post('/upload/multiple', data: formData);
    final filesData = response.data['files'] as List<dynamic>;
    return filesData
        .map((json) => UploadedFile.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Upload multiple files from file paths (mobile only)
  Future<List<UploadedFile>> uploadMultipleFilesFromPaths(
      List<String> filePaths) async {
    if (kIsWeb) {
      throw Exception(
          'uploadMultipleFilesFromPaths is not supported on web. Use uploadMultipleFiles with XFile list instead.');
    }
    final files = filePaths.map((path) => File(path)).toList();

    // Check all files exist
    for (var file in files) {
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }
    }

    return uploadMultipleFiles(files);
  }

  /// Delete a file from S3 by its URL
  Future<void> deleteFile(String fileUrl) async {
    // Extract the S3 key from the URL
    // URL format: https://bucket.s3.region.amazonaws.com/key
    final uri = Uri.parse(fileUrl);
    final key = uri.path.substring(1); // Remove leading slash
    
    await _dio.delete('/upload/delete', data: {
      'key': key,
    });
  }

  /// Create S3 folder for driver using mobile number
  Future<void> createDriverFolder(String mobile) async {
    await _dio.post('/s3/create-folder', data: {
      'mobile': mobile,
    });
  }
}
