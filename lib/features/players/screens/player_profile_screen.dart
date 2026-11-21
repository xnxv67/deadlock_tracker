import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/match_record.dart';
import '../../../domain/entities/player_analysis.dart';
import '../../../domain/entities/player_badge.dart';
import '../../../domain/entities/player_profile.dart';
import '../../../domain/repositories/player_repository.dart';
import '../../../presentation/widgets/error_view.dart';
import '../../../presentation/widgets/rank_badge_chip.dart';
import '../../../presentation/widgets/remote_image.dart';
import '../../../presentation/widgets/shimmer_skeleton.dart';
import '../../../presentation/widgets/surface_card.dart';
import '../player_insights.dart';
import '../widgets/analysis_tab.dart';
import '../widgets/awards_tab.dart';
import '../widgets/heroes_tab.dart';
import '../widgets/laning_tab.dart';
import '../widgets/matches_tab.dart';
import '../widgets/overview_tab.dart';
import '../widgets/performance_tab.dart';
import '../widgets/profile_tab_bar.dart';
import 'match_detail_screen.dart';

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
  static const List<ProfileTabItem> _tabs = [
    ProfileTabItem(icon: Icons.dashboard_rounded, label: 'Обзор'),
    ProfileTabItem(icon: Icons.shield_rounded, label: 'Герои'),
    ProfileTabItem(icon: Icons.alt_route_rounded, label: 'Линии'),
    ProfileTabItem(icon: Icons.insights_rounded, label: 'Статистика'),
    ProfileTabItem(icon: Icons.query_stats_rounded, label: 'Анализ'),
    ProfileTabItem(icon: Icons.emoji_events_rounded, label: 'Награды'),
    ProfileTabItem(icon: Icons.history_rounded, label: 'Матчи'),
  ];

  PlayerProfile? _profile;
  PlayerInsights? _insights;
  PlayerAnalysis? _analysis;
  AppErrorType? _error;
  AppErrorType? _analysisError;
  bool _loading = true;
  bool _analysisLoading = false;
  int _tab = 0;

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
      final profile = await context.read<PlayerRepository>().getProfile(
        widget.accountId,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _insights = PlayerInsights(profile);
        _analysis = null;
        _loading = false;
      });
      if (_tab == 2 || _tab == 4) {
        _ensureAnalysis(force: true);
      }
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
    final insights = _insights;
    final badge = _profile?.badge ?? widget.badge;
    final bannerUrl = insights?.mostPlayedHero?.hero.bannerUrl ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.personaName.isEmpty ? 'Игрок' : widget.personaName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: _loading ? null : _load,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 19),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 30),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeader(
                      personaName: widget.personaName,
                      accountId: widget.accountId,
                      avatarUrl: widget.avatarUrl,
                      badge: badge,
                      bannerUrl: bannerUrl,
                      insights: insights,
                    ),
                    const SizedBox(height: 12),
                    ProfileTabBar(
                      items: _tabs,
                      selectedIndex: _tab,
                      onSelected: _selectTab,
                    ),
                    const SizedBox(height: 12),
                    _body(insights),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(PlayerInsights? insights) {
    if (_loading) {
      return _loadingBody();
    }
    if (_error != null) {
      return ErrorView(
        title: errorTitle(_error),
        text: errorText(_error),
        onRetry: _load,
      );
    }
    if (_profile == null || _profile!.isEmpty || insights == null) {
      return const SurfaceCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 26),
          child: Column(
            children: [
              Icon(Icons.person_off_rounded, size: 32, color: AppColors.copper),
              SizedBox(height: 10),
              Text(
                'Нет статистики по этому игроку',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final Widget content;
    switch (_tab) {
      case 1:
        content = ProfileHeroesTab(insights: insights);
        break;
      case 2:
        content = _analysisBody(
          insights,
          (analysis) => ProfileLaningTab(analysis: analysis),
        );
        break;
      case 3:
        content = ProfilePerformanceTab(
          insights: insights,
          onOpenMatch: _openMatch,
        );
        break;
      case 4:
        content = _analysisBody(
          insights,
          (analysis) =>
              ProfileAnalysisTab(analysis: analysis, insights: insights),
        );
        break;
      case 5:
        content = ProfileAwardsTab(insights: insights);
        break;
      case 6:
        content = ProfileMatchesTab(
          insights: insights,
          onOpenMatch: _openMatch,
        );
        break;
      default:
        content = ProfileOverviewTab(
          insights: insights,
          badge: _profile!.badge ?? widget.badge,
          onOpenMatch: _openMatch,
          onOpenMatchesTab: () => _selectTab(6),
        );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: ValueKey<int>(_tab), child: content),
    );
  }

  Widget _analysisBody(
    PlayerInsights insights,
    Widget Function(PlayerAnalysis analysis) builder,
  ) {
    final analysis = _analysis;
    if (_analysisLoading && analysis == null) {
      return const SurfaceCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: Column(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(height: 12),
              Text(
                'Загружаем аналитику Deadlock API…',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }
    if (_analysisError != null && analysis == null) {
      return ErrorView(
        title: errorTitle(_analysisError),
        text: errorText(_analysisError),
        onRetry: () => _ensureAnalysis(force: true),
      );
    }
    if (analysis == null) {
      return const SizedBox.shrink();
    }
    return builder(analysis);
  }

  void _selectTab(int index) {
    if (_tab == index) {
      return;
    }
    setState(() => _tab = index);
    if (index == 2 || index == 4) {
      _ensureAnalysis();
    }
  }

  Future<void> _ensureAnalysis({bool force = false}) async {
    if (_analysisLoading) {
      return;
    }
    if (!force && _analysis != null) {
      return;
    }
    setState(() {
      _analysisLoading = true;
      _analysisError = null;
    });
    try {
      final analysis = await context.read<PlayerRepository>().getAnalysis(
        widget.accountId,
      );
      if (!mounted) return;
      setState(() {
        _analysis = analysis;
        _analysisLoading = false;
      });
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _analysisError = error.type;
        _analysisLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _analysisError = AppErrorType.unknown;
        _analysisLoading = false;
      });
    }
  }

  Widget _loadingBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth < 520 ? 2 : 4;
        final width = (constraints.maxWidth - (count - 1) * 10) / count;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var index = 0; index < 4; index++)
                  SkeletonStatTile(width: width),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonTable(rows: 6, showAvatar: true, trailingBlocks: 3),
          ],
        );
      },
    );
  }

  void _openMatch(MatchRecord match) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MatchDetailScreen(match: match)),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.personaName,
    required this.accountId,
    required this.avatarUrl,
    required this.badge,
    required this.bannerUrl,
    required this.insights,
  });

  final String personaName;
  final int accountId;
  final String avatarUrl;
  final PlayerBadge? badge;
  final String bannerUrl;
  final PlayerInsights? insights;

  @override
  Widget build(BuildContext context) {
    final name = personaName.isEmpty ? 'Игрок #$accountId' : personaName;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.copper.withValues(alpha: 0.32)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B0F16), Color(0xFF171214), Color(0xFF1D1613)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (bannerUrl.isNotEmpty)
            Positioned(
              right: -30,
              top: -50,
              bottom: -50,
              width: 360,
              child: Opacity(
                opacity: 0.28,
                child: RemoteImage(
                  url: bannerUrl,
                  useProxy: true,
                  proxyWidth: 640,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF1B1214),
                    const Color(0xFF1B1214).withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 560;
                return Row(
                  children: [
                    _Avatar(avatarUrl: avatarUrl),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Text(
                                'account_id $accountId',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (insights != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    color: AppColors.muted,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${formatCount(insights!.totalMatches)} матчей',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              RankBadgeChip(badge: badge, compact: true),
                              if (insights != null)
                                _HeaderMetric(
                                  label: 'Winrate',
                                  value: formatPercent(insights!.winRate),
                                  color: AppColors.winRateColor(
                                    insights!.winRate,
                                  ),
                                ),
                              if (insights != null)
                                _HeaderMetric(
                                  label: 'KDA',
                                  value: insights!.kda.toStringAsFixed(2),
                                  color: AppColors.gold,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (wide && insights != null)
                      _HeaderScore(insights: insights!),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.copper.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: RemoteImage(
        url: avatarUrl,
        fallback: const DeadlockImageFallback(),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderScore extends StatelessWidget {
  const _HeaderScore({required this.insights});

  final PlayerInsights insights;

  @override
  Widget build(BuildContext context) {
    final score = insights.performanceScore.round();
    final color = score >= 62
        ? AppColors.win
        : score >= 45
        ? AppColors.gold
        : AppColors.lose;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ФОРМА',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$score',
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          Text(
            insights.performanceLabel,
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
