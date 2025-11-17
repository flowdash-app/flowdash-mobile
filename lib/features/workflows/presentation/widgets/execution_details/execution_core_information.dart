import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/execution_details/execution_info_row.dart';
import 'package:flutter/material.dart';

class ExecutionCoreInformation extends StatelessWidget {
  final WorkflowExecution execution;
  final String? workflowName;

  const ExecutionCoreInformation({
    super.key,
    required this.execution,
    this.workflowName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (workflowName != null)
          ExecutionInfoRow(label: 'Workflow', value: workflowName!),
        ExecutionInfoRow(label: 'Execution ID', value: execution.id),
        ExecutionInfoRow(label: 'Workflow ID', value: execution.workflowId),
        if (execution.startedAt != null)
          ExecutionInfoRow(
            label: 'Started',
            value: _formatDateTime(execution.startedAt!),
          ),
        if (execution.stoppedAt != null)
          ExecutionInfoRow(
            label: 'Stopped',
            value: _formatDateTime(execution.stoppedAt!),
          ),
        if (execution.duration != null)
          ExecutionInfoRow(
            label: 'Duration',
            value: _formatDuration(execution.duration!),
          ),
      ],
    );
  }

  static String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }
}

