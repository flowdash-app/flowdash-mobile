import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';

abstract class WorkflowRepository {
  Future<List<Workflow>> getWorkflows();
  Future<Workflow> getWorkflowById(String id);
  Future<void> toggleWorkflow(String id, bool enabled);
  Future<void> refreshWorkflows();
}

