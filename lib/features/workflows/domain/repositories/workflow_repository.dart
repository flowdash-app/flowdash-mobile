import 'package:dio/dio.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';

abstract class WorkflowRepository {
  Future<List<Workflow>> getWorkflows({CancelToken? cancelToken});
  Future<({List<Workflow> data, String? nextCursor})> getWorkflowsPaginated({
    required String instanceId,
    int limit = 20,
    String? cursor,
    bool? active,
    CancelToken? cancelToken,
  });
  Future<Workflow> getWorkflowById(String id, {CancelToken? cancelToken});
  Future<void> toggleWorkflow(String id, bool enabled,
      {required String instanceId, CancelToken? cancelToken});
  Future<void> refreshWorkflows();
  Future<({List<WorkflowExecution> data, String? nextCursor})> getExecutions({
    required String instanceId,
    String? workflowId,
    String? status,
    int limit = 20,
    String? cursor,
    CancelToken? cancelToken,
  });
  Future<WorkflowExecution> getExecutionById({
    required String executionId,
    required String instanceId,
    bool includeData = true,
    CancelToken? cancelToken,
  });
  Future<String> retryExecution({
    required String executionId,
    required String instanceId,
    CancelToken? cancelToken,
  });
}
