import 'dart:math' as math;

import 'package:flutter/material.dart' hide Hero;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/hero.dart';
import '../../../domain/entities/hero_ability_path.dart';
import '../../../domain/entities/hero_build.dart';
import '../../../domain/entities/hero_counter.dart';
import '../../../domain/entities/hero_detailed_stats.dart';
import '../../../domain/entities/hero_duration_stat.dart';
import '../../../domain/entities/hero_meta.dart';
import '../../../domain/entities/hero_synergy.dart';
import '../../../domain/entities/hero_trend.dart';
import '../../../domain/entities/item.dart';
import '../../../domain/entities/leaderboard_player.dart';
import '../../../domain/entities/popular_item.dart';
import '../../../domain/repositories/hero_repository.dart';
import '../../../domain/repositories/leaderboard_repository.dart';
import '../../../presentation/widgets/hero_avatar.dart';
import '../../../presentation/widgets/hero_trend_chart.dart';
import '../../../presentation/widgets/item_icon.dart';
import '../../../presentation/widgets/remote_image.dart';
import '../../../presentation/widgets/shimmer_skeleton.dart';
import '../../../presentation/widgets/surface_card.dart';
import '../../players/screens/player_profile_screen.dart';
import '../../secret/screens/labs_screen.dart';

/// Детальный экран героя: обзор, сборки и матчапы.
class HeroDetailScreen extends StatefulWidget {
  const HeroDetailScreen({super.key, required this.hero});

  final Hero hero;

  @override
  State<HeroDetailScreen> createState() => _HeroDetailScreenState();
}

class _HeroDetailScreenState extends State<HeroDetailScreen> {
  static const int _labsClicks = 10;
  static const double _bannerMaxHeight = 230;

  int _clickCount = 0;

  HeroDetailedStats? _stats;
  List<HeroCounter> _counters = const [];
  List<HeroSynergy> _synergies = const [];
  List<HeroBuild> _builds = const [];
  HeroTrend? _trend;
  HeroMeta? _meta;
  List<HeroMeta> _allMeta = const [];
  List<HeroDurationStat> _duration = const [];
  HeroAbilityPath? _abilityPath;
  Map<String, List<PopularItem>> _popularItems = const {};
  List<LeaderboardPlayer> _heroLeaders = const [];
  bool _showAllBuilds = false;
  bool _loading = true;

  /// Пасхалка открывается только у Inferno (id 1 в Deadlock API).
  bool get _isInferno {
    final name = widget.hero.name.toLowerCase();
    return name == 'inferno' || name == 'infernus' || widget.hero.id == 1;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<T?> _safely<T>(Future<T?> Function() task) async {
    try {
      return await task();
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    final repo = context.read<HeroRepository>();
    final heroId = widget.hero.id;

    // Запросы стартуют одновременно, падение одного не ломает остальные.
    final statsFuture = _safely(() => repo.getHeroDetailedStats(heroId));
    final countersFuture = _safely(() => repo.getCounters(heroId));
    final synergiesFuture = _safely(() => repo.getSynergies(heroId));
    final buildsFuture = _safely(() => repo.getBuilds(heroId));
    final trendFuture = _safely(() => repo.getHeroTrend(heroId));
    final metaFuture = _safely(() => repo.getMeta());
    final durationFuture = _safely(() => repo.getDurationStats(heroId));
    final abilityFuture = _safely(() => repo.getAbilityPath(heroId));
    final popularFuture = _safely(() => repo.getPopularItems(heroId));
    final leadersFuture = _safely(
      () => context.read<LeaderboardRepository>().getLeaderboard(),
    );

    final stats = await statsFuture;
    final counters = await countersFuture;
    final synergies = await synergiesFuture;
    final builds = await buildsFuture;
    final trend = await trendFuture;
    final allMeta = await metaFuture;
    final duration = await durationFuture;
    final abilityPath = await abilityFuture;
    final popularItems = await popularFuture;
    final leaders = await leadersFuture;

    if (!mounted) return;
    final metaList = allMeta ?? const <HeroMeta>[];
    setState(() {
      _stats = stats;
      _counters = counters ?? const [];
      _synergies = synergies ?? const [];
      _builds = builds ?? const [];
      _trend = trend;
      _allMeta = metaList;
      _meta = metaList.any((entry) => entry.hero.id == heroId)
          ? metaList.firstWhere((entry) => entry.hero.id == heroId)
          : null;
      _duration = duration ?? const [];
      _abilityPath = abilityPath;
      _popularItems = popularItems ?? const {};
      _heroLeaders = (leaders ?? const <LeaderboardPlayer>[])
          .where(
            (player) =>
                player.topHeroes.any((hero) => hero.id == widget.hero.id),
          )
          .take(5)
          .toList();
      _loading = false;
    });
  }

  Future<void> _onKdaTap() async {
    if (!_isInferno) return;
    _clickCount++;
    if (_clickCount >= _labsClicks) {
      _clickCount = 0;
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const LabsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.hero.name)),
        body: Column(
          children: [
            _banner(),
            _tabBar(),
            Expanded(
              child: TabBarView(
                children: [_overviewTab(), _buildsTab(), _matchupsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- banner

  Widget _banner() {
    final hero = widget.hero;
    final url = hero.bannerUrl.isNotEmpty
        ? hero.bannerUrl
        : 'https://assets.deadlock-api.com/v2/heroes/${hero.id}/icon';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = math.min(width * 9 / 16, _bannerMaxHeight);

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(22),
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Фоновый арт: заполняет баннер без искажений.
                RemoteImage(
                  url: url,
                  fit: BoxFit.cover,
                  useProxy: true,
                  proxyWidth: 1400,
                  fallback: DeadlockImageFallback(label: hero.name),
                ),
                // Градиент: прозрачный верх → фон приложения снизу,
                // чтобы имя героя читалось на любой картинке.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppColors.background],
                      stops: [0.3, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hero.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          height: 1.02,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 16,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      if (hero.role.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 2,
                              color: AppColors.copper,
                            ),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                hero.role.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: TabBar(
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: AppColors.copper.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.copper.withValues(alpha: 0.55)),
          ),
          dividerColor: Colors.transparent,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.muted,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          tabs: const [
            Tab(height: 36, text: 'ОБЗОР'),
            Tab(height: 36, text: 'СБОРКИ'),
            Tab(height: 36, text: 'МАТЧАПЫ'),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- tabs

  Widget _tabView(List<Widget> children) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: children,
      ),
    );
  }

  Widget _loadingBlock() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SkeletonTable(rows: 5, showAvatar: true, trailingBlocks: 2),
        SizedBox(height: 14),
        SkeletonBanner(height: 96),
      ],
    );
  }

  Widget _overviewTab() {
    if (_loading) {
      return _tabView([_loadingBlock()]);
    }

    return _tabView([
      _metaStrip(),
      if (_meta != null) const SizedBox(height: 10),
      _statGrid(),
      const SizedBox(height: 14),
      if (_trend != null && _trend!.hasData)
        HeroTrendChart(trend: _trend!)
      else
        _emptyCard('Нет данных по трендам'),
      if (_duration.isNotEmpty) ...[
        const SizedBox(height: 12),
        _durationCard(),
      ],
      if (_abilityPath != null && _abilityPath!.steps.isNotEmpty) ...[
        const SizedBox(height: 12),
        _abilityCard(),
      ],
      if (_heroLeaders.isNotEmpty) ...[
        const SizedBox(height: 12),
        _heroLeadersCard(),
      ],
    ]);
  }

  Widget _metaStrip() {
    final meta = _meta;
    if (meta == null) {
      return const SizedBox.shrink();
    }
    final rank = meta.winRateRank > 0 ? meta.winRateRank : null;
    final total = meta.totalHeroes > 0 ? meta.totalHeroes : _allMeta.length;
    final percentile = rank != null && total > 1
        ? ((1 - (rank - 1) / (total - 1)) * 100).round()
        : null;
    final delta = _trend?.weekDelta;
    final deltaText = delta == null
        ? '—'
        : '${delta >= 0 ? '+' : ''}${(delta * 100).toStringAsFixed(1)}';
    final metaDelta = meta.winRateDelta;
    final metaDeltaText =
        '${metaDelta >= 0 ? '+' : ''}${(metaDelta * 100).toStringAsFixed(1)}';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _metricPill('ТИР', meta.tier, AppColors.gold),
        _metricPill('ПИКРЕЙТ', formatPercent(meta.pickRate), AppColors.copper),
        if (rank != null)
          _metricPill('МЕСТО В МЕТЕ', '#$rank/$total', AppColors.text),
        if (percentile != null)
          _metricPill('ПЕРЦЕНТИЛЬ', '$percentile%', AppColors.win),
        _metricPill(
          'К СРЕДНЕМУ',
          metaDeltaText,
          metaDelta >= 0 ? AppColors.win : AppColors.lose,
        ),
        _metricPill(
          'ЗА 7 ДНЕЙ',
          deltaText,
          delta == null
              ? AppColors.muted
              : delta >= 0
              ? AppColors.win
              : AppColors.lose,
        ),
      ],
    );
  }

  Widget _metricPill(String label, String value, Color color) {
    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statGrid() {
    final stats = _stats;
    if (stats == null || !stats.hasData) {
      return _emptyCard('Нет данных по статистике');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        Widget tile(Widget child) => SizedBox(width: tileWidth, child: child);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            tile(
              _StatBox(
                label: 'Винрейт',
                icon: Icons.percent_rounded,
                value: formatPercent(stats.winRate),
                color: AppColors.winRateColor(stats.winRate),
                subtitle: '${formatCount(stats.matches)} матчей',
              ),
            ),
            if (_meta != null)
              tile(
                _StatBox(
                  label: 'Пикрейт',
                  icon: Icons.people_alt_rounded,
                  value: formatPercent(_meta!.pickRate),
                  color: AppColors.copper,
                  subtitle: 'в текущей мете',
                ),
              ),
            tile(
              GestureDetector(
                onTap: _onKdaTap,
                behavior: HitTestBehavior.opaque,
                child: _StatBox(
                  label: 'KDA',
                  icon: Icons.bolt_rounded,
                  value: stats.kdaRatio.toStringAsFixed(2),
                  color: AppColors.gold,
                  subtitle:
                      '${stats.kills.toStringAsFixed(1)} / '
                      '${stats.deaths.toStringAsFixed(1)} / '
                      '${stats.assists.toStringAsFixed(1)}',
                ),
              ),
            ),
            tile(
              _StatBox(
                label: 'Урон',
                icon: Icons.local_fire_department_rounded,
                value: _compact(stats.playerDamage),
                color: AppColors.copper,
                subtitle: 'по врагам за матч',
              ),
            ),
            tile(
              _StatBox(
                label: 'Получено',
                icon: Icons.shield_rounded,
                value: _compact(stats.playerDamageTaken),
                color: AppColors.lose,
                subtitle: 'урона за матч',
              ),
            ),
            tile(
              _StatBox(
                label: 'Net Worth',
                icon: Icons.savings_rounded,
                value: _compact(stats.netWorth),
                color: AppColors.text,
                subtitle: 'золото за матч',
              ),
            ),
            tile(
              _StatBox(
                label: 'Ластхиты',
                icon: Icons.agriculture_rounded,
                value: _compact(stats.lastHits),
                color: AppColors.gold,
                subtitle: 'добито крипов',
              ),
            ),
            tile(
              _StatBox(
                label: 'Денай',
                icon: Icons.block_rounded,
                value: _compact(stats.denies),
                color: AppColors.muted,
                subtitle: 'отказано крипов',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _durationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, size: 17, color: AppColors.copper),
              SizedBox(width: 7),
              Text(
                'ВИНРЕЙТ ПО ДЛИТЕЛЬНОСТИ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final stat in _duration) _DurationRow(stat: stat),
        ],
      ),
    );
  }

  Widget _abilityCard() {
    final path = _abilityPath!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_fix_high_rounded,
                size: 17,
                color: AppColors.gold,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'ПУТЬ ПРОКАЧКИ',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                'WR ${formatPercent(path.winRate)}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${formatCount(path.matches)} матчей · ${formatCount(path.players)} игроков',
            style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [for (final step in path.steps) _AbilityStep(step: step)],
          ),
        ],
      ),
    );
  }

  Widget _heroLeadersCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.copper.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 17,
                color: AppColors.copper,
              ),
              SizedBox(width: 7),
              Text(
                'ЛУЧШИЕ ИГРОКИ НА ГЕРОЕ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < _heroLeaders.length; index++) ...[
            if (index > 0)
              const Divider(height: 12, color: AppColors.surfaceLight),
            _HeroLeaderRow(player: _heroLeaders[index]),
          ],
        ],
      ),
    );
  }

  Widget _buildsTab() {
    if (_loading) {
      return _tabView([_loadingBlock()]);
    }
    if (_builds.isEmpty) {
      return _tabView([_emptyCard('Нет данных по сборкам')]);
    }

    final builds = _showAllBuilds
        ? _builds
        : _builds.take(3).toList(growable: false);
    return _tabView([
      _popularItemsCard(),
      if (_popularItems.values.any((list) => list.isNotEmpty))
        const SizedBox(height: 12),
      const _TabHint(
        icon: Icons.inventory_2_outlined,
        text: 'Сборки по винрейту. Под каждым предметом — время покупки.',
      ),
      const SizedBox(height: 12),
      for (var index = 0; index < builds.length; index++) ...[
        if (index > 0) const SizedBox(height: 12),
        _BuildCard(heroBuild: builds[index], rank: index + 1),
      ],
      if (_builds.length > 3) ...[
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _showAllBuilds = !_showAllBuilds),
            icon: Icon(
              _showAllBuilds
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
            ),
            label: Text(
              _showAllBuilds ? 'Свернуть' : 'Показать все (${_builds.length})',
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _popularItemsCard() {
    if (_popularItems.values.every((list) => list.isEmpty)) {
      return const SizedBox.shrink();
    }
    const stages = <String, String>{
      'early_game': 'Ранняя игра',
      'mid_game': 'Средняя игра',
      'late_game': 'Поздняя игра',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.shopping_bag_rounded,
                size: 17,
                color: AppColors.copper,
              ),
              SizedBox(width: 7),
              Text(
                'ПОПУЛЯРНЫЕ ПРЕДМЕТЫ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Pick% и винрейт по стадиям матча',
            style: TextStyle(color: AppColors.muted, fontSize: 9.5),
          ),
          const SizedBox(height: 10),
          for (final stage in stages.entries)
            _popularStage(stage.value, _popularItems[stage.key] ?? const []),
        ],
      ),
    );
  }

  Widget _popularStage(String label, List<PopularItem> items) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.copper,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [for (final item in items.take(8)) _popularTile(item)],
          ),
        ],
      ),
    );
  }

  Widget _popularTile(PopularItem item) {
    final winRate = item.winratePct / 100;
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ItemIcon(item: item.item, size: 34),
          const SizedBox(height: 4),
          Text(
            '${item.pickPct.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
          Text(
            formatPercent(winRate),
            style: TextStyle(
              color: AppColors.winRateColor(winRate),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchupsTab() {
    if (_loading) {
      return _tabView([_loadingBlock()]);
    }
    if (_counters.isEmpty && _synergies.isEmpty) {
      return _tabView([_emptyCard('Нет данных по матчапам')]);
    }
    if (_counters.isEmpty) {
      return _tabView([_SynergyCard(synergies: _synergies.take(5).toList())]);
    }

    final sorted = [..._counters]
      ..sort((a, b) => a.winRate.compareTo(b.winRate));
    final worst = sorted.take(5).toList(growable: false);
    final worstIds = worst.map((counter) => counter.enemy.id).toSet();
    final best = sorted.reversed
        .where((counter) => !worstIds.contains(counter.enemy.id))
        .take(5)
        .toList(growable: false);

    return _tabView([
      _MatchupCard(
        title: 'Худшие противники',
        subtitle: 'Низкий винрейт против этих героев',
        icon: Icons.trending_down_rounded,
        color: AppColors.lose,
        counters: worst,
      ),
      if (best.isNotEmpty) ...[
        const SizedBox(height: 12),
        _MatchupCard(
          title: 'Лучшие противники',
          subtitle: 'Высокий винрейт против этих героев',
          icon: Icons.trending_up_rounded,
          color: AppColors.win,
          counters: best,
        ),
      ],
      if (_synergies.isNotEmpty) ...[
        const SizedBox(height: 12),
        _SynergyCard(synergies: _synergies.take(5).toList()),
      ],
    ]);
  }

  Widget _emptyCard(String text) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_empty_rounded,
            size: 32,
            color: AppColors.muted,
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static String _compact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

// --------------------------------------------------------------- widgets

class _TabHint extends StatelessWidget {
  const _TabHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.copper),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
    this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (icon != null)
                Icon(icon, size: 12, color: color.withValues(alpha: 0.75)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 8.5,
                height: 1.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BuildCard extends StatelessWidget {
  const _BuildCard({required this.heroBuild, required this.rank});

  final HeroBuild heroBuild;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final early = <_BuildEntry>[];
    final mid = <_BuildEntry>[];
    final late = <_BuildEntry>[];

    final annotations = <int, String>{
      for (final category in heroBuild.categories)
        for (final entry in category.annotations.entries)
          entry.key: entry.value,
    };
    final entries =
        <_BuildEntry>[
          for (final item in heroBuild.items)
            _BuildEntry(
              item: item,
              seconds: heroBuild.buyTimes[item.id],
              annotation: annotations[item.id],
            ),
        ]..sort((a, b) {
          final left = a.seconds ?? double.infinity;
          final right = b.seconds ?? double.infinity;
          return left.compareTo(right);
        });

    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      final seconds = entry.seconds;
      if (seconds != null) {
        if (seconds <= 600) {
          early.add(entry);
        } else if (seconds <= 1200) {
          mid.add(entry);
        } else {
          late.add(entry);
        }
      } else {
        // Нет таймингов — делим список на три равные стадии.
        final third = entries.length / 3;
        if (index < third) {
          early.add(entry);
        } else if (index < third * 2) {
          mid.add(entry);
        } else {
          late.add(entry);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank == 1
              ? AppColors.gold.withValues(alpha: 0.55)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: rank == 1 ? AppColors.gold : AppColors.border,
                  ),
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    color: rank == 1 ? AppColors.gold : AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  heroBuild.name.isEmpty ? 'Сборка #$rank' : heroBuild.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatPercent(heroBuild.winRate),
                    style: TextStyle(
                      color: AppColors.winRateColor(heroBuild.winRate),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${formatCount(heroBuild.matches)} матчей',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 8.5,
                    ),
                  ),
                  if (heroBuild.players > 0)
                    Text(
                      '${formatCount(heroBuild.players)} игроков · бейдж ${heroBuild.avgBadge.toStringAsFixed(1)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 8,
                      ),
                    ),
                  if (heroBuild.authorAccountId > 0)
                    Text(
                      'автор #${heroBuild.authorAccountId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 8,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (heroBuild.items.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Предметы не указаны',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ] else ...[
            const SizedBox(height: 10),
            _BuildStage(label: 'Ранняя игра', hint: '0–10 мин', entries: early),
            _BuildStage(label: 'Средняя игра', hint: '10–20 мин', entries: mid),
            _BuildStage(label: 'Поздняя игра', hint: '20+ мин', entries: late),
          ],
        ],
      ),
    );
  }
}

class _BuildEntry {
  const _BuildEntry({
    required this.item,
    required this.seconds,
    this.annotation,
  });

  final Item item;
  final double? seconds;
  final String? annotation;
}

class _BuildStage extends StatelessWidget {
  const _BuildStage({
    required this.label,
    required this.hint,
    required this.entries,
  });

  final String label;
  final String hint;
  final List<_BuildEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.copper,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· $hint',
                style: const TextStyle(color: AppColors.muted, fontSize: 8.5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final entry in entries) _ItemChip(entry: entry)],
          ),
        ],
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({required this.entry});

  final _BuildEntry entry;

  @override
  Widget build(BuildContext context) {
    final seconds = entry.seconds;
    return Tooltip(
      message: entry.annotation == null
          ? entry.item.name
          : '${entry.item.name}\n\n${entry.annotation}',
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                ItemIcon(item: entry.item, size: 40),
                if (entry.annotation != null)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.copper),
                    ),
                    child: const Icon(
                      Icons.comment_rounded,
                      size: 8,
                      color: AppColors.copper,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              seconds == null ? '—' : formatDuration(seconds.round()),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: seconds == null ? AppColors.muted : AppColors.text,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchupCard extends StatelessWidget {
  const _MatchupCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.counters,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<HeroCounter> counters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < counters.length; index++) ...[
            if (index > 0)
              const Divider(height: 14, color: AppColors.surfaceLight),
            _MatchupRow(counter: counters[index]),
          ],
        ],
      ),
    );
  }
}

class _MatchupRow extends StatelessWidget {
  const _MatchupRow({required this.counter});

  final HeroCounter counter;

  @override
  Widget build(BuildContext context) {
    final winRate = counter.winRate;
    final color = AppColors.winRateColor(winRate);

    return Row(
      children: [
        HeroAvatar(hero: counter.enemy, size: 28),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      counter.enemy.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${formatCount(counter.matches)} матчей',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: winRate.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 46,
          child: Text(
            formatPercent(winRate),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SynergyCard extends StatelessWidget {
  const _SynergyCard({required this.synergies});

  final List<HeroSynergy> synergies;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.handshake_rounded, size: 17, color: AppColors.gold),
              SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ЛУЧШИЕ СОЮЗНИКИ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Наибольший винрейт в паре',
                      style: TextStyle(color: AppColors.muted, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < synergies.length; index++) ...[
            if (index > 0)
              const Divider(height: 14, color: AppColors.surfaceLight),
            _SynergyRow(synergy: synergies[index]),
          ],
        ],
      ),
    );
  }
}

class _SynergyRow extends StatelessWidget {
  const _SynergyRow({required this.synergy});

  final HeroSynergy synergy;

  @override
  Widget build(BuildContext context) {
    final winRate = synergy.winRate;
    final color = AppColors.winRateColor(winRate);

    return Row(
      children: [
        HeroAvatar(hero: synergy.ally, size: 28),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      synergy.ally.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${formatCount(synergy.matches)} матчей',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: winRate.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 46,
          child: Text(
            formatPercent(winRate),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroLeaderRow extends StatelessWidget {
  const _HeroLeaderRow({required this.player});

  final LeaderboardPlayer player;

  @override
  Widget build(BuildContext context) {
    final accountId = player.accountId;
    return InkWell(
      onTap: accountId == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlayerProfileScreen(
                    accountId: accountId,
                    personaName: player.name,
                  ),
                ),
              );
            },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '#${player.position}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (player.wins != null)
              Text(
                '${formatCount(player.wins!)} побед',
                style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
              ),
          ],
        ),
      ),
    );
  }
}

class _DurationRow extends StatelessWidget {
  const _DurationRow({required this.stat});

  final HeroDurationStat stat;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.winRateColor(stat.winRate);
    final normalized = ((stat.winRate - 0.35) / 0.3).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 62,
                child: Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: normalized,
                    minHeight: 5,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 44,
                child: Text(
                  formatPercent(stat.winRate),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const SizedBox(width: 70),
              Expanded(
                child: Text(
                  '${formatCount(stat.matches)} матчей',
                  style: const TextStyle(color: AppColors.muted, fontSize: 8.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AbilityStep extends StatelessWidget {
  const _AbilityStep({required this.step});

  final AbilityPathStep step;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: step.imageUrl.isEmpty
                      ? const Icon(
                          Icons.auto_fix_high_rounded,
                          color: AppColors.muted,
                        )
                      : RemoteImage(
                          url: step.imageUrl,
                          useProxy: true,
                          proxyWidth: 128,
                          fallback: DeadlockImageFallback(
                            label: step.abilityName,
                          ),
                        ),
                ),
              ),
              Positioned(
                left: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '${step.order}',
                    style: const TextStyle(
                      color: Color(0xFF1B1408),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            step.abilityName,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
          ),
          if (step.timeLabel.isNotEmpty)
            Text(
              step.timeLabel,
              style: const TextStyle(
                color: AppColors.copper,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}
