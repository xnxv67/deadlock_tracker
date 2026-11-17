import 'package:flutter/material.dart' hide Hero;

import '../../../core/theme/app_theme.dart';
import '../../../data/models/hero.dart';

/// Детальный экран героя: изображение, имя, роль и описание.
class HeroDetailScreen extends StatelessWidget {
  const HeroDetailScreen({super.key, required this.hero});

  final Hero hero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(hero.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: AppColors.surfaceLight,
                child: (hero.cardUrl.isNotEmpty ? hero.cardUrl : hero.imageUrl)
                        .isNotEmpty
                    ? Image.network(
                        hero.cardUrl.isNotEmpty ? hero.cardUrl : hero.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(
                            Icons.sports_esports_rounded,
                            size: 64,
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.sports_esports_rounded,
                          size: 64,
                          color: AppColors.muted,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hero.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          if (hero.role.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              hero.role,
              style: const TextStyle(
                color: AppColors.copper,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '${hero.name} — ${hero.role.isEmpty ? 'герой Deadlock' : hero.role}. '
              'Подробная информация о герое, его роли и способностях.',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
