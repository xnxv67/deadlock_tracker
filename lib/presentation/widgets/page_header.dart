import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Компактная шапка внутреннего экрана в нуар-стиле.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.watermark,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String? watermark;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.copper.withValues(alpha: 0.32)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B0F16), Color(0xFF171214), Color(0xFF1D1613)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (watermark != null)
            Positioned(
              right: -4,
              top: -26,
              child: Text(
                watermark!,
                style: TextStyle(
                  fontSize: 92,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -3,
                  color: Colors.white.withValues(alpha: 0.035),
                  height: 1,
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final accent = Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.copper,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                  final label = Text(
                    eyebrow.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  );

                  if (trailing == null) {
                    return Row(
                      children: [
                        accent,
                        const SizedBox(width: 8),
                        Expanded(child: label),
                      ],
                    );
                  }

                  if (constraints.maxWidth < 520) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            accent,
                            const SizedBox(width: 8),
                            Expanded(child: label),
                          ],
                        ),
                        const SizedBox(height: 8),
                        trailing!,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      accent,
                      const SizedBox(width: 8),
                      Expanded(child: label),
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  );
                },
              ),
              const SizedBox(height: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
