import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/customers_repository.dart';
import '../data/ride_model.dart';

// Provider
final customerRideDetailProvider = FutureProvider.autoDispose
    .family<RideDetail, int>((ref, rideId) async {
  final repo = ref.watch(customersRepositoryProvider);
  return await repo.getRideDetail(rideId);
});

class CustomerRideDetailPage extends ConsumerWidget {
  final String customerId;
  final int rideId;

  const CustomerRideDetailPage({
    super.key,
    required this.customerId,
    required this.rideId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideAsync = ref.watch(customerRideDetailProvider(rideId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
      ),
      body: rideAsync.when(
        data: (ride) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ride Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Ride #${ride.id}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          Chip(
                            label: Text(
                              ride.status.toUpperCase(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        context,
                        'Created',
                        _formatDateTime(ride.createdAt),
                      ),
                      if (ride.otpCode != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(context, 'OTP Code', ride.otpCode!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Customer Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Information',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(context, 'Name', ride.customerName),
                      const SizedBox(height: 8),
                      _buildInfoRow(context, 'Mobile', ride.customerMobile),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Driver Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver Information',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(context, 'Name', ride.driverName),
                      if (ride.driverMobile.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(context, 'Mobile', ride.driverMobile),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Vehicle Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Information',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(context, 'Model', ride.vehicleInfo),
                      if (ride.vehicleNumberPlate.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                            context, 'Number Plate', ride.vehicleNumberPlate),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pickup Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pickup Information',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        'Time',
                        _formatDateTime(ride.pickupTime),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(context, 'Location', ride.pickupLocation),
                      if (ride.pickupLatitude != null &&
                          ride.pickupLongitude != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          context,
                          'Coordinates',
                          '${ride.pickupLatitude}, ${ride.pickupLongitude}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Drop Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Drop Information',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (ride.dropTime != null) ...[
                        _buildInfoRow(
                          context,
                          'Time',
                          _formatDateTime(ride.dropTime!),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildInfoRow(context, 'Location', ride.dropLocation),
                      if (ride.destinationLatitude != null &&
                          ride.destinationLongitude != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          context,
                          'Coordinates',
                          '${ride.destinationLatitude}, ${ride.destinationLongitude}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading ride details'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }
}
