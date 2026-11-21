import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/hero_meta.dart';
import '../../../presentation/widgets/remote_image.dart';
import '../screens/hero_detail_screen.dart';

/// Карточка героя: изображение, имя, роль, винрейт/пикрейт, кнопка лайка.
class HeroCard extends StatefulWidget {
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

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard> {
  static const _duration = Duration(milliseconds: 200);

  bool _hovered = false;

  /// Картинка из API; если её нет — собираем по ID героя.
  String get _imageUrl {
    final hero = widget.meta.hero;
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
    final meta = widget.meta;
    final hero = meta.hero;
    final hovered = _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: hovered ? 1.025 : 1,
        duration: _duration,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: hovered
                    ? AppColors.copper.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.3),
                blurRadius: hovered ? 26 : 8,
                spreadRadius: hovered ? 1 : 0,
                offset: Offset(0, hovered ? 8 : 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              hoverColor: AppColors.copper.withValues(alpha: 0.08),
              onTap:
                  widget.onTap ??
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HeroDetailScreen(hero: hero),
                    ),
                  ),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: hovered ? AppColors.copper : AppColors.border,
                    width: hovered ? 1.4 : 1,
                  ),
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                              child: _HeroImage(
                                url: _imageUrl,
                                label: hero.name,
                                hovered: hovered,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: _FavoriteButton(
                                isFavorite: widget.isFavorite,
                                onPressed: widget.onToggleFavorite,
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
                                Expanded(
                                  child: _RateMeter(
                                    value: meta.winRate,
                                    color: AppColors.winRateColor(meta.winRate),
                                    label: 'WR',
                                    tooltip: 'Winrate',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _RateMeter(
                                    // Пикрейт редко превышает 20%, растягиваем шкалу.
                                    value: (meta.pickRate / 0.2).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                    displayValue: meta.pickRate,
                                    color: AppColors.copper,
                                    label: 'PR',
                                    tooltip: 'Pickrate',
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
          ),
        ),
      ),
    );
  }
}

class _RateMeter extends StatelessWidget {
  const _RateMeter({
    required this.value,
    required this.color,
    required this.label,
    required this.tooltip,
    this.displayValue,
  });

  final double value;
  final double? displayValue;
  final Color color;
  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final percent = (displayValue ?? value) * 100;

    return Tooltip(
      message: tooltip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${percent.toStringAsFixed(1)}%',
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tier.toUpperCase()) {
      'S' => (const Color(0xFFC2313F), Colors.white),
      'A' => (const Color(0xFFD97A2B), const Color(0xFF1B1008)),
      'B' => (const Color(0xFFD9A441), const Color(0xFF1B1408)),
      _ => (AppColors.surfaceLight, AppColors.muted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: colors.$1.withValues(alpha: 0.55),
            blurRadius: 8,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Text(
        tier,
        style: TextStyle(
          color: colors.$2,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.url,
    required this.label,
    required this.hovered,
  });

  final String url;
  final String label;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AnimatedScale(
        scale: hovered ? 1.03 : 1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: RemoteImage(
          url: url,
          useProxy: true,
          proxyWidth: 600,
          fallback: DeadlockImageFallback(label: label),
        ),
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
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
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
