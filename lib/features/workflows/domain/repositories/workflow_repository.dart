import 'package:dio/dio.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';

abstract class WorkflowRepository {
  Future<List<Workflow>> getWorkflows({CancelToken? cancelToken});
  Future<Workflow> getWorkflowById(String id, {CancelToken? cancelToken});
  Future<void> toggleWorkflow(String id, bool enabled, {CancelToken? cancelToken});
  Future<void> refreshWorkflows();
}
