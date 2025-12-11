import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/customers_repository.dart';
import '../data/customer_model.dart';
import '../data/ride_model.dart';

// Providers
final customerDetailProvider = FutureProvider.autoDispose
    .family<Customer, int>((ref, customerId) async {
  final repo = ref.watch(customersRepositoryProvider);
  return await repo.getCustomer(customerId);
});

final customerRidesProvider = FutureProvider.autoDispose
    .family<List<Ride>, int>((ref, customerId) async {
  final repo = ref.watch(customersRepositoryProvider);
  return await repo.getCustomerRides(customerId, limit: 5);
});

class CustomerDetailPage extends ConsumerStatefulWidget {
  final int customerId;

  const CustomerDetailPage({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<CustomerDetailPage> createState() =>
      _CustomerDetailPageState();
}

class _CustomerDetailPageState extends ConsumerState<CustomerDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerDetailProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Rides'),
          ],
        ),
      ),
      body: customerAsync.when(
        data: (customer) => TabBarView(
          controller: _tabController,
          children: [
            _buildProfileTab(customer),
            _buildRidesTab(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading customer'),
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

  Widget _buildProfileTab(Customer customer) {
    final isActive = customer.status == 'active';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    customer.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      customer.status.toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(
                    context,
                    Icons.phone,
                    'Mobile',
                    customer.mobile,
                  ),
                  if (customer.email != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.email,
                      'Email',
                      customer.email!,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.book,
                    'Total Bookings',
                    customer.bookingsCount.toString(),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    Icons.upcoming,
                    'Upcoming Bookings',
                    customer.upcomingBookingsCount.toString(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildRidesTab() {
    final ridesAsync = ref.watch(customerRidesProvider(widget.customerId));

    return ridesAsync.when(
      data: (rides) {
        if (rides.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No rides found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            return _buildRideCard(ride);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error loading rides'),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push(
          '/customers/${widget.customerId}/rides/${ride.id}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ride #${ride.id}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      ride.status.toUpperCase(),
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRideInfoRow(Icons.person, 'Driver', ride.driverName),
              const SizedBox(height: 8),
              _buildRideInfoRow(Icons.car_rental, 'Vehicle', ride.vehicleInfo),
              const SizedBox(height: 8),
              _buildRideInfoRow(
                Icons.access_time,
                'Pickup',
                _formatDateTime(ride.pickupTime),
              ),
              if (ride.dropTime != null) ...[
                const SizedBox(height: 8),
                _buildRideInfoRow(
                  Icons.access_time_filled,
                  'Drop',
                  _formatDateTime(ride.dropTime!),
                ),
              ],
              const SizedBox(height: 8),
              _buildRideInfoRow(
                Icons.location_on,
                'From',
                ride.pickupLocation,
              ),
              const SizedBox(height: 8),
              _buildRideInfoRow(
                Icons.location_on_outlined,
                'To',
                ride.dropLocation,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRideInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }
}
