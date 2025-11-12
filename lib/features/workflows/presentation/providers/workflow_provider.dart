import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/workflows/domain/repositories/workflow_repository.dart';
import 'package:flowdash_mobile/features/workflows/data/repositories/workflow_repository_impl.dart';
import 'package:flowdash_mobile/features/workflows/data/datasources/workflow_remote_datasource.dart';
import 'package:flowdash_mobile/features/workflows/data/datasources/workflow_local_datasource.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_with_instance.dart';
import 'package:flowdash_mobile/features/instances/presentation/providers/instance_provider.dart';

final workflowLocalDataSourceProvider =
    Provider<WorkflowLocalDataSource>((ref) {
  return WorkflowLocalDataSource();
});

final workflowRepositoryProvider = Provider<WorkflowRepository>((ref) {
  final remoteDataSource = ref.watch(workflowRemoteDataSourceProvider);
  final localDataSource = ref.watch(workflowLocalDataSourceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  final instanceRepository = ref.watch(instanceRepositoryProvider);
  return WorkflowRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    analytics: analytics,
    instanceRepository: instanceRepository,
  );
});

final workflowsProvider = FutureProvider<List<Workflow>>((ref) async {
  final repository = ref.watch(workflowRepositoryProvider);
  final cancelToken = CancelToken();

  ref.onDispose(() {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('Provider disposed');
    }
  });

  return repository.getWorkflows(cancelToken: cancelToken);
});

final workflowProvider =
    FutureProvider.family<Workflow, String>((ref, id) async {
  // Keep the provider alive so it doesn't get disposed
  // This ensures the data is cached and only refetched on explicit invalidation
  ref.keepAlive();
  
  final repository = ref.watch(workflowRepositoryProvider);
  final cancelToken = CancelToken();

  // Only cancel if the provider is manually invalidated
  // Since we're using keepAlive, this won't be called on normal disposal
  ref.onDispose(() {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('Provider invalidated');
    }
  });

  // The repository will use cached data if available, or fetch from the list
  return repository.getWorkflowById(id, cancelToken: cancelToken);
});

// Provider that returns workflows with instance information for sorting and display
// This is the main provider used by both home page and workflows page
final workflowsWithInstanceProvider = FutureProvider<List<WorkflowWithInstance>>((ref) async {
  final workflowRepository = ref.watch(workflowRepositoryProvider);
  final instanceRepository = ref.watch(instanceRepositoryProvider);
  final cancelToken = CancelToken();
  
  ref.onDispose(() {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('Provider disposed');
    }
  });
  
  // Get all instances
  final allInstances = await instanceRepository.getInstances(cancelToken: cancelToken);
  if (allInstances.isEmpty) {
    return [];
  }
  
  final allWorkflowsWithInstance = <WorkflowWithInstance>[];
  
  // Fetch workflows from all instances using the repository (which handles caching)
  for (final instance in allInstances) {
    try {
      // Use getWorkflowsPaginated to get workflows for this instance
      // We'll fetch a reasonable limit (100) to get all workflows
      final result = await workflowRepository.getWorkflowsPaginated(
        instanceId: instance.id,
        limit: 100,
        cursor: null,
        cancelToken: cancelToken,
      );
      
      for (final workflow in result.data) {
        allWorkflowsWithInstance.add(WorkflowWithInstance(
          workflow: workflow,
          instanceId: instance.id,
          instanceName: instance.name,
        ));
      }
    } catch (e) {
      // Skip instances that fail - log but continue
      // The repository already handles logging
    }
  }
  
  // Sort: by instance name, then by active status (enabled first), then by name
  allWorkflowsWithInstance.sort((a, b) {
    final instanceCompare = a.instanceName.compareTo(b.instanceName);
    if (instanceCompare != 0) return instanceCompare;
    
    if (a.workflow.active != b.workflow.active) {
      return b.workflow.active ? 1 : -1; // Active (enabled) first
    }
    
    return a.workflow.name.compareTo(b.workflow.name);
  });
  
  return allWorkflowsWithInstance;
});

// Execution providers
final executionsProvider = FutureProvider.family<({List<WorkflowExecution> data, String? nextCursor}), ({String instanceId, String? workflowId, String? status, int limit, String? cursor})>((ref, params) async {
  final repository = ref.watch(workflowRepositoryProvider);
  final cancelToken = CancelToken();

  ref.onDispose(() {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('Provider disposed');
    }
  });

  return repository.getExecutions(
    instanceId: params.instanceId,
    workflowId: params.workflowId,
    status: params.status,
    limit: params.limit,
    cursor: params.cursor,
    cancelToken: cancelToken,
  );
});

final executionProvider = FutureProvider.family<WorkflowExecution, ({String executionId, String instanceId})>((ref, params) async {
  final repository = ref.watch(workflowRepositoryProvider);
  final cancelToken = CancelToken();

  ref.onDispose(() {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('Provider disposed');
    }
  });

  return repository.getExecutionById(
    executionId: params.executionId,
    instanceId: params.instanceId,
    cancelToken: cancelToken,
  );
});
