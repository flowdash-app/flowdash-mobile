import 'package:flutter/material.dart';

/// Wrapper widget for carousel items.
/// 
/// Provides consistent styling with Material Design Card,
/// proper padding, elevation, and responsive sizing.
class CarouselItemWrapper extends StatelessWidget {
  final Widget child;

  const CarouselItemWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 32,
        ),
        child: child,
      ),
    );
  }
}

