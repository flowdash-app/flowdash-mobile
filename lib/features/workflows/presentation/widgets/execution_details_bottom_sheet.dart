import 'package:flowdash_mobile/features/instances/domain/entities/instance.dart';
import 'package:flowdash_mobile/features/instances/presentation/providers/instance_provider.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/execution_details/execution_actions.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/execution_details/execution_core_information.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/execution_details/execution_details_header.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/execution_details/execution_error_details.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/execution_details/execution_node_steps.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/execution_details/execution_raw_data.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/execution_details/execution_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExecutionDetailsBottomSheet extends ConsumerWidget {
  final String executionId;
  final String instanceId;
  final String? workflowName;

  const ExecutionDetailsBottomSheet({
    super.key,
    required this.executionId,
    required this.instanceId,
    this.workflowName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch execution provider to get fresh data and enable refresh
    final executionAsync = ref.watch(
      executionProvider((executionId: executionId, instanceId: instanceId)),
    );

    // Use execution from provider, or fallback if provided
    final execution = executionAsync.maybeWhen(data: (exec) => exec, orElse: () => null);

    if (execution == null) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(32.0),
          child: executionAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Failed to load execution: $error'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(
                        executionProvider((executionId: executionId, instanceId: instanceId)),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (_) => const SizedBox.shrink(), // Should not reach here
          ),
        ),
      );
    }

    final instancesAsync = ref.watch(instancesProvider);
    Instance? instance;
    if (instancesAsync.hasValue) {
      instance = instancesAsync.value!.firstWhere(
        (i) => i.id == instanceId,
        orElse: () => instancesAsync.value!.first,
      );
    }

    return SafeArea(
      child: Material(
        // Use a transparent material so the Container's decoration is visible
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              ExecutionDetailsHeader(
                executionId: execution.id,
                onClose: () => Navigator.of(context).pop(),
              ),

              const Divider(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      ExecutionStatusBadge(status: execution.status),

                      const SizedBox(height: 16),

                      // Core Information
                      ExecutionCoreInformation(execution: execution, workflowName: workflowName),

                      const SizedBox(height: 16),

                      // Error Details (if error)
                      if (execution.status == WorkflowExecutionStatus.error)
                        ExecutionErrorDetails(errorMessage: execution.errorMessage),

                      const SizedBox(height: 16),

                      // Node Execution Steps
                      if (_hasNodeData(execution)) ExecutionNodeSteps(execution: execution),

                      const SizedBox(height: 16),

                      // Execution Data
                      ExecutionRawData(data: execution.data),

                      const SizedBox(height: 16),

                      // Actions
                      ExecutionActions(
                        execution: execution,
                        instanceId: instanceId,
                        instanceUrl: instance?.url,
                        workflowName: workflowName,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _hasNodeData(WorkflowExecution execution) {
    if (execution.data == null) return false;
    final resultData = execution.data!.resultData;
    if (resultData == null) return false;
    final runData = resultData.runData;
    return runData != null && runData.isNotEmpty;
  }
}
