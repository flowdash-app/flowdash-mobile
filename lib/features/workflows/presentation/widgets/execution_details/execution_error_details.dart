import 'package:flutter/material.dart';

class ExecutionErrorDetails extends StatelessWidget {
  final String? errorMessage;

  const ExecutionErrorDetails({
    super.key,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 20, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                'Error Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            errorMessage!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[700],
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

