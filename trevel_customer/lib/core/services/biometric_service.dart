import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';

  Future<bool> isDeviceSupported() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      print("Biometric Support Check Error: $e");
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          biometricOnly: false, 
          stickyAuth: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print("Authentication Error: $e");
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }
}
