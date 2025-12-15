import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../bookings/data/bookings_repository.dart';

class EditBookingLocationPage extends ConsumerStatefulWidget {
  const EditBookingLocationPage({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  ConsumerState<EditBookingLocationPage> createState() =>
      _EditBookingLocationPageState();
}

class _EditBookingLocationPageState
    extends ConsumerState<EditBookingLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _pickupLatController = TextEditingController();
  final _pickupLngController = TextEditingController();
  final _destLatController = TextEditingController();
  final _destLngController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _pickupLatController.dispose();
    _pickupLngController.dispose();
    _destLatController.dispose();
    _destLngController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final repo = ref.read(bookingsRepositoryProvider);
    try {
      double? _parseController(TextEditingController c) {
        if (c.text.trim().isEmpty) return null;
        return double.tryParse(c.text.trim());
      }

      await repo.updateBookingLocations(
        bookingId: widget.bookingId,
        pickupLocation: _pickupController.text.trim().isEmpty
            ? null
            : _pickupController.text.trim(),
        destinationLocation: _destinationController.text.trim().isEmpty
            ? null
            : _destinationController.text.trim(),
        pickupLatitude: _parseController(_pickupLatController),
        pickupLongitude: _parseController(_pickupLngController),
        destinationLatitude: _parseController(_destLatController),
        destinationLongitude: _parseController(_destLngController),
      );
      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update locations: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Locations'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Update pickup and drop details. Leave fields blank to keep existing values.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pickupController,
                decoration: const InputDecoration(
                  labelText: 'Pickup address',
                  prefixIcon: Icon(Icons.trip_origin),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pickupLatController,
                      decoration: const InputDecoration(
                        labelText: 'Pickup lat',
                        prefixIcon: Icon(Icons.my_location),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pickupLngController,
                      decoration: const InputDecoration(
                        labelText: 'Pickup lng',
                        prefixIcon: Icon(Icons.explore),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'Destination address',
                  prefixIcon: Icon(Icons.flag),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _destLatController,
                      decoration: const InputDecoration(
                        labelText: 'Destination lat',
                        prefixIcon: Icon(Icons.my_location),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _destLngController,
                      decoration: const InputDecoration(
                        labelText: 'Destination lng',
                        prefixIcon: Icon(Icons.explore),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSubmitting ? 'Saving...' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
