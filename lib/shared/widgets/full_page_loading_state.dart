import 'package:flutter/material.dart';

/// A full-page loading state widget with centered spinner and message.
/// 
/// Use this for dedicated pages (NOT in home/main pages).
/// This is a pure StatelessWidget with no dependencies.
class FullPageLoadingState extends StatelessWidget {
  /// Optional loading message
  final String? message;

  const FullPageLoadingState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

