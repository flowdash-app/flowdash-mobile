// ignore_for_file: invalid_annotation_target

import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/features/workflows/data/models/execution_data_models.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
  final logger = AppLogger.getLogger('WorkflowExecutionModel');

  if (json == null) {
    logger.fine('_executionDataFromJson: json is null');
    return null;
  }

  // Handle different JSON structures
  if (json is Map<String, dynamic>) {
    logger.info('_executionDataFromJson: Entry - json keys: ${json.keys.toList()}');

    try {
      // Check if resultData.runData contains arrays that need transformation
      if (json.containsKey('resultData') && json['resultData'] is Map<String, dynamic>) {
        final resultData = json['resultData'] as Map<String, dynamic>;

        if (resultData.containsKey('runData') && resultData['runData'] is Map<String, dynamic>) {
          final runData = resultData['runData'] as Map<String, dynamic>;
          logger.info('_executionDataFromJson: Found runData with ${runData.length} nodes');

          // Check if any values are arrays (n8n API format)
          bool needsTransformation = false;
          final transformedRunData = <String, dynamic>{};

          for (final entry in runData.entries) {
            final nodeName = entry.key;
            final nodeValue = entry.value;

            if (nodeValue is List && nodeValue.isNotEmpty) {
              // Array format: [{startTime: ..., data: {main: [...]}}]
              logger.info(
                '_executionDataFromJson: Node "$nodeName" has array format with ${nodeValue.length} items',
              );
              needsTransformation = true;

              // Extract data.main from the first execution item
              final firstItem = nodeValue[0] as Map<String, dynamic>?;
              if (firstItem != null && firstItem.containsKey('data')) {
                final itemData = firstItem['data'] as Map<String, dynamic>?;
                if (itemData != null && itemData.containsKey('main')) {
                  // Extract executionStatus for type/error fields
                  final executionStatus = firstItem['executionStatus'] as String?;
                  final error = firstItem['error'] as String?;

                  // Create NodeRunData structure
                  transformedRunData[nodeName] = {
                    'main': itemData['main'],
                    'type': executionStatus,
                    'error': error,
                  };
                  logger.fine(
                    '_executionDataFromJson: Transformed "$nodeName" - extracted main data',
                  );
                } else {
                  logger.warning(
                    '_executionDataFromJson: Node "$nodeName" array item missing data.main',
                  );
                  transformedRunData[nodeName] = nodeValue; // Keep original if transformation fails
                }
              } else {
                logger.warning(
                  '_executionDataFromJson: Node "$nodeName" array item missing data field',
                );
                transformedRunData[nodeName] = nodeValue; // Keep original if transformation fails
              }
            } else {
              // Already in correct format (single object)
              transformedRunData[nodeName] = nodeValue;
            }
          }

          if (needsTransformation) {
            logger.info('_executionDataFromJson: Transforming runData arrays to single objects');
            // Create a new json map with transformed runData
            final transformedJson = Map<String, dynamic>.from(json);
            transformedJson['resultData'] = {...resultData, 'runData': transformedRunData};

            try {
              final result = ExecutionData.fromJson(transformedJson);
              logger.info(
                '_executionDataFromJson: Success - parsed ExecutionData with transformed runData',
              );
              return result;
            } catch (e, stackTrace) {
              logger.severe(
                '_executionDataFromJson: Failed to parse transformed json',
                e,
                stackTrace,
              );
              // Fall through to try original parsing
            }
          }
        }
      }

      // Try to parse as ExecutionData directly (handles both transformed and original formats)
      final result = ExecutionData.fromJson(json);
      logger.info('_executionDataFromJson: Success - parsed ExecutionData directly');
      return result;
    } catch (e, stackTrace) {
      logger.warning(
        '_executionDataFromJson: Direct parsing failed, trying alternative structures',
        e,
        stackTrace,
      );

      // If direct parsing fails, try to extract data field
      // n8n might return the data in a nested structure
      try {
        // Check if there's a 'data' field that contains the execution data
        if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
          logger.info('_executionDataFromJson: Trying nested data field');
          return ExecutionData.fromJson(json['data'] as Map<String, dynamic>);
        }
        // If the json itself looks like execution data structure, try parsing it
        if (json.containsKey('resultData') || json.containsKey('executionData')) {
          logger.info(
            '_executionDataFromJson: JSON contains resultData or executionData, but parsing failed',
          );
          logger.severe('_executionDataFromJson: Final parsing attempt failed', e, stackTrace);
        }
      } catch (e2, stackTrace2) {
        logger.severe('_executionDataFromJson: All parsing attempts failed', e2, stackTrace2);
        logger.severe('_executionDataFromJson: Original error', e, stackTrace);
      }
      return null;
    }
  }

  logger.warning(
    '_executionDataFromJson: json is not a Map<String, dynamic>, type: ${json.runtimeType}',
  );
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
