import 'package:flutter/material.dart' hide Hero;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/error_messages.dart';
import '../../domain/entities/hero.dart';
import '../../domain/entities/leaderboard_player.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../bloc/leaderboard/leaderboard_bloc.dart';
import '../bloc/leaderboard/leaderboard_event.dart';
import '../bloc/leaderboard/leaderboard_state.dart';
import '../widgets/error_view.dart';
import '../widgets/hero_avatar.dart';
import '../widgets/page_header.dart';
import '../widgets/rank_badge_chip.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/simple_table.dart';
import '../widgets/surface_card.dart';

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

  static const Color _gold = Color(0xFFD9A441);
  static const Color _silver = Color(0xFFB9C1C7);
  static const Color _bronze = Color(0xFFCB7B45);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<LeaderboardBloc, LeaderboardState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<LeaderboardBloc>().add(
                  const LeaderboardRefreshRequested(),
                );
                await Future<void>.delayed(const Duration(milliseconds: 700));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PageHeader(
                            eyebrow: 'Рейтинг',
                            title: 'ЛИДЕРЫ',
                            subtitle:
                                'Топ-100 ${state.region.label} · место, никнейм и ранг',
                            watermark: 'TOP',
                            trailing: _RegionSelector(selected: state.region),
                          ),
                          const SizedBox(height: 18),
                          _content(context, state),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
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
      return const ScreenSkeleton(
        showBanner: false,
        statTiles: 0,
        tableRows: 8,
        showAvatar: true,
      );
    }

    final top = state.players.take(3).toList(growable: false);
    final rest = state.players.skip(3).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Пьедестал',
          subtitle: 'Золото · серебро · бронза',
          trailing: _LoadingDot(
            loading: state.status == LeaderboardStatus.loading,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            final cards = [
              for (var index = 0; index < top.length; index++)
                _PodiumCard(
                  player: top[index],
                  medal: switch (index) {
                    0 => _gold,
                    1 => _silver,
                    _ => _bronze,
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
                    if (index > 0) const SizedBox(width: 12),
                    Expanded(child: cards[index]),
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  if (index > 0) const SizedBox(height: 10),
                  cards[index],
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Топ-100',
          subtitle: 'Показано ${state.players.length} игроков',
        ),
        const SizedBox(height: 10),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 680;
              return SimpleTable(
                columns: [
                  const TableColumn('Место', flex: 2),
                  const TableColumn('Игрок', flex: 6),
                  const TableColumn('Ранг', flex: 3),
                  if (wide) const TableColumn('Герои', flex: 3),
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
                        Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: RankBadgeChip(
                            badge: player.badge,
                            compact: true,
                          ),
                        ),
                        if (wide) _TopHeroes(heroes: player.topHeroes),
                      ],
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 16),
        const Text(
          'Ранг берётся из /players/rank и доступен только для игроков '
          'с однозначным account_id. «—» — ник встречается у нескольких аккаунтов.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 9.5, height: 1.45),
        ),
      ],
    );
  }
}

class _RegionSelector extends StatelessWidget {
  const _RegionSelector({required this.selected});

  final LeaderboardRegion selected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final region in LeaderboardRegion.values)
          GestureDetector(
            onTap: () => context.read<LeaderboardBloc>().add(
              LeaderboardRegionChanged(region),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: region == selected
                    ? AppColors.copper.withValues(alpha: 0.18)
                    : Colors.transparent,
                border: Border.all(
                  color: region == selected
                      ? AppColors.copper
                      : AppColors.copper.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                region.label,
                style: TextStyle(
                  color: region == selected ? AppColors.gold : AppColors.muted,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LoadingDot extends StatelessWidget {
  const _LoadingDot({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (!loading) {
      return const SizedBox.shrink();
    }
    return const SizedBox(
      width: 14,
      height: 14,
      child: CircularProgressIndicator(strokeWidth: 2),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
              Icon(icon, color: medal, size: 18),
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
          const SizedBox(height: 10),
          Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          _TopHeroes(heroes: player.topHeroes),
        ],
      ),
    );
  }
}

class _TopHeroes extends StatelessWidget {
  const _TopHeroes({required this.heroes});

  final List<Hero> heroes;

  @override
  Widget build(BuildContext context) {
    if (heroes.isEmpty) {
      return const Text(
        'Герои не указаны',
        style: TextStyle(color: AppColors.muted, fontSize: 9.5),
      );
    }

    final shown = heroes.take(3).toList(growable: false);
    return Row(
      children: [
        for (final hero in shown) ...[
          HeroAvatar(hero: hero, size: 22),
          const SizedBox(width: 4),
        ],
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            shown.map((hero) => hero.name).join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
          ),
        ),
      ],
    );
  }
}
