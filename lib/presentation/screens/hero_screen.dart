import 'package:flutter/material.dart' hide Hero;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/hero.dart';
import '../../domain/entities/build_category.dart';
import '../../domain/entities/hero_ability_path.dart';
import '../../domain/entities/hero_build.dart';
import '../../domain/entities/hero_counter.dart';
import '../../domain/entities/hero_detailed_stats.dart';
import '../../domain/entities/hero_duration_stat.dart';
import '../../domain/entities/hero_meta.dart';
import '../../domain/entities/hero_synergy.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/popular_item.dart';
import '../../domain/repositories/hero_repository.dart';
import '../bloc/hero/hero_bloc.dart';
import '../bloc/hero/hero_event.dart';
import '../bloc/hero/hero_state.dart';
import '../bloc/hero_builds/hero_builds_bloc.dart';
import '../bloc/hero_builds/hero_builds_event.dart';
import '../bloc/hero_builds/hero_builds_sort.dart';
import '../bloc/hero_builds/hero_builds_state.dart';
import '../widgets/ability_priority_chart.dart';
import '../widgets/error_view.dart';
import '../widgets/hero_avatar.dart';
import '../widgets/hero_trend_chart.dart';
import '../widgets/item_icon.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/simple_table.dart';
import '../widgets/surface_card.dart';

class HeroScreen extends StatelessWidget {
  const HeroScreen({super.key, required this.meta});

  final HeroMeta meta;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              HeroBloc(context.read<HeroRepository>())
                ..add(HeroRequested(meta)),
        ),
        BlocProvider(
          create: (context) =>
              HeroBuildsBloc(context.read<HeroRepository>())
                ..add(HeroBuildsRequested(meta.hero.id)),
        ),
      ],
      child: DefaultTabController(length: 4, child: _HeroView(meta: meta)),
    );
  }
}

class _HeroView extends StatelessWidget {
  const _HeroView({required this.meta});

  final HeroMeta meta;

  void _refresh(BuildContext context) {
    context.read<HeroBloc>().add(const HeroRefreshRequested());
    context.read<HeroBuildsBloc>().add(const HeroBuildsRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            HeroAvatar(hero: meta.hero, size: 27, borderRadius: 7),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                meta.hero.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => _refresh(context),
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
        bottom: const TabBar(
          indicatorColor: AppColors.copper,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.muted,
          dividerColor: AppColors.surfaceLight,
          labelStyle: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
          tabs: [
            Tab(text: 'ОБЗОР'),
            Tab(text: 'БИЛДЫ'),
            Tab(text: 'СПОСОБНОСТИ'),
            Tab(text: 'МАТЧАПЫ'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _OverviewTab(meta: meta),
          _BuildsTab(heroId: meta.hero.id),
          _AbilitiesTab(heroId: meta.hero.id),
          _MatchupsTab(meta: meta),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.meta});

  final HeroMeta meta;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HeroBloc, HeroState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<HeroBloc>().add(const HeroRefreshRequested());
            await Future<void>.delayed(const Duration(milliseconds: 700));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroBanner(
                        meta: state.meta ?? meta,
                        detailed: state.detailed,
                      ),
                      const SizedBox(height: 20),
                      _overviewBody(context, state),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _overviewBody(BuildContext context, HeroState state) {
    if (!state.hasData) {
      if (state.status == HeroStatus.failure) {
        return ErrorView(
          title: errorTitle(state.error),
          text: errorText(state.error),
          onRetry: () =>
              context.read<HeroBloc>().add(const HeroRefreshRequested()),
        );
      }
      if (state.status == HeroStatus.loading) {
        return const SkeletonTable(rows: 6, showAvatar: true);
      }
      return const SurfaceCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 26),
          child: Text(
            'Нет данных по этому герою',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.trend != null && state.trend!.hasData) ...[
          HeroTrendChart(trend: state.trend!),
          const SizedBox(height: 20),
        ],
        _DurationChart(durations: state.durations),
        const SizedBox(height: 22),
        const _ApiNote(),
      ],
    );
  }
}

class _MatchupsTab extends StatelessWidget {
  const _MatchupsTab({required this.meta});

  final HeroMeta meta;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HeroBloc, HeroState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<HeroBloc>().add(const HeroRefreshRequested());
            await Future<void>.delayed(const Duration(milliseconds: 700));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: _matchupsBody(context, state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _matchupsBody(BuildContext context, HeroState state) {
    if (!state.hasData) {
      if (state.status == HeroStatus.failure) {
        return ErrorView(
          title: errorTitle(state.error),
          text: errorText(state.error),
          onRetry: () =>
              context.read<HeroBloc>().add(const HeroRefreshRequested()),
        );
      }
      if (state.status == HeroStatus.loading) {
        return const SkeletonTable(rows: 6, showAvatar: true);
      }
      return const _EmptyCard(text: 'Нет данных по матчапам');
    }

    final counterTable = _CounterSection(
      counters: state.counters,
      heroName: meta.hero.name,
    );
    final synergyTable = _SynergySection(
      synergies: state.synergies,
      heroName: meta.hero.name,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 960) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: counterTable),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: synergyTable),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                counterTable,
                const SizedBox(height: 20),
                synergyTable,
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        const _ApiNote(),
      ],
    );
  }
}

class _DurationChart extends StatelessWidget {
  const _DurationChart({required this.durations});

  final List<HeroDurationStat> durations;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Винрейт по длительности',
            subtitle: 'Как герой играет в коротких и долгих матчах',
          ),
          const SizedBox(height: 16),
          if (durations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Нет данных по длительности',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 11.5),
              ),
            )
          else
            for (var index = 0; index < durations.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              _DurationBar(stat: durations[index]),
            ],
          const SizedBox(height: 10),
          const Row(
            children: [
              _LegendDot(color: AppColors.win, label: '≥ 50%'),
              SizedBox(width: 14),
              _LegendDot(color: AppColors.lose, label: '< 50%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DurationBar extends StatelessWidget {
  const _DurationBar({required this.stat});

  final HeroDurationStat stat;

  @override
  Widget build(BuildContext context) {
    final hasData = stat.matches > 0;
    final color = AppColors.winRateColor(stat.winRate);
    final factor = hasData ? stat.winRate.clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: factor,
                    child: Container(
                      height: 9,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                hasData ? '${formatCount(stat.matches)} матчей' : 'Нет данных',
                style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          child: Text(
            hasData ? formatPercent(stat.winRate) : '—',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: hasData ? color : AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
        ),
      ],
    );
  }
}

class _CounterSection extends StatelessWidget {
  const _CounterSection({required this.counters, required this.heroName});

  final List<HeroCounter> counters;
  final String heroName;

  static const int _minSamples = 100;

  @override
  Widget build(BuildContext context) {
    // Отсекаем шум: пары с маленькой выборкой дают нестабильный винрейт.
    var filtered = counters.where((c) => c.matches >= _minSamples).toList();
    if (filtered.isEmpty) {
      filtered = [...counters];
    }
    final worst = filtered
      ..sort((first, second) => first.winRate.compareTo(second.winRate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Худшие матчапы',
          subtitle: 'Против кого $heroName играет хуже всего · мин. $_minSamples матчей',
          trailing: Text(
            '${worst.length.clamp(0, 10)}',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (worst.isEmpty)
          const _EmptyCard(text: 'Нет данных по контр-пикам')
        else
          SimpleTable(
            columns: const [
              TableColumn('Герой', flex: 5),
              TableColumn('Матчи', flex: 2, align: Alignment.centerRight),
              TableColumn('Win%', flex: 2, align: Alignment.centerRight),
              TableColumn('Δ', flex: 2, align: Alignment.centerRight),
            ],
            rows: [
              for (final counter in worst.take(10))
                TableRowData(
                  cells: [
                    _HeroNameCell(hero: counter.enemy, subtitle: 'противник'),
                    Text(
                      formatCount(counter.matches),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                    Text(
                      formatPercent(counter.winRate),
                      style: TextStyle(
                        color: AppColors.winRateColor(counter.winRate),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _DeltaText(winRate: counter.winRate),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}

class _SynergySection extends StatelessWidget {
  const _SynergySection({required this.synergies, required this.heroName});

  final List<HeroSynergy> synergies;
  final String heroName;

  static const int _minSamples = 50;

  @override
  Widget build(BuildContext context) {
    var filtered = synergies.where((s) => s.matches >= _minSamples).toList();
    if (filtered.isEmpty) {
      filtered = [...synergies];
    }
    final best = filtered
      ..sort((first, second) {
        final byWinRate = second.winRate.compareTo(first.winRate);
        if (byWinRate != 0) {
          return byWinRate;
        }
        return second.matches.compareTo(first.matches);
      });
    final shown = best.take(5).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Лучшие синергии',
          subtitle: 'Союзники с максимальным винрейтом · мин. $_minSamples матчей',
        ),
        const SizedBox(height: 10),
        if (shown.isEmpty)
          const _EmptyCard(text: 'Нет данных по синергиям')
        else
          SimpleTable(
            columns: const [
              TableColumn('Союзник', flex: 5),
              TableColumn('Матчи', flex: 2, align: Alignment.centerRight),
              TableColumn('Win%', flex: 2, align: Alignment.centerRight),
              TableColumn('Δ', flex: 2, align: Alignment.centerRight),
            ],
            rows: [
              for (final synergy in shown)
                TableRowData(
                  cells: [
                    _HeroNameCell(hero: synergy.ally, subtitle: 'союзник'),
                    Text(
                      formatCount(synergy.matches),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                    Text(
                      formatPercent(synergy.winRate),
                      style: TextStyle(
                        color: AppColors.winRateColor(synergy.winRate),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    _DeltaText(winRate: synergy.winRate),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}

class _DeltaText extends StatelessWidget {
  const _DeltaText({required this.winRate});

  final double winRate;

  @override
  Widget build(BuildContext context) {
    final delta = (winRate - 0.5) * 100;
    final positive = delta >= 0;
    return Text(
      '${positive ? '+' : ''}${delta.toStringAsFixed(1)}%',
      textAlign: TextAlign.right,
      style: TextStyle(
        color: positive ? AppColors.win : AppColors.lose,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _HeroNameCell extends StatelessWidget {
  const _HeroNameCell({required this.hero, required this.subtitle});

  final Hero hero;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeroAvatar(hero: hero, size: 28),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hero.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BuildsTab extends StatelessWidget {
  const _BuildsTab({required this.heroId});

  final int heroId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HeroBuildsBloc, HeroBuildsState>(
      builder: (context, state) {
        if (state.status == HeroBuildsStatus.loading && !state.hasData) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 28),
            child: SkeletonTable(rows: 5, showAvatar: false, trailingBlocks: 0),
          );
        }

        if (state.status == HeroBuildsStatus.failure && !state.hasData) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: ErrorView(
                    title: errorTitle(state.error),
                    text: errorText(state.error),
                    onRetry: () => context.read<HeroBuildsBloc>().add(
                      const HeroBuildsRefreshRequested(),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<HeroBuildsBloc>().add(
              const HeroBuildsRefreshRequested(),
            );
            await Future<void>.delayed(const Duration(milliseconds: 700));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader(
                        title: 'Сборки героя',
                        subtitle: 'Сортировка по винрейту · минимум 50 матчей',
                        trailing: Text(
                          '${state.builds.length}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _PopularItemsSection(),
                      const SizedBox(height: 20),
                      SectionHeader(
                        title: 'Сборки сообщества',
                        subtitle: 'Минимум 50 матчей · переключай сортировку',
                        trailing: _BuildsSortToggle(current: state.sort),
                      ),
                      const SizedBox(height: 10),
                      if (!state.hasData)
                        const _EmptyCard(
                          text: 'Пока нет сборок с достаточным числом матчей',
                        )
                      else
                        for (
                          var index = 0;
                          index < state.builds.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(height: 10),
                          _BuildCard(
                            heroBuild: state.builds[index],
                            index: index,
                          ),
                        ],
                      const SizedBox(height: 18),
                      const Text(
                        'Данные: /analytics/hero-build-stats/{hero_id} · '
                        '/builds/{hero_id}/{build_id}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 9.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PopularItemsSection extends StatelessWidget {
  const _PopularItemsSection();

  static const Map<String, String> _stageLabels = {
    'early_game': 'Ранняя игра',
    'mid_game': 'Средняя игра',
    'late_game': 'Поздняя игра',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HeroBloc, HeroState>(
      builder: (context, state) {
        final stages = state.popularItems;
        final hasAny = stages.values.any((list) => list.isNotEmpty);
        if (!hasAny) {
          return const SizedBox.shrink();
        }

        final blocks = <Widget>[];
        for (final entry in _stageLabels.entries) {
          final items = stages[entry.key] ?? const [];
          if (items.isEmpty) {
            continue;
          }
          blocks.add(_StageItemsBlock(label: entry.value, items: items));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(
              title: 'Популярные предметы',
              subtitle: 'Что покупают по стадиям игры · pick% и винрейт',
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < blocks.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              blocks[i],
            ],
          ],
        );
      },
    );
  }
}

class _StageItemsBlock extends StatelessWidget {
  const _StageItemsBlock({required this.label, required this.items});

  final String label;
  final List<PopularItem> items;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.copper,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in items.take(8)) _PopularItemTile(item: item),
            ],
          ),
        ],
      ),
    );
  }
}

class _PopularItemTile extends StatelessWidget {
  const _PopularItemTile({required this.item});

  final PopularItem item;

  @override
  Widget build(BuildContext context) {
    final wr = item.winratePct / 100;
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ItemIcon(item: item.item, size: 34),
          const SizedBox(height: 4),
          Text(
            '${item.pickPct.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            formatPercent(wr),
            style: TextStyle(
              color: AppColors.winRateColor(wr),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildsSortToggle extends StatelessWidget {
  const _BuildsSortToggle({required this.current});

  final HeroBuildsSort current;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final sort in HeroBuildsSort.values)
            GestureDetector(
              onTap: () => context.read<HeroBuildsBloc>().add(
                HeroBuildsSortChanged(sort),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: sort == current
                      ? AppColors.copper.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  sort.label,
                  style: TextStyle(
                    color: sort == current
                        ? AppColors.gold
                        : AppColors.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BuildCard extends StatelessWidget {
  const _BuildCard({required this.heroBuild, required this.index});

  final HeroBuild heroBuild;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.winRateColor(heroBuild.winRate);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: index == 0
                  ? AppColors.gold.withValues(alpha: 0.16)
                  : AppColors.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: index == 0
                    ? AppColors.gold.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: index == 0 ? AppColors.gold : AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  heroBuild.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                if (heroBuild.items.isEmpty)
                  const Text(
                    'Предметы не указаны',
                    style: TextStyle(color: AppColors.muted, fontSize: 10),
                  )
                else if (heroBuild.categories.isEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final item in heroBuild.items)
                        _BuildItemWithTime(
                          item: item,
                          buyTimeSeconds: heroBuild.buyTimes[item.id],
                        ),
                    ],
                  )
                else
                  for (var c = 0; c < heroBuild.categories.length; c++) ...[
                    if (c > 0) const SizedBox(height: 10),
                    _BuildCategoryRow(
                      category: heroBuild.categories[c],
                      buyTimes: heroBuild.buyTimes,
                    ),
                  ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatPercent(heroBuild.winRate),
                style: TextStyle(
                  color: color,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'ВИНРЕЙТ',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatCount(heroBuild.matches),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'матчей',
                style: TextStyle(color: AppColors.muted, fontSize: 8.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuildCategoryRow extends StatelessWidget {
  const _BuildCategoryRow({required this.category, required this.buyTimes});

  final BuildCategory category;
  final Map<int, double> buyTimes;

  @override
  Widget build(BuildContext context) {
    final label = category.name.replaceAll('#Citadel_HeroBuilds_', '');
    final hasAnnotation = category.annotations.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: category.isCore ? AppColors.copper : AppColors.muted,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final item in category.items)
              hasAnnotation && category.annotations[item.id] != null
                  ? Tooltip(
                      message: category.annotations[item.id]!,
                      child: _BuildItemWithTime(
                        item: item,
                        buyTimeSeconds: buyTimes[item.id],
                      ),
                    )
                  : _BuildItemWithTime(
                      item: item,
                      buyTimeSeconds: buyTimes[item.id],
                    ),
          ],
        ),
      ],
    );
  }
}

class _BuildItemWithTime extends StatelessWidget {
  const _BuildItemWithTime({required this.item, this.buyTimeSeconds});

  final Item item;
  final double? buyTimeSeconds;

  String? get _timeLabel {
    final seconds = buyTimeSeconds;
    if (seconds == null || seconds <= 0) {
      return null;
    }
    final minutes = (seconds / 60).round();
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final label = _timeLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ItemIcon(item: item, size: 30),
        if (label != null) ...[
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.meta, this.detailed});

  final HeroMeta meta;
  final HeroDetailedStats? detailed;

  @override
  Widget build(BuildContext context) {
    final hero = meta.hero;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.copper.withValues(alpha: 0.4)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B0F16), Color(0xFF171214)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hero.hasCard)
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.network(
                  hero.cardUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
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
                    AppColors.background.withValues(alpha: 0.92),
                    AppColors.background.withValues(alpha: 0.55),
                    AppColors.background.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 620;
                    final nameBlock = _NameBlock(meta: meta);

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          HeroAvatar(
                            hero: hero,
                            size: 78,
                            borderRadius: 16,
                            borderColor: AppColors.copper,
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: nameBlock),
                          const SizedBox(width: 16),
                          _WinRateBlock(meta: meta),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            HeroAvatar(
                              hero: hero,
                              size: 62,
                              borderRadius: 14,
                              borderColor: AppColors.copper,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: nameBlock),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _Pills(meta: meta),
                      ],
                    );
                  },
                ),
                if (detailed != null && detailed!.hasData) ...[
                  const SizedBox(height: 14),
                  _DetailedStats(stats: detailed!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedStats extends StatelessWidget {
  const _DetailedStats({required this.stats});

  final HeroDetailedStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _DetailTile(
        label: 'KDA',
        value: stats.kdaRatio.toStringAsFixed(2),
        footnote:
            '${stats.kills.toStringAsFixed(1)} / '
            '${stats.deaths.toStringAsFixed(1)} / '
            '${stats.assists.toStringAsFixed(1)}',
        accent: AppColors.gold,
      ),
      _DetailTile(
        label: 'Средний урон',
        value: formatCompact(stats.playerDamage),
        footnote: 'за матч',
        accent: AppColors.copper,
      ),
      _DetailTile(
        label: 'Net worth',
        value: formatCompact(stats.netWorth),
        footnote: 'за матч',
        accent: AppColors.text,
      ),
      _DetailTile(
        label: 'Last hits',
        value: stats.lastHits.toStringAsFixed(0),
        footnote: '${stats.denies.toStringAsFixed(0)} денаев',
        accent: AppColors.muted,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        final perRow = wide ? 4 : 2;
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.label,
    required this.value,
    required this.footnote,
    required this.accent,
  });

  final String label;
  final String value;
  final String footnote;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            footnote,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 8.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NameBlock extends StatelessWidget {
  const _NameBlock({required this.meta});

  final HeroMeta meta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          meta.hero.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 6),
        _HeroMetaLine(meta: meta),
        if (meta.hero.role.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            meta.hero.role,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 10),
        _Pills(meta: meta),
      ],
    );
  }
}

class _HeroMetaLine extends StatelessWidget {
  const _HeroMetaLine({required this.meta});

  final HeroMeta meta;

  @override
  Widget build(BuildContext context) {
    final tier = meta.tier;
    final tierColor = switch (tier) {
      'S' => AppColors.gold,
      'A' => AppColors.win,
      'B' => AppColors.copper,
      _ => AppColors.lose,
    };
    final delta = meta.winRateDelta;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: tierColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tierColor.withValues(alpha: 0.6)),
          ),
          child: Text(
            tier,
            style: TextStyle(
              color: tierColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (meta.winRateRank > 0)
          Text(
            '#${meta.winRateRank} из ${meta.totalHeroes} по винрейту',
            style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
          ),
        if (meta.winRateRank > 0)
          Text(
            '${delta >= 0 ? '+' : ''}${(delta * 100).toStringAsFixed(1)}% к среднему',
            style: TextStyle(
              color: delta >= 0 ? AppColors.win : AppColors.lose,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _Pills extends StatelessWidget {
  const _Pills({required this.meta});

  final HeroMeta meta;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatPill(
          label: 'Винрейт',
          value: formatPercent(meta.winRate),
          color: AppColors.winRateColor(meta.winRate),
        ),
        _StatPill(
          label: 'Пикрейт',
          value: formatPercent(meta.pickRate),
          color: AppColors.gold,
        ),
        _StatPill(
          label: 'Матчей',
          value: formatCount(meta.matches),
          color: AppColors.text,
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WinRateBlock extends StatelessWidget {
  const _WinRateBlock({required this.meta});

  final HeroMeta meta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatPercent(meta.winRate),
          style: TextStyle(
            color: AppColors.winRateColor(meta.winRate),
            fontSize: 32,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'ВИНРЕЙТ В ПАТЧЕ',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
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

class _ApiNote extends StatelessWidget {
  const _ApiNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Данные: api.deadlock-api.com · hero-counter-stats · hero-synergy-stats · '
      'hero-stats по длительности\n'
      'Win% — винрейт выбранного героя в матчах с этим противником или союзником',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.muted, fontSize: 10, height: 1.5),
    );
  }
}


class _AbilitiesTab extends StatelessWidget {
  const _AbilitiesTab({required this.heroId});

  final int heroId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  title: 'Путь прокачки',
                  subtitle: 'Топ-путь по винрейту · порядок и среднее время открытия',
                ),
                const SizedBox(height: 12),
                const _AbilityPathCard(),
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Приоритет способностей',
                  subtitle: 'Распределение путей прокачки по винрейту',
                ),
                const SizedBox(height: 12),
                SurfaceCard(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: AbilityPriorityChart(heroId: heroId),
                ),
                const SizedBox(height: 12),
                const SurfaceCard(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'Таланты: API не отдаёт структурированный список талантов с винрейтом, '
                      'поэтому раздел пока недоступен.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AbilityPathCard extends StatelessWidget {
  const _AbilityPathCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HeroBloc, HeroState>(
      builder: (context, state) {
        final path = state.abilityPath;
        if (state.status == HeroStatus.loading && path == null) {
          return const SurfaceCard(
            child: SizedBox(
              height: 150,
              child: Center(child: ShimmerBox(width: 200, height: 14)),
            ),
          );
        }
        if (path == null || path.steps.isEmpty) {
          return const SurfaceCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Text(
                'Нет данных по пути прокачки',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          );
        }

        return SurfaceCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '${path.matches} матчей',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatPercent(path.winRate),
                    style: TextStyle(
                      color: AppColors.winRateColor(path.winRate),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'ВИНРЕЙТ',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  for (final step in path.steps)
                    _AbilityStepChip(step: step),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AbilityStepChip extends StatelessWidget {
  const _AbilityStepChip({required this.step});

  final AbilityPathStep step;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: step.imageUrl.isEmpty
                    ? const Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: AppColors.muted,
                      )
                    : Image.network(
                        step.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.auto_awesome,
                              size: 20,
                              color: AppColors.muted,
                            ),
                      ),
              ),
              Positioned(
                top: -4,
                left: -4,
                child: Container(
                  width: 17,
                  height: 17,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.copper,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background),
                  ),
                  child: Text(
                    '${step.order}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            step.timeLabel,
            style: const TextStyle(color: AppColors.muted, fontSize: 8.5),
          ),
        ],
      ),
    );
  }
}
