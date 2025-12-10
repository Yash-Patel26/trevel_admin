import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/auth/auth_controller.dart';
import '../data/driver_model.dart';
import '../data/drivers_repository.dart';

final driversProvider = FutureProvider.autoDispose<List<Driver>>((ref) async {
  final repo = ref.watch(driversRepositoryProvider);
  return await repo.getDrivers();
});

class DriversPage extends ConsumerWidget {
  const DriversPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(driversProvider);
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final canCreate = user?.hasPermission('driver:create') == true;
    final isDriverIndividual = user?.role == 'Driver Individual';
    final isTeam = user?.role == 'Team';

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDriverIndividual)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTeam ? 'Driver Requests' : 'Drivers',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (isTeam)
                          Text(
                            'Review and verify drivers created by Driver Individual users',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                      ],
                    ),
                  ),
                  if (canCreate)
                    FilledButton.icon(
                      onPressed: () => context.push('/drivers/create'),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Onboard Driver'),
                    ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(driversProvider);
              },
              child: driversAsync.when(
                data: (drivers) {
                  if (drivers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No drivers yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Onboard your first driver to get started',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          if (canCreate)
                            FilledButton.icon(
                              onPressed: () => context.push('/drivers/create'),
                              icon: const Icon(Icons.person_add),
                              label: const Text('Onboard Driver'),
                            ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: drivers.length,
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: driver.profileImageUrl != null &&
                                  driver.profileImageUrl!.isNotEmpty
                              ? CircleAvatar(
                                  backgroundColor: driver.status.color
                                      .withValues(alpha: 0.1),
                                  backgroundImage:
                                      NetworkImage(driver.profileImageUrl!),
                                  onBackgroundImageError:
                                      (exception, stackTrace) {
                                    // Image failed to load, will show fallback icon
                                  },
                                  child: Icon(
                                    Icons.person,
                                    color: driver.status.color,
                                  ),
                                )
                              : CircleAvatar(
                                  backgroundColor: driver.status.color
                                      .withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.person,
                                    color: driver.status.color,
                                  ),
                                ),
                          title: Text(
                            driver.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(driver.email),
                              const SizedBox(height: 4),
                              Text(
                                'Mobile: ${driver.mobile}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      driver.status.displayName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: driver.status.color,
                                      ),
                                    ),
                                    backgroundColor: driver.status.color
                                        .withValues(alpha: 0.1),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  if (driver.assignedVehicleNumber != null) ...[
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(
                                        'Vehicle: ${driver.assignedVehicleNumber}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing:
                              isTeam && driver.status == DriverStatus.pending
                                  ? FilledButton(
                                      onPressed: () {
                                        context.push('/drivers/${driver.id}');
                                      },
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                      ),
                                      child: const Text('Review'),
                                    )
                                  : const Icon(Icons.chevron_right),
                          onTap: () {
                            context.push('/drivers/${driver.id}');
                          },
                        ),
                      );
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
                      Text('Error loading drivers'),
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
            ),
          ),
        ],
      ),
    );
  }
}
