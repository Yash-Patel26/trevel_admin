import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/customers_repository.dart';
import '../data/customer_model.dart';

// Providers
final customerStatsProvider = FutureProvider.autoDispose<CustomerStats>((ref) async {
  final repo = ref.watch(customersRepositoryProvider);
  return await repo.getDashboardStats();
});

final customersProvider = FutureProvider.autoDispose
    .family<List<Customer>, ({int? page, int? pageSize, String? search, String? status})>((ref, params) async {
  final repo = ref.watch(customersRepositoryProvider);
  return await repo.getCustomers(
    page: params.page,
    pageSize: params.pageSize,
    search: params.search,
    status: params.status,
  );
});

class CustomersDashboardPage extends ConsumerStatefulWidget {
  const CustomersDashboardPage({super.key});

  @override
  ConsumerState<CustomersDashboardPage> createState() =>
      _CustomersDashboardPageState();
}

class _CustomersDashboardPageState
    extends ConsumerState<CustomersDashboardPage> {
  String? searchQuery;
  String? statusFilter;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(customerStatsProvider);
    final customersAsync = ref.watch(customersProvider((
      page: null,
      pageSize: null,
      search: searchQuery,
      status: statusFilter,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.push('/customers/create'),
            icon: const Icon(Icons.add),
            label: const Text('Add Customer'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerStatsProvider);
          ref.invalidate(customersProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Cards
              statsAsync.when(
                data: (stats) => _buildKPICards(stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Search and Filter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search customers...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.isEmpty ? null : value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String?>(
                    value: statusFilter,
                    hint: const Text('Status'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                          value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        statusFilter = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Customer List
              customersAsync.when(
                data: (customers) {
                  if (customers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No customers found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return _buildCustomerCard(customer);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Error loading customers'),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICards(CustomerStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            'Total Customers',
            stats.totalCustomers.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            'Total Bookings',
            stats.totalBookings.toString(),
            Icons.book,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            'Upcoming',
            stats.upcomingBookings.toString(),
            Icons.upcoming,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKPICard(
            'Cancelled',
            stats.cancelledBookings.toString(),
            Icons.cancel,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final isActive = customer.status == 'active';

    return Card(
      child: InkWell(
        onTap: () => context.push('/customers/${customer.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: isActive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                child: Icon(
                  Icons.person,
                  size: 32,
                  color: isActive ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      customer.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.mobile,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            customer.status.toUpperCase(),
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${customer.bookingsCount} bookings',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
