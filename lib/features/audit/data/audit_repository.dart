import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  return AuditRepository(dio);
});

class AuditRepository {
  AuditRepository(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getAuditLogs({
    int? page,
    int? pageSize,
    String? entityType,
    int? actorId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (pageSize != null) queryParams['pageSize'] = pageSize;
    if (entityType != null) queryParams['entityType'] = entityType;
    if (actorId != null) queryParams['actorId'] = actorId;

    final response =
        await _dio.get('/audit-logs', queryParameters: queryParams);
    final data = response.data['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }
}
