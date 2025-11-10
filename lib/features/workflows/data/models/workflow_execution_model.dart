import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';

class WorkflowExecutionModel extends WorkflowExecution {
  const WorkflowExecutionModel({
    required super.id,
    required super.workflowId,
    required super.status,
    super.startedAt,
    super.stoppedAt,
    super.duration,
    super.errorMessage,
    super.data,
  });

  factory WorkflowExecutionModel.fromJson(Map<String, dynamic> json) {
    return WorkflowExecutionModel(
      id: json['id'] as String,
      workflowId: json['workflowId'] as String? ?? json['workflow_id'] as String,
      status: _parseStatus(json['status'] as String? ?? json['state'] as String?),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : json['started_at'] != null
              ? DateTime.parse(json['started_at'] as String)
              : null,
      stoppedAt: json['stoppedAt'] != null
          ? DateTime.parse(json['stoppedAt'] as String)
          : json['stopped_at'] != null
              ? DateTime.parse(json['stopped_at'] as String)
              : null,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      errorMessage: json['errorMessage'] as String? ?? json['error_message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  static WorkflowExecutionStatus _parseStatus(String? status) {
    if (status == null) return WorkflowExecutionStatus.waiting;
    
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'finished':
        return WorkflowExecutionStatus.success;
      case 'error':
      case 'failed':
      case 'failure':
        return WorkflowExecutionStatus.error;
      case 'running':
      case 'executing':
      case 'active':
        return WorkflowExecutionStatus.running;
      case 'waiting':
      case 'pending':
      case 'queued':
        return WorkflowExecutionStatus.waiting;
      case 'canceled':
      case 'cancelled':
        return WorkflowExecutionStatus.canceled;
      default:
        return WorkflowExecutionStatus.waiting;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workflowId': workflowId,
      'status': _statusToString(status),
      if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
      if (stoppedAt != null) 'stoppedAt': stoppedAt!.toIso8601String(),
      if (duration != null) 'duration': duration!.inMilliseconds,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (data != null) 'data': data,
    };
  }

  String _statusToString(WorkflowExecutionStatus status) {
    switch (status) {
      case WorkflowExecutionStatus.success:
        return 'success';
      case WorkflowExecutionStatus.error:
        return 'error';
      case WorkflowExecutionStatus.running:
        return 'running';
      case WorkflowExecutionStatus.waiting:
        return 'waiting';
      case WorkflowExecutionStatus.canceled:
        return 'canceled';
    }
  }

  @override
  WorkflowExecutionModel copyWith({
    String? id,
    String? workflowId,
    WorkflowExecutionStatus? status,
    DateTime? startedAt,
    DateTime? stoppedAt,
    Duration? duration,
    String? errorMessage,
    Map<String, dynamic>? data,
  }) {
    return WorkflowExecutionModel(
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

