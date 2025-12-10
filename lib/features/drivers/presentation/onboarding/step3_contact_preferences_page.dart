import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/state/auth/auth_controller.dart';
import '../../data/driver_onboarding_state.dart';
import '../../data/drivers_repository.dart';

class Step3ContactPreferencesPage extends ConsumerStatefulWidget {
  const Step3ContactPreferencesPage({super.key});

  @override
  ConsumerState<Step3ContactPreferencesPage> createState() =>
      _Step3ContactPreferencesPageState();
}

class _Step3ContactPreferencesPageState
    extends ConsumerState<Step3ContactPreferencesPage> {
  final _formKey = GlobalKey<FormState>();

  // Addresses
  final _currentAddressController = TextEditingController();
  final _permanentAddressController = TextEditingController();

  // Reference Contact 1
  final _referenceContact1NameController = TextEditingController();
  final _referenceContact1MobileController = TextEditingController();
  String? _referenceContact1Relation;

  // Reference Contact 2
  final _referenceContact2NameController = TextEditingController();
  final _referenceContact2MobileController = TextEditingController();
  String? _referenceContact2Relation;

  // Emergency Contact
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactNumberController = TextEditingController();
  final _emergencyContactRelationController = TextEditingController();

  bool _hasLoadedState = false;

  final List<String> _relationOptions = [
    'father',
    'mother',
    'sister',
    'brother',
    'spouse',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedState) {
      final state = ref.read(driverOnboardingStateProvider);

      if (state.currentAddress != null && state.currentAddress!.isNotEmpty) {
        _currentAddressController.text = state.currentAddress!;
      }
      if (state.permanentAddress != null &&
          state.permanentAddress!.isNotEmpty) {
        _permanentAddressController.text = state.permanentAddress!;
      }
      if (state.referenceContact1Name != null &&
          state.referenceContact1Name!.isNotEmpty) {
        _referenceContact1NameController.text = state.referenceContact1Name!;
      }
      if (state.referenceContact1Mobile != null &&
          state.referenceContact1Mobile!.isNotEmpty) {
        _referenceContact1MobileController.text =
            state.referenceContact1Mobile!;
      }
      _referenceContact1Relation = state.referenceContact1Relation;
      if (state.referenceContact2Name != null &&
          state.referenceContact2Name!.isNotEmpty) {
        _referenceContact2NameController.text = state.referenceContact2Name!;
      }
      if (state.referenceContact2Mobile != null &&
          state.referenceContact2Mobile!.isNotEmpty) {
        _referenceContact2MobileController.text =
            state.referenceContact2Mobile!;
      }
      _referenceContact2Relation = state.referenceContact2Relation;
      if (state.emergencyContactName != null &&
          state.emergencyContactName!.isNotEmpty) {
        _emergencyContactNameController.text = state.emergencyContactName!;
      }
      if (state.emergencyContactNumber != null &&
          state.emergencyContactNumber!.isNotEmpty) {
        _emergencyContactNumberController.text = state.emergencyContactNumber!;
      }
      if (state.emergencyContactRelation != null &&
          state.emergencyContactRelation!.isNotEmpty) {
        _emergencyContactRelationController.text =
            state.emergencyContactRelation!;
      }

      _hasLoadedState = true;
    }
  }

  @override
  void dispose() {
    _currentAddressController.dispose();
    _permanentAddressController.dispose();
    _referenceContact1NameController.dispose();
    _referenceContact1MobileController.dispose();
    _referenceContact2NameController.dispose();
    _referenceContact2MobileController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactNumberController.dispose();
    _emergencyContactRelationController.dispose();
    super.dispose();
  }

  Future<void> _continueToNextStep() async {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(driverOnboardingStateProvider.notifier).updateContactPreferences(
            currentAddress: _currentAddressController.text.trim().isEmpty
                ? null
                : _currentAddressController.text.trim(),
            permanentAddress: _permanentAddressController.text.trim().isEmpty
                ? null
                : _permanentAddressController.text.trim(),
            referenceContact1Name:
                _referenceContact1NameController.text.trim().isEmpty
                    ? null
                    : _referenceContact1NameController.text.trim(),
            referenceContact1Mobile:
                _referenceContact1MobileController.text.trim().isEmpty
                    ? null
                    : _referenceContact1MobileController.text.trim(),
            referenceContact1Relation: _referenceContact1Relation,
            referenceContact2Name:
                _referenceContact2NameController.text.trim().isEmpty
                    ? null
                    : _referenceContact2NameController.text.trim(),
            referenceContact2Mobile:
                _referenceContact2MobileController.text.trim().isEmpty
                    ? null
                    : _referenceContact2MobileController.text.trim(),
            referenceContact2Relation: _referenceContact2Relation,
            emergencyContactName:
                _emergencyContactNameController.text.trim().isEmpty
                    ? null
                    : _emergencyContactNameController.text.trim(),
            emergencyContactNumber:
                _emergencyContactNumberController.text.trim().isEmpty
                    ? null
                    : _emergencyContactNumberController.text.trim(),
            emergencyContactRelation:
                _emergencyContactRelationController.text.trim().isEmpty
                    ? null
                    : _emergencyContactRelationController.text.trim(),
          );

      // Check if user is Driver Individual - submit driver after step 3
      final auth = ref.read(authControllerProvider);
      final user = auth.user;
      final isDriverIndividual = user?.role == 'Driver Individual';

      if (isDriverIndividual) {
        // Submit the driver for Driver Individual
        await _submitDriver();
      } else {
        // Continue to step 4 for other roles
        if (mounted) {
          context.push('/drivers/onboard/step4');
        }
      }
    }
  }

  Future<void> _submitDriver() async {
    try {
      final state = ref.read(driverOnboardingStateProvider);
      final repo = ref.read(driversRepositoryProvider);

      // Create the driver
      final createdDriver = await repo.createDriver(
        name: state.fullName!,
        mobile: state.mobile!,
        email: state.email,
        onboardingData: {
          if (state.bloodGroup != null) 'bloodGroup': state.bloodGroup,
          if (state.dateOfBirth != null)
            'dateOfBirth': state.dateOfBirth!.toIso8601String(),
          if (state.profileImageUrl != null)
            'profileImageUrl': state.profileImageUrl,
          if (state.shiftTiming != null) 'shiftTiming': state.shiftTiming,
          if (state.notes != null) 'notes': state.notes,
        },
        contactPreferences: {
          'emailNotifications': state.emailNotifications,
          'smsNotifications': state.smsNotifications,
          'pushNotifications': state.pushNotifications,
          if (state.preferredContactMethod != null)
            'preferredContactMethod': state.preferredContactMethod,
          if (state.currentAddress != null)
            'currentAddress': state.currentAddress,
          if (state.permanentAddress != null)
            'permanentAddress': state.permanentAddress,
          if (state.referenceContact1Name != null)
            'referenceContact1Name': state.referenceContact1Name,
          if (state.referenceContact1Mobile != null)
            'referenceContact1Mobile': state.referenceContact1Mobile,
          if (state.referenceContact1Relation != null)
            'referenceContact1Relation': state.referenceContact1Relation,
          if (state.referenceContact2Name != null)
            'referenceContact2Name': state.referenceContact2Name,
          if (state.referenceContact2Mobile != null)
            'referenceContact2Mobile': state.referenceContact2Mobile,
          if (state.referenceContact2Relation != null)
            'referenceContact2Relation': state.referenceContact2Relation,
          if (state.emergencyContactName != null)
            'emergencyContactName': state.emergencyContactName,
          if (state.emergencyContactNumber != null)
            'emergencyContactNumber': state.emergencyContactNumber,
          if (state.emergencyContactRelation != null)
            'emergencyContactRelation': state.emergencyContactRelation,
        },
      );

      // Upload documents if any
      for (final doc in state.documents) {
        if (doc.fileUrl != null && doc.fileUrl!.isNotEmpty) {
          try {
            if (!doc.fileUrl!.startsWith('http://') &&
                !doc.fileUrl!.startsWith('https://') &&
                !doc.fileUrl!.startsWith('/uploads/')) {
              // On web, we can't check if file exists, so just try to upload
              // On mobile, check if file exists first
              bool shouldUpload = false;
              if (kIsWeb) {
                // On web, filePath should be an XFile path, just try to upload
                shouldUpload = true;
              } else {
                // On mobile, check if file exists
                final file = File(doc.fileUrl!);
                shouldUpload = await file.exists();
                if (!shouldUpload) {
                  debugPrint(
                      'File not found for document ${doc.type}: ${doc.fileUrl}');
                }
              }

              if (shouldUpload) {
                debugPrint(
                    'Uploading document ${doc.type} from path: ${doc.fileUrl}');
                await repo.uploadDriverDocument(
                  driverId: createdDriver.id,
                  filePath: doc.fileUrl!,
                  type: doc.type,
                );
                debugPrint('Successfully uploaded document ${doc.type}');
              }
            } else {
              debugPrint(
                  'Document ${doc.type} already uploaded (URL: ${doc.fileUrl})');
            }
          } catch (e, stackTrace) {
            debugPrint('Error uploading document ${doc.type}: $e');
            debugPrint('Stack trace: $stackTrace');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Failed to upload ${doc.type}: ${e.toString()}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        }
      }

      // Reset onboarding state
      ref.read(driverOnboardingStateProvider.notifier).reset();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Driver submitted successfully! It will be reviewed by the team.'),
            backgroundColor: Colors.green,
          ),
        );
        // For Driver Individual, go to My Drivers list instead of restarting onboarding
        context.go('/drivers');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting driver: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getRelationDisplayName(String relation) {
    switch (relation) {
      case 'father':
        return 'Father';
      case 'mother':
        return 'Mother';
      case 'sister':
        return 'Sister';
      case 'brother':
        return 'Brother';
      case 'spouse':
        return 'Spouse';
      default:
        return relation;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final isDriverIndividual = user?.role == 'Driver Individual';
    final stepText = isDriverIndividual ? 'Step 3 of 3' : 'Step 3 of 7';
    final progressValue = isDriverIndividual ? 1.0 : 3 / 7;

    return Scaffold(
      appBar: AppBar(
        title: Text('Onboard Driver - $stepText'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey[300],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Contact & Address Information',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Provide addresses and emergency contacts',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),

              // Addresses Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.home, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Addresses',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _currentAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Current Address',
                          hintText: 'Enter current residential address',
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _permanentAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Permanent Address',
                          hintText: 'Enter permanent address',
                          prefixIcon: Icon(Icons.home),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reference Contact 1
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Reference Contact 1',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenceContact1NameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          hintText: 'Enter reference contact name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Reference contact 1 name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenceContact1MobileController,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number *',
                          hintText: 'e.g., +1234567890',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Reference contact 1 mobile number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _referenceContact1Relation,
                        decoration: const InputDecoration(
                          labelText: 'Relation',
                          prefixIcon: Icon(Icons.people),
                        ),
                        hint: const Text('Select relation'),
                        items: _relationOptions.map((relation) {
                          return DropdownMenuItem(
                            value: relation,
                            child: Text(_getRelationDisplayName(relation)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _referenceContact1Relation = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reference Contact 2
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Reference Contact 2',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenceContact2NameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          hintText: 'Enter reference contact name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Reference contact 2 name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _referenceContact2MobileController,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number *',
                          hintText: 'e.g., +1234567890',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Reference contact 2 mobile number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _referenceContact2Relation,
                        decoration: const InputDecoration(
                          labelText: 'Relation',
                          prefixIcon: Icon(Icons.people),
                        ),
                        hint: const Text('Select relation'),
                        items: _relationOptions.map((relation) {
                          return DropdownMenuItem(
                            value: relation,
                            child: Text(_getRelationDisplayName(relation)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _referenceContact2Relation = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Emergency Contact
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emergency, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Emergency Contact',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emergencyContactNameController,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          hintText: 'Enter emergency contact name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Emergency contact name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emergencyContactNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Contact Number *',
                          hintText: 'e.g., +1234567890',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Emergency contact number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emergencyContactRelationController,
                        decoration: const InputDecoration(
                          labelText: 'Relation *',
                          hintText: 'e.g., Father, Mother, Spouse, etc.',
                          prefixIcon: Icon(Icons.people),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Emergency contact relation is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Flexible(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back),
                          SizedBox(width: 8),
                          Flexible(child: Text('Back')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: FilledButton(
                      onPressed: _continueToNextStep,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                                isDriverIndividual ? 'Submit' : 'Continue'),
                          ),
                          SizedBox(width: 8),
                          Icon(isDriverIndividual
                              ? Icons.check
                              : Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
