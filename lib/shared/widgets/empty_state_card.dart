import 'package:flutter/material.dart';

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String message;
  final Widget? actionButton;
  final bool centered;

  const EmptyStateCard({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.message,
    this.actionButton,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: iconColor ?? Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (actionButton != null) ...[
                const SizedBox(height: 16),
                actionButton!,
              ],
            ],
          ),
        ),
      ),
    );

    if (centered) {
      return Center(child: card);
    }
    return card;
  }
}

