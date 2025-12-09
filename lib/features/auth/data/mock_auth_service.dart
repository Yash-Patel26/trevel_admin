import '../../../core/state/auth/auth_state.dart';

/// Mock authentication service that bypasses backend
/// Contains predefined users for frontend development
class MockAuthService {
  // Mock users database
  static final Map<String, MockUser> _users = {
    'admin@example.com': MockUser(
      id: 1,
      email: 'admin@example.com',
      password: 'admin123',
      fullName: 'Operational Administrator',
      role: 'Operational Admin',
      permissions: [
        // All permissions for Operational Admin
        'vehicle:create',
        'vehicle:review',
        'vehicle:approve',
        'vehicle:view',
        'vehicle:assign',
        'vehicle:logs',
        'driver:create',
        'driver:verify',
        'driver:train',
        'driver:approve',
        'driver:view',
        'driver:assign',
        'driver:logs',
        'dashboard:view',
        'ticket:create',
        'ticket:view',
        'ticket:update',
        'notifications:manage',
        'reports:view',
        'audit:view',
        'customer:view',
        'booking:create',
        'booking:view',
        'booking:assign',
        'booking:update',
        'ride:create',
        'ride:view',
        'ride:update',
        'user:create',
        'user:view',
        'user:update',
        'user:delete',
      ],
    ),
    'fleet@example.com': MockUser(
      id: 2,
      email: 'fleet@example.com',
      password: 'fleet123',
      fullName: 'Fleet Administrator',
      role: 'Fleet Admin',
      permissions: [
        // Fleet Admin permissions
        'vehicle:create',
        'vehicle:review',
        'vehicle:approve',
        'vehicle:logs',
        'vehicle:view',
        'vehicle:assign',
        'dashboard:view',
        'ticket:create',
        'ticket:view',
        'ticket:update',
        'notifications:manage',
        'reports:view',
        'customer:view',
        'booking:view',
        'booking:assign',
        'booking:update',
        'ride:view',
      ],
    ),
    'driver@example.com': MockUser(
      id: 3,
      email: 'driver@example.com',
      password: 'driver123',
      fullName: 'Driver Administrator',
      role: 'Driver Admin',
      permissions: [
        // Driver Admin permissions
        'driver:create',
        'driver:verify',
        'driver:train',
        'driver:approve',
        'driver:view',
        'driver:assign',
        'driver:edit',
        'driver:delete',
        'driver:logs',
        'vehicle:assign',
        'dashboard:view',
        'ticket:create',
        'ticket:view',
        'ticket:update',
        'customer:view',
        'booking:view',
        'booking:assign',
        'booking:update',
        'ride:create',
        'ride:view',
        'ride:update',
      ],
    ),
  };

  /// Mock login - validates credentials and returns user info
  static Future<(String accessToken, String refreshToken, UserInfo user)>
      login({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final user = _users[email.toLowerCase().trim()];

    if (user == null || user.password != password) {
      throw Exception('Invalid credentials');
    }

    // Generate mock tokens
    final accessToken =
        'mock_access_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
    final refreshToken =
        'mock_refresh_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';

    final userInfo = UserInfo(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      permissions: user.permissions,
    );

    return (accessToken, refreshToken, userInfo);
  }

  /// Get user by access token (for session restoration)
  static Future<UserInfo?> getUserByToken(String accessToken) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Extract user ID from mock token (format: mock_access_token_{id}_{timestamp})
    try {
      final parts = accessToken.split('_');
      if (parts.length >= 3 &&
          parts[0] == 'mock' &&
          parts[1] == 'access' &&
          parts[2] == 'token') {
        final userId = int.parse(parts[3]);
        final user = _users.values.firstWhere((u) => u.id == userId);
        return UserInfo(
          id: user.id,
          email: user.email,
          fullName: user.fullName,
          role: user.role,
          permissions: user.permissions,
        );
      }
    } catch (_) {
      // Invalid token format
    }
    return null;
  }
}

class MockUser {
  final int id;
  final String email;
  final String password;
  final String? fullName;
  final String role;
  final List<String> permissions;

  MockUser({
    required this.id,
    required this.email,
    required this.password,
    this.fullName,
    required this.role,
    required this.permissions,
  });
}
