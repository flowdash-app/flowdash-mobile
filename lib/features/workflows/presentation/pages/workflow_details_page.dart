import 'package:dio/dio.dart';
import 'package:flowdash_mobile/core/errors/exceptions.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/core/utils/pagination_helper.dart';
import 'package:flowdash_mobile/core/utils/pagination_state.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkflowDetailsPage extends ConsumerStatefulWidget {
  final String workflowId;
  final String instanceId;
  final String instanceName;

  const WorkflowDetailsPage({
    super.key,
    required this.workflowId,
    required this.instanceId,
    required this.instanceName,
  });

  @override
  ConsumerState<WorkflowDetailsPage> createState() => _WorkflowDetailsPageState();
}

class _WorkflowDetailsPageState extends ConsumerState<WorkflowDetailsPage>
    with PaginationHelper<WorkflowExecution> {
  int _executionLimit = 10; // Default limit
  bool? _pendingToggleValue; // Track pending toggle during confirmation

  @override
  void initState() {
    super.initState();
    initPagination();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logScreenView(screenName: 'workflow_details', screenClass: 'WorkflowDetailsPage');
      // Load initial executions
      _loadExecutions();
    });
  }

  Future<void> _loadExecutions({bool loadMore = false}) async {
    if (!mounted) return;
    
    final repository = ref.read(workflowRepositoryProvider);

    if (loadMore) {
      await this.loadMore(
        fetchData: (cursor) => repository.getExecutions(
          instanceId: widget.instanceId,
          workflowId: widget.workflowId,
          status: null,
          limit: _executionLimit,
          cursor: cursor,
        ),
        onStateChanged: (state) {
          if (mounted) {
            setState(() {});
          }
        },
      );
    } else {
      await loadInitial(
        fetchData: () => repository.getExecutions(
          instanceId: widget.instanceId,
          workflowId: widget.workflowId,
          status: null,
          limit: _executionLimit,
          cursor: null,
        ),
        onStateChanged: (state) {
          if (mounted) {
            setState(() {});
          }
        },
      );
    }
  }

  void _onLimitChanged(int? newLimit) {
    if (newLimit != null && newLimit != _executionLimit) {
      setState(() {
        _executionLimit = newLimit;
      });
      // Reset pagination and reload with new limit
      initPagination();
      _loadExecutions();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _isNotFoundError(AsyncValue<Workflow> state) {
    if (!state.hasError) return false;
    final error = state.error;
    if (error is NotFoundException) return true;
    final errorString = error.toString().toLowerCase();
    return errorString.contains('not found') || errorString.contains('404');
  }

  Future<bool> _showDisableConfirmation() async {
    if (!mounted) return false;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Workflow'),
        content: const Text(
          'Are you sure you want to disable this workflow? It will stop running until you enable it again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    
    return confirmed ?? false;
  }

  Future<void> _handleToggle(bool value) async {
    final analytics = ref.read(analyticsServiceProvider);
    
    // Log analytics for tap action
    await analytics.logEvent(
      name: value ? 'workflow_enable_tapped' : 'workflow_disable_tapped',
      parameters: {
        'workflow_id': widget.workflowId,
        'instance_id': widget.instanceId,
      },
    );
    
    // Show confirmation dialog when disabling
    if (!value) {
      // Set pending toggle to show immediate visual feedback
      setState(() {
        _pendingToggleValue = value;
      });
      
      final confirmed = await _showDisableConfirmation();
      if (!confirmed || !mounted) {
        // User cancelled or widget unmounted, revert the switch
        await analytics.logEvent(
          name: 'workflow_disable_cancelled',
          parameters: {
            'workflow_id': widget.workflowId,
            'instance_id': widget.instanceId,
          },
        );
        setState(() {
          _pendingToggleValue = null;
        });
        return;
      }
      
      // Log confirmation
      await analytics.logEvent(
        name: 'workflow_disable_confirmed',
        parameters: {
          'workflow_id': widget.workflowId,
          'instance_id': widget.instanceId,
        },
      );
      
      // Clear pending toggle as we're proceeding
      setState(() {
        _pendingToggleValue = null;
      });
    }

    final repository = ref.read(workflowRepositoryProvider);
    try {
      await repository.toggleWorkflow(widget.workflowId, value, instanceId: widget.instanceId);
      // Invalidate providers to refresh data (only if not a 404 error)
      final currentState = ref.read(workflowProvider(widget.workflowId));
      if (!_isNotFoundError(currentState)) {
        ref.invalidate(workflowProvider(widget.workflowId));
      }
      ref.invalidate(workflowsProvider);
      ref.read(workflowsWithInstanceProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Workflow enabled' : 'Workflow disabled'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Ignore cancellation errors - they're expected when invalidating providers
      if (e is DioException && e.type == DioExceptionType.cancel) {
        return;
      }
      // Also check for cancellation in error message (for wrapped exceptions)
      if (e.toString().contains('Request cancelled') ||
          e.toString().contains('request cancelled')) {
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflowAsync = ref.watch(workflowProvider(widget.workflowId));
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Don't refresh if the current state is a 404 error
          if (!_isNotFoundError(workflowAsync)) {
            // Clear cache to force fresh fetch
            if (!mounted) return;
            final repository = ref.read(workflowRepositoryProvider);
            await repository.refreshWorkflows();
            if (!mounted) return;
            // Invalidate provider to trigger refetch with fresh data
            ref.invalidate(workflowProvider(widget.workflowId));
            await ref.read(workflowProvider(widget.workflowId).future);
            if (!mounted) return;
            // Reload executions
            _loadExecutions();
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Workflow Details'),
              floating: true,
              snap: true,
              actions: [
                workflowAsync.when(
                  data: (workflow) => Switch(
                    value: _pendingToggleValue ?? workflow.active,
                    onChanged: _handleToggle,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
            workflowAsync.when(
              data: (workflow) => _buildContent(workflow),
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading workflow...',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              error: (error, stack) {
                final errorMessage = error.toString().replaceAll('Exception: ', '');
                final isNotFound =
                    error is NotFoundException ||
                    errorMessage.toLowerCase().contains('not found') ||
                    errorMessage.contains('404');

                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            isNotFound ? Icons.search_off : Icons.error_outline,
                            size: 64,
                            color: isNotFound ? Colors.orange[300] : Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isNotFound ? 'Workflow not found' : 'Failed to load workflow',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isNotFound
                                ? 'This workflow may have been deleted or the ID is incorrect.'
                                : errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          if (!isNotFound) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Only invalidate if not a 404 error
                                if (!_isNotFoundError(workflowAsync)) {
                                  ref.invalidate(workflowProvider(widget.workflowId));
                                }
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Workflow workflow) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Workflow Information Section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Text(
                workflow.name,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Status Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: workflow.active
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: workflow.active ? Colors.green : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          workflow.active ? Icons.play_circle_outline : Icons.pause_circle_outline,
                          size: 16,
                          color: workflow.active ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          workflow.active ? 'Running' : 'Paused',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: workflow.active ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              if (workflow.description != null && workflow.description!.isNotEmpty) ...[
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(workflow.description!, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
              ],

              // Divider
              const Divider(),
              const SizedBox(height: 8),

              // Instance Information
              _buildInfoRow(icon: Icons.cloud, label: 'Instance', value: widget.instanceName),
              const SizedBox(height: 12),

              // Created Date
              if (workflow.createdAt != null)
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Created',
                  value: _formatFullDate(workflow.createdAt!),
                  subtitle: _formatDate(workflow.createdAt!),
                ),
              if (workflow.createdAt != null) const SizedBox(height: 12),

              // Updated Date
              if (workflow.updatedAt != null)
                _buildInfoRow(
                  icon: Icons.update,
                  label: 'Last Updated',
                  value: _formatFullDate(workflow.updatedAt!),
                  subtitle: _formatDate(workflow.updatedAt!),
                ),
              if (workflow.updatedAt != null) const SizedBox(height: 12),

              // Workflow ID
              _buildInfoRow(icon: Icons.tag, label: 'ID', value: workflow.id),
            ],
          ),
        ),

        // Execution History Section
        _buildExecutionHistorySection(),

        // Bottom padding
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExecutionHistorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history, size: 20, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Execution History',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // Limit dropdown
              DropdownButton<int>(
                value: _executionLimit,
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10')),
                  DropdownMenuItem(value: 20, child: Text('20')),
                  DropdownMenuItem(value: 30, child: Text('30')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                ],
                onChanged: _onLimitChanged,
                underline: Container(), // Remove default underline
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (paginationState.isLoading && paginationState.items.isEmpty)
            const Center(
              child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()),
            )
          else if (paginationState.hasError && paginationState.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load executions',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Reset state to loading immediately
                      updatePaginationState(
                        PaginationState<WorkflowExecution>(
                          isLoading: true,
                          items: [],
                          nextCursor: null,
                        ),
                      );
                      setState(() {});
                      // Then load data
                      _loadExecutions();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (paginationState.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No executions yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Workflow execution history will appear here once the workflow runs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                ...paginationState.items.map((execution) => _buildExecutionCard(execution)),
                if (paginationState.hasMore)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: OutlinedButton.icon(
                      onPressed: paginationState.isLoadingMore
                          ? null
                          : () => _loadExecutions(loadMore: true),
                      icon: paginationState.isLoadingMore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(paginationState.isLoadingMore ? 'Loading...' : 'Load More'),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildExecutionCard(WorkflowExecution execution) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (execution.status) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        onTap: () => _showExecutionDetails(execution),
        leading: Icon(statusIcon, color: statusColor),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                statusText,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ),
            if (execution.duration != null) ...[
              const SizedBox(width: 8),
              Text(
                _formatDuration(execution.duration!),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (execution.startedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Started: ${_formatDate(execution.startedAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (execution.errorMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                execution.errorMessage!,
                style: TextStyle(fontSize: 12, color: Colors.red[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: execution.stoppedAt != null
            ? Text(
                _formatDate(execution.stoppedAt!),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              )
            : null,
      ),
    );
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

  void _showExecutionDetails(WorkflowExecution execution) {
    final workflowAsync = ref.read(workflowProvider(widget.workflowId));
    String? workflowName;
    if (workflowAsync.hasValue) {
      workflowName = workflowAsync.value!.name;
    }

    // Navigate to execution details route (will show as bottom sheet)
    ExecutionDetailsRoute(
      executionId: execution.id,
      instanceId: widget.instanceId,
      workflowName: workflowName,
    ).push(context);
  }
}
