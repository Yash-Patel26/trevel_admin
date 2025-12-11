import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/auth/auth_controller.dart';
import '../data/vehicles_repository.dart';
import '../data/vehicle_model.dart';
import 'vehicles_page.dart';

final vehicleDetailProvider =
    FutureProvider.autoDispose.family<Vehicle, int>((ref, vehicleId) async {
  final repo = ref.watch(vehiclesRepositoryProvider);
  final vehicles = await repo.getVehicles();
  return vehicles.firstWhere((v) => v.id == vehicleId);
});

final vehicleLogsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, vehicleId) async {
  final repo = ref.watch(vehiclesRepositoryProvider);
  return await repo.getVehicleLogs(vehicleId);
});

final vehicleMetricsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, vehicleId) async {
  final repo = ref.watch(vehiclesRepositoryProvider);
  return await repo.getVehicleMetrics(vehicleId);
});

final vehicleAssignmentLogsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int>((ref, vehicleId) async {
  final repo = ref.watch(vehiclesRepositoryProvider);
  return await repo.getVehicleAssignmentLogs(vehicleId);
});

class VehicleDetailPage extends ConsumerWidget {
  final int vehicleId;

  const VehicleDetailPage({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(vehicleDetailProvider(vehicleId));
    final logsAsync = ref.watch(vehicleLogsProvider(vehicleId));
    final metricsAsync = ref.watch(vehicleMetricsProvider(vehicleId));
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final canApprove = user?.hasPermission('vehicle:review') == true ||
        user?.hasPermission('vehicle:approve') == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
      ),
      body: vehicleAsync.when(
        data: (vehicle) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: vehicle.status.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: vehicle.status.color,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vehicle.vehicleNumber,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${vehicle.make} ${vehicle.model} (${vehicle.year})',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(vehicle.status.displayName),
                            backgroundColor:
                                vehicle.status.color.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildInfoRow(
                          context, 'License Plate', vehicle.licensePlate),
                      _buildInfoRow(context, 'Color', vehicle.color),
                      _buildInfoRow(
                          context, 'Created', _formatDate(vehicle.createdAt)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Insurance Info
              if (vehicle.insurancePolicyNumber != null ||
                  vehicle.insuranceExpiryDate != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insurance Information',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        if (vehicle.insurancePolicyNumber != null)
                          _buildInfoRow(context, 'Policy Number',
                              vehicle.insurancePolicyNumber!),
                        if (vehicle.insuranceExpiryDate != null)
                          _buildInfoRow(
                            context,
                            'Expiry Date',
                            _formatDate(vehicle.insuranceExpiryDate!),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Access Keys
              if (vehicle.liveLocationAccessKey != null ||
                  vehicle.dashcamAccessKey != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Access Keys',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        if (vehicle.liveLocationAccessKey != null)
                          _buildInfoRow(context, 'Live Location Key',
                              vehicle.liveLocationAccessKey!),
                        if (vehicle.dashcamAccessKey != null)
                          _buildInfoRow(context, 'Dashcam Key',
                              vehicle.dashcamAccessKey!),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Driver Assignment Section
              if (vehicle.assignedDriverName != null ||
                  vehicle.assignedDriverStatus != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver Assignment',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        if (vehicle.assignedDriverName != null)
                          _buildInfoRow(
                              context, 'Assigned Driver', vehicle.assignedDriverName!),
                        if (vehicle.assignedDriverStatus != null)
                          _buildInfoRow(
                            context,
                            'Driver Status',
                            vehicle.assignedDriverStatus!.toUpperCase(),
                          ),
                        // Show reassign button if driver is inactive
                        if (vehicle.assignedDriverStatus != null &&
                            (vehicle.assignedDriverStatus!.toLowerCase() == 'inactive' ||
                                vehicle.assignedDriverStatus!.toLowerCase() == 'suspended')) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Assigned driver is inactive. Please reassign this vehicle.',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () async {
                              final result = await context.push<bool>(
                                '/vehicles/$vehicleId/reassign',
                                extra: vehicle,
                              );
                              if (result == true && context.mounted) {
                                ref.invalidate(vehicleDetailProvider(vehicleId));
                                ref.invalidate(vehicleAssignmentLogsProvider(vehicleId));
                                ref.invalidate(vehiclesProvider);
                              }
                            },
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Reassign Driver'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Assignment Logs
              ref.watch(vehicleAssignmentLogsProvider(vehicleId)).when(
                    data: (assignmentLogs) {
                      if (assignmentLogs.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assignment History',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              ...assignmentLogs.take(10).map((log) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.swap_horiz,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                log['action']?.toString() ??
                                                    'Driver Assignment',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              if (log['driverName'] != null)
                                                Text(
                                                  'Driver: ${log['driverName']}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              if (log['createdAt'] != null)
                                                Text(
                                                  _formatDate(DateTime.parse(
                                                      log['createdAt'])),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
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
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
              const SizedBox(height: 16),
              // Approval Actions (for Fleet Admin)
              if (canApprove && vehicle.status == VehicleStatus.pending)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Vehicle',
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
                                onPressed: () => _showReviewDialog(
                                    context, ref, vehicleId, 'rejected'),
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
                                onPressed: () => _showReviewDialog(
                                    context, ref, vehicleId, 'approved'),
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
              // Metrics
              metricsAsync.when(
                data: (metrics) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metrics',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        ...metrics.entries.map((e) => _buildInfoRow(
                              context,
                              e.key,
                              e.value.toString(),
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
              const Text('Error loading vehicle details'),
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

  void _showReviewDialog(
      BuildContext context, WidgetRef ref, int vehicleId, String status) {
    final commentsController = TextEditingController();
    final isApproving = status == 'approved';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isApproving ? 'Approve Vehicle' : 'Reject Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isApproving
                  ? 'Are you sure you want to approve this vehicle?'
                  : 'Are you sure you want to reject this vehicle?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Comments (optional)',
                hintText: 'Add any comments about this decision',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final repo = ref.read(vehiclesRepositoryProvider);
                await repo.reviewVehicle(
                  vehicleId: vehicleId,
                  status: status,
                  comments: commentsController.text.trim().isEmpty
                      ? null
                      : commentsController.text.trim(),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  ref.invalidate(vehicleDetailProvider(vehicleId));
                  ref.invalidate(vehiclesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isApproving
                              ? 'Vehicle approved successfully'
                              : 'Vehicle rejected',
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: isApproving ? Colors.green : Colors.red,
            ),
            child: Text(isApproving ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }
}
