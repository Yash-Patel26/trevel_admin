import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/bookings_repository.dart';

final bookingDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, bookingId) async {
  final repo = ref.watch(bookingsRepositoryProvider);
  return await repo.getBooking(bookingId);
});

class BookingDetailPage extends ConsumerWidget {
  final String bookingId;

  const BookingDetailPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          IconButton(
            tooltip: 'Edit pickup/drop',
            icon: const Icon(Icons.edit_location_alt),
            onPressed: () async {
              final updated = await context
                  .push<bool>('/bookings/$bookingId/edit-location');
              if (updated == true && context.mounted) {
                ref.invalidate(bookingDetailProvider(bookingId));
              }
            },
          ),
        ],
      ),
      body: bookingAsync.when(
        data: (booking) {
          final customer = booking['customer'] as Map<String, dynamic>?;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                        booking['status'] as String? ??
                                            'upcoming')
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.event_note,
                                color: _getStatusColor(
                                    booking['status'] as String? ?? 'upcoming'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Booking #${booking['id']}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Chip(
                                    label: Text((booking['status'] as String? ??
                                            'upcoming')
                                        .toUpperCase()),
                                    backgroundColor: _getStatusColor(
                                            booking['status'] as String? ??
                                                'upcoming')
                                        .withValues(alpha: 0.1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        if (customer != null) ...[
                          _buildInfoRow(
                              context,
                              'Customer',
                              customer['name']?.toString() ??
                                  customer['email']?.toString() ??
                                  'Unknown'),
                          if (customer['mobile'] != null)
                            _buildInfoRow(context, 'Mobile',
                                customer['mobile'] as String),
                          if (customer['email'] != null)
                            _buildInfoRow(
                                context, 'Email', customer['email'] as String),
                        ],
                        if (booking['pickupLocation'] != null)
                          _buildInfoRow(context, 'Pickup Location',
                              booking['pickupLocation'] as String),
                        if (booking['pickupLatitude'] != null ||
                            booking['pickupLongitude'] != null)
                          _buildInfoRow(
                            context,
                            'Pickup Lat/Lng',
                            '${booking['pickupLatitude'] ?? '-'}, ${booking['pickupLongitude'] ?? '-'}',
                          ),
                        if (booking['destinationLocation'] != null)
                          _buildInfoRow(context, 'Destination',
                              booking['destinationLocation'] as String),
                        if (booking['destinationLatitude'] != null ||
                            booking['destinationLongitude'] != null)
                          _buildInfoRow(
                            context,
                            'Destination Lat/Lng',
                            '${booking['destinationLatitude'] ?? '-'}, ${booking['destinationLongitude'] ?? '-'}',
                          ),
                        if (booking['pickupTime'] != null)
                          _buildInfoRow(context, 'Pickup Time',
                              _formatDateTime(booking['pickupTime'])),
                        if (booking['createdAt'] != null)
                          _buildInfoRow(context, 'Created',
                              _formatDateTime(booking['createdAt'])),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading booking details'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
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
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'today':
        return Colors.orange;
      case 'assigned':
        return Colors.purple;
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

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '';
    try {
      final dt =
          dateTime is String ? DateTime.parse(dateTime) : dateTime as DateTime;
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTime.toString();
    }
  }
}
