import 'package:dio/dio.dart';
import 'package:flowdash_mobile/core/analytics/analytics_service.dart';
import 'package:flowdash_mobile/core/errors/exceptions.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/features/instances/domain/repositories/instance_repository.dart';
import 'package:flowdash_mobile/features/workflows/data/datasources/workflow_local_datasource.dart';
import 'package:flowdash_mobile/features/workflows/data/datasources/workflow_remote_datasource.dart';
import 'package:flowdash_mobile/features/workflows/data/models/workflow_execution_model.dart';
import 'package:flowdash_mobile/features/workflows/data/models/workflow_model.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:flowdash_mobile/features/workflows/domain/repositories/workflow_repository.dart';
import 'package:logging/logging.dart';

class WorkflowRepositoryImpl implements WorkflowRepository {
  final WorkflowRemoteDataSource _remoteDataSource;
  final WorkflowLocalDataSource _localDataSource;
  final AnalyticsService _analytics;
  final InstanceRepository _instanceRepository;
  final Logger _logger = AppLogger.getLogger('WorkflowRepositoryImpl');

  WorkflowRepositoryImpl({
    required WorkflowRemoteDataSource remoteDataSource,
    required WorkflowLocalDataSource localDataSource,
    required AnalyticsService analytics,
    required InstanceRepository instanceRepository,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _analytics = analytics,
       _instanceRepository = instanceRepository;

  @override
  Future<List<Workflow>> getWorkflows({CancelToken? cancelToken}) async {
    final trace = _analytics.startTrace('get_workflows');
    trace?.start();

    _logger.info('getWorkflows: Entry');

    try {
      // Try local cache first
      final cached = await _localDataSource.getWorkflows();
      if (cached != null && cached.isNotEmpty) {
        _logger.info('getWorkflows: Success (cached) - ${cached.length} workflows');
        await _analytics.logSuccess(
          action: 'get_workflows',
          parameters: {'source': 'cache', 'count': cached.length},
        );
        trace?.stop();
        // Convert WorkflowModel list to Workflow list
        return cached.map((w) => w.toEntity()).toList();
      }

      // If cache is empty, clear it and fetch from remote
      if (cached != null && cached.isEmpty) {
        _logger.info('getWorkflows: Cache is empty, clearing and fetching from remote');
        await _localDataSource.clearCache();
      }

      // Get all instances to fetch workflows from all of them
      final instances = await _instanceRepository.getInstances(cancelToken: cancelToken);
      if (instances.isEmpty) {
        throw Exception('No instances found. Please add an instance first.');
      }

      // Fetch workflows from all enabled instances and track which instance they belong to
      final allWorkflows = <({WorkflowModel workflow, String instanceId, String instanceName})>[];
      for (final instance in instances) {
        // Skip disabled instances - don't fetch workflows for them
        if (!instance.active) {
          continue;
        }

        try {
          final workflows = await _remoteDataSource.getWorkflows(
            instanceId: instance.id,
            cancelToken: cancelToken,
          );
          for (final workflow in workflows) {
            allWorkflows.add((
              workflow: workflow,
              instanceId: instance.id,
              instanceName: instance.name,
            ));
          }
        } catch (e) {
          // Log error but continue with other instances
          _logger.warning(
            'getWorkflows: Failed to fetch workflows for instance ${instance.id}: $e',
          );
        }
      }

      // Sort workflows: by instance ID, then by active status (enabled first), then by name
      allWorkflows.sort((a, b) {
        // First by instance ID (alphabetically by instance name)
        final instanceCompare = a.instanceName.compareTo(b.instanceName);
        if (instanceCompare != 0) return instanceCompare;

        // Then by active status (enabled/active first)
        if (a.workflow.active != b.workflow.active) {
          return b.workflow.active ? 1 : -1; // Active (enabled) first
        }

        // Finally alphabetically by workflow name
        return a.workflow.name.compareTo(b.workflow.name);
      });

      // Extract just the workflows for caching (without instance info)
      // The workflows from remote are already WorkflowModel instances
      final workflowsList = allWorkflows.map((w) => w.workflow).toList();
      await _localDataSource.cacheWorkflows(workflowsList);
      _logger.info(
        'getWorkflows: Success (remote) - ${allWorkflows.length} workflows from ${instances.length} instances',
      );
      await _analytics.logSuccess(
        action: 'get_workflows',
        parameters: {
          'source': 'remote',
          'count': allWorkflows.length,
          'instances': instances.length,
        },
      );
      trace?.stop();
      // Convert WorkflowModel list to Workflow list for return
      return workflowsList.map((w) => w.toEntity()).toList();
    } catch (e, stackTrace) {
      // Don't send business logic exceptions to Crashlytics
      final errorString = e.toString();
      final isBusinessLogicException =
          errorString.contains('No active instance found') ||
          errorString.contains('No instances found') ||
          errorString.contains('Please activate');

      await _analytics.logFailure(
        action: 'get_workflows',
        error: errorString,
        sendToCrashlytics: !isBusinessLogicException,
      );
      trace?.stop();
      _logger.severe('getWorkflows: Failure', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<({List<Workflow> data, String? nextCursor})> getWorkflowsPaginated({
    required String instanceId,
    int limit = 20,
    String? cursor,
    bool? active,
    CancelToken? cancelToken,
  }) async {
    final trace = _analytics.startTrace('get_workflows_paginated');
    trace?.start();

    _logger.info(
      'getWorkflowsPaginated: Entry - instanceId: $instanceId, limit: $limit, cursor: $cursor',
    );

    try {
      // If no cursor (first page), try cache first for instant UI updates
      if (cursor == null) {
        final cached = await _localDataSource.getWorkflows();
        if (cached != null && cached.isNotEmpty) {
          // Filter by instance if we can determine which workflows belong to this instance
          // For now, return all cached workflows (they'll be filtered by the provider)
          // This allows optimistic updates to be visible immediately
          final workflows = cached.map((w) => w.toEntity()).toList();
          _logger.info('getWorkflowsPaginated: Success (cached) - ${workflows.length} workflows');
          await _analytics.logSuccess(
            action: 'get_workflows_paginated',
            parameters: {
              'instance_id': instanceId,
              'count': workflows.length,
              'has_next': false,
              'source': 'cache',
            },
          );
          trace?.stop();
          return (data: workflows, nextCursor: null);
        }
      }

      final result = await _remoteDataSource.getWorkflowsPaginated(
        instanceId: instanceId,
        limit: limit,
        cursor: cursor,
        active: active,
        cancelToken: cancelToken,
      );

      // Convert WorkflowModel list to Workflow list
      final workflows = result.data.map((w) => w.toEntity()).toList();

      _logger.info(
        'getWorkflowsPaginated: Success - ${workflows.length} workflows, hasNext: ${result.nextCursor != null}',
      );
      await _analytics.logSuccess(
        action: 'get_workflows_paginated',
        parameters: {
          'instance_id': instanceId,
          'count': workflows.length,
          'has_next': result.nextCursor != null,
        },
      );
      trace?.stop();
      return (data: workflows, nextCursor: result.nextCursor);
    } catch (e, stackTrace) {
      // Don't log cancellation errors as failures - they're expected when provider is invalidated
      if (e is DioException && e.type == DioExceptionType.cancel) {
        trace?.stop();
        _logger.info(
          'getWorkflowsPaginated: Cancelled - instanceId: $instanceId (expected when provider invalidated)',
        );
        rethrow;
      }
      await _analytics.logFailure(
        action: 'get_workflows_paginated',
        error: e.toString(),
        parameters: {'instance_id': instanceId},
      );
      trace?.stop();
      _logger.severe('getWorkflowsPaginated: Failure', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Workflow> getWorkflowById(String id, {CancelToken? cancelToken}) async {
    final trace = _analytics.startTrace('get_workflow_by_id');
    trace?.start();

    _logger.info('getWorkflowById: Entry - $id');

    try {
      // First, try to find the workflow in the cached list
      final cached = await _localDataSource.getWorkflows();
      if (cached != null) {
        try {
          final found = cached.firstWhere((w) => w.id == id);
          _logger.info('getWorkflowById: Success (cached) - $id');
          await _analytics.logSuccess(
            action: 'get_workflow_by_id',
            parameters: {'workflow_id': id, 'source': 'cache'},
          );
          trace?.stop();
          return found.toEntity();
        } catch (e) {
          // Not found in cache, continue to search in fetched workflows
        }
      }

      // If not in cache, fetch all workflows and find the one we need
      // The backend doesn't have a /workflows/{id} endpoint, so we need to search
      final allWorkflows = await getWorkflows(cancelToken: cancelToken);
      try {
        final found = allWorkflows.firstWhere((w) => w.id == id);
        _logger.info('getWorkflowById: Success (from list) - $id');
        await _analytics.logSuccess(
          action: 'get_workflow_by_id',
          parameters: {'workflow_id': id, 'source': 'list'},
        );
        trace?.stop();
        return found;
      } catch (e) {
        // Not found in fetched workflows either
      }

      // Workflow not found
      throw NotFoundException('Workflow not found: $id');
    } catch (e, stackTrace) {
      if (e is NotFoundException) {
        // Don't log NotFoundException as a failure - it's expected
        trace?.stop();
        rethrow;
      }
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
  Future<void> toggleWorkflow(
    String id,
    bool enabled, {
    required String instanceId,
    CancelToken? cancelToken,
  }) async {
    final trace = _analytics.startTrace('toggle_workflow');
    trace?.start();

    _logger.info('toggleWorkflow: Entry - $id, enabled: $enabled, instanceId: $instanceId');

    // Create a separate CancelToken for the toggle request to avoid cancellation
    // when providers are invalidated
    final toggleCancelToken = cancelToken ?? CancelToken();

    // Optimistically update cache for instant UI feedback
    final cacheUpdated = await _localDataSource.updateWorkflow(id, enabled);
    if (cacheUpdated) {
      _logger.info('toggleWorkflow: Cache updated optimistically - $id');
    }

    try {
      await _remoteDataSource.toggleWorkflow(
        id,
        enabled,
        instanceId: instanceId,
        cancelToken: toggleCancelToken,
      );

      // Cache was already updated optimistically, so we're good
      // If needed, we could fetch the workflow again to ensure consistency,
      // but typically the server just confirms the toggle
      _logger.info('toggleWorkflow: Success - $id');
      await _analytics.logSuccess(
        action: 'toggle_workflow',
        parameters: {'workflow_id': id, 'enabled': enabled},
      );
      trace?.stop();
    } catch (e, stackTrace) {
      // On failure, clear cache to ensure consistency
      // This ensures we don't have stale optimistic data
      await _localDataSource.clearCache();
      _logger.info('toggleWorkflow: Cache cleared due to failure - $id');

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

  @override
  Future<({List<WorkflowExecution> data, String? nextCursor})> getExecutions({
    required String instanceId,
    String? workflowId,
    String? status,
    int limit = 20,
    String? cursor,
    CancelToken? cancelToken,
  }) async {
    final trace = _analytics.startTrace('get_executions');
    trace?.start();

    _logger.info(
      'getExecutions: Entry - instanceId: $instanceId, workflowId: $workflowId, limit: $limit, cursor: $cursor',
    );

    try {
      final result = await _remoteDataSource.getExecutions(
        instanceId: instanceId,
        workflowId: workflowId,
        status: status,
        limit: limit,
        cursor: cursor,
        cancelToken: cancelToken,
      );

      // Convert WorkflowExecutionModel list to WorkflowExecution list
      final executions = result.data.map((e) => e.toEntity()).toList();

      _logger.info(
        'getExecutions: Success - ${executions.length} executions, hasNext: ${result.nextCursor != null}',
      );
      await _analytics.logSuccess(
        action: 'get_executions',
        parameters: {
          'instance_id': instanceId,
          if (workflowId != null) 'workflow_id': workflowId,
          'count': executions.length,
          'has_next': result.nextCursor != null,
        },
      );
      trace?.stop();
      return (data: executions, nextCursor: result.nextCursor);
    } catch (e, stackTrace) {
      await _analytics.logFailure(
        action: 'get_executions',
        error: e.toString(),
        parameters: {'instance_id': instanceId, if (workflowId != null) 'workflow_id': workflowId},
      );
      trace?.stop();
      _logger.severe('getExecutions: Failure', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<WorkflowExecution> getExecutionById({
    required String executionId,
    required String instanceId,
    bool includeData = true,
    CancelToken? cancelToken,
  }) async {
    final trace = _analytics.startTrace('get_execution_by_id');
    trace?.start();

    _logger.info(
      'getExecutionById: Entry - executionId: $executionId, instanceId: $instanceId, includeData: $includeData',
    );

    try {
      final executionModel = await _remoteDataSource.getExecutionById(
        executionId: executionId,
        instanceId: instanceId,
        includeData: includeData,
        cancelToken: cancelToken,
      );

      final execution = executionModel.toEntity();
      _logger.info('getExecutionById: Success - $executionId');
      await _analytics.logSuccess(
        action: 'get_execution_by_id',
        parameters: {'execution_id': executionId, 'instance_id': instanceId},
      );
      trace?.stop();
      return execution;
    } catch (e, stackTrace) {
      await _analytics.logFailure(
        action: 'get_execution_by_id',
        error: e.toString(),
        parameters: {'execution_id': executionId, 'instance_id': instanceId},
      );
      trace?.stop();
      _logger.severe('getExecutionById: Failure', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> retryExecution({
    required String executionId,
    required String instanceId,
    CancelToken? cancelToken,
  }) async {
    final trace = _analytics.startTrace('retry_execution');
    trace?.start();

    _logger.info(
      'retryExecution: Entry - executionId: $executionId, instanceId: $instanceId',
    );

    try {
      final newExecutionId = await _remoteDataSource.retryExecution(
        executionId: executionId,
        instanceId: instanceId,
        cancelToken: cancelToken,
      );

      _logger.info(
        'retryExecution: Success - executionId: $executionId, newExecutionId: $newExecutionId',
      );
      await _analytics.logSuccess(
        action: 'retry_execution',
        parameters: {
          'execution_id': executionId,
          'instance_id': instanceId,
          'new_execution_id': newExecutionId,
        },
      );
      trace?.stop();
      return newExecutionId;
    } catch (e, stackTrace) {
      await _analytics.logFailure(
        action: 'retry_execution',
        error: e.toString(),
        parameters: {
          'execution_id': executionId,
          'instance_id': instanceId,
        },
      );
      trace?.stop();
      _logger.severe('retryExecution: Failure', e, stackTrace);
      rethrow;
    }
  }
}
