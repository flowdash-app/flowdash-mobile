import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:flowdash_mobile/features/workflows/data/models/execution_data_models.dart';

part 'workflow_execution_model.freezed.dart';
part 'workflow_execution_model.g.dart';

@freezed
sealed class WorkflowExecutionModel with _$WorkflowExecutionModel {
  const factory WorkflowExecutionModel({
    required String id,
    @JsonKey(fromJson: _workflowIdFromJson) required String workflowId,
    @JsonKey(fromJson: _statusFromJson) required WorkflowExecutionStatus status,
    @JsonKey(fromJson: _dateTimeFromJson) DateTime? startedAt,
    @JsonKey(fromJson: _dateTimeFromJson) DateTime? stoppedAt,
    @JsonKey(fromJson: _durationFromJson) Duration? duration,
    @JsonKey(fromJson: _errorMessageFromJson) String? errorMessage,
    @JsonKey(fromJson: _executionDataFromJson) ExecutionData? data,
  }) = _WorkflowExecutionModel;

  factory WorkflowExecutionModel.fromJson(Map<String, dynamic> json) =>
      _$WorkflowExecutionModelFromJson(json);
}

// JSON conversion helpers
String _workflowIdFromJson(dynamic json) {
  if (json is String) return json;
  if (json is Map) {
    return json['workflowId'] as String? ?? json['workflow_id'] as String;
  }
  return json.toString();
}

WorkflowExecutionStatus _statusFromJson(dynamic json) {
  if (json == null) return WorkflowExecutionStatus.waiting;
  
  final status = json is String ? json : json.toString();
  
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

DateTime? _dateTimeFromJson(dynamic json) {
  if (json == null) return null;
  if (json is String) {
    try {
      return DateTime.parse(json);
    } catch (e) {
      return null;
    }
  }
  return null;
}

Duration? _durationFromJson(dynamic json) {
  if (json == null) return null;
  if (json is int) {
    return Duration(milliseconds: json);
  }
  return null;
}

String? _errorMessageFromJson(dynamic json) {
  if (json == null) return null;
  if (json is String) return json;
  if (json is Map) {
    return json['errorMessage'] as String? ?? json['error_message'] as String?;
  }
  return json.toString();
}

ExecutionData? _executionDataFromJson(dynamic json) {
  if (json == null) return null;
  
  // Handle different JSON structures
  if (json is Map<String, dynamic>) {
    try {
      // Try to parse as ExecutionData directly
      return ExecutionData.fromJson(json);
    } catch (e) {
      // If direct parsing fails, try to extract data field
      // n8n might return the data in a nested structure
      try {
        // Check if there's a 'data' field that contains the execution data
        if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
          return ExecutionData.fromJson(json['data'] as Map<String, dynamic>);
        }
        // If the json itself looks like execution data structure, try parsing it
        if (json.containsKey('resultData') || json.containsKey('executionData')) {
          return ExecutionData.fromJson(json);
        }
      } catch (e2) {
        // Log the error for debugging but don't crash
        // The data might be in a different format than expected
        return null;
      }
      return null;
    }
  }
  
  // If it's not a Map, it's not valid execution data
  return null;
}

extension WorkflowExecutionModelToEntity on WorkflowExecutionModel {
  WorkflowExecution toEntity() {
    return WorkflowExecution(
      id: id,
      workflowId: workflowId,
      status: status,
      startedAt: startedAt,
      stoppedAt: stoppedAt,
      duration: duration,
      errorMessage: errorMessage,
      data: data,
    );
  }
}

extension WorkflowExecutionToModel on WorkflowExecution {
  WorkflowExecutionModel toModel() {
    return WorkflowExecutionModel(
      id: id,
      workflowId: workflowId,
      status: status,
      startedAt: startedAt,
      stoppedAt: stoppedAt,
      duration: duration,
      errorMessage: errorMessage,
      data: data,
    );
  }
}
