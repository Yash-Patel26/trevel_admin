import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/state/auth/auth_state.dart';
import 'mock_auth_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  return AuthRepository(dio);
});

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  // Set to true to use mock authentication (bypasses backend)
  static const bool useMockAuth = false;

  Future<(String accessToken, String refreshToken, UserInfo user)> login({
    required String email,
    required String password,
  }) async {
    if (useMockAuth) {
      // Use mock authentication - bypasses backend
      return await MockAuthService.login(email: email, password: password);
    }

    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final user = UserInfo.fromJson(data['user'] as Map<String, dynamic>);

      return (accessToken, refreshToken, user);
    } on DioException catch (e) {
      // Log detailed error for debugging
      // print('DioException type: ${e.type}');
      // print('DioException message: ${e.message}');
      // print('Response status: ${e.response?.statusCode}');
      // print('Response data: ${e.response?.data}');

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Connection error: Unable to reach the server. Please check your network connection and ensure the backend is running.');
      }

      // Check for CORS errors (usually status 0 or null response)
      if (e.response == null && e.type == DioExceptionType.unknown) {
        throw Exception(
            'CORS error: The server may be blocking requests from this origin. Please check CORS configuration on the backend.');
      }

      if (e.response?.statusCode == 401) {
        throw Exception('Invalid credentials');
      }

      // Check for CORS preflight failure (status 0)
      if (e.response?.statusCode == null || e.response?.statusCode == 0) {
        throw Exception(
            'Network error: Could not connect to server. This might be a CORS issue. Check backend CORS configuration.');
      }

      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Login failed';
      throw Exception(errorMessage);
    } catch (e) {
      // print('Unexpected error: $e');
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  Future<UserInfo> getCurrentUser() async {
    if (useMockAuth) {
      throw Exception('getCurrentUser requires access token in mock mode');
    }

    try {
      final response = await _dio.get('/auth/me');
      return UserInfo.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized - please login again');
      }
      throw Exception('Failed to get current user');
    }
  }

  Future<String> refreshToken(String refreshToken) async {
    if (useMockAuth) {
      throw Exception('Token refresh not available in mock mode');
    }

    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      return response.data['accessToken'] as String;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid or expired refresh token');
      }
      throw Exception('Token refresh failed');
    }
  }

  Future<void> logout() async {
    if (useMockAuth) {
      return;
    }

    try {
      await _dio.post('/auth/logout');
    } catch (_) {
      // Ignore errors on logout
    }
  }
}
