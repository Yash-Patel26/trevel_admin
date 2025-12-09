import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/driver_onboarding_state.dart';

class Step4VerificationPage extends ConsumerWidget {
  const Step4VerificationPage({super.key});

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

  Widget _buildInfoRow(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                Flexible(
                  child: OutlinedButton.icon(
                    onPressed: isApproved
                        ? null
                        : () {
                            ref
                                .read(driverOnboardingStateProvider.notifier)
                                .disapproveSection(sectionKey);
                          },
                    icon: const Icon(Icons.close),
                    label: const Text(
                      'Disapprove',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FilledButton.icon(
                    onPressed: isApproved
                        ? null
                        : () {
                            ref
                                .read(driverOnboardingStateProvider.notifier)
                                .approveSection(sectionKey);
                          },
                    icon: const Icon(Icons.check),
                    label: const Text(
                      'Approve',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverOnboardingStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboard Driver - Step 4 of 7'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 4 / 7,
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
              'Background Verification',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Review and approve each section',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            // Basic Information Section
            _buildSectionCard(
              context: context,
              ref: ref,
              sectionKey: 'basic_info',
              title: 'Basic Information',
              icon: Icons.person,
              iconColor: Colors.blue,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(context, 'Full Name', state.fullName),
                  _buildInfoRow(context, 'Email', state.email),
                  _buildInfoRow(context, 'Mobile', state.mobile),
                  if (state.shiftTiming != null)
                    _buildInfoRow(context, 'Shift Timing', state.shiftTiming),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Addresses Section
            if (state.currentAddress != null || state.permanentAddress != null)
              _buildSectionCard(
                context: context,
                ref: ref,
                sectionKey: 'addresses',
                title: 'Addresses',
                icon: Icons.home,
                iconColor: Colors.green,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.currentAddress != null)
                      _buildInfoRow(
                          context, 'Current Address', state.currentAddress),
                    if (state.permanentAddress != null)
                      _buildInfoRow(
                          context, 'Permanent Address', state.permanentAddress),
                  ],
                ),
              ),
            if (state.currentAddress != null || state.permanentAddress != null)
              const SizedBox(height: 16),

            // Reference Contacts Section
            if (state.referenceContact1Name != null ||
                state.referenceContact2Name != null)
              _buildSectionCard(
                context: context,
                ref: ref,
                sectionKey: 'reference_contacts',
                title: 'Reference Contacts',
                icon: Icons.person_outline,
                iconColor: Colors.orange,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.referenceContact1Name != null) ...[
                      _buildInfoRow(
                        context,
                        'Contact 1 Name',
                        state.referenceContact1Name,
                      ),
                      if (state.referenceContact1Relation != null)
                        _buildInfoRow(
                          context,
                          'Contact 1 Relation',
                          _getRelationDisplayName(
                              state.referenceContact1Relation!),
                        ),
                      const SizedBox(height: 8),
                    ],
                    if (state.referenceContact2Name != null) ...[
                      _buildInfoRow(
                        context,
                        'Contact 2 Name',
                        state.referenceContact2Name,
                      ),
                      if (state.referenceContact2Relation != null)
                        _buildInfoRow(
                          context,
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

            // Emergency Contact Section
            if (state.emergencyContactName != null ||
                state.emergencyContactNumber != null)
              _buildSectionCard(
                context: context,
                ref: ref,
                sectionKey: 'emergency_contact',
                title: 'Emergency Contact',
                icon: Icons.emergency,
                iconColor: Colors.red,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.emergencyContactName != null)
                      _buildInfoRow(
                        context,
                        'Name',
                        state.emergencyContactName,
                      ),
                    if (state.emergencyContactNumber != null)
                      _buildInfoRow(
                        context,
                        'Contact Number',
                        state.emergencyContactNumber,
                      ),
                    if (state.emergencyContactRelation != null)
                      _buildInfoRow(
                        context,
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

            // Verification Info Card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Background Verification Process',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'After submission, the Team role will perform background verification on this driver. This includes:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...[
                      'License verification',
                      'Criminal background check',
                      'Driving record review'
                    ].map((item) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 20,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Status: Will be set to "Pending Verification" after submission',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    onPressed: () => context.push('/drivers/onboard/step5'),
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
                            'Continue to Vehicle Allocation',
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
