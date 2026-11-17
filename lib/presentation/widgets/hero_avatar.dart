import 'package:flutter/material.dart' hide Hero;

import '../../core/theme/app_theme.dart';
import '../../domain/entities/hero.dart';

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
      child: hero.hasImage
          ? Image.network(
              hero.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _AvatarFallback(size: size),
              loadingBuilder: (context, child, progress) {
                if (progress == null) {
                  return child;
                }
                return const ColoredBox(color: AppColors.surfaceLight);
              },
            )
          : _AvatarFallback(size: size),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.person_outline,
        size: size * 0.5,
        color: AppColors.muted,
      ),
    );
  }
}
