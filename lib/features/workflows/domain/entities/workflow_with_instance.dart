import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';

class WorkflowWithInstance {
  final Workflow workflow;
  final String instanceId;
  final String instanceName;

  const WorkflowWithInstance({
    required this.workflow,
    required this.instanceId,
    required this.instanceName,
  });
}



