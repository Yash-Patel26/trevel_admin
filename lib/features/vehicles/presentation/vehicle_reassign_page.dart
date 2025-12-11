import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../drivers/data/drivers_repository.dart';
import '../../drivers/data/driver_model.dart';
import '../data/vehicles_repository.dart';
import '../data/vehicle_model.dart';

// Provider to fetch active drivers for reassignment
final activeDriversProvider = FutureProvider.autoDispose<List<Driver>>((ref) async {
  final repo = ref.watch(driversRepositoryProvider);
  final allDrivers = await repo.getDrivers();
  // Filter only active/approved drivers
  return allDrivers.where((driver) => 
    driver.status == DriverStatus.active || 
    driver.status == DriverStatus.approved
  ).toList();
});

class VehicleReassignPage extends ConsumerStatefulWidget {
  final int vehicleId;
  final Vehicle vehicle;

  const VehicleReassignPage({
    super.key,
    required this.vehicleId,
    required this.vehicle,
  });

  @override
  ConsumerState<VehicleReassignPage> createState() => _VehicleReassignPageState();
}

class _VehicleReassignPageState extends ConsumerState<VehicleReassignPage> {
  int? selectedDriverId;
  bool isReassigning = false;

  Future<void> _handleReassignment() async {
    if (selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a driver'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reassignment'),
        content: const Text(
          'Are you sure you want to reassign this vehicle to the selected driver?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => isReassigning = true);

    try {
      final repo = ref.read(vehiclesRepositoryProvider);
      await repo.reassignVehicle(
        vehicleId: widget.vehicleId,
        newDriverId: selectedDriverId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle reassigned successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reassigning vehicle: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isReassigning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(activeDriversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reassign Vehicle'),
      ),
      body: Column(
        children: [
          // Current Assignment Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Current Driver Inactive',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Vehicle: ${widget.vehicle.vehicleNumber}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                if (widget.vehicle.assignedDriverName != null)
                  Text(
                    'Current Driver: ${widget.vehicle.assignedDriverName} (${widget.vehicle.assignedDriverStatus})',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
              ],
            ),
          ),
          
          // Driver Selection List
          Expanded(
            child: driversAsync.when(
              data: (drivers) {
                if (drivers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No active drivers available',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please ensure drivers are approved and active',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    final isSelected = selectedDriverId == driver.id;
                    final isCurrentDriver = driver.id == widget.vehicle.assignedDriverId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isSelected ? 4 : 1,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        enabled: !isCurrentDriver,
                        leading: CircleAvatar(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : driver.status.color.withValues(alpha: 0.1),
                          child: driver.profileImageUrl != null &&
                                  driver.profileImageUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    driver.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.onPrimary
                                          : driver.status.color,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : driver.status.color,
                                ),
                        ),
                        title: Text(
                          driver.fullName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driver.mobile),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    driver.status.displayName,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor:
                                      driver.status.color.withValues(alpha: 0.1),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                                if (isCurrentDriver) ...[
                                  const SizedBox(width: 8),
                                  const Chip(
                                    label: Text(
                                      'Current',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: Colors.grey,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : isCurrentDriver
                                ? null
                                : const Icon(Icons.radio_button_unchecked),
                        onTap: isCurrentDriver
                            ? null
                            : () {
                                setState(() {
                                  selectedDriverId = driver.id;
                                });
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
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Error loading drivers'),
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

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isReassigning ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: isReassigning || selectedDriverId == null
                          ? null
                          : _handleReassignment,
                      icon: isReassigning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.swap_horiz),
                      label: Text(isReassigning ? 'Reassigning...' : 'Reassign Vehicle'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
