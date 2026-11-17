import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/item.dart';

class ItemIcon extends StatelessWidget {
  const ItemIcon({
    super.key,
    required this.item,
    this.size = 30,
    this.borderColor,
  });

  final Item item;
  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: item.hasImage
          ? Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _Fallback(size: size),
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }
                return const ColoredBox(color: AppColors.surfaceLight);
              },
            )
          : _Fallback(size: size),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: size * 0.5,
        color: AppColors.muted,
      ),
    );
  }
}
