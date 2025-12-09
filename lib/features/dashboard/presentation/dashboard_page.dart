import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/auth/auth_controller.dart';
import '../../../core/utils/permissions.dart';
import '../data/dashboards_repository.dart';
import '../../vehicles/data/vehicles_repository.dart';
import '../../vehicles/data/vehicle_model.dart';
import '../../drivers/data/drivers_repository.dart';
import '../../drivers/data/driver_model.dart';
import '../../tickets/data/tickets_repository.dart';
import '../../bookings/data/bookings_repository.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    if (user == null) {
      return const Center(child: Text('Not authenticated'));
    }

    // Determine dashboard type based on role/permissions
    final isOperationalAdmin = user.role == 'Operational Admin';
    final isFleetAdmin =
        user.role == 'Fleet Admin' || PermissionChecker.canAccessVehicles(user);
    final isDriverAdmin =
        user.role == 'Driver Admin' || PermissionChecker.canAccessDrivers(user);

    // Fetch dashboard data
    final fleetDashboardAsync = ref.watch(fleetDashboardProvider);
    final vehiclesAsync = ref.watch(dashboardVehiclesProvider);
    final driversAsync = ref.watch(dashboardDriversProvider);
    final ticketsAsync = ref.watch(ticketsProvider);
    final bookingsSummaryAsync = ref.watch(bookingsSummaryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOperationalAdmin) ...[
            _buildSectionTitle(context, 'Operational Overview'),
            const SizedBox(height: 16),
            _buildOperationalStats(context, ref, vehiclesAsync, driversAsync,
                ticketsAsync, bookingsSummaryAsync),
          ] else if (isFleetAdmin) ...[
            _buildSectionTitle(context, 'Fleet Management Dashboard'),
            const SizedBox(height: 16),
            _buildFleetStats(
                context, ref, fleetDashboardAsync, vehiclesAsync, ticketsAsync),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Quick Actions'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (user.hasPermission('vehicle:create'))
                  _ActionChip(
                    label: 'Add Vehicle',
                    icon: Icons.add,
                    onTap: () => context.push('/vehicles/create'),
                  ),
                if (user.hasPermission('vehicle:review'))
                  _ActionChip(
                    label: 'Review Vehicles',
                    icon: Icons.rate_review,
                    onTap: () => context.push('/vehicles'),
                  ),
                if (user.hasPermission('ticket:view'))
                  _ActionChip(
                    label: 'View Tickets',
                    icon: Icons.confirmation_num,
                    onTap: () => context.push('/tickets'),
                  ),
              ],
            ),
          ] else if (isDriverAdmin) ...[
            _buildSectionTitle(context, 'Driver Management Dashboard'),
            const SizedBox(height: 16),
            _buildDriverStats(context, ref, driversAsync),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Quick Actions'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (user.hasPermission('driver:create'))
                  _ActionChip(
                    label: 'Add Driver',
                    icon: Icons.person_add,
                    onTap: () => context.push('/drivers/create'),
                  ),
                if (user.hasPermission('driver:verify'))
                  _ActionChip(
                    label: 'Verify Background',
                    icon: Icons.verified_user,
                    onTap: () => context.push('/drivers'),
                  ),
                if (user.hasPermission('driver:train'))
                  _ActionChip(
                    label: 'Assign Training',
                    icon: Icons.school,
                    onTap: () => context.push('/drivers'),
                  ),
              ],
            ),
          ] else ...[
            _buildSectionTitle(context, 'Dashboard'),
            const SizedBox(height: 16),
            const Text('Welcome! Select a section from the navigation menu.'),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, List<_StatCard> stats) {
    // Responsive grid: more columns on larger screens
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 4
        : screenWidth > 800
            ? 3
            : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1, // Wider cards for better proportions
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: stat.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(stat.icon, color: stat.color, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  stat.value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  stat.label,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOperationalStats(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Vehicle>> vehiclesAsync,
    AsyncValue<List<Driver>> driversAsync,
    AsyncValue<List<Map<String, dynamic>>> ticketsAsync,
    AsyncValue<Map<String, dynamic>> bookingsSummaryAsync,
  ) {
    return vehiclesAsync.when(
      data: (vehicles) => driversAsync.when(
        data: (drivers) => ticketsAsync.when(
          data: (tickets) => bookingsSummaryAsync.when(
            data: (summary) => _buildStatsGrid(context, [
              _StatCard('Total Vehicles', vehicles.length.toString(),
                  Icons.directions_car, Colors.blue),
              _StatCard('Total Drivers', drivers.length.toString(),
                  Icons.person, Colors.green),
              _StatCard(
                  'Active Tickets',
                  tickets
                      .where((t) =>
                          t['status'] == 'open' || t['status'] == 'in_progress')
                      .length
                      .toString(),
                  Icons.confirmation_num,
                  Colors.orange),
              _StatCard(
                  'Total Bookings',
                  (summary['totalBookings'] ?? 0).toString(),
                  Icons.event_note,
                  Colors.purple),
            ]),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildStatsGrid(context, [
              _StatCard('Total Vehicles', vehicles.length.toString(),
                  Icons.directions_car, Colors.blue),
              _StatCard('Total Drivers', drivers.length.toString(),
                  Icons.person, Colors.green),
              _StatCard(
                  'Active Tickets',
                  tickets
                      .where((t) =>
                          t['status'] == 'open' || t['status'] == 'in_progress')
                      .length
                      .toString(),
                  Icons.confirmation_num,
                  Colors.orange),
              _StatCard('Total Bookings', '0', Icons.event_note, Colors.purple),
            ]),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildStatsGrid(context, [
            _StatCard('Total Vehicles', vehicles.length.toString(),
                Icons.directions_car, Colors.blue),
            _StatCard('Total Drivers', drivers.length.toString(), Icons.person,
                Colors.green),
            _StatCard(
                'Active Tickets', '0', Icons.confirmation_num, Colors.orange),
            _StatCard('Total Bookings', '0', Icons.event_note, Colors.purple),
          ]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildStatsGrid(context, [
          _StatCard('Total Vehicles', vehicles.length.toString(),
              Icons.directions_car, Colors.blue),
          _StatCard('Total Drivers', '0', Icons.person, Colors.green),
          _StatCard(
              'Active Tickets', '0', Icons.confirmation_num, Colors.orange),
          _StatCard('Total Bookings', '0', Icons.event_note, Colors.purple),
        ]),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildStatsGrid(context, [
        _StatCard('Total Vehicles', '0', Icons.directions_car, Colors.blue),
        _StatCard('Total Drivers', '0', Icons.person, Colors.green),
        _StatCard('Active Tickets', '0', Icons.confirmation_num, Colors.orange),
        _StatCard('Total Bookings', '0', Icons.event_note, Colors.purple),
      ]),
    );
  }

  Widget _buildFleetStats(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, dynamic>> fleetDashboardAsync,
    AsyncValue<List<Vehicle>> vehiclesAsync,
    AsyncValue<List<Map<String, dynamic>>> ticketsAsync,
  ) {
    return fleetDashboardAsync.when(
      data: (fleetData) => vehiclesAsync.when(
        data: (vehicles) => ticketsAsync.when(
          data: (tickets) => _buildStatsGrid(context, [
            _StatCard(
                'Total Vehicles',
                (fleetData['totalVehicles'] ?? vehicles.length).toString(),
                Icons.directions_car,
                Colors.blue),
            _StatCard(
                'Active Vehicles',
                (fleetData['activeVehicles'] ??
                        vehicles
                            .where((v) => v.status == VehicleStatus.active)
                            .length)
                    .toString(),
                Icons.check_circle,
                Colors.green),
            _StatCard(
                'Pending Reviews',
                vehicles
                    .where((v) => v.status == VehicleStatus.pending)
                    .length
                    .toString(),
                Icons.pending,
                Colors.orange),
            _StatCard(
                'Open Tickets',
                tickets.where((t) => t['status'] == 'open').length.toString(),
                Icons.confirmation_num,
                Colors.red),
          ]),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildStatsGrid(context, [
            _StatCard(
                'Total Vehicles',
                (fleetData['totalVehicles'] ?? vehicles.length).toString(),
                Icons.directions_car,
                Colors.blue),
            _StatCard(
                'Active Vehicles',
                (fleetData['activeVehicles'] ??
                        vehicles
                            .where((v) => v.status == VehicleStatus.active)
                            .length)
                    .toString(),
                Icons.check_circle,
                Colors.green),
            _StatCard(
                'Pending Reviews',
                vehicles
                    .where((v) => v.status == VehicleStatus.pending)
                    .length
                    .toString(),
                Icons.pending,
                Colors.orange),
            _StatCard('Open Tickets', '0', Icons.confirmation_num, Colors.red),
          ]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildStatsGrid(context, [
          _StatCard(
              'Total Vehicles',
              (fleetData['totalVehicles'] ?? 0).toString(),
              Icons.directions_car,
              Colors.blue),
          _StatCard(
              'Active Vehicles',
              (fleetData['activeVehicles'] ?? 0).toString(),
              Icons.check_circle,
              Colors.green),
          _StatCard('Pending Reviews', '0', Icons.pending, Colors.orange),
          _StatCard('Open Tickets', '0', Icons.confirmation_num, Colors.red),
        ]),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildStatsGrid(context, [
        _StatCard('Total Vehicles', '0', Icons.directions_car, Colors.blue),
        _StatCard('Active Vehicles', '0', Icons.check_circle, Colors.green),
        _StatCard('Pending Reviews', '0', Icons.pending, Colors.orange),
        _StatCard('Open Tickets', '0', Icons.confirmation_num, Colors.red),
      ]),
    );
  }

  Widget _buildDriverStats(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Driver>> driversAsync,
  ) {
    return driversAsync.when(
      data: (drivers) => _buildStatsGrid(context, [
        _StatCard('Total Drivers', drivers.length.toString(), Icons.person,
            Colors.green),
        _StatCard(
            'Pending Approval',
            drivers
                .where((d) => d.status == DriverStatus.pending)
                .length
                .toString(),
            Icons.pending,
            Colors.orange),
        _StatCard(
            'In Training',
            drivers.where((d) => !d.trainingCompleted).length.toString(),
            Icons.school,
            Colors.blue),
        _StatCard(
            'Active Drivers',
            drivers
                .where((d) =>
                    d.status == DriverStatus.active ||
                    d.status == DriverStatus.approved)
                .length
                .toString(),
            Icons.check_circle,
            Colors.green),
      ]),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildStatsGrid(context, [
        _StatCard('Total Drivers', '0', Icons.person, Colors.green),
        _StatCard('Pending Approval', '0', Icons.pending, Colors.orange),
        _StatCard('In Training', '0', Icons.school, Colors.blue),
        _StatCard('Active Drivers', '0', Icons.check_circle, Colors.green),
      ]),
    );
  }
}

// Providers for dashboard data
final fleetDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(dashboardsRepositoryProvider);
  return await repo.getFleetDashboard();
});

final ticketsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(ticketsRepositoryProvider);
  return await repo.getTickets();
});

final dashboardVehiclesProvider =
    FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  final repo = ref.watch(vehiclesRepositoryProvider);
  return await repo.getVehicles();
});

final dashboardDriversProvider =
    FutureProvider.autoDispose<List<Driver>>((ref) async {
  final repo = ref.watch(driversRepositoryProvider);
  return await repo.getDrivers();
});

final bookingsSummaryProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(bookingsRepositoryProvider);
  return await repo.getBookingSummary();
});

class _StatCard {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatCard(this.label, this.value, this.icon, this.color);
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
