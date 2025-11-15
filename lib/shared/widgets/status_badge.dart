import 'package:flutter/material.dart';

/// A widget that displays a status badge with an icon, text, and color.
/// 
/// This is a pure StatelessWidget with no dependencies, making it
/// highly reusable and testable.
class StatusBadge extends StatelessWidget {
  /// The text to display in the badge
  final String statusText;
  
  /// The color theme for the badge
  final Color statusColor;
  
  /// The icon to display in the badge
  final IconData statusIcon;
  
  /// Optional padding (defaults to symmetric horizontal: 12, vertical: 8)
  final EdgeInsets? padding;

  const StatusBadge({
    super.key,
    required this.statusText,
    required this.statusColor,
    required this.statusIcon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 20, color: statusColor),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

