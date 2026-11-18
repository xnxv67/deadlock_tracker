import 'package:flutter/material.dart' hide Hero;

import '../../core/theme/app_theme.dart';
import '../../domain/entities/hero.dart';
import 'remote_image.dart';

class HeroAvatar extends StatelessWidget {
  const HeroAvatar({
    super.key,
    required this.hero,
    this.size = 34,
    this.borderRadius,
    this.borderColor,
  });

  final Hero hero;
  final double size;
  final double? borderRadius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size * 0.18;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: RemoteImage(
        url: hero.imageUrl,
        useProxy: true,
        proxyWidth: 128,
        fallback: const DeadlockImageFallback(),
      ),
    );
  }
}
