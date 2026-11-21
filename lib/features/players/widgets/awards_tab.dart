import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/player_hero_stat.dart';
import '../../../presentation/widgets/surface_card.dart';
import '../player_insights.dart';
import 'profile_common.dart';

class ProfileAwardsTab extends StatelessWidget {
  const ProfileAwardsTab({super.key, required this.insights});

  final PlayerInsights insights;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 880;
        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_mvpCard(), const SizedBox(height: 12), _recordsCard()],
        );
        final right = _achievementsCard();

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 12), right],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 360, child: left),
            const SizedBox(width: 14),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _mvpCard() {
    final heroes = insights.heroes;
    var first = 0;
    var second = 0;
    var third = 0;
    var rated = 0;
    for (final hero in heroes) {
      first += hero.mvpFirst;
      second += hero.mvpSecond;
      third += hero.mvpThird;
      rated += hero.mvpRatedMatches;
    }
    final total = first + second + third;
    final podium = [
      _PodiumEntry(place: 2, count: second, color: const Color(0xFFB9C4CF)),
      _PodiumEntry(place: 1, count: first, color: AppColors.gold),
      _PodiumEntry(place: 3, count: third, color: AppColors.copper),
    ];
    final topHero = _topMvpHero(heroes);

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSectionTitle(
            icon: Icons.workspace_premium_rounded,
            title: 'Награды MVP',
            subtitle: rated > 0
                ? '${formatCount(rated)} матчей с оценкой MVP'
                : 'Всего наград: ${formatCount(total)}',
            trailing: Text(
              formatCount(total),
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var index = 0; index < podium.length; index++) ...[
                if (index > 0) const SizedBox(width: 6),
                Expanded(
                  child: _PodiumCard(
                    entry: podium[index],
                    total: math.max(1, total),
                  ),
                ),
              ],
            ],
          ),
          if (topHero != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Чаще всего MVP: ${topHero.hero.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${topHero.mvpTotal}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _achievementsCard() {
    final achievements = _buildAchievements(insights);
    final unlocked = achievements.where((item) => item.progress >= 1).length;

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSectionTitle(
            icon: Icons.emoji_events_rounded,
            title: 'Достижения',
            subtitle:
                '$unlocked из ${achievements.length} открыто · прогресс локальный',
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < achievements.length; index++) ...[
            if (index > 0) const SizedBox(height: 11),
            _AchievementRow(item: achievements[index]),
          ],
        ],
      ),
    );
  }

  Widget _recordsCard() {
    final records = _buildRecords(insights);
    if (records.isEmpty) {
      return const SizedBox.shrink();
    }
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileSectionTitle(
            icon: Icons.bolt_rounded,
            title: 'Личные рекорды',
            subtitle: 'Лучшие результаты в загруженных матчах',
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < records.length; index++) ...[
            if (index > 0)
              const Divider(height: 14, color: AppColors.surfaceLight),
            Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Icon(
                    records[index].icon,
                    size: 14,
                    color: AppColors.copper,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        records[index].label,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        records[index].detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 8.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  records[index].value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PodiumEntry {
  const _PodiumEntry({
    required this.place,
    required this.count,
    required this.color,
  });

  final int place;
  final int count;
  final Color color;
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.entry, required this.total});

  final _PodiumEntry entry;
  final int total;

  @override
  Widget build(BuildContext context) {
    final share = entry.count / total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: entry.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: entry.color.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            entry.place == 1
                ? Icons.military_tech_rounded
                : Icons.workspace_premium_outlined,
            color: entry.color,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.place} место',
            style: TextStyle(
              color: entry.color,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatCount(entry.count),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            formatPercent(share, digits: 0),
            style: const TextStyle(color: AppColors.muted, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _AchievementItem {
  const _AchievementItem({
    required this.icon,
    required this.label,
    required this.current,
    required this.target,
    required this.valueText,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double current;
  final double target;
  final String valueText;
  final Color color;

  double get progress => target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.item});

  final _AchievementItem item;

  @override
  Widget build(BuildContext context) {
    final done = item.progress >= 1;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: (done ? AppColors.win : item.color).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (done ? AppColors.win : item.color).withValues(alpha: 0.4),
            ),
          ),
          child: Icon(
            done ? Icons.check_rounded : item.icon,
            size: 14,
            color: done ? AppColors.win : item.color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    done ? 'Открыто' : item.valueText,
                    style: TextStyle(
                      color: done ? AppColors.win : AppColors.muted,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ProfileProgressBar(
                value: item.progress,
                color: done ? AppColors.win : item.color,
                height: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordItem {
  const _RecordItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
}

PlayerHeroStat? _topMvpHero(List<PlayerHeroStat> heroes) {
  final pool = heroes.where((hero) => hero.mvpTotal > 0).toList();
  if (pool.isEmpty) {
    return null;
  }
  return pool.reduce(
    (best, hero) => hero.mvpTotal > best.mvpTotal ? hero : best,
  );
}

List<_AchievementItem> _buildAchievements(PlayerInsights insights) {
  final heroes = insights.heroes;
  var kills = 0;
  var assists = 0;
  var denies = 0;
  var buffs = 0;
  var accuracyWeight = 0.0;
  var accuracyMatches = 0;
  var critWeight = 0.0;
  var critMatches = 0;
  for (final hero in heroes) {
    kills += hero.kills;
    assists += hero.assists;
    denies += hero.deniesPerMin.round();
    buffs += hero.permanentBuffs;
    if (hero.accuracy > 0 && hero.matches > 0) {
      accuracyWeight += hero.accuracy * hero.matches;
      accuracyMatches += hero.matches;
    }
    if (hero.critShotRate > 0 && hero.matches > 0) {
      critWeight += hero.critShotRate * hero.matches;
      critMatches += hero.matches;
    }
  }
  final accuracy = accuracyMatches == 0
      ? 0.0
      : accuracyWeight / accuracyMatches;
  final crit = critMatches == 0 ? 0.0 : critWeight / critMatches;
  final kda = insights.kda;
  final totalMatches = insights.totalMatches == 0
      ? heroes.fold<int>(0, (sum, hero) => sum + hero.matches)
      : insights.totalMatches;

  return [
    _milestone(
      icon: Icons.sports_esports_rounded,
      label: 'Сыграно матчей',
      value: totalMatches,
      steps: const [10, 25, 50, 100, 250, 500, 1000],
      color: AppColors.copper,
    ),
    _milestone(
      icon: Icons.emoji_events_rounded,
      label: 'Побед',
      value: insights.totalWins,
      steps: const [5, 10, 25, 50, 100, 250, 500],
      color: AppColors.gold,
    ),
    _milestone(
      icon: Icons.gps_fixed_rounded,
      label: 'Убийства',
      value: kills,
      steps: const [50, 100, 250, 500, 1000, 2500],
      color: AppColors.lose,
    ),
    _milestone(
      icon: Icons.handshake_rounded,
      label: 'Помощь',
      value: assists,
      steps: const [100, 250, 500, 1000, 2500, 5000],
      color: AppColors.win,
    ),
    _milestone(
      icon: Icons.whatshot_rounded,
      label: 'KDA',
      value: (kda * 100).round(),
      steps: const [200, 250, 300, 400, 500],
      color: AppColors.ember,
      format: (value) => (value / 100).toStringAsFixed(2),
    ),
    _milestone(
      icon: Icons.my_location_rounded,
      label: 'Точность',
      value: (accuracy * 1000).round(),
      steps: const [350, 400, 450, 500, 550, 600],
      color: AppColors.win,
      format: (value) => formatPercent(value / 1000),
    ),
    _milestone(
      icon: Icons.flash_on_rounded,
      label: 'Критические удары',
      value: (crit * 1000).round(),
      steps: const [100, 150, 200, 250, 300],
      color: AppColors.lose,
      format: (value) => formatPercent(value / 1000),
    ),
    _milestone(
      icon: Icons.shield_moon_rounded,
      label: 'Постоянные бонусы',
      value: buffs,
      steps: const [10, 25, 50, 100, 250],
      color: AppColors.copper,
    ),
    _milestone(
      icon: Icons.content_cut_rounded,
      label: 'Денаи',
      value: denies,
      steps: const [25, 50, 100, 250, 500],
      color: AppColors.gold,
    ),
  ];
}

_AchievementItem _milestone({
  required IconData icon,
  required String label,
  required int value,
  required List<int> steps,
  required Color color,
  String Function(int value)? format,
}) {
  final target = steps.firstWhere(
    (step) => value < step,
    orElse: () => steps.last,
  );
  final done = value >= steps.last;
  return _AchievementItem(
    icon: icon,
    label: label,
    current: done ? target.toDouble() : value.toDouble(),
    target: target.toDouble(),
    valueText:
        '${format?.call(value) ?? formatCount(value)} / '
        '${format?.call(target) ?? formatCount(target)}',
    color: color,
  );
}

List<_RecordItem> _buildRecords(PlayerInsights insights) {
  final matches = insights.matches;
  final records = <_RecordItem>[];
  if (matches.isEmpty) {
    return records;
  }

  final bestKills = matches.reduce(
    (best, match) => match.kills > best.kills ? match : best,
  );
  records.add(
    _RecordItem(
      icon: Icons.gps_fixed_rounded,
      label: 'Больше всего убийств за матч',
      value: '${bestKills.kills}',
      detail:
          '${bestKills.hero.name} · ${bestKills.kda.toStringAsFixed(2)} KDA',
    ),
  );

  final bestAssists = matches.reduce(
    (best, match) => match.assists > best.assists ? match : best,
  );
  records.add(
    _RecordItem(
      icon: Icons.handshake_rounded,
      label: 'Больше всего помощи за матч',
      value: '${bestAssists.assists}',
      detail: bestAssists.hero.name,
    ),
  );

  final worthMatches = matches
      .where((match) => (match.netWorth ?? 0) > 0)
      .toList();
  if (worthMatches.isNotEmpty) {
    final bestWorth = worthMatches.reduce(
      (best, match) =>
          (match.netWorth ?? 0) > (best.netWorth ?? 0) ? match : best,
    );
    records.add(
      _RecordItem(
        icon: Icons.savings_rounded,
        label: 'Рекорд по net worth',
        value: formatCompact((bestWorth.netWorth ?? 0).toDouble()),
        detail: bestWorth.hero.name,
      ),
    );
  }

  final streak = insights.longestWinStreak;
  if (streak > 1) {
    records.add(
      _RecordItem(
        icon: Icons.local_fire_department_rounded,
        label: 'Самая длинная серия побед',
        value: '$streak',
        detail: 'матчей подряд',
      ),
    );
  }

  final heroes = insights.heroes;
  final accurate = heroes
      .where((hero) => hero.matches >= 3 && hero.accuracy > 0)
      .toList();
  if (accurate.isNotEmpty) {
    final best = accurate.reduce((a, b) => a.accuracy > b.accuracy ? a : b);
    records.add(
      _RecordItem(
        icon: Icons.my_location_rounded,
        label: 'Лучшая точность по герою',
        value: formatPercent(best.accuracy),
        detail: '${best.hero.name} · ${best.matches} матчей',
      ),
    );
  }

  return records;
}
