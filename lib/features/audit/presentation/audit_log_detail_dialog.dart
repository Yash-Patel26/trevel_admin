import 'package:flutter/material.dart';

class AuditLogDetailDialog extends StatelessWidget {
  final Map<String, dynamic> log;

  const AuditLogDetailDialog({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Audit Log Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
                context, 'Action', log['action']?.toString() ?? 'Unknown'),
            _buildInfoRow(context, 'Entity Type',
                log['entityType']?.toString() ?? 'Unknown'),
            if (log['entityId'] != null)
              _buildInfoRow(
                  context, 'Entity ID', log['entityId']?.toString() ?? ''),
            if (log['actorId'] != null)
              _buildInfoRow(
                  context, 'Actor ID', log['actorId']?.toString() ?? ''),
            if (log['createdAt'] != null)
              _buildInfoRow(
                  context, 'Timestamp', _formatDateTime(log['createdAt'])),
            if (log['before'] != null) ...[
              const SizedBox(height: 16),
              Text(
                'Before',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log['before'].toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            if (log['after'] != null) ...[
              const SizedBox(height: 16),
              Text(
                'After',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log['after'].toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '';
    try {
      final dt =
          dateTime is String ? DateTime.parse(dateTime) : dateTime as DateTime;
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateTime.toString();
    }
  }
}
