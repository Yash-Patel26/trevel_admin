import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/state/auth/auth_controller.dart';

import '../../data/driver_onboarding_state.dart';
import '../../data/drivers_repository.dart';
import '../../../upload/data/upload_repository.dart';

class Step1BasicInfoPage extends ConsumerStatefulWidget {
  const Step1BasicInfoPage({super.key});

  @override
  ConsumerState<Step1BasicInfoPage> createState() => _Step1BasicInfoPageState();
}

class _Step1BasicInfoPageState extends ConsumerState<Step1BasicInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _dateOfBirthController;
  String? _bloodGroup;
  String? _shiftTiming;
  XFile? _profileImage;
  String? _profileImageUrl;
  bool _hasLoadedState = false;
  bool _isCheckingMobile = false;

  static const List<String> _bloodGroupOptions = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  static const List<String> _shiftTimingOptions = [
    'Morning (6 AM - 2 PM)',
    'Afternoon (2 PM - 10 PM)',
    'Evening (4 PM - 12 AM)',
    'Night (10 PM - 6 AM)',
    'Flexible',
  ];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _mobileController = TextEditingController();
    _dateOfBirthController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedState) {
      final state = ref.read(driverOnboardingStateProvider);
      if (state.fullName != null && state.fullName!.isNotEmpty) {
        _fullNameController.text = state.fullName!;
      }
      if (state.email != null && state.email!.isNotEmpty) {
        _emailController.text = state.email!;
      }
      if (state.mobile != null && state.mobile!.isNotEmpty) {
        _mobileController.text = state.mobile!;
      }
      if (state.dateOfBirth != null) {
        _dateOfBirthController.text =
            DateFormat('yyyy-MM-dd').format(state.dateOfBirth!);
      }
      _bloodGroup = state.bloodGroup;
      _shiftTiming = state.shiftTiming;
      _profileImageUrl = state.profileImageUrl;
      _hasLoadedState = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _profileImage = image; // Store XFile directly for web compatibility
      });

      // Upload the image
      try {
        final uploadRepo = ref.read(uploadRepositoryProvider);
        final mobile = _mobileController.text.trim();
        
        // Upload to drivers/{mobile}/ folder
        final uploadedFile = await uploadRepo.uploadFile(
          image,
          entityType: 'drivers',
          entityId: mobile.isNotEmpty ? mobile : null,
        );
        
        setState(() {
          _profileImageUrl = uploadedFile.url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload image: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _profileImage = null;
        });
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<bool> _checkMobileUniqueness(String mobile) async {
    try {
      setState(() => _isCheckingMobile = true);
      final repo = ref.read(driversRepositoryProvider);
      final result = await repo.checkMobileExists(mobile.trim());
      setState(() => _isCheckingMobile = false);
      return result['exists'] as bool? ?? false;
    } catch (e) {
      setState(() => _isCheckingMobile = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking mobile number: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  void _continueToNextStep() async {
    final formState = _formKey.currentState;
    if (formState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form not initialized'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isValid = formState.validate();

    if (isValid) {
      // Check mobile number uniqueness
      final mobile = _mobileController.text.trim();
      final mobileExists = await _checkMobileUniqueness(mobile);

      if (mobileExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'User already found with that mobile number. Please enter correct number.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Parse date of birth
      DateTime? dateOfBirth;
      if (_dateOfBirthController.text.isNotEmpty) {
        try {
          dateOfBirth =
              DateFormat('yyyy-MM-dd').parse(_dateOfBirthController.text);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid date format'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Update state
      ref.read(driverOnboardingStateProvider.notifier).updateBasicInfo(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            mobile: mobile,
            bloodGroup: _bloodGroup,
            dateOfBirth: dateOfBirth,
            profileImageUrl: _profileImageUrl,
            shiftTiming: _shiftTiming,
          );

      // Navigate to next step
      if (mounted) {
        context.push('/drivers/onboard/step2');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all required fields correctly'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final isDriverIndividual = user?.role == 'Driver Individual';
    final stepText = isDriverIndividual ? 'Step 1 of 3' : 'Step 1 of 7';
    final progressValue = isDriverIndividual ? 1.0 / 3.0 : 1 / 7;

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
                'Basic Information',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the driver\'s basic details',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              // Profile Image Upload
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                          color: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        child: _profileImage != null
                            ? ClipOval(
                                child: FutureBuilder<Uint8List>(
                                  future: _profileImage!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      );
                                    } else {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                  },
                                ),
                              )
                            : _profileImageUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _profileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.person,
                                            size: 60);
                                      },
                                    ),
                                  )
                                : const Icon(Icons.add_a_photo, size: 40),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickProfileImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Upload Profile Image'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'e.g., John Doe',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  hintText: 'e.g., john.doe@example.com',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                maxLength: 10,
                buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    null,
                decoration: InputDecoration(
                  labelText: 'Mobile Number *',
                  hintText: 'e.g., +1234567890',
                  prefixIcon: const Icon(Icons.phone),
                  suffixIcon: _isCheckingMobile
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mobile number is required';
                  }
                  if (value.length != 10) {
                    return 'Mobile number must be 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _bloodGroup,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Blood Group *',
                  hintText: 'Select blood group',
                  prefixIcon: Icon(Icons.bloodtype),
                ),
                items: _bloodGroupOptions.map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Text(group),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _bloodGroup = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Blood group is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth *',
                  hintText: 'Select date of birth',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDateOfBirth,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Date of birth is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Shift Timing',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _shiftTiming,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Shift Timing',
                          hintText: 'Select shift timing',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: _shiftTimingOptions.map((timing) {
                          return DropdownMenuItem(
                            value: timing,
                            child: Text(
                              timing,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _shiftTiming = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isCheckingMobile ? null : _continueToNextStep,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCheckingMobile
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Checking...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Continue to Documents'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
