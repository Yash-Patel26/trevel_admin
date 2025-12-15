import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/bookings_repository.dart';
import 'assign_booking_dialog.dart';

final bookingTypeProvider = StateProvider.autoDispose<String?>((ref) => null);

final bookingsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(bookingsRepositoryProvider);
  final type = ref.watch(bookingTypeProvider);
  // Default to first page, default size 
  return await repo.getBookings(type: type);
});

class BookingsPage extends ConsumerWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final selectedType = ref.watch(bookingTypeProvider);

    return Scaffold(
      body: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Bookings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              onTap: (index) {
                String? type;
                switch (index) {
                  case 0:
                    type = null; // All
                    break;
                  case 1:
                    type = 'mini-trip';
                    break;
                  case 2:
                    type = 'hourly';
                    break;
                  case 3:
                    type = 'airport';
                    break;
                }
                ref.read(bookingTypeProvider.notifier).state = type;
              },
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Mini Trip'),
                Tab(text: 'Hourly Rental'),
                Tab(text: 'Airport'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(bookingsProvider);
                },
                child: bookingsAsync.when(
                  data: (bookings) {
                    if (bookings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No bookings yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        final status = booking['status'] as String? ?? 'upcoming';
                        final customer =
                            booking['customer'] as Map<String, dynamic>?;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.event_note,
                                    color: _getStatusColor(status),
                                  ),
                                ),
                                title: Text(
                                  customer != null
                                      ? '${customer['name'] ?? customer['email'] ?? 'Customer'}'
                                      : 'Booking #${booking['id']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    if (booking['pickupLocation'] != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.trip_origin,
                                              size: 16, color: Colors.green),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${booking['pickupLocation']}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 4),
                                    if (booking['destinationLocation'] != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 16, color: Colors.red),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${booking['destinationLocation']}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (booking['pickupTime'] != null)
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time,
                                                  size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDateTime(booking['pickupTime']),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        const Spacer(),
                                        Chip(
                                          label: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _getStatusColor(status),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          backgroundColor: _getStatusColor(status)
                                              .withValues(alpha: 0.1),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          side: BorderSide.none,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  context.push('/bookings/${booking['id']}');
                                },
                              ),
                              if (status == 'upcoming' || status == 'pending')
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AssignBookingDialog(
                                              bookingId: booking['id'].toString(),
                                              onSuccess: () {
                                                ref.invalidate(bookingsProvider);
                                              },
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.assignment_ind, size: 18),
                                        label: const Text('Assign'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Error loading bookings'),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () => ref.invalidate(bookingsProvider), 
                          child: const Text('Retry')
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
