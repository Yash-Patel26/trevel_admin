import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/auth/auth_controller.dart';
import '../data/vehicles_repository.dart';
import '../data/vehicle_model.dart';

final vehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  final repo = ref.watch(vehiclesRepositoryProvider);
  return await repo.getVehicles();
});

class VehiclesPage extends ConsumerWidget {
  const VehiclesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final canApprove = user?.hasPermission('vehicle:review') == true ||
        user?.hasPermission('vehicle:approve') == true;
    final canCreate = user?.hasPermission('vehicle:create') == true;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Vehicles',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (canCreate)
                  FilledButton.icon(
                    onPressed: () => context.push('/vehicles/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Vehicle'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(vehiclesProvider);
              },
              child: vehiclesAsync.when(
                data: (vehicles) {
                  if (vehicles.isEmpty) {
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
                            'No vehicles yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first vehicle to get started',
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
                              onPressed: () => context.push('/vehicles/create'),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Vehicle'),
                            ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  vehicle.status.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: vehicle.status.color,
                            ),
                          ),
                          title: Text(
                            vehicle.vehicleNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${vehicle.make} ${vehicle.model} (${vehicle.year})'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      vehicle.status.displayName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: vehicle.status.color,
                                      ),
                                    ),
                                    backgroundColor: vehicle.status.color
                                        .withValues(alpha: 0.1),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Assign icon button
                              if (user?.hasPermission('vehicle:assign') == true)
                                IconButton(
                                  icon: const Icon(Icons.person_add,
                                      color: Colors.blue),
                                  tooltip: 'Assign Driver',
                                  onPressed: () {
                                    context.push(
                                        '/vehicles/${vehicle.id}/assign-driver');
                                  },
                                ),
                              // View icon button
                              IconButton(
                                icon: const Icon(Icons.visibility,
                                    color: Colors.grey),
                                tooltip: 'View Details',
                                onPressed: () {
                                  context.push('/vehicles/${vehicle.id}');
                                },
                              ),
                              // Status icon button (shows status chip)
                              IconButton(
                                icon: Icon(
                                  _getStatusIcon(vehicle.status),
                                  color: vehicle.status.color,
                                ),
                                tooltip:
                                    'Status: ${vehicle.status.displayName}',
                                onPressed: () {
                                  _showStatusInfo(context, vehicle);
                                },
                              ),
                              // Approve/Reject buttons for pending vehicles
                              if (canApprove &&
                                  vehicle.status == VehicleStatus.pending) ...[
                                IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Colors.green),
                                  tooltip: 'Approve',
                                  onPressed: () => _showQuickApproveDialog(
                                      context, ref, vehicle),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  tooltip: 'Reject',
                                  onPressed: () => _showQuickRejectDialog(
                                      context, ref, vehicle),
                                ),
                              ],
                            ],
                          ),
                          onTap: () {
                            context.push('/vehicles/${vehicle.id}');
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
                      const Text('Error loading vehicles'),
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

  void _showQuickApproveDialog(
      BuildContext context, WidgetRef ref, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Vehicle'),
        content: Text(
          'Are you sure you want to approve ${vehicle.vehicleNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final repo = ref.read(vehiclesRepositoryProvider);
                await repo.reviewVehicle(
                  vehicleId: vehicle.id,
                  status: 'approved',
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  ref.invalidate(vehiclesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vehicle approved successfully'),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showQuickRejectDialog(
      BuildContext context, WidgetRef ref, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Vehicle'),
        content: Text(
          'Are you sure you want to reject ${vehicle.vehicleNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final repo = ref.read(vehiclesRepositoryProvider);
                await repo.reviewVehicle(
                  vehicleId: vehicle.id,
                  status: 'rejected',
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  ref.invalidate(vehiclesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vehicle rejected'),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.pending:
        return Icons.pending;
      case VehicleStatus.active:
        return Icons.check_circle;
      case VehicleStatus.retired:
        return Icons.cancel;
      case VehicleStatus.maintenance:
        return Icons.build;
    }
  }

  void _showStatusInfo(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Vehicle Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle: ${vehicle.vehicleNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Status: ${vehicle.status.displayName}'),
            const SizedBox(height: 8),
            Text('Make: ${vehicle.make}'),
            const SizedBox(height: 8),
            Text('Model: ${vehicle.model}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
