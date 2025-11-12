import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/node_execution_step_tile.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/execution_data_viewer.dart';
import 'package:flowdash_mobile/features/workflows/data/services/execution_export_service.dart';
import 'package:flowdash_mobile/features/instances/presentation/providers/instance_provider.dart';
import 'package:flowdash_mobile/features/instances/domain/entities/instance.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';

class ExecutionDetailsBottomSheet extends ConsumerStatefulWidget {
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
  ConsumerState<ExecutionDetailsBottomSheet> createState() =>
      _ExecutionDetailsBottomSheetState();
}

class _ExecutionDetailsBottomSheetState
    extends ConsumerState<ExecutionDetailsBottomSheet> {
  final ExecutionExportService _exportService = ExecutionExportService();
  bool _isExporting = false;
  
  // Get execution from provider or fallback
  WorkflowExecution? get execution {
    final executionAsync = ref.read(executionProvider((
      executionId: widget.executionId,
      instanceId: widget.instanceId,
    )));
    return executionAsync.maybeWhen(
      data: (exec) => exec,
      orElse: () => null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch execution provider to get fresh data and enable refresh
    final executionAsync = ref.watch(executionProvider((
      executionId: widget.executionId,
      instanceId: widget.instanceId,
    )));
    
    // Use execution from provider, or fallback if provided
    final execution = executionAsync.maybeWhen(
      data: (exec) => exec,
      orElse: () => null,
    );
    
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
                      ref.invalidate(executionProvider((
                        executionId: widget.executionId,
                        instanceId: widget.instanceId,
                      )));
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
        (i) => i.id == widget.instanceId,
        orElse: () => instancesAsync.value!.first,
      );
    }

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Execution Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          execution.id,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Content - no scrolling
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    _buildStatusBadge(),

                    const SizedBox(height: 16),

                    // Core Information
                    _buildCoreInformation(),

                    const SizedBox(height: 16),

                    // Error Details (if error)
                    if (execution.status ==
                        WorkflowExecutionStatus.error)
                      _buildErrorDetails(),

                    const SizedBox(height: 16),

                    // Node Execution Steps
                    if (_hasNodeData()) _buildNodeSteps(),

                    const SizedBox(height: 16),

                    // Execution Data
                    _buildExecutionData(),

                    const SizedBox(height: 16),

                    // Actions
                    _buildActions(instance?.url),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (execution == null) return const SizedBox.shrink();
    
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (execution!.status) {
      case WorkflowExecutionStatus.success:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        statusText = 'Success';
        break;
      case WorkflowExecutionStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        statusText = 'Error';
        break;
      case WorkflowExecutionStatus.running:
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle_outline;
        statusText = 'Running';
        break;
      case WorkflowExecutionStatus.waiting:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Waiting';
        break;
      case WorkflowExecutionStatus.canceled:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel_outlined;
        statusText = 'Canceled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 20, color: statusColor),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (widget.workflowName != null)
          _buildInfoRow('Workflow', widget.workflowName!),
        _buildInfoRow('Execution ID', execution!.id),
        _buildInfoRow('Workflow ID', execution!.workflowId),
        if (execution!.startedAt != null)
          _buildInfoRow(
            'Started',
            _formatDateTime(execution!.startedAt!),
          ),
        if (execution!.stoppedAt != null)
          _buildInfoRow(
            'Stopped',
            _formatDateTime(execution!.stoppedAt!),
          ),
        if (execution!.duration != null)
          _buildInfoRow(
            'Duration',
            _formatDuration(execution!.duration!),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDetails() {
    if (execution == null || execution!.errorMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 20, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                'Error Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            execution!.errorMessage!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[700],
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  bool _hasNodeData() {
    if (execution == null || execution!.data == null) return false;
    final resultData = execution!.data!.resultData;
    if (resultData == null) return false;
    final runData = resultData.runData;
    return runData != null && runData.isNotEmpty;
  }

  Widget _buildNodeSteps() {
    if (execution == null || execution!.data == null) return const SizedBox.shrink();
    final resultData = execution!.data!.resultData;
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
          final hasError = execution!.status ==
              WorkflowExecutionStatus.error;

          return NodeExecutionStepTile(
            nodeName: nodeName,
            nodeData: nodeData,
            hasError: hasError,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildExecutionData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Raw Execution Data',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ExecutionDataViewer(data: execution!.data),
      ],
    );
  }

  Widget _buildActions(String? instanceUrl) {
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
                ref.invalidate(executionProvider((
                  executionId: widget.executionId,
                  instanceId: widget.instanceId,
                )));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),

            // Open in n8n
            if (instanceUrl != null)
              ElevatedButton.icon(
                onPressed: () => _openInN8n(instanceUrl),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open in n8n'),
              ),

            // Export
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportExecution,
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

  Future<void> _openInN8n(String instanceUrl) async {
    final analytics = ref.read(analyticsServiceProvider);
    analytics.logEvent(
      name: 'open_execution_in_n8n',
      parameters: {
        'execution_id': execution!.id,
        'instance_id': widget.instanceId,
      },
    );

    try {
      final url = Uri.parse('$instanceUrl/workflow/${execution!.workflowId}/executions/${execution!.id}');
      
      // Check if URL can be launched
      final canLaunch = await canLaunchUrl(url);
      if (!canLaunch) {
        if (mounted) {
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
            'execution_id': execution!.id,
            'instance_id': widget.instanceId,
            'reason': 'cannot_launch_url',
          },
        );
        return;
      }

      // Try to launch the URL
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (mounted) {
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
            'execution_id': execution!.id,
            'instance_id': widget.instanceId,
            'reason': 'launch_failed',
          },
        );
      } else {
        analytics.logEvent(
          name: 'open_execution_in_n8n_success',
          parameters: {
            'execution_id': execution!.id,
            'instance_id': widget.instanceId,
          },
        );
      }
    } catch (e) {
      if (mounted) {
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
          'execution_id': execution!.id,
          'instance_id': widget.instanceId,
          'reason': 'exception',
          'error': e.toString(),
        },
      );
    }
  }

  Future<void> _exportExecution() async {
    setState(() {
      _isExporting = true;
    });

    final analytics = ref.read(analyticsServiceProvider);
    analytics.logEvent(
      name: 'export_execution',
      parameters: {
        'execution_id': execution!.id,
        'instance_id': widget.instanceId,
      },
    );

    try {
      final instancesAsync = ref.read(instancesProvider);
      Instance? instance;
      if (instancesAsync.hasValue) {
        instance = instancesAsync.value!.firstWhere(
          (i) => i.id == widget.instanceId,
          orElse: () => instancesAsync.value!.first,
        );
      }

      if (execution == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot export: execution data not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _exportService.exportAndShare(
        execution: execution!,
        workflowName: widget.workflowName,
        instanceName: instance?.name,
      );
    } catch (e) {
      if (mounted) {
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

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }
}

