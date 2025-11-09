import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/workflows/domain/repositories/workflow_repository.dart';
import 'package:flowdash_mobile/features/workflows/data/repositories/workflow_repository_impl.dart';
import 'package:flowdash_mobile/features/workflows/data/datasources/workflow_remote_datasource.dart';
import 'package:flowdash_mobile/features/workflows/data/datasources/workflow_local_datasource.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';

final workflowLocalDataSourceProvider =
    Provider<WorkflowLocalDataSource>((ref) {
  return WorkflowLocalDataSource();
});

final workflowRepositoryProvider = Provider<WorkflowRepository>((ref) {
  final remoteDataSource = ref.watch(workflowRemoteDataSourceProvider);
  final localDataSource = ref.watch(workflowLocalDataSourceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return WorkflowRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    analytics: analytics,
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
  final repository = ref.watch(workflowRepositoryProvider);
  final cancelToken = CancelToken();
  
  ref.onDispose(() {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('Provider disposed');
    }
  });
  
  return repository.getWorkflowById(id, cancelToken: cancelToken);
});
