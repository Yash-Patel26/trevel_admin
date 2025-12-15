import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/auth/auth_controller.dart';
import '../../drivers/data/drivers_repository.dart';
import '../../drivers/data/driver_model.dart';
import '../data/vehicles_repository.dart';

final driversForAssignmentProvider =
    FutureProvider.autoDispose<List<Driver>>((ref) async {
  final repo = ref.watch(driversRepositoryProvider);
  // Get all approved drivers who can be assigned to vehicles
  return await repo.getDrivers(status: 'approved');
});

class AssignDriverToVehiclePage extends ConsumerStatefulWidget {
  final String vehicleId;

  const AssignDriverToVehiclePage({
    super.key,
    required this.vehicleId,
  });

  @override
  ConsumerState<AssignDriverToVehiclePage> createState() =>
      _AssignDriverToVehiclePageState();
}

class _AssignDriverToVehiclePageState
    extends ConsumerState<AssignDriverToVehiclePage> {
  String? _selectedDriverId;
  bool _isAssigning = false;

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(driversForAssignmentProvider);
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Driver to Vehicle'),
      ),
      body: driversAsync.when(
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
                    'No drivers available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All drivers need to be approved before assignment',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Info banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Select a driver to assign to this vehicle. Each vehicle can have up to 2 drivers.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Drivers list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    final isSelected = _selectedDriverId == driver.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: RadioListTile<String>(
                        value: driver.id,
                        groupValue: _selectedDriverId,
                        onChanged: (value) {
                          setState(() {
                            _selectedDriverId = value;
                          });
                        },
                        title: Text(
                          driver.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (driver.mobile.isNotEmpty)
                              Text('Mobile: ${driver.mobile}'),
                            if (driver.email.isNotEmpty)
                              Text('Email: ${driver.email}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    driver.status.displayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: driver.status.color,
                                    ),
                                  ),
                                  backgroundColor:
                                      driver.status.color.withValues(alpha: 0.1),
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
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
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
                        secondary: IconButton(
                          icon: const Icon(Icons.visibility),
                          tooltip: 'View Driver Details',
                          onPressed: () {
                            context.push('/drivers/${driver.id}');
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Assign button
              if (_selectedDriverId != null)
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
                    child: FilledButton.icon(
                      onPressed: _isAssigning ? null : _assignDriver,
                      icon: _isAssigning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isAssigning ? 'Assigning...' : 'Assign Driver'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ),
            ],
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
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(driversForAssignmentProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _assignDriver() async {
    if (_selectedDriverId == null) return;

    setState(() => _isAssigning = true);

    try {
      final vehiclesRepo = ref.read(vehiclesRepositoryProvider);
      await vehiclesRepo.assignDriver(
        vehicleId: widget.vehicleId,
        driverId: _selectedDriverId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver assigned to vehicle successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning driver: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }
}

