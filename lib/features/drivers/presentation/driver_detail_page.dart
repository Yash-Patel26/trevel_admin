import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/auth/auth_controller.dart';
import '../data/drivers_repository.dart';
import '../data/driver_model.dart';
import '../data/driver_document.dart';

final driverDetailProvider =
    FutureProvider.autoDispose.family<Driver, int>((ref, driverId) async {
  final repo = ref.watch(driversRepositoryProvider);
  final drivers = await repo.getDrivers();
  return drivers.firstWhere((d) => d.id == driverId);
});

final driverLogsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, driverId) async {
  final repo = ref.watch(driversRepositoryProvider);
  return await repo.getDriverLogs(driverId);
});

final driverDocumentsProvider = FutureProvider.autoDispose
    .family<List<DriverDocument>, int>((ref, driverId) async {
  final repo = ref.watch(driversRepositoryProvider);
  return await repo.getDriverDocuments(driverId);
});

final driverAuditTrailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, driverId) async {
  final repo = ref.watch(driversRepositoryProvider);
  return await repo.getAuditTrail(driverId);
});

class DriverDetailPage extends ConsumerWidget {
  final int driverId;

  const DriverDetailPage({super.key, required this.driverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverAsync = ref.watch(driverDetailProvider(driverId));
    final logsAsync = ref.watch(driverLogsProvider(driverId));
    final documentsAsync = ref.watch(driverDocumentsProvider(driverId));
    final auditTrailAsync = ref.watch(driverAuditTrailProvider(driverId));
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final isDriverIndividual = user?.role == 'Driver Individual';
    final isTeam = user?.role == 'Team';
    final isDriverAdmin = user?.role == 'Driver Admin';
    final isOperationalAdmin = user?.role == 'Operational Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(driverDetailProvider(driverId));
              ref.invalidate(driverDocumentsProvider(driverId));
              ref.invalidate(driverLogsProvider(driverId));
              ref.invalidate(driverAuditTrailProvider(driverId));
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: driverAsync.when(
        data: (driver) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner for Driver Individual
              if (isDriverIndividual)
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'View-only: You can see the status of your onboarded driver. The team will review and approve.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (isDriverIndividual) const SizedBox(height: 16),
              // Driver Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          driver.profileImageUrl != null &&
                                  driver.profileImageUrl!.isNotEmpty
                              ? CircleAvatar(
                                  radius: 32,
                                  backgroundColor: driver.status.color
                                      .withValues(alpha: 0.1),
                                  backgroundImage:
                                      NetworkImage(driver.profileImageUrl!),
                                  onBackgroundImageError:
                                      (exception, stackTrace) {
                                    // Image failed to load, will show fallback icon
                                  },
                                  child: Icon(
                                    Icons.person,
                                    color: driver.status.color,
                                    size: 32,
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 32,
                                  backgroundColor: driver.status.color
                                      .withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.person,
                                    color: driver.status.color,
                                    size: 32,
                                  ),
                                ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver.fullName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  driver.email,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(driver.status.displayName),
                            backgroundColor:
                                driver.status.color.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildInfoRow(context, 'Mobile', driver.mobile),
                      if (driver.licenseNumber != null)
                        _buildInfoRow(
                            context, 'License Number', driver.licenseNumber!),
                      if (driver.assignedVehicleNumber != null)
                        _buildInfoRow(context, 'Assigned Vehicle',
                            driver.assignedVehicleNumber!),
                      _buildInfoRow(
                          context, 'Created', _formatDate(driver.createdAt)),
                      if (driver.trainingCompleted)
                        _buildInfoRow(context, 'Training', 'Completed'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Background Check
              if (driver.backgroundCheckStatus != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Background Check',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          context,
                          'Status',
                          driver.backgroundCheckStatus!.displayName,
                        ),
                        if (driver.backgroundCheckDate != null)
                          _buildInfoRow(
                            context,
                            'Date',
                            _formatDate(driver.backgroundCheckDate!),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Documents
              documentsAsync.when(
                data: (documents) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documents',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        if (documents.isEmpty)
                          const Text('No documents uploaded')
                        else
                          ...documents.map((doc) => ListTile(
                                leading: const Icon(Icons.description),
                                title: Text(doc.name),
                                subtitle: Text(doc.type),
                                trailing: doc.fileUrl != null
                                    ? IconButton(
                                        icon: const Icon(Icons.open_in_new),
                                        onPressed: () {
                                          // TODO: Open document
                                        },
                                      )
                                    : null,
                              )),
                      ],
                    ),
                  ),
                ),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              // Team Review/Approve Section
              if (isTeam && driver.status == DriverStatus.pending) ...[
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review & Verification',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Review the driver information and documents. Approve to verify the driver.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Reject Driver'),
                                      content: const Text(
                                          'Are you sure you want to reject this driver?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Reject'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true && context.mounted) {
                                    try {
                                      final repo =
                                          ref.read(driversRepositoryProvider);
                                      await repo.approveDriver(
                                        driverId: driverId,
                                        decision: 'rejected',
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Driver rejected successfully')),
                                        );
                                        ref.invalidate(
                                            driverDetailProvider(driverId));
                                        context.pop();
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error: ${e.toString()}')),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Approve Driver'),
                                      content: const Text(
                                          'Approve this driver for verification?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text('Approve'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true && context.mounted) {
                                    try {
                                      final repo =
                                          ref.read(driversRepositoryProvider);
                                      await repo.approveDriver(
                                        driverId: driverId,
                                        decision: 'approved',
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Driver verified successfully')),
                                        );
                                        ref.invalidate(
                                            driverDetailProvider(driverId));
                                        context.pop();
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error: ${e.toString()}')),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Driver Admin Actions
              if (isDriverAdmin) ...[
                if (driver.status == DriverStatus.verified ||
                    driver.status == DriverStatus.vehicle_assigned) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vehicle Assignment',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          if (driver.status == DriverStatus.verified)
                            FilledButton.icon(
                              onPressed: () {
                                context
                                    .push('/drivers/$driverId/assign-vehicle');
                              },
                              icon: const Icon(Icons.directions_car),
                              label: const Text('Assign Vehicle'),
                            )
                          else if (driver.assignedVehicleNumber != null)
                            Text(
                              'Vehicle: ${driver.assignedVehicleNumber}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (driver.status == DriverStatus.vehicle_assigned ||
                    driver.status == DriverStatus.training_completed) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Training Assignment',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          if (driver.status == DriverStatus.vehicle_assigned)
                            FilledButton.icon(
                              onPressed: () {
                                context.push('/drivers/$driverId/training');
                              },
                              icon: const Icon(Icons.school),
                              label: const Text('Assign Training'),
                            )
                          else if (driver.status ==
                              DriverStatus.training_completed)
                            Text(
                              'Training completed',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
              // Driver Admin Approval Actions
              // Driver Admin can approve drivers at verified, vehicle_assigned, or training_completed status
              if (isDriverAdmin &&
                  (driver.status == DriverStatus.verified ||
                      driver.status == DriverStatus.vehicle_assigned ||
                      driver.status == DriverStatus.training_completed)) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver Approval',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          driver.status == DriverStatus.verified
                              ? 'Driver has been verified. Approve to activate.'
                              : driver.status == DriverStatus.vehicle_assigned
                                  ? 'Vehicle assigned. Approve to activate.'
                                  : 'Training completed. Approve to activate.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Reject Driver'),
                                      content: const Text(
                                          'Are you sure you want to reject this driver?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Reject'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true && context.mounted) {
                                    try {
                                      final repo =
                                          ref.read(driversRepositoryProvider);
                                      await repo.approveDriver(
                                        driverId: driverId,
                                        decision: 'rejected',
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Driver rejected successfully')),
                                        );
                                        ref.invalidate(
                                            driverDetailProvider(driverId));
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error: ${e.toString()}')),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Approve Driver'),
                                      content: const Text(
                                          'Approve this driver for activation?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text('Approve'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true && context.mounted) {
                                    try {
                                      final repo =
                                          ref.read(driversRepositoryProvider);
                                      await repo.approveDriver(
                                        driverId: driverId,
                                        decision: 'approved',
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Driver approved successfully')),
                                        );
                                        ref.invalidate(
                                            driverDetailProvider(driverId));
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error: ${e.toString()}')),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Approve'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Operational Admin Actions
              if (isOperationalAdmin &&
                  driver.status == DriverStatus.training_completed) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Final Approval',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Reject Driver'),
                                      content: const Text(
                                          'Are you sure you want to reject this driver?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Reject'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true && context.mounted) {
                                    try {
                                      final repo =
                                          ref.read(driversRepositoryProvider);
                                      await repo.approveDriver(
                                        driverId: driverId,
                                        decision: 'rejected',
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Driver rejected successfully')),
                                        );
                                        ref.invalidate(
                                            driverDetailProvider(driverId));
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error: ${e.toString()}')),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Approve Driver'),
                                      content: const Text(
                                          'Approve this driver for final activation?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text('Approve'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true && context.mounted) {
                                    try {
                                      final repo =
                                          ref.read(driversRepositoryProvider);
                                      await repo.approveDriver(
                                        driverId: driverId,
                                        decision: 'approved',
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Driver approved successfully')),
                                        );
                                        ref.invalidate(
                                            driverDetailProvider(driverId));
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Error: ${e.toString()}')),
                                        );
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              // Audit Trail
              auditTrailAsync.when(
                data: (auditTrail) {
                  final timeline =
                      auditTrail['timeline'] as List<dynamic>? ?? [];

                  if (timeline.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Audit Trail',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          ...timeline.map((event) {
                            final eventMap = event as Map<String, dynamic>;
                            final type = eventMap['type'] as String? ?? '';
                            final action =
                                eventMap['action'] as String? ?? 'Unknown';
                            final actor =
                                eventMap['actor'] as Map<String, dynamic>?;
                            final timestamp = eventMap['timestamp'] != null
                                ? DateTime.parse(
                                    eventMap['timestamp'] as String)
                                : null;
                            final details =
                                eventMap['details'] as Map<String, dynamic>?;

                            IconData icon;
                            Color iconColor;

                            switch (type) {
                              case 'creation':
                                icon = Icons.person_add;
                                iconColor = Colors.blue;
                                break;
                              case 'audit':
                              case 'driver_log':
                                icon = Icons.info_outline;
                                iconColor = Colors.grey;
                                break;
                              case 'vehicle_assignment':
                                icon = Icons.directions_car;
                                iconColor = Colors.purple;
                                break;
                              case 'background_check':
                                icon = Icons.verified_user;
                                iconColor = Colors.green;
                                break;
                              case 'training':
                                icon = Icons.school;
                                iconColor = Colors.teal;
                                break;
                              default:
                                icon = Icons.event;
                                iconColor = Colors.grey;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(icon, size: 20, color: iconColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          action,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (actor != null)
                                          Text(
                                            'By: ${actor['fullName'] ?? actor['email'] ?? 'Unknown'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        if (timestamp != null)
                                          Text(
                                            _formatDate(timestamp),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        if (details != null &&
                                            details.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              _formatEventDetails(details),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              // Logs
              logsAsync.when(
                data: (logs) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activity Logs',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        if (logs.isEmpty)
                          const Text('No logs available')
                        else
                          ...logs.take(10).map((log) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            log['action']?.toString() ??
                                                'Unknown',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          if (log['createdAt'] != null)
                                            Text(
                                              _formatDate(DateTime.parse(
                                                  log['createdAt'])),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                      ],
                    ),
                  ),
                ),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading driver details'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatEventDetails(Map<String, dynamic> details) {
    final parts = <String>[];
    if (details['vehicle'] != null) {
      final vehicle = details['vehicle'] as Map<String, dynamic>?;
      if (vehicle != null) {
        parts.add('Vehicle: ${vehicle['numberPlate'] ?? 'N/A'}');
      }
    }
    if (details['module'] != null) {
      parts.add('Module: ${details['module']}');
    }
    if (details['status'] != null) {
      parts.add('Status: ${details['status']}');
    }
    return parts.join(', ');
  }
}
