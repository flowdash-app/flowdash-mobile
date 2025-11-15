import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/execution_status_helper.dart';
import 'package:flowdash_mobile/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A StatelessWidget that displays an execution card.
///
/// Extracted from WorkflowDetailsPage._buildExecutionCard()
class ExecutionCardWidget extends StatelessWidget {
  final WorkflowExecution execution;
  final VoidCallback onTap;

  const ExecutionCardWidget({super.key, required this.execution, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = ExecutionStatusHelper.getStatusColor(execution.status);
    final statusIcon = ExecutionStatusHelper.getStatusIcon(execution.status);
    final statusText = ExecutionStatusHelper.getStatusText(execution.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(
          'Execution #${execution.id.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            StatusBadge(
              statusText: statusText,
              statusColor: statusColor,
              statusIcon: statusIcon,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            const SizedBox(height: 8),
            Text(_formatDate(execution.startedAt), style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Unknown time';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }
}
