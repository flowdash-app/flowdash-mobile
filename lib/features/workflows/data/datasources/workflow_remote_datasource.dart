import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/core/network/api_client_provider.dart';
import 'package:flowdash_mobile/core/models/paginated_response.dart';
import 'package:flowdash_mobile/features/workflows/data/models/workflow_model.dart';
import 'package:flowdash_mobile/features/workflows/data/models/workflow_execution_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkflowRemoteDataSource {
  final Dio _dio;
  final Logger _logger = AppLogger.getLogger('WorkflowRemoteDataSource');

  WorkflowRemoteDataSource(this._dio);

  Future<List<WorkflowModel>> getWorkflows({
    required String instanceId,
    CancelToken? cancelToken,
  }) async {
    // Legacy method - fetches all workflows without pagination
    // For pagination, use getWorkflowsPaginated
    final result = await getWorkflowsPaginated(
      instanceId: instanceId,
      limit: 250, // Max limit to get all workflows
      cancelToken: cancelToken,
    );
    return result.data;
  }

  Future<({List<WorkflowModel> data, String? nextCursor})> getWorkflowsPaginated({
    required String instanceId,
    int limit = 20,
    String? cursor,
    bool? active,
    CancelToken? cancelToken,
  }) async {
    _logger.info('getWorkflowsPaginated: Entry - instanceId: $instanceId, limit: $limit, cursor: $cursor');

    try {
      final queryParams = <String, dynamic>{
        'instance_id': instanceId,
        'limit': limit,
      };
      if (cursor != null) {
        queryParams['cursor'] = cursor;
      }
      if (active != null) {
        queryParams['active'] = active;
      }

      final response = await _dio.get(
        '/workflows',
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );
      
      // Handle paginated response structure
      if (response.data is List) {
        // Legacy: direct list response (no pagination)
        final workflows = (response.data as List<dynamic>)
            .map((json) => WorkflowModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _logger.info('getWorkflowsPaginated: Success (legacy format) - ${workflows.length} workflows');
        return (data: workflows, nextCursor: null);
      } else if (response.data is Map) {
        // Paginated response
        final paginatedResponse = PaginatedResponse<WorkflowModel>.fromJson(
          response.data as Map<String, dynamic>,
          (json) => WorkflowModel.fromJson(json as Map<String, dynamic>),
        );
        _logger.info('getWorkflowsPaginated: Success - ${paginatedResponse.data.length} workflows, hasNext: ${paginatedResponse.nextCursor != null}');
        return (data: paginatedResponse.data, nextCursor: paginatedResponse.nextCursor);
      } else {
        throw FormatException(
          'Unexpected response format: expected List or Map, got ${response.data.runtimeType}',
        );
      }
    } catch (e, stackTrace) {
      _logger.severe('getWorkflowsPaginated: Failure', e, stackTrace);
      rethrow;
    }
  }

  Future<WorkflowModel> getWorkflowById(
    String id, {
    CancelToken? cancelToken,
  }) async {
    _logger.info('getWorkflowById: Entry - $id');

    try {
      final response = await _dio.get(
        '/workflows/$id',
        cancelToken: cancelToken,
      );
      final workflow =
          WorkflowModel.fromJson(response.data as Map<String, dynamic>);

      _logger.info('getWorkflowById: Success - $id');
      return workflow;
    } catch (e, stackTrace) {
      _logger.severe('getWorkflowById: Failure', e, stackTrace);
      rethrow;
    }
  }

  Future<void> toggleWorkflow(
    String id,
    bool enabled, {
    required String instanceId,
    CancelToken? cancelToken,
  }) async {
    _logger.info('toggleWorkflow: Entry - $id, enabled: $enabled, instanceId: $instanceId');

    try {
      await _dio.post(
        '/workflows/$id/toggle',
        queryParameters: {
          'instance_id': instanceId,
          'enabled': enabled,
        },
        cancelToken: cancelToken,
      );

      _logger.info('toggleWorkflow: Success - $id');
    } catch (e, stackTrace) {
      _logger.severe('toggleWorkflow: Failure', e, stackTrace);
      rethrow;
    }
  }

  Future<({List<WorkflowExecutionModel> data, String? nextCursor})> getExecutions({
    required String instanceId,
    String? workflowId,
    String? status,
    int limit = 20,
    String? cursor,
    CancelToken? cancelToken,
  }) async {
    _logger.info('getExecutions: Entry - instanceId: $instanceId, workflowId: $workflowId, limit: $limit, cursor: $cursor');

    try {
      final queryParams = <String, dynamic>{
        'instance_id': instanceId,
        'limit': limit,
      };
      if (workflowId != null) {
        queryParams['workflow_id'] = workflowId;
      }
      if (status != null) {
        queryParams['status'] = status;
      }
      if (cursor != null) {
        queryParams['cursor'] = cursor;
      }

      final response = await _dio.get(
        '/workflows/executions',
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );

      // Handle paginated response structure
      if (response.data is! Map) {
        throw FormatException(
          'Unexpected response format: expected Map, got ${response.data.runtimeType}',
        );
      }

      final paginatedResponse = PaginatedResponse<WorkflowExecutionModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => WorkflowExecutionModel.fromJson(json as Map<String, dynamic>),
      );

      _logger.info('getExecutions: Success - ${paginatedResponse.data.length} executions, hasNext: ${paginatedResponse.nextCursor != null}');
      return (data: paginatedResponse.data, nextCursor: paginatedResponse.nextCursor);
    } catch (e, stackTrace) {
      _logger.severe('getExecutions: Failure', e, stackTrace);
      rethrow;
    }
  }

  Future<WorkflowExecutionModel> getExecutionById({
    required String executionId,
    required String instanceId,
    bool includeData = true,
    CancelToken? cancelToken,
  }) async {
    _logger.info('getExecutionById: Entry - executionId: $executionId, instanceId: $instanceId, includeData: $includeData');

    try {
      // Use POST with body for secure instance_id handling
      final response = await _dio.post(
        '/workflows/executions/$executionId',
        data: {
          'instance_id': instanceId,
          'include_data': includeData,
        },
        cancelToken: cancelToken,
      );
      final execution =
          WorkflowExecutionModel.fromJson(response.data as Map<String, dynamic>);

      _logger.info('getExecutionById: Success - $executionId');
      return execution;
    } catch (e, stackTrace) {
      _logger.severe('getExecutionById: Failure', e, stackTrace);
      rethrow;
    }
  }

  Future<String> retryExecution({
    required String executionId,
    required String instanceId,
    CancelToken? cancelToken,
  }) async {
    _logger.info('retryExecution: Entry - executionId: $executionId, instanceId: $instanceId');

    try {
      // Use POST with body for secure instance_id handling
      final response = await _dio.post(
        '/workflows/executions/$executionId/retry',
        data: {
          'instance_id': instanceId,
        },
        cancelToken: cancelToken,
      );

      // Extract new execution ID from response
      final newExecutionId = response.data['new_execution_id'] as String?;
      
      if (newExecutionId == null || newExecutionId.isEmpty) {
        throw FormatException(
          'Invalid response: new_execution_id not found in response',
        );
      }

      _logger.info('retryExecution: Success - executionId: $executionId, newExecutionId: $newExecutionId');
      return newExecutionId;
    } catch (e, stackTrace) {
      _logger.severe('retryExecution: Failure', e, stackTrace);
      rethrow;
    }
  }
}

final workflowRemoteDataSourceProvider =
    Provider<WorkflowRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkflowRemoteDataSource(apiClient.dio);
});
