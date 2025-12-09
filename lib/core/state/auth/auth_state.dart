class AuthState {
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;
  final UserInfo? user;

  const AuthState({
    required this.accessToken,
    required this.refreshToken,
    required this.isLoading,
    this.user,
  });

  bool get isAuthenticated => accessToken != null;

  AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    UserInfo? user,
    bool clearTokens = false,
    bool clearUser = false,
  }) {
    return AuthState(
      accessToken: clearTokens ? null : (accessToken ?? this.accessToken),
      refreshToken: clearTokens ? null : (refreshToken ?? this.refreshToken),
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
    );
  }

  factory AuthState.initial() => const AuthState(
        accessToken: null,
        refreshToken: null,
        isLoading: true,
        user: null,
      );
}

class UserInfo {
  final int id;
  final String email;
  final String? fullName;
  final String role;
  final List<String> permissions;

  const UserInfo({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.permissions,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      role: json['role'] as String,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<String> requiredPermissions) {
    return requiredPermissions.any((p) => permissions.contains(p));
  }

  bool hasAllPermissions(List<String> requiredPermissions) {
    return requiredPermissions.every((p) => permissions.contains(p));
  }
}
