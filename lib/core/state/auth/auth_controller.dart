import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../features/auth/data/mock_auth_service.dart';
import 'auth_state.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = ref.watch(apiClientProvider);
  return AuthController(storage, client)..init();
});

class AuthController extends StateNotifier<AuthState> {
  final TokenStorage _storage;
  final ApiClient _client;
  final _controller = StreamController<AuthState>.broadcast();

  AuthController(this._storage, this._client) : super(AuthState.initial());

  @override
  Stream<AuthState> get stream => _controller.stream;

  Future<void> init() async {
    final (access, refresh) = await _storage.readTokens();
    _client.setAuthToken(access);
    _client.setRefreshToken(refresh);
    _client.setOnTokenExpired(() => logout());
    UserInfo? user;
    if (access != null) {
      try {
        // Use mock auth service to restore user from token
        if (AuthRepository.useMockAuth) {
          user = await MockAuthService.getUserByToken(access);
          if (user == null) {
            // Invalid token, clear it
            await _storage.clearTokens();
            _client.setAuthToken(null);
            _client.setRefreshToken(null);
          }
        } else {
          final repo = AuthRepository(_client.client);
          user = await repo.getCurrentUser();
        }
      } catch (_) {
        // Token might be invalid, clear it
        await _storage.clearTokens();
        _client.setAuthToken(null);
        _client.setRefreshToken(null);
      }
    }
    state = state.copyWith(
      accessToken: access,
      refreshToken: refresh,
      user: user,
      isLoading: false,
    );
    _controller.add(state);
  }

  Future<void> login({
    required String accessToken,
    required String refreshToken,
    required UserInfo user,
  }) async {
    await _storage.saveTokens(
        accessToken: accessToken, refreshToken: refreshToken);
    _client.setAuthToken(accessToken);
    _client.setRefreshToken(refreshToken);
    _client.setOnTokenExpired(() => logout());
    state = state.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      isLoading: false,
    );
    _controller.add(state);
  }

  Future<void> updateAccessToken(String newAccessToken) async {
    await _storage.saveTokens(
        accessToken: newAccessToken, refreshToken: state.refreshToken!);
    _client.setAuthToken(newAccessToken);
    state = state.copyWith(accessToken: newAccessToken);
    _controller.add(state);
  }

  Future<void> logout() async {
    try {
      if (!AuthRepository.useMockAuth && state.refreshToken != null) {
        final repo = AuthRepository(_client.client);
        await repo.logout();
      }
    } catch (_) {
      // Ignore logout errors
    }
    await _storage.clearTokens();
    _client.setAuthToken(null);
    _client.setRefreshToken(null);
    final newState = state.copyWith(
      isLoading: false,
      clearTokens: true,
      clearUser: true,
    );
    state = newState;
    _controller.add(newState);
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
