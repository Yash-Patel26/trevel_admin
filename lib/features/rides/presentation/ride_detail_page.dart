import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/rides_repository.dart';

final rideDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, rideId) async {
  final repo = ref.watch(ridesRepositoryProvider);
  return await repo.getRide(rideId);
});

class RideDetailPage extends ConsumerWidget {
  final int rideId;

  const RideDetailPage({super.key, required this.rideId});

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'canceled':
        return 'Canceled';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTimeStr;
    }
  }

  String _formatDuration(String? startStr, String? endStr) {
    if (startStr == null || endStr == null) return 'N/A';
    try {
      final start = DateTime.parse(startStr);
      final end = DateTime.parse(endStr);
      final duration = end.difference(start);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${minutes}m';
    } catch (_) {
      return 'N/A';
    }
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideAsync = ref.watch(rideDetailProvider(rideId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
      ),
      body: rideAsync.when(
        data: (ride) {
          final status = ride['status'] as String? ?? 'unknown';
          final statusColor = _getStatusColor(status);
          final vehicle = ride['vehicle'] as Map<String, dynamic>?;
          final driver = ride['driver'] as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            color: statusColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ride #${ride['id']}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Chip(
                                label: Text(_getStatusDisplayName(status)),
                                backgroundColor: statusColor.withValues(alpha: 0.1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ride Information
                _buildDetailCard(
                  context,
                  title: 'Ride Information',
                  children: [
                    _buildDetailRow(
                      context,
                      'Ride ID',
                      ride['id'].toString(),
                    ),
                    _buildDetailRow(
                      context,
                      'Status',
                      _getStatusDisplayName(status),
                    ),
                    _buildDetailRow(
                      context,
                      'Started At',
                      _formatDateTime(ride['startedAt']?.toString()),
                    ),
                    _buildDetailRow(
                      context,
                      'Ended At',
                      _formatDateTime(ride['endedAt']?.toString()),
                    ),
                    _buildDetailRow(
                      context,
                      'Duration',
                      _formatDuration(
                        ride['startedAt']?.toString(),
                        ride['endedAt']?.toString(),
                      ),
                    ),
                    if (ride['distanceKm'] != null)
                      _buildDetailRow(
                        context,
                        'Distance',
                        '${ride['distanceKm']} km',
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Vehicle Information
                if (vehicle != null)
                  _buildDetailCard(
                    context,
                    title: 'Vehicle Information',
                    children: [
                      _buildDetailRow(
                        context,
                        'Number Plate',
                        vehicle['numberPlate']?.toString() ?? 'N/A',
                      ),
                      if (vehicle['make'] != null)
                        _buildDetailRow(
                          context,
                          'Make',
                          vehicle['make'].toString(),
                        ),
                      if (vehicle['model'] != null)
                        _buildDetailRow(
                          context,
                          'Model',
                          vehicle['model'].toString(),
                        ),
                    ],
                  ),
                if (vehicle != null) const SizedBox(height: 16),

                // Driver Information
                if (driver != null)
                  _buildDetailCard(
                    context,
                    title: 'Driver Information',
                    children: [
                      _buildDetailRow(
                        context,
                        'Name',
                        driver['name']?.toString() ?? 'N/A',
                      ),
                      if (driver['mobile'] != null)
                        _buildDetailRow(
                          context,
                          'Mobile',
                          driver['mobile'].toString(),
                        ),
                      if (driver['email'] != null)
                        _buildDetailRow(
                          context,
                          'Email',
                          driver['email'].toString(),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Scaffold(
          appBar: AppBar(
            title: const Text('Ride Details'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading ride details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
