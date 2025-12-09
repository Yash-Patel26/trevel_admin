import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  return UsersRepository(dio);
});

class UsersRepository {
  UsersRepository(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getUsers({
    int? page,
    int? pageSize,
    String? search,
    int? roleId,
    bool? isActive,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (pageSize != null) queryParams['pageSize'] = pageSize;
    if (search != null) queryParams['search'] = search;
    if (roleId != null) queryParams['roleId'] = roleId;
    if (isActive != null) queryParams['isActive'] = isActive.toString();

    final response = await _dio.get('/users', queryParameters: queryParams);
    final data = response.data['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getUser(int userId) async {
    final response = await _dio.get('/users/$userId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createUser({
    required String email,
    required String fullName,
    required String password,
    required int roleId,
    bool isActive = true,
  }) async {
    final response = await _dio.post('/users', data: {
      'email': email,
      'fullName': fullName,
      'password': password,
      'roleId': roleId,
      'isActive': isActive,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? email,
    String? fullName,
    String? password,
    int? roleId,
    bool? isActive,
  }) async {
    final data = <String, dynamic>{};
    if (email != null) data['email'] = email;
    if (fullName != null) data['fullName'] = fullName;
    if (password != null) data['password'] = password;
    if (roleId != null) data['roleId'] = roleId;
    if (isActive != null) data['isActive'] = isActive;

    final response = await _dio.patch('/users/$userId', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteUser(int userId) async {
    await _dio.delete('/users/$userId');
  }

  Future<List<Map<String, dynamic>>> getRoles() async {
    final response = await _dio.get('/roles');
    return (response.data as List).cast<Map<String, dynamic>>();
  }
}
