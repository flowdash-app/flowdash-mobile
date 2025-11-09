import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/core/utils/retry_helper.dart';
import 'package:flowdash_mobile/core/analytics/analytics_service.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';
import 'package:flowdash_mobile/features/workflows/domain/repositories/workflow_repository.dart';
import 'package:flowdash_mobile/features/workflows/data/datasources/workflow_remote_datasource.dart';
import 'package:flowdash_mobile/features/workflows/data/datasources/workflow_local_datasource.dart';

class WorkflowRepositoryImpl implements WorkflowRepository {
  final WorkflowRemoteDataSource _remoteDataSource;
  final WorkflowLocalDataSource _localDataSource;
  final AnalyticsService _analytics;
  final Logger _logger = AppLogger.getLogger('WorkflowRepositoryImpl');

  WorkflowRepositoryImpl({
    required WorkflowRemoteDataSource remoteDataSource,
    required WorkflowLocalDataSource localDataSource,
    required AnalyticsService analytics,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _analytics = analytics;

  @override
  Future<List<Workflow>> getWorkflows({CancelToken? cancelToken}) async {
    final trace = _analytics.startTrace('get_workflows');
    trace?.start();

    _logger.info('getWorkflows: Entry');

    try {
      // Try local cache first
      final cached = await _localDataSource.getWorkflows();
      if (cached != null) {
        _logger.info('getWorkflows: Success (cached)');
        await _analytics.logSuccess(
            action: 'get_workflows', parameters: {'source': 'cache'});
        trace?.stop();
        return cached;
      }

      // Fetch from remote with retry
      final workflows = await RetryHelper.retry(
        operation: () =>
            _remoteDataSource.getWorkflows(cancelToken: cancelToken),
        maxAttempts: 3,
      );

      await _localDataSource.cacheWorkflows(workflows);
      _logger.info(
          'getWorkflows: Success (remote) - ${workflows.length} workflows');
      await _analytics.logSuccess(
        action: 'get_workflows',
        parameters: {'source': 'remote', 'count': workflows.length},
      );
      trace?.stop();
      return workflows;
    } catch (e, stackTrace) {
      await _analytics.logFailure(
        action: 'get_workflows',
        error: e.toString(),
      );
      trace?.stop();
      _logger.severe('getWorkflows: Failure', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Workflow> getWorkflowById(String id,
      {CancelToken? cancelToken}) async {
    final trace = _analytics.startTrace('get_workflow_by_id');
    trace?.start();

    _logger.info('getWorkflowById: Entry - $id');

    try {
      final workflow = await RetryHelper.retry(
        operation: () =>
            _remoteDataSource.getWorkflowById(id, cancelToken: cancelToken),
        maxAttempts: 3,
      );

      _logger.info('getWorkflowById: Success - $id');
      await _analytics.logSuccess(
        action: 'get_workflow_by_id',
        parameters: {'workflow_id': id},
      );
      trace?.stop();
      return workflow;
    } catch (e, stackTrace) {
      await _analytics.logFailure(
        action: 'get_workflow_by_id',
        error: e.toString(),
        parameters: {'workflow_id': id},
      );
      trace?.stop();
      _logger.severe('getWorkflowById: Failure', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> toggleWorkflow(String id, bool enabled,
      {CancelToken? cancelToken}) async {
    final trace = _analytics.startTrace('toggle_workflow');
    trace?.start();

    _logger.info('toggleWorkflow: Entry - $id, enabled: $enabled');

    try {
      await RetryHelper.retry(
        operation: () => _remoteDataSource.toggleWorkflow(id, enabled,
            cancelToken: cancelToken),
        maxAttempts: 3,
      );

      // Invalidate cache after toggle
      await _localDataSource.clearCache();

      _logger.info('toggleWorkflow: Success - $id');
      await _analytics.logSuccess(
        action: 'toggle_workflow',
        parameters: {'workflow_id': id, 'enabled': enabled},
      );
      trace?.stop();
    } catch (e, stackTrace) {
      await _analytics.logFailure(
        action: 'toggle_workflow',
        error: e.toString(),
        parameters: {'workflow_id': id, 'enabled': enabled},
      );
      trace?.stop();
      _logger.severe('toggleWorkflow: Failure', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> refreshWorkflows() async {
    _logger.info('refreshWorkflows: Entry');

    try {
      await _localDataSource.clearCache();
      _logger.info('refreshWorkflows: Success');
    } catch (e, stackTrace) {
      _logger.severe('refreshWorkflows: Failure', e, stackTrace);
      rethrow;
    }
  }
}
