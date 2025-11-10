import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/core/analytics/analytics_service.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:flowdash_mobile/features/workflows/domain/repositories/workflow_repository.dart';
import 'package:flowdash_mobile/features/workflows/data/datasources/workflow_remote_datasource.dart';
import 'package:flowdash_mobile/features/workflows/data/datasources/workflow_local_datasource.dart';
import 'package:flowdash_mobile/features/workflows/data/models/workflow_model.dart';
import 'package:flowdash_mobile/features/instances/domain/repositories/instance_repository.dart';

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
  })  : _remoteDataSource = remoteDataSource,
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
      if (cached != null) {
        _logger.info('getWorkflows: Success (cached)');
        await _analytics.logSuccess(
            action: 'get_workflows', parameters: {'source': 'cache'});
        trace?.stop();
        return cached;
      }

      // Get all instances to fetch workflows from all of them
      final instances = await _instanceRepository.getInstances(
        cancelToken: cancelToken,
      );
      if (instances.isEmpty) {
        throw Exception('No instances found. Please add an instance first.');
      }

      // Fetch workflows from all instances and track which instance they belong to
      final allWorkflows = <({Workflow workflow, String instanceId, String instanceName})>[];
      for (final instance in instances) {
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
      // Convert to WorkflowModel for caching
      final workflowsList = allWorkflows.map((w) {
        final workflow = w.workflow;
        return WorkflowModel(
          id: workflow.id,
          name: workflow.name,
          active: workflow.active,
          description: workflow.description,
          updatedAt: workflow.updatedAt,
          createdAt: workflow.createdAt,
        );
      }).toList();
      await _localDataSource.cacheWorkflows(workflowsList);
      _logger.info(
          'getWorkflows: Success (remote) - ${allWorkflows.length} workflows from ${instances.length} instances');
      await _analytics.logSuccess(
        action: 'get_workflows',
        parameters: {'source': 'remote', 'count': allWorkflows.length, 'instances': instances.length},
      );
      trace?.stop();
      return workflowsList;
    } catch (e, stackTrace) {
      // Don't send business logic exceptions to Crashlytics
      final errorString = e.toString();
      final isBusinessLogicException = errorString.contains('No active instance found') ||
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

    _logger.info('getWorkflowsPaginated: Entry - instanceId: $instanceId, limit: $limit, cursor: $cursor');

    try {
      final result = await _remoteDataSource.getWorkflowsPaginated(
        instanceId: instanceId,
        limit: limit,
        cursor: cursor,
        active: active,
        cancelToken: cancelToken,
      );

      _logger.info('getWorkflowsPaginated: Success - ${result.data.length} workflows, hasNext: ${result.nextCursor != null}');
      await _analytics.logSuccess(
        action: 'get_workflows_paginated',
        parameters: {
          'instance_id': instanceId,
          'count': result.data.length,
          'has_next': result.nextCursor != null,
        },
      );
      trace?.stop();
      return result;
    } catch (e, stackTrace) {
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
  Future<Workflow> getWorkflowById(String id,
      {CancelToken? cancelToken}) async {
    final trace = _analytics.startTrace('get_workflow_by_id');
    trace?.start();

    _logger.info('getWorkflowById: Entry - $id');

    try {
      final workflow = await _remoteDataSource.getWorkflowById(
        id,
        cancelToken: cancelToken,
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
      await _remoteDataSource.toggleWorkflow(
        id,
        enabled,
        cancelToken: cancelToken,
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

    _logger.info('getExecutions: Entry - instanceId: $instanceId, workflowId: $workflowId, limit: $limit, cursor: $cursor');

    try {
      final result = await _remoteDataSource.getExecutions(
        instanceId: instanceId,
        workflowId: workflowId,
        status: status,
        limit: limit,
        cursor: cursor,
        cancelToken: cancelToken,
      );

      _logger.info('getExecutions: Success - ${result.data.length} executions, hasNext: ${result.nextCursor != null}');
      await _analytics.logSuccess(
        action: 'get_executions',
        parameters: {
          'instance_id': instanceId,
          if (workflowId != null) 'workflow_id': workflowId,
          'count': result.data.length,
          'has_next': result.nextCursor != null,
        },
      );
      trace?.stop();
      return result;
    } catch (e, stackTrace) {
      await _analytics.logFailure(
        action: 'get_executions',
        error: e.toString(),
        parameters: {
          'instance_id': instanceId,
          if (workflowId != null) 'workflow_id': workflowId,
        },
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
    CancelToken? cancelToken,
  }) async {
    final trace = _analytics.startTrace('get_execution_by_id');
    trace?.start();

    _logger.info('getExecutionById: Entry - executionId: $executionId, instanceId: $instanceId');

    try {
      final execution = await _remoteDataSource.getExecutionById(
        executionId: executionId,
        instanceId: instanceId,
        cancelToken: cancelToken,
      );

      _logger.info('getExecutionById: Success - $executionId');
      await _analytics.logSuccess(
        action: 'get_execution_by_id',
        parameters: {
          'execution_id': executionId,
          'instance_id': instanceId,
        },
      );
      trace?.stop();
      return execution;
    } catch (e, stackTrace) {
      await _analytics.logFailure(
        action: 'get_execution_by_id',
        error: e.toString(),
        parameters: {
          'execution_id': executionId,
          'instance_id': instanceId,
        },
      );
      trace?.stop();
      _logger.severe('getExecutionById: Failure', e, stackTrace);
      rethrow;
    }
  }
}
