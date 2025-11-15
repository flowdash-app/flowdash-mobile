import 'package:flutter/material.dart';

/// A widget that displays an info row with a leading icon and optional subtitle.
/// 
/// This is a pure StatelessWidget with no dependencies, making it
/// highly reusable and testable.
class InfoRowWithIcon extends StatelessWidget {
  /// The icon to display at the start of the row
  final IconData icon;
  
  /// The label text to display
  final String label;
  
  /// The value text to display
  final String value;
  
  /// Optional subtitle to display below the value
  final String? subtitle;

  const InfoRowWithIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

