import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';
import 'package:flowdash_mobile/features/instances/presentation/providers/instance_provider.dart';

class WorkflowListTile extends ConsumerWidget {
  final Workflow workflow;
  final String? instanceName;
  final String? instanceId;
  final bool showInstanceName;
  final bool showUpdatedDate;
  final bool wrapInCard;
  final EdgeInsets? cardMargin;
  final Function(String, bool)? onToggle;

  const WorkflowListTile({
    super.key,
    required this.workflow,
    this.instanceName,
    this.instanceId,
    this.showInstanceName = false,
    this.showUpdatedDate = false,
    this.wrapInCard = false,
    this.cardMargin,
    this.onToggle,
  });

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

  Future<bool> _showDisableConfirmation(BuildContext context) async {
    if (!context.mounted) return false;
    
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

  Future<void> _handleToggle(BuildContext context, WidgetRef ref, bool value) async {
    final analytics = ref.read(analyticsServiceProvider);
    
    // Log analytics for tap action
    await analytics.logEvent(
      name: value ? 'workflow_enable_tapped' : 'workflow_disable_tapped',
      parameters: {
        'workflow_id': workflow.id,
        if (instanceId != null) 'instance_id': instanceId!,
      },
    );
    
    // Show confirmation dialog when disabling
    if (!value) {
      final confirmed = await _showDisableConfirmation(context);
      if (!confirmed || !context.mounted) {
        // User cancelled or context unmounted, revert the switch
        await analytics.logEvent(
          name: 'workflow_disable_cancelled',
          parameters: {
            'workflow_id': workflow.id,
            if (instanceId != null) 'instance_id': instanceId!,
          },
        );
        return;
      }
      
      // Log confirmation
      await analytics.logEvent(
        name: 'workflow_disable_confirmed',
        parameters: {
          'workflow_id': workflow.id,
          if (instanceId != null) 'instance_id': instanceId!,
        },
      );
    }

    if (onToggle != null) {
      onToggle!(workflow.id, value);
      return;
    }

    // Need instanceId to toggle workflow
    if (instanceId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Instance ID is required')),
        );
      }
      return;
    }

    // Check if instance is enabled before allowing toggle
    final instancesAsync = ref.read(instancesProvider);
    final instances = instancesAsync.value;
    if (instances != null) {
      final instance = instances.firstWhere(
        (inst) => inst.id == instanceId,
        orElse: () => throw Exception('Instance not found'),
      );
      if (!instance.active) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable the instance first'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    // Default behavior: use repository
    final repository = ref.read(workflowRepositoryProvider);
    try {
      await repository.toggleWorkflow(workflow.id, value, instanceId: instanceId!);
      // Invalidate providers to refresh data
      // The optimistic update should already be visible in the cache
      ref.invalidate(workflowsProvider);
      // Refresh workflowsWithInstanceProvider to show the updated data
      ref.read(workflowsWithInstanceProvider.notifier).refresh();
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _handleTap(BuildContext context) {
    // Only navigate if we have instance info
    if (instanceId != null && instanceName != null) {
      WorkflowDetailsRoute(
        workflowId: workflow.id,
        instanceId: instanceId!,
        instanceName: instanceName!,
      ).push(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if instance is enabled to determine if switch should be enabled
    final instancesAsync = ref.watch(instancesProvider);
    final isInstanceEnabled = instancesAsync.when(
      data: (instances) {
        if (instanceId == null) return false;
        try {
          final instance = instances.firstWhere((inst) => inst.id == instanceId);
          return instance.active;
        } catch (e) {
          return false;
        }
      },
      loading: () => false,
      error: (_, __) => false,
    );

    final listTile = ListTile(
      onTap: () => _handleTap(context),
      title: Text(
        workflow.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showInstanceName && instanceName != null) ...[
            Text(
              instanceName!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (workflow.description != null) ...[
            Text(
              workflow.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              Icon(
                workflow.active
                    ? Icons.play_circle_outline
                    : Icons.pause_circle_outline,
                size: 14,
                color: workflow.active ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                workflow.active ? 'Running' : 'Paused',
                style: TextStyle(
                  fontSize: 12,
                  color: workflow.active ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (showUpdatedDate && workflow.updatedAt != null) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Updated ${_formatDate(workflow.updatedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: Switch(
        value: workflow.active,
        onChanged: isInstanceEnabled
            ? (value) => _handleToggle(context, ref, value)
            : null, // Disable switch if instance is not enabled
      ),
    );

    if (wrapInCard) {
      return Card(
        margin: cardMargin ??
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
        child: listTile,
      );
    }

    return listTile;
  }
}

