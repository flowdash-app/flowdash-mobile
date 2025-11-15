import 'package:flutter/material.dart';

/// Card for displaying and selecting a setup method (automatic or manual).
/// 
/// Shows method icon, title, description, recommended badge, and action button.
/// Handles loading, success, and error states.
class SetupMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isRecommended;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isSuccess;
  final bool isError;
  final String? errorMessage;
  final bool isDisabled;

  const SetupMethodCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.isRecommended = false,
    this.onTap,
    this.isLoading = false,
    this.isSuccess = false,
    this.isError = false,
    this.errorMessage,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determine border color based on state
    Color? borderColor;
    if (isSuccess) {
      borderColor = colorScheme.primary;
    } else if (isError) {
      borderColor = colorScheme.error;
    } else if (isDisabled) {
      borderColor = colorScheme.outline.withOpacity(0.5);
    }

    return Card(
      elevation: isDisabled ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: borderColor != null
            ? BorderSide(color: borderColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: (isDisabled || isLoading || isSuccess) ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[ Row(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isDisabled
                      ? colorScheme.onSurface.withOpacity(0.4)
                      : colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: textTheme.titleMedium?.copyWith(
                              color: isDisabled
                                  ? colorScheme.onSurface.withOpacity(0.4)
                                  : null,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
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
                                'Recommended',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: textTheme.bodySmall?.copyWith(
                          color: isDisabled
                              ? colorScheme.onSurface.withOpacity(0.4)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
              if (isLoading || isSuccess || isError) ...[
                const SizedBox(height: 12),
                if (isLoading)
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Setting up...',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                if (isSuccess)
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Setup complete!',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                if (isError)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage ?? 'Setup failed. Please try again.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

