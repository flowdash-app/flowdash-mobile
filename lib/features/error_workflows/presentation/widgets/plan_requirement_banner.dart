import 'package:flutter/material.dart';

/// Banner showing plan requirement for error notifications.
/// 
/// Shows current plan status and upgrade button if needed.
class PlanRequirementBanner extends StatelessWidget {
  final String currentPlan;
  final bool meetsRequirement;
  final VoidCallback? onUpgrade;

  const PlanRequirementBanner({
    super.key,
    required this.currentPlan,
    required this.meetsRequirement,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: meetsRequirement
          ? colorScheme.primaryContainer.withOpacity(0.5)
          : colorScheme.errorContainer.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  meetsRequirement ? Icons.check_circle : Icons.lock,
                  size: 24,
                  color: meetsRequirement
                      ? colorScheme.primary
                      : colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meetsRequirement
                            ? 'Plan Requirement: Met'
                            : 'Pro Plan Required',
                        style: textTheme.titleSmall?.copyWith(
                          color: meetsRequirement
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meetsRequirement
                            ? 'Current Plan: ${_formatPlanName(currentPlan)}'
                            : 'Push notifications require Pro or higher',
                        style: textTheme.bodySmall?.copyWith(
                          color: meetsRequirement
                              ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                              : colorScheme.onErrorContainer.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!meetsRequirement)
                  _buildPlanBadge(context, currentPlan, colorScheme),
              ],
            ),
            if (!meetsRequirement && onUpgrade != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onUpgrade,
                  icon: const Icon(Icons.upgrade),
                  label: const Text('Upgrade Now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanBadge(
    BuildContext context,
    String plan,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPlanColor(plan, colorScheme).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getPlanColor(plan, colorScheme),
          width: 1,
        ),
      ),
      child: Text(
        _formatPlanName(plan),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _getPlanColor(plan, colorScheme),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Color _getPlanColor(String plan, ColorScheme colorScheme) {
    switch (plan.toLowerCase()) {
      case 'free':
        return colorScheme.outline;
      case 'pro':
        return colorScheme.primary;
      case 'business':
        return colorScheme.tertiary;
      default:
        return colorScheme.outline;
    }
  }

  String _formatPlanName(String plan) {
    return plan[0].toUpperCase() + plan.substring(1).toLowerCase();
  }
}

