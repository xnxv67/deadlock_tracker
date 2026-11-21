import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/match_record.dart';
import '../../../presentation/widgets/hero_avatar.dart';
import '../../../presentation/widgets/surface_card.dart';
import '../player_insights.dart';

class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.accent = AppColors.copper,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 7),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class ProfileProgressBar extends StatelessWidget {
  const ProfileProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.copper,
    this.height = 5,
    this.marker,
    this.background = AppColors.surfaceLight,
  });

  final double value;
  final Color color;
  final double height;
  final double? marker;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              Container(
                width: width * clamped,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              if (marker != null)
                Positioned(
                  left: (width * marker!.clamp(0.0, 1.0).toDouble() - 1.5)
                      .clamp(0.0, width - 3)
                      .toDouble(),
                  top: -2,
                  child: Container(
                    width: 3,
                    height: height + 4,
                    decoration: BoxDecoration(
                      color: AppColors.text,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileStatCard extends StatelessWidget {
  const ProfileStatCard({
    super.key,
    required this.label,
    required this.value,
    this.accent = AppColors.text,
    this.footnote,
    this.icon,
    this.progress,
    this.progressLabel,
    this.onTap,
  });

  final String label;
  final String value;
  final Color accent;
  final String? footnote;
  final IconData? icon;
  final double? progress;
  final String? progressLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (icon != null)
                Icon(icon, size: 12, color: accent.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          if (progress != null || footnote != null) ...[
            const SizedBox(height: 6),
            if (progress != null) ...[
              ProfileProgressBar(value: progress!, color: accent),
              const SizedBox(height: 4),
            ],
            if (progressLabel != null || footnote != null)
              Text(
                progressLabel ?? footnote!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  height: 1.15,
                ),
              ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: content,
      ),
    );
  }
}

class ProfileScorePanel extends StatelessWidget {
  const ProfileScorePanel({super.key, required this.insights});

  final PlayerInsights insights;

  @override
  Widget build(BuildContext context) {
    final score = insights.performanceScore;
    final window = insights.recentWindow();
    final delta = window.delta;
    final accent = score >= 62
        ? AppColors.win
        : score >= 45
        ? AppColors.gold
        : AppColors.lose;

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ИНДЕКС ФОРМЫ',
            style: TextStyle(
              color: AppColors.copper,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.round()}',
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 3, bottom: 5),
                child: Text(
                  '/ 100',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insights.performanceLabel,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          ProfileProgressBar(
            value: score / 100,
            color: accent,
            height: 6,
            marker: 0.5,
          ),
          const SizedBox(height: 5),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: TextStyle(color: AppColors.muted, fontSize: 8.5),
              ),
              Text(
                'средний',
                style: TextStyle(color: AppColors.muted, fontSize: 8.5),
              ),
              Text(
                '100',
                style: TextStyle(color: AppColors.muted, fontSize: 8.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                delta == null
                    ? Icons.timeline_rounded
                    : delta >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 13,
                color: delta == null
                    ? AppColors.muted
                    : delta >= 0
                    ? AppColors.win
                    : AppColors.lose,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  delta == null
                      ? 'За 7 дней: ${window.wins}–${window.losses}'
                      : 'За 7 дней: ${window.wins}–${window.losses} · '
                            '${delta >= 0 ? '+' : ''}'
                            '${(delta * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: delta == null
                        ? AppColors.muted
                        : delta >= 0
                        ? AppColors.win
                        : AppColors.lose,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key, required this.activity});

  final ActivityGrid activity;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSectionTitle(
            icon: Icons.calendar_view_week_rounded,
            title: 'Недавняя активность',
            trailing: Text(
              '${activity.totalMatches} матчей',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final cell = ((constraints.maxWidth - 11 * 3) / 12)
                  .clamp(7.0, 15.0)
                  .toDouble();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final column in activity.columns)
                    Column(
                      children: [
                        for (final day in column)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: _ActivityCell(day: day, size: cell),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 7),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '12 недель назад',
                style: TextStyle(color: AppColors.muted, fontSize: 8),
              ),
              Text(
                'сегодня',
                style: TextStyle(color: AppColors.muted, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityCell extends StatelessWidget {
  const _ActivityCell({required this.day, required this.size});

  final ActivityDay? day;
  final double size;

  @override
  Widget build(BuildContext context) {
    final date = day?.date;
    Color color;
    if (day == null || !day!.hasGames) {
      color = AppColors.surfaceLight;
    } else if (day!.allWins) {
      color = AppColors.win;
    } else if (day!.wins == 0) {
      color = AppColors.lose;
    } else {
      color = AppColors.gold;
    }

    final cell = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: day?.hasGames == true ? 0.9 : 0.55),
        borderRadius: BorderRadius.circular(2.5),
        border: Border.all(
          color: day?.hasGames == true
              ? color.withValues(alpha: 0.35)
              : AppColors.border.withValues(alpha: 0.6),
          width: 0.7,
        ),
      ),
    );

    if (day == null || !day!.hasGames) {
      return cell;
    }

    return Tooltip(
      message:
          '${date!.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')} · '
          '${day!.matches} матчей · ${day!.wins} побед',
      child: cell,
    );
  }
}

class WeekdayWinRateCard extends StatelessWidget {
  const WeekdayWinRateCard({super.key, required this.stats});

  final List<WeekdayStat> stats;

  static const _labels = ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС'];

  @override
  Widget build(BuildContext context) {
    final window = stats.fold<int>(0, (sum, item) => sum + item.matches);
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSectionTitle(
            icon: Icons.insights_rounded,
            title: 'Активность по дням',
            trailing: Text(
              '$window матчей',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < 7; index++)
                  Expanded(
                    child: _WeekdayBar(
                      label: _labels[index],
                      stat: stats[index],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayBar extends StatelessWidget {
  const _WeekdayBar({required this.label, required this.stat});

  final String label;
  final WeekdayStat stat;

  @override
  Widget build(BuildContext context) {
    final hasGames = stat.matches > 0;
    final color = !hasGames
        ? AppColors.surfaceLight
        : stat.winRate >= 0.5
        ? AppColors.win
        : AppColors.lose;
    final height = hasGames ? (14 + stat.winRate * 34) : 8.0;

    return Tooltip(
      message: hasGames
          ? '$label · ${stat.matches} матчей · '
                '${formatPercent(stat.winRate, digits: 0)} побед'
          : '$label · нет матчей',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (hasGames)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${(stat.winRate * 100).round()}',
                  style: TextStyle(
                    color: color,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            Container(
              height: height,
              decoration: BoxDecoration(
                color: color.withValues(alpha: hasGames ? 0.85 : 0.6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FormCurveCard extends StatelessWidget {
  const FormCurveCard({
    super.key,
    required this.insights,
    required this.onMatchTap,
  });

  final PlayerInsights insights;
  final void Function(MatchRecord match) onMatchTap;

  @override
  Widget build(BuildContext context) {
    final points = insights.recentForm(20);
    if (points.isEmpty) {
      return SurfaceCard(
        child: Text(
          'Нет данных для графика формы',
          style: TextStyle(color: AppColors.muted, fontSize: 11.5),
        ),
      );
    }

    var best = points.first;
    var average = 0.0;
    for (final point in points) {
      average += point.score;
      if (point.score > best.score) {
        best = point;
      }
    }
    average /= points.length;

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: ProfileSectionTitle(
                  icon: Icons.show_chart_rounded,
                  title: 'Кривая формы',
                  subtitle: 'Последние 20 матчей · индекс результата',
                ),
              ),
              const SizedBox(width: 8),
              _LegendDot(color: AppColors.win, label: 'Победа'),
              const SizedBox(width: 8),
              _LegendDot(color: AppColors.lose, label: 'Поражение'),
            ],
          ),
          const SizedBox(height: 12),
          _FormChart(points: points, average: average, onTap: onMatchTap),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Лучший матч: ${best.score.round()} · '
                  '${best.match.hero.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 9),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Среднее: ${average.round()}',
                style: const TextStyle(color: AppColors.muted, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 8),
        ),
      ],
    );
  }
}

class _FormChart extends StatelessWidget {
  const _FormChart({
    required this.points,
    required this.average,
    required this.onTap,
  });

  final List<FormPoint> points;
  final double average;
  final void Function(MatchRecord match) onTap;

  @override
  Widget build(BuildContext context) {
    const chartHeight = 118.0;
    return SizedBox(
      height: 144,
      child: Column(
        children: [
          SizedBox(
            height: chartHeight,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                Positioned(
                  left: 0,
                  right: 0,
                  top: (1 - average / 100) * chartHeight,
                  child: const _DashedLine(color: AppColors.copper),
                ),
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final point in points)
                        Expanded(
                          child: Tooltip(
                            message:
                                '${point.match.hero.name} · '
                                '${point.match.isWin ? 'победа' : 'поражение'} · '
                                '${point.match.kills}/${point.match.deaths}/'
                                '${point.match.assists}\n'
                                'Индекс ${point.score.round()}',
                            child: InkWell(
                              onTap: () => onTap(point.match),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 1.5,
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    height: (point.score / 100) * chartHeight,
                                    decoration: BoxDecoration(
                                      color: point.match.isWin
                                          ? AppColors.win
                                          : AppColors.lose,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                formatMonthDayFromSeconds(points.first.match.startTime),
                style: const TextStyle(color: AppColors.muted, fontSize: 8),
              ),
              const Spacer(),
              Text(
                formatMonthDayFromSeconds(points.last.match.startTime),
                style: const TextStyle(color: AppColors.muted, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceLight
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final middle = Paint()
      ..color = AppColors.border.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      middle,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 5.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          children: [
            for (var index = 0; index < count; index++) ...[
              Container(width: dash, height: 1, color: color),
              if (index != count - 1) const SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }
}

class MatchHistoryTile extends StatelessWidget {
  const MatchHistoryTile({
    super.key,
    required this.match,
    required this.onTap,
    this.compact = false,
  });

  final MatchRecord match;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = match.isWin ? AppColors.win : AppColors.lose;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showFacts = !compact && constraints.maxWidth >= 480;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: compact ? 64 : 78,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  HeroAvatar(hero: match.hero, size: compact ? 40 : 48),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  match.hero.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: compact ? 12.5 : 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  match.isWin ? 'ПОБЕДА' : 'ПОРАЖЕНИЕ',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${match.kills} / ${match.deaths} / ${match.assists}'
                            '  ·  KDA ${match.kda.toStringAsFixed(2)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatDateFromSeconds(match.startTime)} · '
                            '${formatDuration(match.durationSeconds)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showFacts)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: _MatchFacts(match: match),
                    ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MatchFacts extends StatelessWidget {
  const _MatchFacts({required this.match});

  final MatchRecord match;

  @override
  Widget build(BuildContext context) {
    final facts = <_Fact>[
      if (match.netWorth != null)
        _Fact('NW', formatCount(match.netWorth!), AppColors.win),
      if (match.lastHits != null)
        _Fact('LH', formatCount(match.lastHits!), AppColors.gold),
      if (match.denies != null)
        _Fact('DN', formatCount(match.denies!), AppColors.muted),
    ];
    if (facts.isEmpty) {
      return const SizedBox(width: 4);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final fact in facts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fact.label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  fact.value,
                  style: TextStyle(
                    color: fact.color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Fact {
  const _Fact(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}
