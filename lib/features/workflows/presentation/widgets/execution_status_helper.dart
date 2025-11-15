import 'package:flutter/material.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';

/// A utility class for getting execution status display properties.
/// 
/// This helper centralizes the logic for mapping execution status
/// to colors, icons, and text, avoiding duplication across widgets.
class ExecutionStatusHelper {
  // Private constructor to prevent instantiation
  ExecutionStatusHelper._();

  /// Get the color associated with a workflow execution status
  static Color getStatusColor(WorkflowExecutionStatus status) {
    switch (status) {
      case WorkflowExecutionStatus.success:
        return Colors.green;
      case WorkflowExecutionStatus.error:
        return Colors.red;
      case WorkflowExecutionStatus.running:
        return Colors.blue;
      case WorkflowExecutionStatus.waiting:
        return Colors.orange;
      case WorkflowExecutionStatus.canceled:
        return Colors.grey;
    }
  }

  /// Get the icon associated with a workflow execution status
  static IconData getStatusIcon(WorkflowExecutionStatus status) {
    switch (status) {
      case WorkflowExecutionStatus.success:
        return Icons.check_circle_outline;
      case WorkflowExecutionStatus.error:
        return Icons.error_outline;
      case WorkflowExecutionStatus.running:
        return Icons.play_circle_outline;
      case WorkflowExecutionStatus.waiting:
        return Icons.schedule;
      case WorkflowExecutionStatus.canceled:
        return Icons.cancel_outlined;
    }
  }

  /// Get the text associated with a workflow execution status
  static String getStatusText(WorkflowExecutionStatus status) {
    switch (status) {
      case WorkflowExecutionStatus.success:
        return 'Success';
      case WorkflowExecutionStatus.error:
        return 'Error';
      case WorkflowExecutionStatus.running:
        return 'Running';
      case WorkflowExecutionStatus.waiting:
        return 'Waiting';
      case WorkflowExecutionStatus.canceled:
        return 'Canceled';
    }
  }
}

