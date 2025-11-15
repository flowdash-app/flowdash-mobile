import 'package:flutter/material.dart';

/// A full-page error state widget with centered content.
/// 
/// Use this for dedicated pages (NOT in home/main pages).
/// This is a pure StatelessWidget with no dependencies.
class FullPageErrorState extends StatelessWidget {
  /// The icon to display
  final IconData icon;
  
  /// Optional icon color (defaults to red[300])
  final Color? iconColor;
  
  /// The title text
  final String title;
  
  /// The error message text
  final String message;
  
  /// Optional action button
  final Widget? actionButton;

  const FullPageErrorState({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.message,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: iconColor ?? Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
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
              const SizedBox(height: 24),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}

