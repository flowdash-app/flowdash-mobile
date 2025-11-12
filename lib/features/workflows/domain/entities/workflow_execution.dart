import 'package:flowdash_mobile/features/workflows/data/models/execution_data_models.dart';

enum WorkflowExecutionStatus {
  success,
  error,
  running,
  waiting,
  canceled,
}

class WorkflowExecution {
  final String id;
  final String workflowId;
  final WorkflowExecutionStatus status;
  final DateTime? startedAt;
  final DateTime? stoppedAt;
  final Duration? duration;
  final String? errorMessage;
  final ExecutionData? data;

  const WorkflowExecution({
    required this.id,
    required this.workflowId,
    required this.status,
    this.startedAt,
    this.stoppedAt,
    this.duration,
    this.errorMessage,
    this.data,
  });

  WorkflowExecution copyWith({
    String? id,
    String? workflowId,
    WorkflowExecutionStatus? status,
    DateTime? startedAt,
    DateTime? stoppedAt,
    Duration? duration,
    String? errorMessage,
    ExecutionData? data,
  }) {
    return WorkflowExecution(
      id: id ?? this.id,
      workflowId: workflowId ?? this.workflowId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      stoppedAt: stoppedAt ?? this.stoppedAt,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
      data: data ?? this.data,
    );
  }
}

