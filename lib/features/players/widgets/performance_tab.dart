import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/match_record.dart';
import '../../../domain/entities/player_hero_stat.dart';
import '../../../presentation/widgets/hero_avatar.dart';
import '../../../presentation/widgets/surface_card.dart';
import '../player_insights.dart';
import 'profile_common.dart';

class ProfilePerformanceTab extends StatelessWidget {
  const ProfilePerformanceTab({
    super.key,
    required this.insights,
    required this.onOpenMatch,
  });

  final PlayerInsights insights;
  final void Function(MatchRecord match) onOpenMatch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 880;
        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileScorePanel(insights: insights),
            const SizedBox(height: 10),
            _heroCompareCard(),
            const SizedBox(height: 10),
            _averagesCard(),
          ],
        );
        final right = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormCurveCard(insights: insights, onMatchTap: onOpenMatch),
            const SizedBox(height: 12),
            _recentResultsCard(),
            const SizedBox(height: 12),
            _recordsSection(),
          ],
        );

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 12), right],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 310, child: left),
            const SizedBox(width: 14),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _heroCompareCard() {
    final best = insights.bestHero;
    final worst = insights.worstHero;
    if (best == null && worst == null) {
      return const SizedBox.shrink();
    }
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProfileSectionTitle(
            icon: Icons.emoji_events_rounded,
            title: 'Сильные и слабые герои',
          ),
          const SizedBox(height: 10),
          if (best != null)
            _HeroCompareTile(
              stat: best,
              label: 'Лучший герой',
              color: AppColors.win,
            ),
          if (best != null && worst != null) const SizedBox(height: 7),
          if (worst != null)
            _HeroCompareTile(
              stat: worst,
              label: 'Слабый герой',
              color: AppColors.lose,
            ),
        ],
      ),
    );
  }

  Widget _averagesCard() {
    final cards = <Widget>[
      ProfileStatCard(
        label: 'Средний KDA',
        value: insights.kda.toStringAsFixed(2),
        accent: AppColors.gold,
        footnote:
            '${insights.avgKills.toStringAsFixed(1)} / '
            '${insights.avgDeaths.toStringAsFixed(1)} / '
            '${insights.avgAssists.toStringAsFixed(1)}',
      ),
      ProfileStatCard(
        label: 'Длительность',
        value: formatDuration(insights.avgDurationSeconds),
        accent: AppColors.text,
        footnote: 'средний матч',
      ),
      if (insights.avgNetWorth != null)
        ProfileStatCard(
          label: 'Net worth',
          value: formatCompact(insights.avgNetWorth!),
          accent: AppColors.win,
          footnote: 'в среднем',
        ),
      if (insights.avgLastHits != null)
        ProfileStatCard(
          label: 'Ластхиты',
          value: formatCompact(insights.avgLastHits!),
          accent: AppColors.gold,
          footnote: 'в среднем',
        ),
      if (insights.avgHeroDamage != null)
        ProfileStatCard(
          label: 'Урон по героям',
          value: formatCompact(insights.avgHeroDamage!),
          accent: AppColors.copper,
          footnote: 'в среднем',
        ),
      if (insights.avgDenies != null)
        ProfileStatCard(
          label: 'Денай',
          value: formatCompact(insights.avgDenies!),
          accent: AppColors.muted,
          footnote: 'в среднем',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(
          icon: Icons.bar_chart_rounded,
          title: 'Средние показатели',
          subtitle: 'По загруженной истории матчей',
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth < 320 ? 1 : 2;
            final width = (constraints.maxWidth - (count - 1) * 8) / count;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final card in cards) SizedBox(width: width, child: card),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _recentResultsCard() {
    final recent = insights.matches.take(12).toList();
    if (recent.isEmpty) {
      return const SizedBox.shrink();
    }
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileSectionTitle(
            icon: Icons.timeline_rounded,
            title: 'Последние результаты',
            trailing: Text(
              '${recent.where((m) => m.isWin).length}–'
              '${recent.where((m) => !m.isWin).length}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final match in recent.reversed)
                Tooltip(
                  message:
                      '${match.hero.name} · '
                      '${match.isWin ? 'победа' : 'поражение'} · '
                      '${match.kills}/${match.deaths}/${match.assists}',
                  child: Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (match.isWin ? AppColors.win : AppColors.lose)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (match.isWin ? AppColors.win : AppColors.lose)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      match.isWin ? 'W' : 'L',
                      style: TextStyle(
                        color: match.isWin ? AppColors.win : AppColors.lose,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recordsSection() {
    final records = _buildRecords();
    if (records.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSectionTitle(
          icon: Icons.military_tech_rounded,
          title: 'Личные рекорды',
          subtitle: 'Лучшие матчи из загруженной истории',
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final count = constraints.maxWidth < 520 ? 2 : 4;
            final width = (constraints.maxWidth - (count - 1) * 8) / count;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final record in records)
                  SizedBox(
                    width: width,
                    child: _RecordTile(
                      record: record,
                      onTap: record.match == null
                          ? null
                          : () => onOpenMatch(record.match!),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<_Record> _buildRecords() {
    MatchRecord? bestKda;
    MatchRecord? mostKills;
    MatchRecord? mostDamage;
    MatchRecord? mostNetWorth;
    MatchRecord? mostLastHits;
    MatchRecord? longest;
    for (final match in insights.matches) {
      if (bestKda == null || match.kda > bestKda.kda) bestKda = match;
      if (mostKills == null || match.kills > mostKills.kills) mostKills = match;
      if (match.heroDamage != null &&
          (mostDamage == null ||
              match.heroDamage! > (mostDamage.heroDamage ?? 0))) {
        mostDamage = match;
      }
      if (match.netWorth != null &&
          (mostNetWorth == null ||
              match.netWorth! > (mostNetWorth.netWorth ?? 0))) {
        mostNetWorth = match;
      }
      if (match.lastHits != null &&
          (mostLastHits == null ||
              match.lastHits! > (mostLastHits.lastHits ?? 0))) {
        mostLastHits = match;
      }
      if (longest == null || match.durationSeconds > longest.durationSeconds) {
        longest = match;
      }
    }

    return [
      if (bestKda != null)
        _Record(
          label: 'Лучший KDA',
          value: bestKda.kda.toStringAsFixed(2),
          detail: bestKda.hero.name,
          icon: Icons.show_chart_rounded,
          accent: AppColors.gold,
          match: bestKda,
        ),
      if (mostKills != null)
        _Record(
          label: 'Макс убийств',
          value: formatCount(mostKills.kills),
          detail: mostKills.hero.name,
          icon: Icons.gps_fixed_rounded,
          accent: AppColors.lose,
          match: mostKills,
        ),
      if (mostDamage != null)
        _Record(
          label: 'Урон по героям',
          value: formatCompact(mostDamage.heroDamage!.toDouble()),
          detail: mostDamage.hero.name,
          icon: Icons.bolt_rounded,
          accent: AppColors.copper,
          match: mostDamage,
        ),
      if (mostNetWorth != null)
        _Record(
          label: 'Net worth',
          value: formatCount(mostNetWorth.netWorth!),
          detail: mostNetWorth.hero.name,
          icon: Icons.savings_rounded,
          accent: AppColors.win,
          match: mostNetWorth,
        ),
      if (mostLastHits != null)
        _Record(
          label: 'Ластхиты',
          value: formatCount(mostLastHits.lastHits!),
          detail: mostLastHits.hero.name,
          icon: Icons.agriculture_rounded,
          accent: AppColors.gold,
          match: mostLastHits,
        ),
      if (longest != null)
        _Record(
          label: 'Долгий матч',
          value: formatDuration(longest.durationSeconds),
          detail: longest.hero.name,
          icon: Icons.timer_rounded,
          accent: AppColors.text,
          match: longest,
        ),
      if (insights.longestWinStreak > 0)
        _Record(
          label: 'Серия побед',
          value: '${insights.longestWinStreak}',
          detail: 'матчей подряд',
          icon: Icons.local_fire_department_rounded,
          accent: AppColors.win,
          match: null,
        ),
    ];
  }
}

class _HeroCompareTile extends StatelessWidget {
  const _HeroCompareTile({
    required this.stat,
    required this.label,
    required this.color,
  });

  final PlayerHeroStat stat;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          HeroAvatar(hero: stat.hero, size: 36),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.hero.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${stat.matches} матчей · KDA '
                  '${stat.kda.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 8.5),
                ),
              ],
            ),
          ),
          Text(
            formatPercent(stat.winRate, digits: 0),
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Record {
  const _Record({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.match,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color accent;
  final MatchRecord? match;
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, this.onTap});

  final _Record record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: record.accent.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(record.icon, size: 12, color: record.accent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      record.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: record.accent,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                record.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                record.detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 8.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
