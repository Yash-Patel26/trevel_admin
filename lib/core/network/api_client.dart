import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/auth/auth_controller.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref));

class ApiClient {
  final Ref _ref;

  // Get the appropriate base URL based on platform
  static String _getBaseUrl() {
    // Check if API_BASE_URL is explicitly set via environment variable
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Production API URL (EC2 instance)
    const String productionUrl = 'http://13.233.48.227:4000';
    
    // For development, you can switch between production and local
    const bool useProduction = false; // Set to false for local development
    
    if (useProduction) {
      return productionUrl;
    }

    // Local development URLs
    if (kIsWeb) return 'http://localhost:4000/';
    
    // Check for Desktop platforms (macOS, Windows, Linux)
    if (defaultTargetPlatform == TargetPlatform.macOS || 
        defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:4000/';
    }

    // Android Emulator
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000/';
    }
    
    // iOS Simulator / Fallback
    return 'http://localhost:4000/api';
  }

  final Dio _dio = Dio(
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

  String? _refreshToken;
  VoidCallback? _onTokenExpired;
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  ApiClient(this._ref) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          final token = _dio.options.headers['Authorization']
              ?.toString()
              .replaceFirst('Bearer ', '');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 errors - try to refresh token
          if (error.response?.statusCode == 401) {
            final request = error.requestOptions;

            // Skip refresh for auth endpoints
            if (request.path.contains('/auth/login') ||
                request.path.contains('/auth/refresh')) {
              handler.next(error);
              return;
            }

            // If already refreshing, queue this request
            if (_isRefreshing) {
              final completer = Completer<Response<dynamic>>();
              _pendingRequests.add(_PendingRequest(request, completer));
              final response = await completer.future;
              handler.resolve(response);
              return;
            }

            // Try to refresh token
            _isRefreshing = true;
            try {
              if (_refreshToken == null) {
                throw Exception('No refresh token available');
              }

              final refreshResponse = await _dio.post(
                '/auth/refresh',
                data: {'refreshToken': _refreshToken},
              );

              final newAccessToken =
                  refreshResponse.data['accessToken'] as String;
              _dio.options.headers['Authorization'] = 'Bearer $newAccessToken';

              // Update auth state
              final authController = _ref.read(authControllerProvider.notifier);
              await authController.updateAccessToken(newAccessToken);

              // Retry the original request
              final opts = Options(
                method: request.method,
                headers: request.headers,
              );
              opts.headers!['Authorization'] = 'Bearer $newAccessToken';

              final response = await _dio.request(
                request.path,
                options: opts,
                data: request.data,
                queryParameters: request.queryParameters,
              );

              // Resolve all pending requests
              for (final pending in _pendingRequests) {
                pending.completer.complete(response);
              }
              _pendingRequests.clear();

              handler.resolve(response);
            } catch (e) {
              // Refresh failed - logout user
              _pendingRequests.clear();
              _onTokenExpired?.call();
              handler.next(error);
            } finally {
              _isRefreshing = false;
            }
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  void setAuthToken(String? token) {
    if (token == null) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  void setRefreshToken(String? token) {
    _refreshToken = token;
  }

  void setOnTokenExpired(VoidCallback callback) {
    _onTokenExpired = callback;
  }

  Dio get client => _dio;
}

class _PendingRequest {
  final RequestOptions request;
  final Completer<Response> completer;

  _PendingRequest(this.request, this.completer);
}
