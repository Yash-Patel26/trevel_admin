import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/tickets_repository.dart';

final ticketDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, ticketId) async {
  final repo = ref.watch(ticketsRepositoryProvider);
  final tickets = await repo.getTickets();
  return tickets.firstWhere((t) => t['id'] == ticketId);
});

class TicketDetailPage extends ConsumerWidget {
  final int ticketId;

  const TicketDetailPage({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Details'),
      ),
      body: ticketAsync.when(
        data: (ticket) => SingleChildScrollView(
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
                                      ticket['status'] as String? ?? 'open')
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.confirmation_num,
                              color: _getStatusColor(
                                  ticket['status'] as String? ?? 'open'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ticket #${ticket['id']}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(
                                      (ticket['status'] as String? ?? 'open')
                                          .toUpperCase()),
                                  backgroundColor: _getStatusColor(
                                          ticket['status'] as String? ?? 'open')
                                      .withValues(alpha: 0.1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      if (ticket['description'] != null)
                        _buildInfoRow(context, 'Description',
                            ticket['description'] as String),
                      if (ticket['category'] != null)
                        _buildInfoRow(
                            context, 'Category', ticket['category'] as String),
                      if (ticket['priority'] != null)
                        _buildInfoRow(
                            context, 'Priority', ticket['priority'] as String),
                      if (ticket['vehicleNumber'] != null)
                        _buildInfoRow(context, 'Vehicle',
                            ticket['vehicleNumber'] as String),
                      if (ticket['driverName'] != null)
                        _buildInfoRow(
                            context, 'Driver', ticket['driverName'] as String),
                      if (ticket['driverMobile'] != null)
                        _buildInfoRow(context, 'Driver Mobile',
                            ticket['driverMobile'] as String),
                      if (ticket['createdAt'] != null)
                        _buildInfoRow(context, 'Created',
                            _formatDateTime(ticket['createdAt'])),
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
              const Text('Error loading ticket details'),
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
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
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
