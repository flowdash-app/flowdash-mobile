import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/instances/domain/entities/instance.dart';
import 'package:flowdash_mobile/features/instances/presentation/providers/instance_provider.dart';
import 'package:flowdash_mobile/features/workflows/data/services/execution_export_service.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/execution_details_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ExecutionActions extends ConsumerStatefulWidget {
  final WorkflowExecution execution;
  final String instanceId;
  final String? instanceUrl;
  final String? workflowName;

  const ExecutionActions({
    super.key,
    required this.execution,
    required this.instanceId,
    this.instanceUrl,
    this.workflowName,
  });

  @override
  ConsumerState<ExecutionActions> createState() => _ExecutionActionsState();
}

class _ExecutionActionsState extends ConsumerState<ExecutionActions> {
  bool _isExporting = false;
  bool _isRetrying = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Refresh button - refetch execution data
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(
                  executionProvider((
                    executionId: widget.execution.id,
                    instanceId: widget.instanceId,
                  )),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),

            // Retry button - only show for error or canceled executions
            if (_canRetry(widget.execution.status))
              ElevatedButton.icon(
                onPressed: _isRetrying
                    ? null
                    : () => _retryExecution(
                          context,
                          ref,
                          widget.execution,
                          widget.instanceId,
                        ),
                icon: _isRetrying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.replay),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),

            // Open in n8n
            if (widget.instanceUrl != null)
              ElevatedButton.icon(
                onPressed: () => _openInN8n(
                  context,
                  ref,
                  widget.execution,
                  widget.instanceId,
                  widget.instanceUrl!,
                ),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open in n8n'),
              ),

            // Export
            ElevatedButton.icon(
              onPressed: _isExporting
                  ? null
                  : () => _exportExecution(
                        context,
                        ref,
                        widget.execution,
                        widget.instanceId,
                        widget.workflowName,
                      ),
              icon: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: const Text('Export'),
            ),
          ],
        ),
      ],
    );
  }

  static Future<void> _openInN8n(
    BuildContext context,
    WidgetRef ref,
    WorkflowExecution execution,
    String instanceId,
    String instanceUrl,
  ) async {
    final analytics = ref.read(analyticsServiceProvider);
    analytics.logEvent(
      name: 'open_execution_in_n8n',
      parameters: {
        'execution_id': execution.id,
        'instance_id': instanceId,
      },
    );

    try {
      final url = Uri.parse(
        '$instanceUrl/workflow/${execution.workflowId}/executions/${execution.id}',
      );

      // Check if URL can be launched
      final canLaunch = await canLaunchUrl(url);
      if (!canLaunch) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open URL. No app available to handle this URL.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        analytics.logEvent(
          name: 'open_execution_in_n8n_failure',
          parameters: {
            'execution_id': execution.id,
            'instance_id': instanceId,
            'reason': 'cannot_launch_url',
          },
        );
        return;
      }

      // Try to launch the URL
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);

      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to open URL. Please try again or open manually.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        analytics.logEvent(
          name: 'open_execution_in_n8n_failure',
          parameters: {
            'execution_id': execution.id,
            'instance_id': instanceId,
            'reason': 'launch_failed',
          },
        );
      } else {
        analytics.logEvent(
          name: 'open_execution_in_n8n_success',
          parameters: {
            'execution_id': execution.id,
            'instance_id': instanceId,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening URL: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      analytics.logEvent(
        name: 'open_execution_in_n8n_failure',
        parameters: {
          'execution_id': execution.id,
          'instance_id': instanceId,
          'reason': 'exception',
          'error': e.toString(),
        },
      );
    }
  }

  Future<void> _exportExecution(
    BuildContext context,
    WidgetRef ref,
    WorkflowExecution execution,
    String instanceId,
    String? workflowName,
  ) async {
    setState(() {
      _isExporting = true;
    });

    final analytics = ref.read(analyticsServiceProvider);
    final exportService = ExecutionExportService();

    analytics.logEvent(
      name: 'export_execution',
      parameters: {
        'execution_id': execution.id,
        'instance_id': instanceId,
      },
    );

    try {
      final instancesAsync = ref.read(instancesProvider);
      Instance? instance;
      if (instancesAsync.hasValue) {
        instance = instancesAsync.value!.firstWhere(
          (i) => i.id == instanceId,
          orElse: () => instancesAsync.value!.first,
        );
      }

      await exportService.exportAndShare(
        execution: execution,
        workflowName: workflowName,
        instanceName: instance?.name,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  bool _canRetry(WorkflowExecutionStatus status) {
    return status == WorkflowExecutionStatus.error ||
        status == WorkflowExecutionStatus.canceled;
  }

  Future<void> _retryExecution(
    BuildContext context,
    WidgetRef ref,
    WorkflowExecution execution,
    String instanceId,
  ) async {
    // Show confirmation dialog (double-tap confirmation)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retry Execution'),
        content: const Text(
          'This will trigger a new execution with the same input data. Are you sure you want to retry this execution?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );

    // If user didn't confirm, return
    if (confirmed != true) return;

    // Set retrying state
    setState(() {
      _isRetrying = true;
    });

    final analytics = ref.read(analyticsServiceProvider);
    final workflowRepository = ref.read(workflowRepositoryProvider);

    analytics.logEvent(
      name: 'retry_execution_attempt',
      parameters: {
        'execution_id': execution.id,
        'instance_id': instanceId,
        'workflow_id': execution.workflowId,
      },
    );

    try {
      // Call retry execution
      final newExecutionId = await workflowRepository.retryExecution(
        executionId: execution.id,
        instanceId: instanceId,
      );

      analytics.logEvent(
        name: 'retry_execution_success',
        parameters: {
          'execution_id': execution.id,
          'new_execution_id': newExecutionId,
          'instance_id': instanceId,
          'workflow_id': execution.workflowId,
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Execution retried successfully! New execution ID: $newExecutionId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Invalidate current execution provider
                ref.invalidate(
                  executionProvider((
                    executionId: execution.id,
                    instanceId: instanceId,
                  )),
                );
                // Navigate to new execution
                Navigator.of(context).pop();
                // Show new execution details
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (context, scrollController) => Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: ExecutionDetailsBottomSheet(
                        executionId: newExecutionId,
                        instanceId: instanceId,
                        workflowName: widget.workflowName,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // Also refresh the current execution data
        ref.invalidate(
          executionProvider((
            executionId: execution.id,
            instanceId: instanceId,
          )),
        );
      }
    } catch (e) {
      analytics.logEvent(
        name: 'retry_execution_failure',
        parameters: {
          'execution_id': execution.id,
          'instance_id': instanceId,
          'workflow_id': execution.workflowId,
          'error': e.toString(),
        },
      );

      if (context.mounted) {
        // Extract user-friendly error message
        String errorMessage = 'Failed to retry execution';
        final errorString = e.toString();

        if (errorString.contains('403')) {
          errorMessage = 'Access denied. Instance may be disabled.';
        } else if (errorString.contains('404')) {
          errorMessage = 'Execution or workflow not found.';
        } else if (errorString.contains('400')) {
          if (errorString.contains('status')) {
            errorMessage = 'Execution cannot be retried. Only failed or canceled executions can be retried.';
          } else {
            errorMessage = 'Invalid request. Execution may be missing required data.';
          }
        } else if (errorString.contains('502') || errorString.contains('503')) {
          errorMessage = 'Service unavailable. Please check your n8n instance.';
        } else if (errorString.contains('504')) {
          errorMessage = 'Request timed out. Please try again.';
        } else if (errorString.contains('Connection') || errorString.contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage\n\nDetails: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }
}
