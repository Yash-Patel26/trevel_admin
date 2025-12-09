import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/driver_onboarding_state.dart';
import '../../data/drivers_repository.dart';

class Step6ReviewPage extends ConsumerStatefulWidget {
  const Step6ReviewPage({super.key});

  @override
  ConsumerState<Step6ReviewPage> createState() => _Step6ReviewPageState();
}

class _Step6ReviewPageState extends ConsumerState<Step6ReviewPage> {
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(driverOnboardingStateProvider);
    _notesController.text = state.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generateAndDownloadPDF() async {
    final state = ref.read(driverOnboardingStateProvider);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Driver Onboarding Information',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Basic Information
              pw.Header(level: 1, text: 'Basic Information'),
              pw.Paragraph(
                  text: 'Full Name: ${state.fullName ?? 'Not provided'}'),
              pw.Paragraph(text: 'Email: ${state.email ?? 'Not provided'}'),
              pw.Paragraph(text: 'Mobile: ${state.mobile ?? 'Not provided'}'),
              if (state.shiftTiming != null)
                pw.Paragraph(text: 'Shift Timing: ${state.shiftTiming}'),
              pw.SizedBox(height: 20),

              // Addresses
              if (state.currentAddress != null ||
                  state.permanentAddress != null) ...[
                pw.Header(level: 1, text: 'Addresses'),
                if (state.currentAddress != null)
                  pw.Paragraph(
                      text: 'Current Address: ${state.currentAddress}'),
                if (state.permanentAddress != null)
                  pw.Paragraph(
                      text: 'Permanent Address: ${state.permanentAddress}'),
                pw.SizedBox(height: 20),
              ],

              // Reference Contacts
              if (state.referenceContact1Name != null ||
                  state.referenceContact2Name != null) ...[
                pw.Header(level: 1, text: 'Reference Contacts'),
                if (state.referenceContact1Name != null) ...[
                  pw.Paragraph(
                      text: 'Contact 1 Name: ${state.referenceContact1Name}'),
                  if (state.referenceContact1Relation != null)
                    pw.Paragraph(
                        text:
                            'Contact 1 Relation: ${_getRelationDisplayName(state.referenceContact1Relation!)}'),
                ],
                if (state.referenceContact2Name != null) ...[
                  pw.Paragraph(
                      text: 'Contact 2 Name: ${state.referenceContact2Name}'),
                  if (state.referenceContact2Relation != null)
                    pw.Paragraph(
                        text:
                            'Contact 2 Relation: ${_getRelationDisplayName(state.referenceContact2Relation!)}'),
                ],
                pw.SizedBox(height: 20),
              ],

              // Emergency Contact
              if (state.emergencyContactName != null ||
                  state.emergencyContactNumber != null) ...[
                pw.Header(level: 1, text: 'Emergency Contact'),
                if (state.emergencyContactName != null)
                  pw.Paragraph(text: 'Name: ${state.emergencyContactName}'),
                if (state.emergencyContactNumber != null)
                  pw.Paragraph(
                      text: 'Contact Number: ${state.emergencyContactNumber}'),
                if (state.emergencyContactRelation != null)
                  pw.Paragraph(
                      text:
                          'Relation: ${_getRelationDisplayName(state.emergencyContactRelation!)}'),
                pw.SizedBox(height: 20),
              ],

              // Documents
              if (state.documents.isNotEmpty) ...[
                pw.Header(level: 1, text: 'Documents'),
                ...state.documents.map((doc) => pw.Paragraph(
                      text: '${doc.name} (${doc.type})',
                    )),
                pw.SizedBox(height: 20),
              ],

              // Notes
              if (state.notes != null && state.notes!.isNotEmpty) ...[
                pw.Header(level: 1, text: 'Notes'),
                pw.Paragraph(text: state.notes!),
              ],
            ];
          },
        ),
      );

      // Show print dialog or save PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required WidgetRef ref,
    required String sectionKey,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
  }) {
    final state = ref.watch(driverOnboardingStateProvider);
    final isApproved = state.approvedSections.contains(sectionKey);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (isApproved)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Approved',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: isApproved
                      ? null
                      : () {
                          ref
                              .read(driverOnboardingStateProvider.notifier)
                              .disapproveSection(sectionKey);
                        },
                  icon: const Icon(Icons.close),
                  label: const Text('Disapprove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: isApproved
                      ? null
                      : () {
                          ref
                              .read(driverOnboardingStateProvider.notifier)
                              .approveSection(sectionKey);
                        },
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final state = ref.read(driverOnboardingStateProvider);

    if (!state.isStep1Complete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update notes before submitting
      ref.read(driverOnboardingStateProvider.notifier).updateNotes(
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      final finalState = ref.read(driverOnboardingStateProvider);
      final repo = ref.read(driversRepositoryProvider);

      // Create the driver first
      final createdDriver = await repo.createDriver(
        name: finalState.fullName!,
        mobile: finalState.mobile!,
        email: finalState.email,
        onboardingData: {
          if (finalState.bloodGroup != null)
            'bloodGroup': finalState.bloodGroup,
          if (finalState.dateOfBirth != null)
            'dateOfBirth': finalState.dateOfBirth!.toIso8601String(),
          if (finalState.profileImageUrl != null)
            'profileImageUrl': finalState.profileImageUrl,
          if (finalState.shiftTiming != null)
            'shiftTiming': finalState.shiftTiming,
          if (finalState.notes != null) 'notes': finalState.notes,
        },
        contactPreferences: {
          'emailNotifications': finalState.emailNotifications,
          'smsNotifications': finalState.smsNotifications,
          'pushNotifications': finalState.pushNotifications,
          if (finalState.preferredContactMethod != null)
            'preferredContactMethod': finalState.preferredContactMethod,
          if (finalState.currentAddress != null)
            'currentAddress': finalState.currentAddress,
          if (finalState.permanentAddress != null)
            'permanentAddress': finalState.permanentAddress,
          if (finalState.referenceContact1Name != null)
            'referenceContact1Name': finalState.referenceContact1Name,
          if (finalState.referenceContact1Mobile != null)
            'referenceContact1Mobile': finalState.referenceContact1Mobile,
          if (finalState.referenceContact1Relation != null)
            'referenceContact1Relation': finalState.referenceContact1Relation,
          if (finalState.referenceContact2Name != null)
            'referenceContact2Name': finalState.referenceContact2Name,
          if (finalState.referenceContact2Mobile != null)
            'referenceContact2Mobile': finalState.referenceContact2Mobile,
          if (finalState.referenceContact2Relation != null)
            'referenceContact2Relation': finalState.referenceContact2Relation,
          if (finalState.emergencyContactName != null)
            'emergencyContactName': finalState.emergencyContactName,
          if (finalState.emergencyContactNumber != null)
            'emergencyContactNumber': finalState.emergencyContactNumber,
          if (finalState.emergencyContactRelation != null)
            'emergencyContactRelation': finalState.emergencyContactRelation,
        },
      );

      // Upload documents after driver is created
      for (final doc in finalState.documents) {
        if (doc.fileUrl != null && doc.fileUrl!.isNotEmpty) {
          try {
            // Check if fileUrl is a local file path (not a URL)
            // If it's already a URL, skip upload
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
            // Log error but continue with other documents
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

      // Assign vehicle if selected
      if (finalState.assignedVehicleId != null) {
        try {
          await repo.assignVehicle(
            driverId: createdDriver.id,
            vehicleId: finalState.assignedVehicleId!,
          );
        } catch (e) {
          // Log error but continue
          debugPrint('Error assigning vehicle: $e');
        }
      }

      // Reset onboarding state
      ref.read(driverOnboardingStateProvider.notifier).reset();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver onboarded successfully')),
        );
        // Navigate back to drivers list
        context.go('/drivers');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
    final state = ref.watch(driverOnboardingStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboard Driver - Step 7 of 7'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _generateAndDownloadPDF,
            tooltip: 'Download PDF',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 7 / 7,
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
              'Review & Submit',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Review all information before submitting',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              context: context,
              ref: ref,
              sectionKey: 'review_basic_info',
              title: 'Basic Information',
              icon: Icons.person,
              iconColor: Colors.blue,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewRow(
                      'Full Name', state.fullName ?? 'Not provided'),
                  _buildReviewRow('Email', state.email ?? 'Not provided'),
                  _buildReviewRow('Mobile', state.mobile ?? 'Not provided'),
                  if (state.shiftTiming != null)
                    _buildReviewRow('Shift Timing', state.shiftTiming!),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              context: context,
              ref: ref,
              sectionKey: 'review_documents',
              title: 'Documents',
              icon: Icons.description,
              iconColor: Colors.purple,
              content: state.documents.isEmpty
                  ? Text(
                      'No documents uploaded',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: state.documents
                          .map((doc) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            doc.type == 'pan'
                                                ? Icons.credit_card
                                                : doc.type == 'aadhar'
                                                    ? Icons.verified_user
                                                    : doc.type ==
                                                            'driving_license'
                                                        ? Icons.drive_eta
                                                        : Icons.shield,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              doc.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (doc.panNumber != null) ...[
                                        const SizedBox(height: 4),
                                        Text('PAN: ${doc.panNumber}'),
                                      ],
                                      if (doc.aadharNumber != null) ...[
                                        const SizedBox(height: 4),
                                        Text('Aadhar: ${doc.aadharNumber}'),
                                      ],
                                      if (doc.licenseNumber != null) ...[
                                        const SizedBox(height: 4),
                                        Text('License: ${doc.licenseNumber}'),
                                      ],
                                      if (doc.issuingAuthority != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                            'Authority: ${doc.issuingAuthority}'),
                                      ],
                                      if (doc.issuedDate != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Issued: ${doc.issuedDate!.day}/${doc.issuedDate!.month}/${doc.issuedDate!.year}',
                                        ),
                                      ],
                                      if (doc.expiryDate != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Expires: ${doc.expiryDate!.day}/${doc.expiryDate!.month}/${doc.expiryDate!.year}',
                                        ),
                                      ],
                                      if (doc.fileUrl != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Image: ${doc.fileUrl!.split('/').last}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 16),
            // Addresses
            if (state.currentAddress != null || state.permanentAddress != null)
              _buildSectionCard(
                context: context,
                ref: ref,
                sectionKey: 'review_addresses',
                title: 'Addresses',
                icon: Icons.home,
                iconColor: Colors.green,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.currentAddress != null) ...[
                      _buildReviewRow('Current Address', state.currentAddress!),
                      const SizedBox(height: 8),
                    ],
                    if (state.permanentAddress != null)
                      _buildReviewRow(
                          'Permanent Address', state.permanentAddress!),
                  ],
                ),
              ),
            if (state.currentAddress != null || state.permanentAddress != null)
              const SizedBox(height: 16),

            // Reference Contacts
            if (state.referenceContact1Name != null ||
                state.referenceContact2Name != null)
              _buildSectionCard(
                context: context,
                ref: ref,
                sectionKey: 'review_reference_contacts',
                title: 'Reference Contacts',
                icon: Icons.person_outline,
                iconColor: Colors.orange,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.referenceContact1Name != null) ...[
                      _buildReviewRow(
                        'Contact 1 Name',
                        state.referenceContact1Name!,
                      ),
                      if (state.referenceContact1Relation != null)
                        _buildReviewRow(
                          'Contact 1 Relation',
                          _getRelationDisplayName(
                              state.referenceContact1Relation!),
                        ),
                      const SizedBox(height: 8),
                    ],
                    if (state.referenceContact2Name != null) ...[
                      _buildReviewRow(
                        'Contact 2 Name',
                        state.referenceContact2Name!,
                      ),
                      if (state.referenceContact2Relation != null)
                        _buildReviewRow(
                          'Contact 2 Relation',
                          _getRelationDisplayName(
                              state.referenceContact2Relation!),
                        ),
                    ],
                  ],
                ),
              ),
            if (state.referenceContact1Name != null ||
                state.referenceContact2Name != null)
              const SizedBox(height: 16),

            // Emergency Contact
            if (state.emergencyContactName != null ||
                state.emergencyContactNumber != null)
              _buildSectionCard(
                context: context,
                ref: ref,
                sectionKey: 'review_emergency_contact',
                title: 'Emergency Contact',
                icon: Icons.emergency,
                iconColor: Colors.red,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.emergencyContactName != null)
                      _buildReviewRow(
                        'Name',
                        state.emergencyContactName!,
                      ),
                    if (state.emergencyContactNumber != null)
                      _buildReviewRow(
                        'Contact Number',
                        state.emergencyContactNumber!,
                      ),
                    if (state.emergencyContactRelation != null)
                      _buildReviewRow(
                        'Relation',
                        _getRelationDisplayName(
                            state.emergencyContactRelation!),
                      ),
                  ],
                ),
              ),
            if (state.emergencyContactName != null ||
                state.emergencyContactNumber != null)
              const SizedBox(height: 16),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
                hintText: 'Add any additional information...',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Next Steps',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Team role will verify background\n'
                      '2. Sub Driver Admin will assign training\n'
                      '3. Driver Admin will give final approval\n'
                      '4. Vehicle will be assigned to approved driver',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _isLoading ? null : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back),
                      SizedBox(width: 8),
                      Text('Back'),
                    ],
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _generateAndDownloadPDF,
                  icon: const Icon(Icons.download),
                  label: const Text('Download PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check),
                            SizedBox(width: 8),
                            Text('Submit'),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      case 'wife':
        return 'Wife';
      default:
        return relation;
    }
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
