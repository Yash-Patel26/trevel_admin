import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'customer_model.dart';
import 'ride_model.dart';

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  return CustomersRepository(dio);
});

class CustomersRepository {
  CustomersRepository(this._dio);

  final Dio _dio;

  Future<CustomerStats> getDashboardStats() async {
    final response = await _dio.get('/customers/stats');
    return CustomerStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Customer>> getCustomers({
    int? page,
    int? pageSize,
    String? search,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (pageSize != null) queryParams['pageSize'] = pageSize;
    if (search != null) queryParams['search'] = search;
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get('/customers', queryParameters: queryParams);
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => Customer.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Customer> getCustomer(int id) async {
    final response = await _dio.get('/customers/$id');
    return Customer.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Ride>> getCustomerRides(int customerId, {int limit = 5}) async {
    final response = await _dio.get(
      '/customers/$customerId/rides',
      queryParameters: {'limit': limit},
    );
    final data = response.data as List<dynamic>;
    return data.map((json) => Ride.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<RideDetail> getRideDetail(int rideId) async {
    final response = await _dio.get('/rides/$rideId');
    return RideDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    final response = await _dio.post('/customers', data: data);
    return Customer.fromJson(response.data as Map<String, dynamic>);
  }
}
