import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../drivers/data/drivers_repository.dart';
import '../../drivers/data/driver_model.dart';
import '../../vehicles/data/vehicles_repository.dart';
import '../../vehicles/data/vehicle_model.dart';
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
                items: vehicles.where((v) => v.status != VehicleStatus.maintenance).map((vehicle) {
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
                items: drivers.where((d) => 
                  d.status != DriverStatus.rejected && 
                  d.status != DriverStatus.suspended &&
                  d.status != DriverStatus.pending
                ).map((driver) {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a vehicle')),
          );
        }
        return;
      }

      final bookingsRepo = ref.read(bookingsRepositoryProvider);
      
      // 1. Assign the booking
      await bookingsRepo.assignBooking(
        bookingId: widget.bookingId,
        vehicleId: _selectedVehicleId!,
        driverId: _selectedDriverId,
      );

      if (!mounted) return;

      // 2. Fetch updated booking details to get customer info & locations
      final booking = await bookingsRepo.getBooking(widget.bookingId);
      
      // 3. Find the driver to notify
      // If we selected a driver, use that. 
      // If not, checked the assigned vehicle's driver? 
      // For now, prompt mentioned "driver of that particular vehicle". 
      // We'll rely on the manual selection or look it up if we can.
      // If _selectedDriverId is null, we might need to find who is assigned to the vehicle.
      // However, the backend assignment logic might not auto-assign driver if we pass null.
      // But assuming we have a driverId now (either selected or from vehicle):
      
      String? targetDriverId = _selectedDriverId;
      // If no driver selected, try to find driver from the vehicle
      if (targetDriverId == null) {
         final vehicleList = ref.read(allVehiclesProvider).asData?.value ?? [];
         final vehicle = vehicleList.firstWhere(
           (v) => v.id == _selectedVehicleId, 
           orElse: () => Vehicle(
             id: '', vehicleNumber: '', make: '', model: '', year: 0, 
             licensePlate: '', status: VehicleStatus.active, createdAt: DateTime.now()
           ) // Dummy fallback
         );
         // If vehicle has an assigned driver, use that
         if (vehicle.assignedDriverId != null) {
           targetDriverId = vehicle.assignedDriverId;
         }
      }

      if (targetDriverId != null) {
         await _shareOnWhatsApp(booking, targetDriverId);
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking assigned, but no driver found to notify via WhatsApp')),
          );
        }
      }
      
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

  Future<void> _shareOnWhatsApp(Map<String, dynamic> booking, String driverId) async {
    try {
      // Find driver mobile
      final driversList = ref.read(allDriversProvider).asData?.value ?? [];
      final driver = driversList.firstWhere(
        (d) => d.id == driverId,
        orElse: () => Driver(
           id: '', fullName: '', email: '', mobile: '', status: DriverStatus.pending, createdAt: DateTime.now()
        ) // Dummy fallback
      );

      if (driver.mobile.isEmpty) {
        debugPrint('Driver mobile not found for ID: $driverId');
        return;
      }

      final customer = booking['customer'] ?? {};
      final customerName = customer['name'] ?? customer['fullName'] ?? 'Customer';
      final customerMobile = customer['mobile'] ?? 'N/A';
      
      final pickup = booking['pickupLocation'] ?? 'N/A';
      final drop = booking['destinationLocation'] ?? 'N/A';
      
      // Formatting date/time
      // booking['pickupTime'] comes as string from API usually if it's JSON
      // But repo.getBooking returns Map which might have String for DateTime
      final pickupTimeStr = booking['pickupTime']?.toString() ?? DateTime.now().toString();
      
      // Google Maps Links
      final pickupEncoded = Uri.encodeComponent(pickup);
      final dropEncoded = Uri.encodeComponent(drop);
      final pickupMapLink = 'https://www.google.com/maps/search/?api=1&query=$pickupEncoded';
      final dropMapLink = 'https://www.google.com/maps/search/?api=1&query=$dropEncoded';

      final message = '''
*New Trip Assigned!* 🚖

*Customer:* $customerName ($customerMobile)
*Date/Time:* $pickupTimeStr

*Pickup:* $pickup
📍 Map: $pickupMapLink

*Drop:* $drop
📍 Map: $dropMapLink

Please reach on time!
''';

      final whatsappUrl = Uri.parse("https://wa.me/${driver.mobile}?text=${Uri.encodeComponent(message)}");
      
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
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
