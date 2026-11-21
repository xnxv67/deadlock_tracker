import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/match_record.dart';
import '../../../domain/entities/player_hero_stat.dart';
import '../player_insights.dart';
import 'profile_common.dart';

enum _ResultFilter { all, wins, losses }

class ProfileMatchesTab extends StatefulWidget {
  const ProfileMatchesTab({
    super.key,
    required this.insights,
    required this.onOpenMatch,
  });

  final PlayerInsights insights;
  final void Function(MatchRecord match) onOpenMatch;

  @override
  State<ProfileMatchesTab> createState() => _ProfileMatchesTabState();
}

class _ProfileMatchesTabState extends State<ProfileMatchesTab> {
  _ResultFilter _filter = _ResultFilter.all;
  int? _heroId;
  int _visible = 15;

  List<MatchRecord> get _filtered {
    return widget.insights.matches.where((match) {
      if (_filter == _ResultFilter.wins && !match.isWin) {
        return false;
      }
      if (_filter == _ResultFilter.losses && match.isWin) {
        return false;
      }
      if (_heroId != null && match.hero.id != _heroId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _filtered;
    final shown = matches.take(_visible).toList();
    final wins = matches.where((match) => match.isWin).length;
    final winRate = matches.isEmpty ? 0.0 : wins / matches.length;
    final heroName = _heroId == null ? null : _heroName(_heroId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _filters(matches.length, wins, winRate),
        const SizedBox(height: 10),
        if (matches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Text(
              'Матчей по выбранным фильтрам нет',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
          )
        else ...[
          if (heroName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 2),
              child: Text(
                'Фильтр по герою: $heroName',
                style: const TextStyle(
                  color: AppColors.ember,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          for (var index = 0; index < shown.length; index++) ...[
            if (index > 0) const SizedBox(height: 7),
            MatchHistoryTile(
              match: shown[index],
              onTap: () => widget.onOpenMatch(shown[index]),
            ),
          ],
          if (matches.length > shown.length) ...[
            const SizedBox(height: 10),
            Center(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _visible += 15);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.surfaceLight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                child: Text('ПОКАЗАТЬ ЕЩЁ · ${matches.length - shown.length}'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _filters(int total, int wins, double winRate) {
    final heroes = widget.insights.heroes;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chips = Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _FilterChip(
                label: 'ВСЕ',
                count: widget.insights.matches.length,
                selected: _filter == _ResultFilter.all,
                onTap: () => _setFilter(_ResultFilter.all),
              ),
              _FilterChip(
                label: 'ПОБЕДЫ',
                count: widget.insights.matches.where((m) => m.isWin).length,
                selected: _filter == _ResultFilter.wins,
                color: AppColors.win,
                onTap: () => _setFilter(_ResultFilter.wins),
              ),
              _FilterChip(
                label: 'ПОРАЖЕНИЯ',
                count: widget.insights.matches.where((m) => !m.isWin).length,
                selected: _filter == _ResultFilter.losses,
                color: AppColors.lose,
                onTap: () => _setFilter(_ResultFilter.losses),
              ),
            ],
          );

          final summary = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${formatPercent(winRate, digits: 0)} · $wins/$total',
                style: TextStyle(
                  color: AppColors.winRateColor(winRate),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (heroes.isNotEmpty) ...[
                const SizedBox(width: 8),
                _HeroFilter(
                  heroes: heroes,
                  selectedId: _heroId,
                  onSelected: (id) {
                    setState(() {
                      _heroId = id;
                      _visible = 15;
                    });
                  },
                ),
              ],
            ],
          );

          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                chips,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: summary),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: chips),
              const SizedBox(width: 8),
              summary,
            ],
          );
        },
      ),
    );
  }

  void _setFilter(_ResultFilter filter) {
    setState(() {
      _filter = filter;
      _visible = 15;
    });
  }

  String? _heroName(int id) {
    for (final hero in widget.insights.heroes) {
      if (hero.hero.id == id) {
        return hero.hero.name;
      }
    }
    return null;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.color = AppColors.ember,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: selected ? color : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.black : AppColors.muted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.black.withValues(alpha: 0.16)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.black : AppColors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroFilter extends StatelessWidget {
  const _HeroFilter({
    required this.heroes,
    required this.selectedId,
    required this.onSelected,
  });

  final List<PlayerHeroStat> heroes;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = selectedId == null
        ? 'ВСЕ ГЕРОИ'
        : heroes
              .firstWhere(
                (hero) => hero.hero.id == selectedId,
                orElse: () => heroes.first,
              )
              .hero
              .name
              .toUpperCase();

    return PopupMenuButton<int>(
      tooltip: 'Фильтр по герою',
      color: AppColors.surfaceAlt,
      onSelected: (value) => onSelected(value <= 0 ? null : value),
      itemBuilder: (context) => [
        const PopupMenuItem<int>(value: 0, child: Text('Все герои')),
        for (final hero in heroes)
          PopupMenuItem<int>(value: hero.hero.id, child: Text(hero.hero.name)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded, size: 12, color: AppColors.muted),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 88),
              child: Text(
                selected,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const Icon(
              Icons.expand_more_rounded,
              size: 14,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
