import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../drivers/data/drivers_repository.dart';
import '../../vehicles/data/vehicles_repository.dart';
import '../data/bookings_repository.dart';

class AssignBookingDialog extends ConsumerStatefulWidget {
  final String bookingId;
  final VoidCallback onSuccess;

  const AssignBookingDialog({
    super.key,
    required this.bookingId,
    required this.onSuccess,
  });

  @override
  ConsumerState<AssignBookingDialog> createState() => _AssignBookingDialogState();
}

class _AssignBookingDialogState extends ConsumerState<AssignBookingDialog> {
  String? _selectedVehicleId;
  String? _selectedDriverId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(allVehiclesProvider);
    final driversAsync = ref.watch(allDriversProvider);

    return AlertDialog(
      title: const Text('Assign Booking'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Vehicle'),
            const SizedBox(height: 8),
            vehiclesAsync.when(
              data: (vehicles) => DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Choose Vehicle'),
                value: _selectedVehicleId,
                items: vehicles.where((v) => v.status != 'maintenance').map((vehicle) {
                  return DropdownMenuItem<String>(
                    value: vehicle.id,
                    child: Text('${vehicle.make} ${vehicle.model} (${vehicle.vehicleNumber})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedVehicleId = value);
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
            ),
            const SizedBox(height: 16),
            const Text('Select Driver'),
            const SizedBox(height: 8),
            driversAsync.when(
              data: (drivers) => DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Choose Driver'),
                value: _selectedDriverId,
                items: drivers.where((d) => d.status == 'approved').map((driver) {
                  return DropdownMenuItem<String>(
                    value: driver.id,
                    child: Text('${driver.fullName} (${driver.mobile})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedDriverId = value);
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => Text('Error: $err'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_selectedVehicleId == null && _selectedDriverId == null) || _isLoading
              ? null
              : _assign,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }

  Future<void> _assign() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedVehicleId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a vehicle')),
        );
        return;
      }

      await ref.read(bookingsRepositoryProvider).assignBooking(
            bookingId: widget.bookingId,
            vehicleId: _selectedVehicleId!,
            driverId: _selectedDriverId,
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking assigned successfully')),
        );
        widget.onSuccess();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// Providers for fetching lists
final allVehiclesProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(vehiclesRepositoryProvider);
  return repo.getVehicles(); 
});

final allDriversProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(driversRepositoryProvider);
  return repo.getDrivers();
});
