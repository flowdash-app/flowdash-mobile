import 'package:flutter/material.dart';
import 'package:flowdash_mobile/features/error_workflows/data/models/error_workflow_setup_state.dart';
import 'package:flowdash_mobile/features/instances/domain/entities/instance.dart';
import 'package:intl/intl.dart';

/// Card showing error workflow setup status in instance details.
/// 
/// Displays:
/// - Not configured state with "Set Up Now" button
/// - Configured state with status and test/re-setup options
/// - Free tier with upgrade prompt
class ErrorWorkflowSetupCard extends StatelessWidget {
  final Instance instance;
  final ErrorWorkflowSetupState? setupState;
  final bool meetsRequirement;
  final VoidCallback? onSetupNow;
  final VoidCallback? onTest;
  final VoidCallback? onResetup;
  final VoidCallback? onUpgrade;

  const ErrorWorkflowSetupCard({
    super.key,
    required this.instance,
    this.setupState,
    required this.meetsRequirement,
    this.onSetupNow,
    this.onTest,
    this.onResetup,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Free tier - show upgrade prompt
    if (!meetsRequirement) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error Notifications',
                      style: textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Push notifications require Pro plan or higher',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onUpgrade,
                icon: const Icon(Icons.upgrade),
                label: const Text('Upgrade Now'),
              ),
            ],
          ),
        ),
      );
    }

    // Not configured - show setup prompt
    if (setupState == null || !setupState!.isSetupComplete) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error Notifications',
                      style: textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Get instant alerts when workflows fail in this instance',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onSetupNow,
                icon: const Icon(Icons.add),
                label: const Text('Set Up Now'),
              ),
            ],
          ),
        ),
      );
    }

    // Configured - show status
    final lastSetup = setupState!.lastSetupDate;
    final method = setupState!.setupMethod;
    final hasTested = setupState!.hasTestedNotification ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error Notifications',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              method == 'automatic' ? 'Automatic' : 'Manual',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          if (hasTested) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tested',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (lastSetup != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last setup: ${DateFormat.yMMMd().format(lastSetup)}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTest,
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Test'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onResetup,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Re-setup'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

