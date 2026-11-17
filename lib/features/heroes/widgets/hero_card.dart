import 'package:flutter/material.dart' hide Hero;

import '../../../core/theme/app_theme.dart';
import '../../../data/models/hero.dart';
import '../screens/hero_detail_screen.dart';

/// Карточка героя: изображение, имя, роль, кнопка лайка.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.hero,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onTap,
  });

  final Hero hero;
  final bool isFavorite;
  final Future<void> Function() onToggleFavorite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap ??
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HeroDetailScreen(hero: hero),
              ),
            ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2B0F16), Color(0xFF171214)],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _HeroImage(url: hero.imageUrl),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _FavoriteButton(
                        isFavorite: isFavorite,
                        onPressed: onToggleFavorite,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hero.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hero.role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.copper,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.sports_esports_rounded,
            size: 42,
            color: AppColors.muted,
          ),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return const ColoredBox(color: AppColors.surfaceLight);
        },
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onPressed});

  final bool isFavorite;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey<bool>(isFavorite),
              size: 20,
              color: isFavorite ? AppColors.burgundyBright : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
