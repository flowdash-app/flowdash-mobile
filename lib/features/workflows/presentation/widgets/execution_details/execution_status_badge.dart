import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:flutter/material.dart';

class ExecutionStatusBadge extends StatelessWidget {
  final WorkflowExecutionStatus status;

  const ExecutionStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case WorkflowExecutionStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        statusText = 'Success';
        break;
      case WorkflowExecutionStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        statusText = 'Error';
        break;
      case WorkflowExecutionStatus.running:
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle_outline;
        statusText = 'Running';
        break;
      case WorkflowExecutionStatus.waiting:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Waiting';
        break;
      case WorkflowExecutionStatus.canceled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel_outlined;
        statusText = 'Canceled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 20, color: statusColor),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

