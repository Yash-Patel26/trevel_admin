import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../data/vehicles_repository.dart';
import '../data/vehicle_makes_models.dart';

class CreateVehiclePage extends ConsumerStatefulWidget {
  const CreateVehiclePage({super.key});

  @override
  ConsumerState<CreateVehiclePage> createState() => _CreateVehiclePageState();
}

class _CreateVehiclePageState extends ConsumerState<CreateVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _yearController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _notesController = TextEditingController();
  // Insurance fields (PRD requirement)
  final _insuranceDetailsController = TextEditingController();
  final _insurancePolicyNumberController = TextEditingController();
  final _insuranceExpiryDateController = TextEditingController();
  // Access keys (PRD requirement)
  final _liveLocationAccessKeyController = TextEditingController();
  final _dashcamAccessKeyController = TextEditingController();

  String? _selectedMake;
  String? _selectedModel;
  DateTime? _insuranceExpiryDate;
  bool _isLoading = false;
  VehicleMakesModels? _makesAndModels;
  bool _isLoadingMakesModels = false;

  @override
  void initState() {
    super.initState();
    _loadMakesAndModels();
  }

  Future<void> _loadMakesAndModels() async {
    setState(() => _isLoadingMakesModels = true);
    try {
      final repo = ref.read(vehiclesRepositoryProvider);
      final data = await repo.getMakesAndModels();
      setState(() {
        _makesAndModels = VehicleMakesModels(data);
        _isLoadingMakesModels = false;
      });
    } catch (e) {
      setState(() => _isLoadingMakesModels = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to load vehicle makes/models: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _notesController.dispose();
    _insuranceDetailsController.dispose();
    _insurancePolicyNumberController.dispose();
    _insuranceExpiryDateController.dispose();
    _liveLocationAccessKeyController.dispose();
    _dashcamAccessKeyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(vehiclesRepositoryProvider);
      await repo.createVehicle(
        numberPlate: _licensePlateController.text.trim().isEmpty
            ? _vehicleNumberController.text.trim()
            : _licensePlateController.text.trim(),
        make: _selectedMake,
        model: _selectedModel,
        insurancePolicyNumber:
            _insurancePolicyNumberController.text.trim().isEmpty
                ? null
                : _insurancePolicyNumberController.text.trim(),
        insuranceExpiry: _insuranceExpiryDate,
        liveLocationKey: _liveLocationAccessKeyController.text.trim().isEmpty
            ? null
            : _liveLocationAccessKeyController.text.trim(),
        dashcamKey: _dashcamAccessKeyController.text.trim().isEmpty
            ? null
            : _dashcamAccessKeyController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle created successfully')),
        );
        context.pop();
      }
    } catch (e) {
      String errorMessage = 'Failed to create vehicle';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          errorMessage = data['message'];
          if (data.containsKey('issues')) {
            errorMessage += ': ${(data['issues'] as List).join(', ')}';
          }
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      } else {
        errorMessage = e.toString();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number *',
                  hintText: 'e.g., VH-001',
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vehicle number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _isLoadingMakesModels
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _makesAndModels == null
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Failed to load vehicle makes/models',
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedMake,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Make *',
                                  prefixIcon: Icon(Icons.directions_car),
                                ),
                                items: _makesAndModels!.makes.map((make) {
                                  return DropdownMenuItem(
                                    value: make,
                                    child: Text(
                                      make,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMake = value;
                                    _selectedModel =
                                        null; // Reset model when make changes
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Make is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedModel,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Model *',
                                  prefixIcon: Icon(Icons.category),
                                ),
                                items: _selectedMake != null
                                    ? _makesAndModels!
                                        .getModelsForMake(_selectedMake!)
                                        .map((model) {
                                        return DropdownMenuItem(
                                          value: model,
                                          child: Text(
                                            model,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList()
                                    : [],
                                onChanged: _selectedMake != null
                                    ? (value) {
                                        setState(() {
                                          _selectedModel = value;
                                        });
                                      }
                                    : null,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Model is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Year *',
                        hintText: 'e.g., 2023',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Year is required';
                        }
                        final year = int.tryParse(value);
                        if (year == null || year < 1900 || year > 2100) {
                          return 'Enter a valid year';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _licensePlateController,
                      decoration: const InputDecoration(
                        labelText: 'License Plate *',
                        hintText: 'e.g., ABC-1234',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'License plate is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Insurance Section (PRD requirement)
              Divider(),
              const SizedBox(height: 8),
              Text(
                'Insurance Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _insuranceDetailsController,
                decoration: const InputDecoration(
                  labelText: 'Insurance Details (Optional)',
                  hintText: 'Insurance company name and coverage details',
                  prefixIcon: Icon(Icons.security),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _insurancePolicyNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Policy Number (Optional)',
                        hintText: 'e.g., POL-12345',
                        prefixIcon: Icon(Icons.confirmation_number),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _insuranceExpiryDateController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date (Optional)',
                        hintText: 'Select date',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (date != null) {
                          setState(() {
                            _insuranceExpiryDate = date;
                            _insuranceExpiryDateController.text =
                                '${date.day}/${date.month}/${date.year}';
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Access Keys Section (PRD requirement)
              Divider(),
              const SizedBox(height: 8),
              Text(
                'Access Keys',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _liveLocationAccessKeyController,
                decoration: const InputDecoration(
                  labelText: 'Live Location Access Key (Optional)',
                  hintText: 'GPS tracking API key',
                  prefixIcon: Icon(Icons.location_on),
                  helperText: 'Required for real-time vehicle tracking',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dashcamAccessKeyController,
                decoration: const InputDecoration(
                  labelText: 'Dashcam Access Key (Optional)',
                  hintText: 'Dashcam feed API key',
                  prefixIcon: Icon(Icons.videocam),
                  helperText: 'Required for dashcam video feed access',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional information...',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
