import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio _dio;

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
          print("➡️ REQUEST[${options.method}] => FULL URL: ${options.uri}");
          print("➡️ BASE URL: ${options.baseUrl}");
          print("DATA: ${options.data}");
          
          // Skip token for auth endpoints
          if (options.path.contains('/auth/')) {
            print("⚠️ Skipping Auth Token for: ${options.path}");
            return handler.next(options);
          }

          // Add Auth Token if available
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            print("🔑 Adding Auth Token: Bearer ${token.substring(0, 10)}...");
            options.headers['Authorization'] = 'Bearer $token';
          } else {
             print("⚠️ No Auth Token found in storage");
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print("⬅️ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}");
          print("DATA: ${response.data}");
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Global Error Handling
          print("❌ API Error: ${e.message} | Path: ${e.requestOptions.path}");
          print("TYPE: ${e.type}");
          print("RESPONSE: ${e.response?.data}");
          return handler.next(e);
        },
      ),
    );
  }

  static String _getBaseUrl() {
    // Production API URL (EC2 instance)
    const String productionUrl = 'http://13.233.48.227:4000';

    // For development, you can switch between production and local
    const bool useProduction = false; // Set to false for local development

    if (useProduction) {
      return productionUrl;
    }

    if (kIsWeb) return 'http://localhost:4000/api';
    
    // Check for Desktop platforms (macOS, Windows, Linux)
    if (defaultTargetPlatform == TargetPlatform.macOS || 
        defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:4000/api';
    }

    // Android Emulator
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000/api';
    }
    
    // iOS Simulator / Fallback
    return 'http://localhost:4000/api';
  }

  Dio get dio => _dio;
}
