import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/item.dart';
import 'remote_image.dart';

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
      child: RemoteImage(
        url: item.imageUrl,
        useProxy: true,
        proxyWidth: 160,
        fallback: const DeadlockImageFallback(),
      ),
    );
  }
}
