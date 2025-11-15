import 'package:flutter/material.dart';

/// A simple widget that displays a label-value pair in a row.
/// 
/// This is a pure StatelessWidget with no dependencies, making it
/// highly reusable and testable.
class InfoRow extends StatelessWidget {
  /// The label text to display
  final String label;
  
  /// The value text to display
  final String value;
  
  /// Optional width for the label column (defaults to 100)
  final double? labelWidth;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth ?? 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

