import 'package:flutter/material.dart';

/// A ListTile with an integrated switch control.
/// 
/// This is a pure StatelessWidget with no dependencies, making it
/// highly reusable and testable.
class SwitchableListTile extends StatelessWidget {
  /// The title text
  final String title;
  
  /// The subtitle widget
  final Widget subtitle;
  
  /// The current switch value
  final bool switchValue;
  
  /// Callback when switch value changes
  final ValueChanged<bool> onSwitchChanged;
  
  /// Whether to wrap the tile in a Card (defaults to false)
  final bool wrapInCard;
  
  /// Optional card margin (only used if wrapInCard is true)
  final EdgeInsets? cardMargin;

  const SwitchableListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.switchValue,
    required this.onSwitchChanged,
    this.wrapInCard = false,
    this.cardMargin,
  });

  @override
  Widget build(BuildContext context) {
    final listTile = ListTile(
      title: Text(title),
      subtitle: subtitle,
      trailing: Switch(
        value: switchValue,
        onChanged: onSwitchChanged,
      ),
    );

    if (wrapInCard) {
      return Card(
        margin: cardMargin ?? const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: listTile,
      );
    }

    return listTile;
  }
}

