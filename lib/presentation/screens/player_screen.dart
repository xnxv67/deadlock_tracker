import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/colors.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/match_record.dart';
import '../../domain/entities/player_hero_stat.dart';
import '../../domain/entities/player_profile.dart';
import '../../domain/entities/steam_profile.dart';
import '../../domain/repositories/player_repository.dart';
import '../bloc/player/player_bloc.dart';
import '../bloc/player/player_event.dart';
import '../bloc/player/player_state.dart';
import '../widgets/error_view.dart';
import '../widgets/hero_avatar.dart';
import '../widgets/page_header.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/simple_table.dart';
import '../widgets/stat_tile.dart';
import '../widgets/surface_card.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerBloc(context.read<PlayerRepository>()),
      child: const _PlayerView(),
    );
  }
}

class _PlayerView extends StatefulWidget {
  const _PlayerView();

  @override
  State<_PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<_PlayerView> {
  final TextEditingController _input = TextEditingController();
  final TextEditingController _nameInput = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    _nameInput.dispose();
    super.dispose();
  }

  void _search() {
    final raw = _input.text.trim();
    final accountId = int.tryParse(raw);
    if (accountId == null || accountId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введи числовой Steam ID (account_id)')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<PlayerBloc>().add(PlayerSearchRequested(accountId));
  }

  void _searchByName() {
    final query = _nameInput.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введи ник Steam для поиска')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<PlayerBloc>().add(PlayerSteamSearchRequested(query));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<PlayerBloc, PlayerState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                if (state.accountId == null) {
                  return;
                }
                context.read<PlayerBloc>().add(const PlayerRefreshRequested());
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
                          const PageHeader(
                            eyebrow: 'Профиль',
                            title: 'ИГРОК',
                            subtitle: 'Steam ID · статистика героев · последние 10 матчей',
                            watermark: 'P',
                          ),
                          const SizedBox(height: 14),
                          _SearchRow(
                            controller: _input,
                            onSearch: _search,
                            enabled: state.status != PlayerStatus.loading,
                          ),
                          const SizedBox(height: 10),
                          _SteamSearchRow(
                            controller: _nameInput,
                            onSearch: _searchByName,
                            busy: state.steamSearching,
                          ),
                          if (state.steamResults.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _SteamResults(
                              results: state.steamResults,
                              onPick: (id) {
                                context.read<PlayerBloc>().add(
                                  PlayerSteamResultsCleared(),
                                );
                                context.read<PlayerBloc>().add(
                                  PlayerSearchRequested(id),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 18),
                          _content(state),
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

  Widget _content(PlayerState state) {
    if (state.status == PlayerStatus.loading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SkeletonStatTile(width: 170),
              SkeletonStatTile(width: 170),
              SkeletonStatTile(width: 170),
              SkeletonStatTile(width: 170),
            ],
          ),
          SizedBox(height: 20),
          SkeletonTable(rows: 6, showAvatar: true, trailingBlocks: 3),
        ],
      );
    }

    if (state.status == PlayerStatus.failure) {
      return ErrorView(
        title: errorTitle(state.error),
        text: errorText(state.error),
        onRetry: () =>
            context.read<PlayerBloc>().add(const PlayerRefreshRequested()),
      );
    }

    final profile = state.profile;
    if (profile == null) {
      return const _HintCard();
    }

    if (profile.isEmpty) {
      return SurfaceCard(
        child: Column(
          children: [
            const Icon(
              Icons.person_off_rounded,
              color: AppColors.copper,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              'Игрок #${profile.accountId} не найден',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Проверь account_id: это число из Steam-профиля, '
              'а не никнейм.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Summary(profile: profile),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Герои игрока',
          subtitle: 'Сортировка по числу матчей',
          trailing: Text(
            '${profile.heroes.length}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (profile.heroes.isEmpty)
          const _EmptyCard(text: 'Нет данных по героям')
        else
          LayoutBuilder(
            builder: (context, constraints) {
              return SimpleTable(
                columns: const [
                  TableColumn('Герой', flex: 6),
                  TableColumn('Матчи', flex: 2, align: Alignment.centerRight),
                  TableColumn('Win%', flex: 2, align: Alignment.centerRight),
                  TableColumn('KDA', flex: 2, align: Alignment.centerRight),
                ],
                rows: [
                  for (final hero in profile.heroes)
                    TableRowData(
                      cells: [
                        _PlayerHeroCell(stat: hero),
                        Text(
                          formatCount(hero.matches),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          formatPercent(hero.winRate),
                          style: TextStyle(
                            color: AppColors.winRateColor(hero.winRate),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _KdaCell(stat: hero),
                      ],
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 24),
        SectionHeader(
          title: 'Последние матчи',
          subtitle: '10 последних игр · результат и KDA',
          trailing: Text(
            '${profile.matches.length}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (profile.matches.isEmpty)
          const _EmptyCard(text: 'История матчей недоступна')
        else
          _MatchesList(matches: profile.matches),
        const SizedBox(height: 20),
        const Text(
          'Данные: api.deadlock-api.com · /players/hero-stats · '
          '/players/{account_id}/match-history',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 9.5, height: 1.4),
        ),
      ],
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.onSearch,
    required this.enabled,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(20),
              ],
              style: const TextStyle(fontSize: 13.5),
              decoration: const InputDecoration(
                hintText: 'Steam ID (account_id)',
                isDense: true,
                prefixIcon: Icon(
                  Icons.badge_outlined,
                  size: 18,
                  color: AppColors.muted,
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 40),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 46,
          child: FilledButton.icon(
            onPressed: enabled ? onSearch : null,
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Найти'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.copper,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppColors.surfaceLight,
              disabledForegroundColor: AppColors.muted,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final badge = profile.badge;
    final badgeColor = badge == null
        ? AppColors.muted
        : Color(parseHexColor(badge.colorHex) ?? 0xFFD9A441);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        final tileWidth = wide
            ? (constraints.maxWidth - 30) / 4
            : (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: tileWidth,
              child: StatTile(
                label: 'Account ID',
                value: '${profile.accountId}',
                accent: AppColors.gold,
                footnote: badge == null
                    ? 'ранг не определён'
                    : 'бейдж ${badge.badge}',
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: StatTile(
                label: 'Матчей',
                value: formatCount(profile.totalMatches),
                accent: AppColors.text,
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: StatTile(
                label: 'Средний Win%',
                value: formatPercent(profile.winRate),
                accent: AppColors.winRateColor(profile.winRate),
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: StatTile(
                label: 'Ранг',
                value: badge?.label ?? '—',
                accent: badgeColor,
                footnote: badge == null
                    ? 'один аккаунт — один ранг'
                    : '${badge.tierName} · ${badge.subrank}',
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: StatTile(
                label: 'KDA',
                value: profile.kda.toStringAsFixed(2),
                accent: AppColors.copper,
                footnote:
                    '${formatCount(profile.totalKills)} / '
                    '${formatCount(profile.totalDeaths)} / '
                    '${formatCount(profile.totalAssists)}',
              ),
            ),
            if (profile.mostPlayedHero != null)
              SizedBox(
                width: tileWidth,
                child: StatTile(
                  label: 'Любимый герой',
                  value: profile.mostPlayedHero!.hero.name,
                  accent: AppColors.gold,
                  footnote:
                      '${formatCount(profile.mostPlayedHero!.matches)} матчей · '
                      '${formatPercent(profile.mostPlayedHero!.winRate)}',
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlayerHeroCell extends StatelessWidget {
  const _PlayerHeroCell({required this.stat});

  final PlayerHeroStat stat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeroAvatar(hero: stat.hero, size: 30),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            stat.hero.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _KdaCell extends StatelessWidget {
  const _KdaCell({required this.stat});

  final PlayerHeroStat stat;

  @override
  Widget build(BuildContext context) {
    final good = stat.kda >= 3;
    final color = good ? AppColors.gold : AppColors.text;

    return Tooltip(
      message: '${stat.kills} / ${stat.deaths} / ${stat.assists}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatKdaRatio(stat.kills, stat.deaths, stat.assists),
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${stat.kills}/${stat.deaths}/${stat.assists}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchesList extends StatelessWidget {
  const _MatchesList({required this.matches});

  final List<MatchRecord> matches;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < matches.length; index++)
            _MatchTile(
              match: matches[index],
              last: index == matches.length - 1,
            ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match, required this.last});

  final MatchRecord match;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final resultColor = match.isWin ? AppColors.win : AppColors.lose;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: Row(
        children: [
          HeroAvatar(hero: match.hero, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  match.hero.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatMonthDayFromSeconds(match.startTime)} · '
                  '${formatKda(match.kills, match.deaths, match.assists)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: resultColor.withValues(alpha: 0.45)),
            ),
            child: Text(
              match.isWin ? 'WIN' : 'LOSS',
              style: TextStyle(
                color: resultColor,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 12,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 3),
                Text(
                  formatDuration(match.durationSeconds),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          const Icon(
            Icons.person_search_rounded,
            color: AppColors.copper,
            size: 38,
          ),
          const SizedBox(height: 12),
          const Text(
            'Найди игрока',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Введи Steam ID (account_id) — покажем статистику героев, '
            'винрейт, KDA и последние 10 матчей.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'account_id — только цифры',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
    );
  }
}

class _SteamSearchRow extends StatelessWidget {
  const _SteamSearchRow({
    required this.controller,
    required this.onSearch,
    required this.busy,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              style: const TextStyle(fontSize: 13.5),
              decoration: const InputDecoration(
                hintText: 'Поиск по нику Steam',
                isDense: true,
                prefixIcon: Icon(
                  Icons.person_search_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 40),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 46,
          child: OutlinedButton.icon(
            onPressed: busy ? null : onSearch,
            icon: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded, size: 18),
            label: const Text('Ник'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: const BorderSide(color: AppColors.surfaceLight),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SteamResults extends StatelessWidget {
  const _SteamResults({required this.results, required this.onPick});

  final List<SteamProfile> results;
  final void Function(int accountId) onPick;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (final r in results.take(10))
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceLight,
                  backgroundImage: r.avatarMedium.isNotEmpty
                      ? NetworkImage(r.avatarMedium)
                      : null,
                  child: r.avatarMedium.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 16,
                          color: AppColors.muted,
                        )
                      : null,
                ),
                title: Text(
                  r.personaName.isEmpty ? 'Без имени' : r.personaName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'account_id: ${r.accountId}${r.countryCode.isEmpty ? '' : ' · ${r.countryCode}'}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.muted,
                ),
                onTap: () => onPick(r.accountId),
              ),
          ],
        ),
      ),
    );
  }
}
