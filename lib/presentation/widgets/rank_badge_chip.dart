import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/colors.dart';
import '../../domain/entities/player_badge.dart';

class RankBadgeChip extends StatelessWidget {
  const RankBadgeChip({super.key, required this.badge, this.compact = false});

  final PlayerBadge? badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final current = badge;
    final color = current == null
        ? AppColors.muted
        : Color(parseHexColor(current.colorHex) ?? 0xFFD9A441);

    if (current == null) {
      return Text(
        '—',
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.military_tech_rounded,
            size: compact ? 11 : 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              current.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
