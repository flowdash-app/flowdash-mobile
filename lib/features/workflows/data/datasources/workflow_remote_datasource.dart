import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/core/network/api_client_provider.dart';
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
      Map<String, dynamic> responseData;
      if (response.data is Map) {
        responseData = response.data as Map<String, dynamic>;
      } else if (response.data is List) {
        // Legacy: direct list response (no pagination)
        final workflows = (response.data as List<dynamic>)
            .map((json) => WorkflowModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _logger.info('getWorkflowsPaginated: Success (legacy format) - ${workflows.length} workflows');
        return (data: workflows, nextCursor: null);
      } else {
        throw FormatException(
          'Unexpected response format: expected List or Map, got ${response.data.runtimeType}',
        );
      }

      // Extract data array
      List<dynamic> data;
      if (responseData.containsKey('data')) {
        data = responseData['data'] as List<dynamic>;
      } else {
        // Fallback for other response structures
        data = [];
      }

      final workflows = data
          .map((json) => WorkflowModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final nextCursor = responseData['nextCursor'] as String?;

      _logger.info('getWorkflowsPaginated: Success - ${workflows.length} workflows, hasNext: ${nextCursor != null}');
      return (data: workflows, nextCursor: nextCursor);
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
    CancelToken? cancelToken,
  }) async {
    _logger.info('toggleWorkflow: Entry - $id, enabled: $enabled');

    try {
      await _dio.patch(
        '/workflows/$id',
        data: {'active': enabled},
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
      Map<String, dynamic> responseData;
      if (response.data is Map) {
        responseData = response.data as Map<String, dynamic>;
      } else {
        throw FormatException(
          'Unexpected response format: expected Map, got ${response.data.runtimeType}',
        );
      }

      List<dynamic> executionsData;
      if (responseData.containsKey('data')) {
        executionsData = responseData['data'] as List<dynamic>;
      } else {
        executionsData = [];
      }

      final executions = executionsData
          .map((json) => WorkflowExecutionModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final nextCursor = responseData['nextCursor'] as String?;

      _logger.info('getExecutions: Success - ${executions.length} executions, hasNext: ${nextCursor != null}');
      return (data: executions, nextCursor: nextCursor);
    } catch (e, stackTrace) {
      _logger.severe('getExecutions: Failure', e, stackTrace);
      rethrow;
    }
  }

  Future<WorkflowExecutionModel> getExecutionById({
    required String executionId,
    required String instanceId,
    CancelToken? cancelToken,
  }) async {
    _logger.info('getExecutionById: Entry - executionId: $executionId, instanceId: $instanceId');

    try {
      final response = await _dio.get(
        '/workflows/executions/$executionId',
        queryParameters: {'instance_id': instanceId},
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
}

final workflowRemoteDataSourceProvider =
    Provider<WorkflowRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkflowRemoteDataSource(apiClient.dio);
});
