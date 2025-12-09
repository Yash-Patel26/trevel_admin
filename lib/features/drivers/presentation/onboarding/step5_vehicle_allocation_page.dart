import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../vehicles/data/vehicles_repository.dart';
import '../../../vehicles/data/vehicle_model.dart';
import '../../../vehicles/data/vehicle_makes_models.dart';
import '../../data/driver_onboarding_state.dart';

class Step5VehicleAllocationPage extends ConsumerStatefulWidget {
  const Step5VehicleAllocationPage({super.key});

  @override
  ConsumerState<Step5VehicleAllocationPage> createState() =>
      _Step5VehicleAllocationPageState();
}

class _Step5VehicleAllocationPageState
    extends ConsumerState<Step5VehicleAllocationPage> {
  String? _selectedMake;
  List<Vehicle> _availableVehicles = [];
  Vehicle? _selectedVehicle;
  bool _isLoadingMakes = false;
  bool _isLoadingVehicles = false;
  VehicleMakesModels? _makesAndModels;

  @override
  void initState() {
    super.initState();
    _loadMakes();
  }

  Future<void> _loadMakes() async {
    setState(() => _isLoadingMakes = true);
    try {
      final repo = ref.read(vehiclesRepositoryProvider);
      final data = await repo.getMakesAndModels();
      setState(() {
        _makesAndModels = VehicleMakesModels(data);
        _isLoadingMakes = false;
      });
    } catch (e) {
      setState(() => _isLoadingMakes = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load vehicle makes: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _loadAvailableVehicles() async {
    if (_selectedMake == null) return;

    setState(() => _isLoadingVehicles = true);
    try {
      final state = ref.read(driverOnboardingStateProvider);
      final repo = ref.read(vehiclesRepositoryProvider);
      final vehicles = await repo.getAvailableVehicles(
        make: _selectedMake,
        shiftTiming: state.shiftTiming,
      );
      setState(() {
        _availableVehicles = vehicles;
        _isLoadingVehicles = false;
        // Reset selected vehicle if it's not in the new list
        if (_selectedVehicle != null &&
            !vehicles.any((v) => v.id == _selectedVehicle!.id)) {
          _selectedVehicle = null;
        }
      });
    } catch (e) {
      setState(() => _isLoadingVehicles = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load available vehicles: ${e.toString()}'),
          ),
        );
      }
    }
  }

  void _continueToNextStep() {
    // Vehicle selection is optional now
    // if (_selectedVehicle == null) { ... }

    // Update state with selected vehicle
    ref
        .read(driverOnboardingStateProvider.notifier)
        .updateAssignedVehicle(_selectedVehicle?.id);

    // Navigate to next step
    if (mounted) {
      context.push('/drivers/onboard/step6');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverOnboardingStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboard Driver - Step 5 of 7'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 5 / 7,
            backgroundColor: Colors.grey[300],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Allocation',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a vehicle for this driver based on shift timing',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            // Shift Timing Info
            if (state.shiftTiming != null)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shift Timing',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                            ),
                            Text(
                              state.shiftTiming!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Vehicle Make Dropdown
            Text(
              'Vehicle Make (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _isLoadingMakes
                ? const Center(child: CircularProgressIndicator())
                : _makesAndModels == null
                    ? const Text(
                        'Failed to load vehicle makes',
                        style: TextStyle(color: Colors.red),
                      )
                    : DropdownButtonFormField<String>(
                        initialValue: _selectedMake,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Vehicle Make',
                          prefixIcon: Icon(Icons.directions_car),
                          border: OutlineInputBorder(),
                        ),
                        items: _makesAndModels!.makes.map((make) {
                          return DropdownMenuItem(
                            value: make,
                            child: Text(make),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMake = value;
                            _selectedVehicle = null;
                            _availableVehicles = [];
                          });
                          if (value != null) {
                            _loadAvailableVehicles();
                          }
                        },
                      ),
            const SizedBox(height: 24),
            // Available Vehicles List
            if (_selectedMake != null) ...[
              Text(
                'Available Vehicles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _isLoadingVehicles
                  ? const Center(child: CircularProgressIndicator())
                  : _availableVehicles.isEmpty
                      ? Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No available vehicles found for $_selectedMake',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        )
                      : Column(
                          children: _availableVehicles.map((vehicle) {
                            final isSelected =
                                _selectedVehicle?.id == vehicle.id;
                            return Card(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : null,
                              child: RadioListTile<Vehicle>(
                                title: Text(vehicle.vehicleNumber),
                                subtitle: Text(
                                  '${vehicle.make} ${vehicle.model}',
                                ),
                                value: vehicle,
                                // ignore: deprecated_member_use
                                groupValue: _selectedVehicle,
                                // ignore: deprecated_member_use
                                onChanged: (value) {
                                  setState(() {
                                    _selectedVehicle = value;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
            ],
            const SizedBox(height: 32),
            // Continue Button
            FilledButton(
              onPressed: _continueToNextStep,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(_selectedVehicle == null
                  ? 'Skip & Continue to Training'
                  : 'Continue to Training'),
            ),
          ],
        ),
      ),
    );
  }
}
