import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _getBaseUrl(),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add Auth Token if available
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Global Error Handling
          print("API Error: ${e.message} | Path: ${e.requestOptions.path}");
          return handler.next(e);
        },
      ),
    );
  }

  static String _getBaseUrl() {
    // Production API URL (EC2 instance)
    const String productionUrl = 'http://13.233.48.227:4000';

    // For development, you can switch between production and local
    const bool useProduction = true; // Set to false for local development

    if (useProduction) {
      return productionUrl;
    }

    if (kIsWeb) return 'http://localhost:4000';
    
    // Check for Desktop platforms (macOS, Windows, Linux)
    if (defaultTargetPlatform == TargetPlatform.macOS || 
        defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:4000';
    }
    
    return ApiConstants.baseUrl;
  }

  Dio get dio => _dio;
}
