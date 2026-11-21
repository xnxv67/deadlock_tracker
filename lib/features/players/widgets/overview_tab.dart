import 'package:flutter/material.dart' hide Hero;

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/match_record.dart';
import '../../../domain/entities/player_badge.dart';
import '../../../domain/entities/player_hero_stat.dart';
import '../../../presentation/widgets/remote_image.dart';
import '../../../presentation/widgets/surface_card.dart';
import '../player_insights.dart';
import 'profile_common.dart';

class ProfileOverviewTab extends StatelessWidget {
  const ProfileOverviewTab({
    super.key,
    required this.insights,
    required this.badge,
    required this.onOpenMatch,
    required this.onOpenMatchesTab,
  });

  final PlayerInsights insights;
  final PlayerBadge? badge;
  final void Function(MatchRecord match) onOpenMatch;
  final VoidCallback onOpenMatchesTab;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 880;
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _summaryGrid(),
              const SizedBox(height: 12),
              ProfileScorePanel(insights: insights),
              if (insights.hasHeroes) ...[
                const SizedBox(height: 10),
                _topHeroesCard(),
              ],
              const SizedBox(height: 10),
              RecentActivityCard(activity: insights.activity),
              const SizedBox(height: 10),
              WeekdayWinRateCard(stats: insights.weekdayStats),
              const SizedBox(height: 16),
              _recentMatches(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 310,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileScorePanel(insights: insights),
                  const SizedBox(height: 10),
                  if (insights.hasHeroes) ...[
                    _topHeroesCard(),
                    const SizedBox(height: 10),
                  ],
                  RecentActivityCard(activity: insights.activity),
                  const SizedBox(height: 10),
                  WeekdayWinRateCard(stats: insights.weekdayStats),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _summaryGrid(columns: 2),
                  const SizedBox(height: 12),
                  _streakCard(),
                  const SizedBox(height: 12),
                  _recentMatches(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryGrid({int columns = 4}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth < 520 ? 2 : columns;
        final width = (constraints.maxWidth - (count - 1) * 10) / count;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: width,
              child: ProfileStatCard(
                label: 'Винрейт',
                value: formatPercent(insights.winRate),
                accent: AppColors.winRateColor(insights.winRate),
                icon: Icons.percent_rounded,
                progress: insights.winRate,
                progressLabel:
                    '${formatCount(insights.totalWins)} побед · '
                    '${formatCount(insights.totalLosses)} поражений',
              ),
            ),
            SizedBox(
              width: width,
              child: ProfileStatCard(
                label: 'Матчи',
                value: formatCount(insights.totalMatches),
                accent: AppColors.text,
                icon: Icons.sports_esports_rounded,
                footnote: 'по всем героям',
              ),
            ),
            SizedBox(
              width: width,
              child: ProfileStatCard(
                label: 'KDA',
                value: insights.kda.toStringAsFixed(2),
                accent: AppColors.gold,
                icon: Icons.show_chart_rounded,
                footnote:
                    '${insights.avgKills.toStringAsFixed(1)} / '
                    '${insights.avgDeaths.toStringAsFixed(1)} / '
                    '${insights.avgAssists.toStringAsFixed(1)} за матч',
              ),
            ),
            SizedBox(
              width: width,
              child: ProfileStatCard(
                label: 'Ранг',
                value: badge == null ? '—' : badge!.label,
                accent: badge == null
                    ? AppColors.muted
                    : Color(parseHexColor(badge!.colorHex) ?? 0xFFD9A441),
                icon: Icons.military_tech_rounded,
                footnote: badge == null
                    ? 'ранг не определён'
                    : '${badge!.tierName} · ${badge!.subrank}',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _streakCard() {
    final streak = insights.currentStreak;
    final results = insights.recentResults(10).reversed.toList();
    final streakColor = streak >= 0 ? AppColors.win : AppColors.lose;
    final streakText = streak == 0
        ? 'Нет серии'
        : '${streak.abs()} ${streak > 0 ? 'побед' : 'поражений'} подряд';

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: streakColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: streakColor.withValues(alpha: 0.4)),
            ),
            child: Icon(
              streak >= 0
                  ? Icons.local_fire_department_rounded
                  : Icons.trending_down_rounded,
              color: streakColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ТЕКУЩАЯ СЕРИЯ',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  streakText,
                  style: TextStyle(
                    color: streakColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              for (final win in results)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    color: win ? AppColors.win : AppColors.lose,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topHeroesCard() {
    final heroes = insights.topHeroes(3);
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSectionTitle(
            icon: Icons.groups_rounded,
            title: 'Любимые герои',
            trailing: Text(
              '${insights.heroes.length}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < heroes.length; index++) ...[
                if (index > 0) const SizedBox(width: 7),
                Expanded(child: _TopHeroTile(stat: heroes[index])),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _recentMatches() {
    final matches = insights.matches.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionTitle(
          icon: Icons.history_rounded,
          title: 'Последние матчи',
          trailing: TextButton(
            onPressed: onOpenMatchesTab,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.gold,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'ВСЕ МАТЧИ',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (matches.isEmpty)
          const SurfaceCard(
            child: Text(
              'Нет истории матчей',
              style: TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
          )
        else
          for (var index = 0; index < matches.length; index++) ...[
            if (index > 0) const SizedBox(height: 7),
            MatchHistoryTile(
              match: matches[index],
              compact: true,
              onTap: () => onOpenMatch(matches[index]),
            ),
          ],
      ],
    );
  }
}

class _TopHeroTile extends StatelessWidget {
  const _TopHeroTile({required this.stat});

  final PlayerHeroStat stat;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.winRateColor(stat.winRate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
            color: AppColors.surfaceLight,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RemoteImage(
                url: stat.hero.bannerUrl,
                useProxy: true,
                proxyWidth: 240,
                fallback: DeadlockImageFallback(label: stat.hero.name),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE60C0A0C)],
                    stops: [0.35, 1],
                  ),
                ),
              ),
              Positioned(
                left: 5,
                right: 5,
                bottom: 4,
                child: Text(
                  stat.hero.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          formatPercent(stat.winRate, digits: 0),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${stat.matches} игр',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 8),
        ),
        Text(
          'KDA ${stat.kda.toStringAsFixed(2)}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.gold, fontSize: 8),
        ),
      ],
    );
  }
}
