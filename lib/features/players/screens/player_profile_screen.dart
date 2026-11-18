import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/match_record.dart';
import '../../../domain/entities/player_badge.dart';
import '../../../domain/entities/player_hero_stat.dart';
import '../../../domain/entities/player_profile.dart';
import '../../../domain/repositories/player_repository.dart';
import '../../../presentation/widgets/error_view.dart';
import '../../../presentation/widgets/hero_avatar.dart';
import '../../../presentation/widgets/rank_badge_chip.dart';
import '../../../presentation/widgets/remote_image.dart';
import '../../../presentation/widgets/shimmer_skeleton.dart';
import '../../../presentation/widgets/simple_table.dart';
import '../../../presentation/widgets/surface_card.dart';
import 'match_detail_screen.dart';

/// Профиль игрока: винрейт, KDA, ранг и любимые герои.
class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({
    super.key,
    required this.accountId,
    required this.personaName,
    this.avatarUrl = '',
    this.badge,
  });

  final int accountId;
  final String personaName;
  final String avatarUrl;
  final PlayerBadge? badge;

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  PlayerProfile? _profile;
  AppErrorType? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await context
          .read<PlayerRepository>()
          .getProfile(widget.accountId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.type;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppErrorType.unknown;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.personaName.isEmpty ? 'Игрок' : widget.personaName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          children: [
            _header(),
            const SizedBox(height: 14),
            if (_loading)
              const SkeletonTable(rows: 5, showAvatar: true, trailingBlocks: 2)
            else if (_error != null)
              ErrorView(
                title: errorTitle(_error),
                text: errorText(_error),
                onRetry: _load,
              )
            else if (_profile == null || _profile!.isEmpty)
              const SurfaceCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Нет статистики по этому игроку',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
              )
            else
              _content(_profile!),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final badge = _profile?.badge ?? widget.badge;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.copper.withValues(alpha: 0.32)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B0F16), Color(0xFF171214), Color(0xFF1D1613)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: RemoteImage(
              url: widget.avatarUrl,
              fallback: const DeadlockImageFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.personaName.isEmpty
                      ? 'Игрок #${widget.accountId}'
                      : widget.personaName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'account_id ${widget.accountId}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 7),
                RankBadgeChip(badge: badge, compact: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(PlayerProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 620;
            final tileWidth = wide
                ? (constraints.maxWidth - 30) / 4
                : (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: tileWidth,
                  child: _StatBlock(
                    label: 'Винрейт',
                    value: formatPercent(profile.winRate),
                    accent: AppColors.winRateColor(profile.winRate),
                    footnote: '${formatCount(profile.totalWins)} побед',
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _StatBlock(
                    label: 'Матчи',
                    value: formatCount(profile.totalMatches),
                    accent: AppColors.text,
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _StatBlock(
                    label: 'KDA',
                    value: profile.kda.toStringAsFixed(2),
                    accent: AppColors.gold,
                    footnote:
                        '${formatCount(profile.totalKills)} / '
                        '${formatCount(profile.totalDeaths)} / '
                        '${formatCount(profile.totalAssists)}',
                  ),
                ),
                SizedBox(
                  width: tileWidth,
                  child: _StatBlock(
                    label: 'Ранг',
                    value: profile.badge?.label ?? '—',
                    accent: AppColors.copper,
                    footnote: profile.badge == null
                        ? 'ранг не определён'
                        : '${profile.badge!.tierName} · '
                            '${profile.badge!.subrank}',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _SectionTitle(
          title: 'Любимые герои',
          subtitle: 'Топ по числу матчей',
          trailing: Text(
            '${profile.heroes.length}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (profile.heroes.isEmpty)
          const SurfaceCard(
            child: Text(
              'Нет данных по героям',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          )
        else
          SimpleTable(
            columns: const [
              TableColumn('Герой', flex: 5),
              TableColumn('Матчи', flex: 2, align: Alignment.centerRight),
              TableColumn('Win%', flex: 2, align: Alignment.centerRight),
              TableColumn('KDA', flex: 2, align: Alignment.centerRight),
            ],
            rows: [
              for (final stat in profile.heroes.take(8))
                TableRowData(
                  cells: [
                    _HeroCell(stat: stat),
                    Text(
                      formatCount(stat.matches),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                    Text(
                      formatPercent(stat.winRate),
                      style: TextStyle(
                        color: AppColors.winRateColor(stat.winRate),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      formatKdaRatio(stat.kills, stat.deaths, stat.assists),
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
        if (profile.heroes.length > 8) ...[
          const SizedBox(height: 8),
          Text(
            'Показано 8 из ${profile.heroes.length} героев',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
          ),
        ],
        const SizedBox(height: 20),
        _SectionTitle(
          title: 'История матчей',
          subtitle: 'Последние ${profile.matches.length} игр',
          trailing: Text(
            '${profile.matches.length}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (profile.matches.isEmpty)
          const SurfaceCard(
            child: Text(
              'Нет истории матчей',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < profile.matches.length; index++) ...[
                if (index > 0) const SizedBox(height: 8),
                _MatchCard(
                  match: profile.matches[index],
                  onTap: () => _openMatch(profile.matches[index]),
                ),
              ],
            ],
          ),
      ],
    );
  }

  void _openMatch(MatchRecord match) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchDetailScreen(match: match),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.onTap});

  final MatchRecord match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = match.isWin ? AppColors.win : AppColors.lose;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(11, 9, 8, 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.38)),
          ),
          child: Row(
            children: [
              HeroAvatar(hero: match.hero, size: 40),
              const SizedBox(width: 10),
              Expanded(
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
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: color.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            match.isWin ? 'ПОБЕДА' : 'ПОРАЖЕНИЕ',
                            style: TextStyle(
                              color: color,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDateFromSeconds(match.startTime)} · '
                      '${formatDuration(match.durationSeconds)}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    match.kda.toStringAsFixed(2),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    '${match.kills}/${match.deaths}/${match.assists}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
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
        HeroAvatar(hero: stat.hero, size: 26),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            stat.hero.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    required this.accent,
    this.footnote,
  });

  final String label;
  final String value;
  final Color accent;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: 3),
            Text(
              footnote!,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
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
