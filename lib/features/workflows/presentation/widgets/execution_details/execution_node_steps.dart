import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/node_execution_step_tile.dart';
import 'package:flutter/material.dart';

class ExecutionNodeSteps extends StatelessWidget {
  final WorkflowExecution execution;

  const ExecutionNodeSteps({
    super.key,
    required this.execution,
  });

  @override
  Widget build(BuildContext context) {
    if (execution.data == null) return const SizedBox.shrink();
    final resultData = execution.data!.resultData;
    final runData = resultData?.runData;

    if (runData == null || runData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Node Execution Steps',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...runData.entries.map((entry) {
          final nodeName = entry.key;
          final nodeData = entry.value;
          final hasError = execution.status == WorkflowExecutionStatus.error;

          return NodeExecutionStepTile(
            nodeName: nodeName,
            nodeData: nodeData,
            hasError: hasError,
          );
        }),
      ],
    );
  }
}

