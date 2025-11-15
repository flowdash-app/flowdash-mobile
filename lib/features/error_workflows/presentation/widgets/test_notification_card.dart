import 'package:flutter/material.dart';

/// Card for testing error notifications.
/// 
/// Large prominent button that sends a test notification.
/// Shows loading, success, and error states with appropriate messaging.
class TestNotificationCard extends StatelessWidget {
  final VoidCallback? onTest;
  final bool isLoading;
  final bool isSuccess;
  final bool isError;
  final String? errorMessage;
  final String? successMessage;

  const TestNotificationCard({
    super.key,
    this.onTest,
    this.isLoading = false,
    this.isSuccess = false,
    this.isError = false,
    this.errorMessage,
    this.successMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: (isLoading || isSuccess) ? null : onTest,
          icon: _buildIcon(colorScheme),
          label: Text(_getButtonLabel()),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: isSuccess
                ? colorScheme.primaryContainer
                : isError
                    ? colorScheme.errorContainer
                    : null,
            foregroundColor: isSuccess
                ? colorScheme.onPrimaryContainer
                : isError
                    ? colorScheme.onErrorContainer
                    : null,
          ),
        ),
        if (isSuccess || isError) ...[
          const SizedBox(height: 12),
          _buildMessage(context, colorScheme, textTheme),
        ],
      ],
    );
  }

  Widget _buildIcon(ColorScheme colorScheme) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.onPrimary,
        ),
      );
    } else if (isSuccess) {
      return Icon(
        Icons.check_circle,
        color: colorScheme.primary,
      );
    } else if (isError) {
      return Icon(
        Icons.error_outline,
        color: colorScheme.error,
      );
    } else {
      return const Icon(Icons.send);
    }
  }

  String _getButtonLabel() {
    if (isLoading) {
      return 'Sending Test...';
    } else if (isSuccess) {
      return 'Test Sent Successfully!';
    } else if (isError) {
      return 'Test Failed - Retry';
    } else {
      return 'Send Test Notification';
    }
  }

  Widget _buildMessage(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (isSuccess) {
      return Card(
        color: colorScheme.primaryContainer.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  successMessage ??
                      'Test notification sent! Check your phone for the notification.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (isError) {
      return Card(
        color: colorScheme.errorContainer.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 20,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage ?? 'Test failed. Please check your setup.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Common issues:\n'
                '• Workflow not imported in n8n\n'
                '• Workflow not activated\n'
                '• Instance is disabled',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

