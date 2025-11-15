import 'package:flutter/material.dart';

/// A section header widget with title, optional subtitle, and action button.
/// 
/// This is a pure StatelessWidget with no dependencies, making it
/// highly reusable and testable.
class SectionHeader extends StatelessWidget {
  /// The main title text
  final String title;
  
  /// Optional subtitle text
  final String? subtitle;
  
  /// Optional action button (e.g., "View All")
  final Widget? actionButton;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionButton != null) actionButton!,
      ],
    );
  }
}

