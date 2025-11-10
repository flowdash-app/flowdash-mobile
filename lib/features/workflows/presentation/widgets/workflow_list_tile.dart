import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';

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

  Future<void> _handleToggle(BuildContext context, WidgetRef ref, bool value) async {
    if (onToggle != null) {
      onToggle!(workflow.id, value);
      return;
    }

    // Default behavior: use repository
    final repository = ref.read(workflowRepositoryProvider);
    try {
      await repository.toggleWorkflow(workflow.id, value);
      ref.invalidate(workflowsProvider);
      ref.invalidate(workflowsWithInstanceProvider);
    } catch (e) {
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
        onChanged: (value) => _handleToggle(context, ref, value),
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

