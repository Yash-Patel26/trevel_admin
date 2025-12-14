import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();

  /// Normalizes phone number by adding +91 prefix if not present
  String _normalizePhone(String phone) {
    // Remove any spaces or special characters
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // If already has country code, return as is
    if (cleaned.startsWith('+91')) {
      return cleaned;
    }
    
    // If starts with 91 (without +), add the +
    if (cleaned.startsWith('91') && cleaned.length > 10) {
      return '+$cleaned';
    }
    
    // Otherwise, add +91 prefix
    return '+91$cleaned';
  }

  /// Creates a local demo session so users can explore without a backend OTP.
  Future<Map<String, dynamic>> loginAsDemo() async {
    const demoToken = 'demo_user_all_access';
    await _storage.write(key: 'auth_token', value: demoToken);
    return {
      'id': 'demo-user',
      'name': 'Demo Rider',
      'phone': '0000000000',
      'role': 'demo',
      'token': demoToken,
    };
  }

  Future<bool> sendOtp(String phone) async {
    try {
      final normalizedPhone = _normalizePhone(phone);
      final response = await _apiClient.dio.post(
        ApiConstants.sendOtp,
        data: {'phone': normalizedPhone},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      // Handle error gracefully
      return false;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String phone, String otp) async {
    try {
      final normalizedPhone = _normalizePhone(phone);
      final response = await _apiClient.dio.post(
        ApiConstants.verifyOtp,
        data: {'phone': normalizedPhone, 'otp': otp},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['token'];
        if (token != null) {
          await _storage.write(key: 'auth_token', value: token);
        }
        return data; // Return user data & token info
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> logout() async {
    await _storage.delete(key: 'auth_token');
    return true;
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConstants.updateProfile,
        data: data,
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
