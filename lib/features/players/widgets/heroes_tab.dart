import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/player_hero_stat.dart';
import '../../../presentation/widgets/hero_avatar.dart';
import '../../../presentation/widgets/simple_table.dart';
import '../player_insights.dart';
import 'profile_common.dart';

enum HeroSort { matches, winRate, kda }

class ProfileHeroesTab extends StatefulWidget {
  const ProfileHeroesTab({super.key, required this.insights});

  final PlayerInsights insights;

  @override
  State<ProfileHeroesTab> createState() => _ProfileHeroesTabState();
}

class _ProfileHeroesTabState extends State<ProfileHeroesTab> {
  HeroSort _sort = HeroSort.matches;

  List<PlayerHeroStat> get _heroes {
    final heroes = [...widget.insights.heroes];
    switch (_sort) {
      case HeroSort.matches:
        heroes.sort((a, b) => b.matches.compareTo(a.matches));
        break;
      case HeroSort.winRate:
        heroes.sort((a, b) => b.winRate.compareTo(a.winRate));
        break;
      case HeroSort.kda:
        heroes.sort((a, b) => b.kda.compareTo(a.kda));
        break;
    }
    return heroes;
  }

  @override
  Widget build(BuildContext context) {
    final heroes = _heroes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: ProfileSectionTitle(
                icon: Icons.shield_rounded,
                title: 'Герои игрока',
                subtitle: '${heroes.length} героев в профиле',
              ),
            ),
            _SortChip(
              label: 'Матчи',
              selected: _sort == HeroSort.matches,
              onTap: () => setState(() => _sort = HeroSort.matches),
            ),
            const SizedBox(width: 4),
            _SortChip(
              label: 'Win%',
              selected: _sort == HeroSort.winRate,
              onTap: () => setState(() => _sort = HeroSort.winRate),
            ),
            const SizedBox(width: 4),
            _SortChip(
              label: 'KDA',
              selected: _sort == HeroSort.kda,
              onTap: () => setState(() => _sort = HeroSort.kda),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (heroes.isEmpty)
          const Text(
            'Нет данных по героям',
            style: TextStyle(color: AppColors.muted, fontSize: 11.5),
          )
        else
          SimpleTable(
            columns: const [
              TableColumn('Герой', flex: 5),
              TableColumn('Матчи', flex: 2, align: Alignment.centerRight),
              TableColumn('Win%', flex: 3, align: Alignment.centerRight),
              TableColumn('KDA', flex: 2, align: Alignment.centerRight),
            ],
            rows: [
              for (final hero in heroes)
                TableRowData(
                  onTap: () => _showHero(hero),
                  cells: [
                    _HeroCell(stat: hero),
                    Text(
                      formatCount(hero.matches),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                    _WinRateCell(stat: hero),
                    Text(
                      hero.kda.toStringAsFixed(2),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        const SizedBox(height: 8),
        const Text(
          'Нажми на героя, чтобы увидеть детали',
          style: TextStyle(color: AppColors.muted, fontSize: 9),
        ),
      ],
    );
  }

  void _showHero(PlayerHeroStat stat) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _HeroSheet(stat: stat),
    );
  }
}

class _HeroCell extends StatelessWidget {
  const _HeroCell({required this.stat});

  final PlayerHeroStat stat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeroAvatar(hero: stat.hero, size: 32),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stat.hero.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (stat.hero.role.isNotEmpty)
                Text(
                  stat.hero.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 8.5),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WinRateCell extends StatelessWidget {
  const _WinRateCell({required this.stat});

  final PlayerHeroStat stat;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.winRateColor(stat.winRate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatPercent(stat.winRate),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: 58,
          child: ProfileProgressBar(
            value: stat.winRate,
            color: color,
            height: 3,
          ),
        ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.ember.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? AppColors.ember.withValues(alpha: 0.7)
                  : AppColors.border,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: selected ? AppColors.ember : AppColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSheet extends StatelessWidget {
  const _HeroSheet({required this.stat});

  final PlayerHeroStat stat;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.winRateColor(stat.winRate);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              HeroAvatar(hero: stat.hero, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stat.hero.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (stat.hero.role.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        stat.hero.role,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                formatPercent(stat.winRate),
                style: TextStyle(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ProfileProgressBar(value: stat.winRate, color: color, height: 7),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ProfileStatCard(
                  label: 'Матчи',
                  value: formatCount(stat.matches),
                  accent: AppColors.text,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ProfileStatCard(
                  label: 'KDA',
                  value: stat.kda.toStringAsFixed(2),
                  accent: AppColors.gold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ProfileStatCard(
                  label: 'W / L',
                  value:
                      '${formatCount(stat.wins)} / '
                      '${formatCount(stat.matches - stat.wins)}',
                  accent: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProfileStatCard(
            label: 'Убийства / смерти / помощь',
            value: '${stat.kills} / ${stat.deaths} / ${stat.assists}',
            accent: AppColors.copper,
            footnote:
                '${(stat.kills / (stat.matches == 0 ? 1 : stat.matches)).toStringAsFixed(1)} '
                'убийств за матч',
          ),
        ],
      ),
    );
  }
}
