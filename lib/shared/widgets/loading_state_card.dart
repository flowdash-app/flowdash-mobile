import 'package:flutter/material.dart';

class LoadingStateCard extends StatelessWidget {
  final String message;
  final bool centered;

  const LoadingStateCard({
    super.key,
    required this.message,
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
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
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

