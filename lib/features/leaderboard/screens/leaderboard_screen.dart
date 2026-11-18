import 'package:flutter/material.dart' hide Hero;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/hero.dart';
import '../../../domain/entities/leaderboard_player.dart';
import '../../../domain/repositories/leaderboard_repository.dart';
import '../../../presentation/bloc/leaderboard/leaderboard_bloc.dart';
import '../../../presentation/bloc/leaderboard/leaderboard_event.dart';
import '../../../presentation/bloc/leaderboard/leaderboard_state.dart';
import '../../../presentation/widgets/error_view.dart';
import '../../../presentation/widgets/hero_avatar.dart';
import '../../../presentation/widgets/rank_badge_chip.dart';
import '../../../presentation/widgets/shimmer_skeleton.dart';
import '../../../presentation/widgets/simple_table.dart';
import '../../../presentation/widgets/surface_card.dart';
import '../../players/screens/player_profile_screen.dart';

/// Таблица лидеров топ-100: место, ник, ранг и победы.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LeaderboardBloc(context.read<LeaderboardRepository>())
            ..add(const LeaderboardRequested()),
      child: const _LeaderboardView(),
    );
  }
}

class _LeaderboardView extends StatelessWidget {
  const _LeaderboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaderboardBloc, LeaderboardState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<LeaderboardBloc>().add(
              const LeaderboardRefreshRequested(),
            );
            await Future<void>.delayed(const Duration(milliseconds: 600));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 26),
            children: [
              _RegionBar(selected: state.region),
              const SizedBox(height: 12),
              _content(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, LeaderboardState state) {
    if (!state.hasData) {
      if (state.status == LeaderboardStatus.failure) {
        return ErrorView(
          title: errorTitle(state.error),
          text: errorText(state.error),
          onRetry: () =>
              context.read<LeaderboardBloc>().add(const LeaderboardRequested()),
        );
      }
      if (state.status == LeaderboardStatus.success) {
        return const SurfaceCard(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 26),
            child: Text(
              'Нет данных таблицы лидеров',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        );
      }
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonTable(rows: 9, showAvatar: false, trailingBlocks: 2),
        ],
      );
    }

    final top = state.players.take(3).toList(growable: false);
    final rest = state.players.skip(3).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'Пьедестал',
          subtitle: 'Золото · серебро · бронза',
          trailing: state.status == LeaderboardStatus.loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        const SizedBox(height: 9),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            final cards = [
              for (var index = 0; index < top.length; index++)
                _PodiumCard(
                  player: top[index],
                  medal: switch (index) {
                    0 => const Color(0xFFD9A441),
                    1 => const Color(0xFFB9C1C7),
                    _ => const Color(0xFFCB7B45),
                  },
                  icon: switch (index) {
                    0 => Icons.workspace_premium_rounded,
                    1 => Icons.military_tech_rounded,
                    _ => Icons.emoji_events_rounded,
                  },
                ),
            ];

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    if (index > 0) const SizedBox(width: 10),
                    Expanded(child: cards[index]),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  if (index > 0) const SizedBox(height: 8),
                  cards[index],
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _SectionTitle(
          title: 'Топ-100',
          subtitle: 'Показано ${state.players.length} игроков',
        ),
        const SizedBox(height: 9),
        if (rest.isEmpty)
          const SurfaceCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'Нет данных',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          )
        else
          SimpleTable(
            columns: const [
              TableColumn('#', flex: 2),
              TableColumn('Игрок', flex: 5),
              TableColumn('Ранг', flex: 3),
              TableColumn(
                'Победы',
                flex: 2,
                align: Alignment.centerRight,
              ),
            ],
            rows: [
              for (final player in rest)
                TableRowData(
                  cells: [
                    Text(
                      '${player.position}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (player.topHeroes.isNotEmpty)
                          _MiniHeroes(heroes: player.topHeroes),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RankBadgeChip(
                        badge: player.badge,
                        compact: true,
                      ),
                    ),
                    Text(
                      player.wins == null
                          ? '—'
                          : formatCount(player.wins!),
                      style: TextStyle(
                        color: player.wins == null
                            ? AppColors.muted
                            : AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  onTap: player.accountId == null
                      ? null
                      : () => _openProfile(context, player),
                ),
            ],
          ),
        const SizedBox(height: 14),
        const Text(
          'Победы — суммарные по статистике героев. «—» — API не дал '
          'однозначный account_id или данные недоступны.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 9.5, height: 1.45),
        ),
      ],
    );
  }

  void _openProfile(BuildContext context, LeaderboardPlayer player) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerProfileScreen(
          accountId: player.accountId!,
          personaName: player.name,
          badge: player.badge,
        ),
      ),
    );
  }
}

class _RegionBar extends StatelessWidget {
  const _RegionBar({required this.selected});

  final LeaderboardRegion selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.public_rounded,
            size: 16,
            color: AppColors.copper,
          ),
          const SizedBox(width: 8),
          const Text(
            'РЕГИОН',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final region in LeaderboardRegion.values) ...[
                    if (region != LeaderboardRegion.values.first)
                      const SizedBox(width: 6),
                    _RegionChip(region: region, selected: region == selected),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({required this.region, required this.selected});

  final LeaderboardRegion region;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context
          .read<LeaderboardBloc>()
          .add(LeaderboardRegionChanged(region)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? AppColors.copper.withValues(alpha: 0.18)
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? AppColors.copper
                : AppColors.copper.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          region.label,
          style: TextStyle(
            color: selected ? AppColors.gold : AppColors.muted,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.player,
    required this.medal,
    required this.icon,
  });

  final LeaderboardPlayer player;
  final Color medal;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: player.accountId == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlayerProfileScreen(
                    accountId: player.accountId!,
                    personaName: player.name,
                    badge: player.badge,
                  ),
                ),
              ),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: medal.withValues(alpha: 0.5)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                medal.withValues(alpha: 0.14),
                AppColors.surface,
                AppColors.surface,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: medal, size: 17),
                  const SizedBox(width: 5),
                  Text(
                    '#${player.position}',
                    style: TextStyle(
                      color: medal,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  RankBadgeChip(badge: player.badge, compact: true),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    size: 12,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    player.wins == null
                        ? 'победы: —'
                        : 'побед: ${formatCount(player.wins!)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (player.topHeroes.isNotEmpty) ...[
                    const Spacer(),
                    _MiniHeroes(heroes: player.topHeroes),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniHeroes extends StatelessWidget {
  const _MiniHeroes({required this.heroes});

  final List<Hero> heroes;

  @override
  Widget build(BuildContext context) {
    final shown = heroes.take(3).toList(growable: false);
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final hero in shown) ...[
            HeroAvatar(hero: hero, size: 20),
            const SizedBox(width: 3),
          ],
        ],
      ),
    );
  }
}
