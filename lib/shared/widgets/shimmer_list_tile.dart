import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerListTile extends StatelessWidget {
  final bool wrapInCard;
  final bool showTrailing;
  final bool showLeading;

  const ShimmerListTile({
    super.key,
    this.wrapInCard = false,
    this.showTrailing = true,
    this.showLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: ListTile(
        leading: showLeading
            ? const CircleAvatar(
                backgroundColor: Colors.white,
              )
            : null,
        title: Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Container(
            height: 12,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        trailing: showTrailing
            ? Container(
                width: 48,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              )
            : null,
      ),
    );

    if (wrapInCard) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: tile,
      );
    }

    return tile;
  }
}

class ShimmerLoadingList extends StatelessWidget {
  final int itemCount;
  final bool wrapInCard;
  final bool showTrailing;
  final bool showLeading;

  const ShimmerLoadingList({
    super.key,
    this.itemCount = 5,
    this.wrapInCard = false,
    this.showTrailing = true,
    this.showLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => ShimmerListTile(
          wrapInCard: wrapInCard,
          showTrailing: showTrailing,
          showLeading: showLeading,
        ),
      ),
    );
  }
}

