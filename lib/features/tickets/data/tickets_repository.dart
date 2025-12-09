import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final ticketsRepositoryProvider = Provider<TicketsRepository>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  return TicketsRepository(dio);
});

class TicketsRepository {
  TicketsRepository(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getTickets({
    int? page,
    int? pageSize,
    String? status,
    String? category,
    int? assignedTo,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (pageSize != null) queryParams['pageSize'] = pageSize;
    if (status != null) queryParams['status'] = status;
    if (category != null) queryParams['category'] = category;
    if (assignedTo != null) queryParams['assignedTo'] = assignedTo;

    final response = await _dio.get('/tickets', queryParameters: queryParams);
    final data = response.data['data'] as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createTicket({
    String? vehicleNumber,
    String? driverName,
    String? driverMobile,
    String? category,
    String? priority,
    String? description,
  }) async {
    final response = await _dio.post('/tickets', data: {
      if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
      if (driverName != null) 'driverName': driverName,
      if (driverMobile != null) 'driverMobile': driverMobile,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (description != null) 'description': description,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTicket({
    required int ticketId,
    String? status,
    int? assignedTo,
    String? resolutionNotes,
  }) async {
    final response = await _dio.patch('/tickets/$ticketId', data: {
      if (status != null) 'status': status,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
    });
    return response.data as Map<String, dynamic>;
  }
}
