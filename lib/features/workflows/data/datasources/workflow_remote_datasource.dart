import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/core/network/api_client_provider.dart';
import 'package:flowdash_mobile/features/workflows/data/models/workflow_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkflowRemoteDataSource {
  final Dio _dio;
  final Logger _logger = AppLogger.getLogger('WorkflowRemoteDataSource');

  WorkflowRemoteDataSource(this._dio);

  Future<List<WorkflowModel>> getWorkflows({CancelToken? cancelToken}) async {
    _logger.info('getWorkflows: Entry');

    try {
      final response = await _dio.get(
        '/workflows',
        cancelToken: cancelToken,
      );
      final List<dynamic> data = response.data as List<dynamic>;
      final workflows = data
          .map((json) => WorkflowModel.fromJson(json as Map<String, dynamic>))
          .toList();

      _logger.info('getWorkflows: Success - ${workflows.length} workflows');
      return workflows;
    } catch (e, stackTrace) {
      _logger.severe('getWorkflows: Failure', e, stackTrace);
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
}

final workflowRemoteDataSourceProvider =
    Provider<WorkflowRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkflowRemoteDataSource(apiClient.dio);
});
