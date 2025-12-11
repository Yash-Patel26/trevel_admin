import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/driver_document.dart';
import '../../data/driver_onboarding_state.dart';
import '../../../../core/state/auth/auth_controller.dart';
import '../../../upload/data/upload_repository.dart';

class Step2DocumentsPage extends ConsumerStatefulWidget {
  const Step2DocumentsPage({super.key});

  @override
  ConsumerState<Step2DocumentsPage> createState() => _Step2DocumentsPageState();
}

class _Step2DocumentsPageState extends ConsumerState<Step2DocumentsPage> {
  final ImagePicker _imagePicker = ImagePicker();

  // Form keys for each document type
  final _panFormKey = GlobalKey<FormState>();
  final _aadharFormKey = GlobalKey<FormState>();
  final _licenseFormKey = GlobalKey<FormState>();

  // Controllers for PAN
  final _panNumberController = TextEditingController();
  XFile? _panImage;

  // Controllers for Aadhar
  final _aadharNumberController = TextEditingController();
  XFile? _aadharImage;

  // Controllers for Driving License
  final _licenseNumberController = TextEditingController();
  final _issuingAuthorityController = TextEditingController();
  DateTime? _licenseIssuedDate;
  DateTime? _licenseExpiryDate;
  XFile? _licenseImage;

  // Police Verification
  XFile? _policeVerificationImage;

  // Uploaded URLs
  String? _panImageUrl;
  String? _aadharImageUrl;
  String? _licenseImageUrl;
  String? _policeVerificationImageUrl;
  // ignore: unused_field
  bool _isUploading = false;

  bool _hasLoadedState = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedState) {
      _loadExistingDocuments();
      _hasLoadedState = true;
    }
  }

  void _loadExistingDocuments() {
    final state = ref.read(driverOnboardingStateProvider);
    for (final doc in state.documents) {
      switch (doc.type) {
        case 'pan':
          if (doc.panNumber != null) {
            _panNumberController.text = doc.panNumber!;
          }
          _panImageUrl = doc.fileUrl;
          break;
        case 'aadhar':
          if (doc.aadharNumber != null) {
            _aadharNumberController.text = doc.aadharNumber!;
          }
          _aadharImageUrl = doc.fileUrl;
          break;
        case 'driving_license':
          if (doc.licenseNumber != null) {
            _licenseNumberController.text = doc.licenseNumber!;
          }
          if (doc.issuingAuthority != null) {
            _issuingAuthorityController.text = doc.issuingAuthority!;
          }
          _licenseIssuedDate = doc.issuedDate;
          _licenseExpiryDate = doc.expiryDate;
          _licenseImageUrl = doc.fileUrl;
          break;
        case 'police_verification':
          _policeVerificationImageUrl = doc.fileUrl;
          break;
      }
    }
  }

  @override
  void dispose() {
    _panNumberController.dispose();
    _aadharNumberController.dispose();
    _licenseNumberController.dispose();
    _issuingAuthorityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({
    required ImageSource source,
    required Function(XFile) onImagePicked,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image != null) {
        onImagePicked(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog(Function(XFile) onImagePicked) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(
                    source: ImageSource.camera, onImagePicked: onImagePicked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(
                    source: ImageSource.gallery, onImagePicked: onImagePicked);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadDocument(XFile file, String type) async {
    setState(() => _isUploading = true);
    try {
      final repo = ref.read(uploadRepositoryProvider);
      final state = ref.read(driverOnboardingStateProvider);
      final mobile = state.mobile ?? '';
      
      // Map document type to folder name
      String documentType;
      switch (type) {
        case 'pan':
          documentType = 'PAN_Card';
          break;
        case 'aadhar':
          documentType = 'Aadhar_Card';
          break;
        case 'driving_license':
          documentType = 'Driving_License';
          break;
        case 'police_verification':
          documentType = 'Police_Verification';
          break;
        default:
          documentType = 'Other';
      }
      
      // Upload to drivers/{mobile}/{documentType}/ folder
      final uploadedFile = await repo.uploadFile(
        file,
        entityType: 'drivers',
        entityId: mobile.isNotEmpty ? mobile : null,
        documentType: documentType,
      );

      if (mounted) {
        setState(() {
          switch (type) {
            case 'pan':
              _panImageUrl = uploadedFile.url;
              break;
            case 'aadhar':
              _aadharImageUrl = uploadedFile.url;
              break;
            case 'driving_license':
              _licenseImageUrl = uploadedFile.url;
              break;
            case 'police_verification':
              _policeVerificationImageUrl = uploadedFile.url;
              break;
          }
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate({
    required BuildContext context,
    required Function(DateTime) onDateSelected,
    DateTime? initialDate,
    DateTime? firstDate,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  void _saveDocuments() {
    final state = ref.read(driverOnboardingStateProvider);
    final List<DriverDocument> documents = [];
    final now = DateTime.now();

    // Save PAN
    if (_panNumberController.text.isNotEmpty || _panImage != null) {
      final existingPan =
          state.documents.where((d) => d.type == 'pan').firstOrNull;
      documents.add(DriverDocument(
        id: existingPan?.id ?? DateTime.now().millisecondsSinceEpoch,
        name: 'PAN Card',
        type: 'pan',
        fileUrl: _panImageUrl ?? _panImage?.path ?? existingPan?.fileUrl,
        uploadedAt: existingPan?.uploadedAt ?? now,
        panNumber: _panNumberController.text.trim().isEmpty
            ? null
            : _panNumberController.text.trim(),
      ));
    }

    // Save Aadhar
    if (_aadharNumberController.text.isNotEmpty || _aadharImage != null) {
      final existingAadhar =
          state.documents.where((d) => d.type == 'aadhar').firstOrNull;
      documents.add(DriverDocument(
        id: existingAadhar?.id ?? DateTime.now().millisecondsSinceEpoch + 1,
        name: 'Aadhar Card',
        type: 'aadhar',
        fileUrl:
            _aadharImageUrl ?? _aadharImage?.path ?? existingAadhar?.fileUrl,
        uploadedAt: existingAadhar?.uploadedAt ?? now,
        aadharNumber: _aadharNumberController.text.trim().isEmpty
            ? null
            : _aadharNumberController.text.trim(),
      ));
    }

    // Save Driving License
    if (_licenseNumberController.text.isNotEmpty ||
        _issuingAuthorityController.text.isNotEmpty ||
        _licenseIssuedDate != null ||
        _licenseExpiryDate != null ||
        _licenseImage != null) {
      final existingLicense =
          state.documents.where((d) => d.type == 'driving_license').firstOrNull;
      documents.add(DriverDocument(
        id: existingLicense?.id ?? DateTime.now().millisecondsSinceEpoch + 2,
        name: 'Driving License',
        type: 'driving_license',
        fileUrl:
            _licenseImageUrl ?? _licenseImage?.path ?? existingLicense?.fileUrl,
        uploadedAt: existingLicense?.uploadedAt ?? now,
        licenseNumber: _licenseNumberController.text.trim().isEmpty
            ? null
            : _licenseNumberController.text.trim(),
        issuingAuthority: _issuingAuthorityController.text.trim().isEmpty
            ? null
            : _issuingAuthorityController.text.trim(),
        issuedDate: _licenseIssuedDate,
        expiryDate: _licenseExpiryDate,
      ));
    }

    // Save Police Verification
    if (_policeVerificationImage != null) {
      final existingPolice = state.documents
          .where((d) => d.type == 'police_verification')
          .firstOrNull;
      documents.add(DriverDocument(
        id: existingPolice?.id ?? DateTime.now().millisecondsSinceEpoch + 3,
        name: 'Police Verification',
        type: 'police_verification',
        fileUrl: _policeVerificationImageUrl ??
            _policeVerificationImage?.path ??
            existingPolice?.fileUrl,
        uploadedAt: existingPolice?.uploadedAt ?? now,
      ));
    }

    ref.read(driverOnboardingStateProvider.notifier).updateDocuments(documents);
  }

  Widget _buildImagePreview(XFile? image, String label, VoidCallback onRemove) {
    final preview = Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: image == null
            ? _buildPreviewPlaceholder()
            : kIsWeb
                ? Image.network(
                    image.path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPreviewPlaceholder(),
                  )
                : Image.file(
                    File(image.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPreviewPlaceholder(),
                  ),
      ),
    );

    if (image == null) return preview;

    return Stack(
      children: [
        preview,
        // Document label overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // Close button at top right
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
            ),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.insert_drive_file, color: Colors.grey),
      ),
    );
  }

  Widget _buildPanSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _panFormKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.credit_card, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'PAN Card',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _panNumberController,
                      decoration: const InputDecoration(
                        labelText: 'PAN Number',
                        hintText: 'e.g., ABCDE1234F',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 10,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _showImageSourceDialog((image) {
                        setState(() {
                          _panImage = image;
                        });
                        _uploadDocument(image, 'pan');
                      }),
                      icon: const Icon(Icons.camera_alt),
                      label: Text(_panImage == null
                          ? 'Upload PAN Image'
                          : 'Change Image'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 160,
                child: _buildImagePreview(_panImage, 'PAN Card', () {
                  setState(() {
                    _panImage = null;
                  });
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAadharSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _aadharFormKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Aadhar Card',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _aadharNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Aadhar Number',
                        hintText: 'e.g., 1234 5678 9012',
                        prefixIcon: Icon(Icons.perm_identity),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 12,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _showImageSourceDialog((image) {
                        setState(() {
                          _aadharImage = image;
                        });
                        _uploadDocument(image, 'aadhar');
                      }),
                      icon: const Icon(Icons.camera_alt),
                      label: Text(_aadharImage == null
                          ? 'Upload Aadhar Image'
                          : 'Change Image'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 160,
                child: _buildImagePreview(_aadharImage, 'Aadhar Card', () {
                  setState(() {
                    _aadharImage = null;
                  });
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrivingLicenseSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _licenseFormKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.drive_eta, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Driving License',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _licenseNumberController,
                      decoration: const InputDecoration(
                        labelText: 'License Number',
                        hintText: 'e.g., DL-1234567890',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _issuingAuthorityController,
                      decoration: const InputDecoration(
                        labelText: 'Issuing Authority',
                        hintText: 'e.g., RTO Mumbai',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectDate(
                              context: context,
                              onDateSelected: (date) {
                                setState(() {
                                  _licenseIssuedDate = date;
                                });
                              },
                              initialDate: _licenseIssuedDate,
                            ),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _licenseIssuedDate == null
                                  ? 'Issued Date'
                                  : 'Issued: ${_licenseIssuedDate!.day}/${_licenseIssuedDate!.month}/${_licenseIssuedDate!.year}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (_licenseIssuedDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Please select Issued Date first'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              _selectDate(
                                context: context,
                                onDateSelected: (date) {
                                  if (date.isBefore(_licenseIssuedDate!)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Expiry Date cannot be before Issued Date'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _licenseExpiryDate = date;
                                  });
                                },
                                initialDate: _licenseExpiryDate ??
                                    (_licenseIssuedDate!
                                        .add(const Duration(days: 1))),
                                firstDate: _licenseIssuedDate!
                                    .add(const Duration(days: 1)),
                              );
                            },
                            icon: const Icon(Icons.event),
                            label: Text(
                              _licenseExpiryDate == null
                                  ? 'Expiry Date'
                                  : 'Expires: ${_licenseExpiryDate!.day}/${_licenseExpiryDate!.month}/${_licenseExpiryDate!.year}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _showImageSourceDialog((image) {
                        setState(() {
                          _licenseImage = image;
                        });
                        _uploadDocument(image, 'driving_license');
                      }),
                      icon: const Icon(Icons.camera_alt),
                      label: Text(_licenseImage == null
                          ? 'Upload License Image'
                          : 'Change Image'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 160,
                child: _buildImagePreview(_licenseImage, 'Driving License', () {
                  setState(() {
                    _licenseImage = null;
                  });
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoliceVerificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Police Verification',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload police verification certificate',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _showImageSourceDialog((image) {
                      setState(() {
                        _policeVerificationImage = image;
                      });
                      _uploadDocument(image, 'police_verification');
                    }),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_policeVerificationImage == null
                        ? 'Upload Police Verification'
                        : 'Change Image'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 160,
              child: _buildImagePreview(_policeVerificationImage, 'Police Verification', () {
                setState(() {
                  _policeVerificationImage = null;
                });
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final isDriverIndividual = user?.role == 'Driver Individual';
    final stepText = isDriverIndividual ? 'Step 2 of 3' : 'Step 2 of 7';
    final progressValue = isDriverIndividual ? 2.0 / 3.0 : 2 / 7;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Upload Documents',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload required driver documents with images',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            _buildPanSection(),
            const SizedBox(height: 16),
            _buildAadharSection(),
            const SizedBox(height: 16),
            _buildDrivingLicenseSection(),
            const SizedBox(height: 16),
            _buildPoliceVerificationSection(),
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
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Back',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      _saveDocuments();
                      context.push('/drivers/onboard/step3');
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Continue to Preferences',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
