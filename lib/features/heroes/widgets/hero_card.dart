import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/hero_meta.dart';
import '../screens/hero_detail_screen.dart';

/// Карточка героя: изображение, имя, роль, винрейт/пикрейт, кнопка лайка.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.meta,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onTap,
  });

  final HeroMeta meta;
  final bool isFavorite;
  final Future<void> Function() onToggleFavorite;
  final VoidCallback? onTap;

  /// Картинка из API; если её нет — собираем по ID героя.
  String get _imageUrl {
    final hero = meta.hero;
    if (hero.cardUrl.isNotEmpty) {
      return hero.cardUrl;
    }
    if (hero.imageUrl.isNotEmpty) {
      return hero.imageUrl;
    }
    return 'https://assets.deadlock-api.com/v2/heroes/${hero.id}/icon';
  }

  @override
  Widget build(BuildContext context) {
    final hero = meta.hero;
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
                      _HeroImage(url: _imageUrl),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _FavoriteButton(
                          isFavorite: isFavorite,
                          onPressed: onToggleFavorite,
                        ),
                      ),
                      if (meta.tier.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _TierBadge(tier: meta.tier),
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
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Tooltip(
                            message: 'Winrate',
                            child: _RateValue(
                              value: meta.winRate,
                              color: AppColors.winRateColor(meta.winRate),
                            ),
                          ),
                          const Text(
                            ' WR',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const Spacer(),
                          Tooltip(
                            message: 'Pickrate',
                            child: _RateValue(
                              value: meta.pickRate,
                              color: AppColors.copper,
                            ),
                          ),
                          const Text(
                            ' PR',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
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

class _RateValue extends StatelessWidget {
  const _RateValue({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${(value * 100).toStringAsFixed(1)}%',
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        height: 1.1,
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        tier,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
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
