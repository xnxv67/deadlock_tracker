import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/storage/recent_hero_store.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/hero_meta.dart';
import '../../domain/repositories/hero_repository.dart';
import '../bloc/meta/meta_bloc.dart';
import '../bloc/meta/meta_event.dart';
import '../bloc/meta/meta_sort.dart';
import '../bloc/meta/meta_state.dart';
import '../widgets/error_view.dart';
import '../widgets/hero_avatar.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/surface_card.dart';
import 'hero_screen.dart';

class MetaScreen extends StatelessWidget {
  const MetaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MetaBloc(context.read<HeroRepository>())..add(const MetaRequested()),
      child: const _MetaView(),
    );
  }
}

class _MetaView extends StatefulWidget {
  const _MetaView();

  @override
  State<_MetaView> createState() => _MetaViewState();
}

class _MetaViewState extends State<_MetaView> {
  final TextEditingController _search = TextEditingController();
  final RecentHeroStore _recentStore = const RecentHeroStore();
  int? _recentHeroId;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final id = await _recentStore.load();
    if (!mounted) {
      return;
    }
    setState(() => _recentHeroId = id);
  }

  void _openHero(HeroMeta meta) {
    _recentStore.save(meta.hero.id);
    setState(() => _recentHeroId = meta.hero.id);
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => HeroScreen(meta: meta)));
  }

  List<HeroMeta> _filter(List<HeroMeta> heroes) {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) {
      return heroes;
    }
    return heroes
        .where((item) => item.hero.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<MetaBloc, MetaState>(
          builder: (context, state) {
            final heroes = _filter(state.heroes);
            HeroMeta? recent;
            for (final item in state.heroes) {
              if (item.hero.id == _recentHeroId) {
                recent = item;
                break;
              }
            }
            final recentMeta = recent;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<MetaBloc>().add(const MetaRefreshRequested());
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
                          const _HeaderBanner(),
                          const SizedBox(height: 14),
                          if (recentMeta != null) ...[
                            const SizedBox(height: 12),
                            _RecentHero(
                              meta: recentMeta,
                              onOpen: () => _openHero(recentMeta),
                            ),
                          ],
                          const SizedBox(height: 18),
                          _SearchBar(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            count: heroes.length,
                            enabled: state.hasData,
                          ),
                          const SizedBox(height: 20),
                          SectionHeader(
                            title: 'Тирлист меты',
                            subtitle:
                                'Тиры по винрейту · сортировка внутри тира',
                            trailing:
                                state.status == MetaStatus.loading &&
                                    state.hasData
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 10),
                          _content(state, heroes),
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

  void _sort(MetaSortField field) {
    context.read<MetaBloc>().add(MetaSortRequested(field));
  }

  Widget _content(MetaState state, List<HeroMeta> heroes) {
    if (!state.hasData) {
      if (state.status == MetaStatus.failure) {
        return ErrorView(
          title: errorTitle(state.error),
          text: errorText(state.error),
          onRetry: () => context.read<MetaBloc>().add(const MetaRequested()),
        );
      }
      return const SkeletonTable(rows: 8, showAvatar: true);
    }

    if (heroes.isEmpty) {
      return const SurfaceCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 26),
          child: Text(
            'Герой не найден. Попробуй другое имя.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
      );
    }

    final groups = <String, List<HeroMeta>>{};
    for (final meta in heroes) {
      groups.putIfAbsent(meta.tier, () => <HeroMeta>[]).add(meta);
    }
    final tiers = const ['S', 'A', 'B', 'C']
        .where((tier) => groups[tier]?.isNotEmpty ?? false)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SortBar(
          selected: state.sortField,
          ascending: state.ascending,
          onSelected: _sort,
        ),
        const SizedBox(height: 18),
        for (final tier in tiers)
          _TierSection(tier: tier, heroes: groups[tier]!, onOpen: _openHero),
      ],
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({
    required this.selected,
    required this.ascending,
    required this.onSelected,
  });

  final MetaSortField selected;
  final bool ascending;
  final ValueChanged<MetaSortField> onSelected;

  static const Map<MetaSortField, String> _labels = {
    MetaSortField.winRate: 'Винрейт',
    MetaSortField.pickRate: 'Пикрейт',
    MetaSortField.matches: 'Матчи',
    MetaSortField.name: 'Имя',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final field in MetaSortField.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_labels[field] ?? field.name),
                    if (field == selected) ...[
                      const SizedBox(width: 4),
                      Icon(
                        ascending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 13,
                      ),
                    ],
                  ],
                ),
                selected: field == selected,
                visualDensity: VisualDensity.compact,
                showCheckmark: false,
                onSelected: (_) => onSelected(field),
              ),
            ),
        ],
      ),
    );
  }
}

class _TierSection extends StatelessWidget {
  const _TierSection({
    required this.tier,
    required this.heroes,
    required this.onOpen,
  });

  final String tier;
  final List<HeroMeta> heroes;
  final void Function(HeroMeta) onOpen;

  static const List<String> _tierOrder = ['S', 'A', 'B', 'C'];
  static const List<String> _descriptions = [
    'Винрейт выше 54%',
    'Винрейт выше 52%',
    'Винрейт выше 50%',
    'Винрейт 50% и ниже',
  ];

  Color get _color {
    return switch (tier) {
      'S' => const Color(0xFFFF4D4D),
      'A' => const Color(0xFFFFA940),
      'B' => const Color(0xFF4DA6FF),
      _ => AppColors.muted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final index = _tierOrder.indexOf(tier);
    final color = _color;
    final description = index >= 0 && index < _descriptions.length
        ? _descriptions[index]
        : 'Группа меты';

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.32),
                      color.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(color: color.withValues(alpha: 0.65)),
                ),
                child: Text(
                  tier,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIER $tier',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${heroes.length}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final width = constraints.maxWidth;
              final columns = width >= 980
                  ? 5
                  : width >= 760
                  ? 4
                  : width >= 560
                  ? 3
                  : width >= 370
                  ? 2
                  : 1;
              final cardWidth = (width - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final meta in heroes)
                    SizedBox(
                      width: cardWidth,
                      child: _HeroCard(
                        meta: meta,
                        color: color,
                        onOpen: () => onOpen(meta),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.meta,
    required this.color,
    required this.onOpen,
  });

  final HeroMeta meta;
  final Color color;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final winRate = meta.winRate;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.surface,
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  HeroAvatar(hero: meta.hero, size: 38),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          meta.hero.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta.hero.role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatPercent(winRate),
                        style: TextStyle(
                          color: AppColors.winRateColor(winRate),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'WIN',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.8),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'PICK',
                      value: formatPercent(meta.pickRate),
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'MATCHES',
                      value: formatCount(meta.matches),
                    ),
                  ),
                  if (meta.winRateRank > 0)
                    Expanded(
                      child: _Metric(
                        label: 'RANK',
                        value: '#${meta.winRateRank}',
                      ),
                    ),
                ],
              ),
              if (meta.winRateDelta.abs() >= 0.0005) ...[
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      meta.winRateDelta > 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 12,
                      color: meta.winRateDelta > 0
                          ? AppColors.win
                          : AppColors.lose,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${meta.winRateDelta > 0 ? '+' : ''}${formatPercent(meta.winRateDelta, digits: 2)} к среднему',
                      style: TextStyle(
                        color: meta.winRateDelta > 0
                            ? AppColors.win
                            : AppColors.lose,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.copper.withValues(alpha: 0.35)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B0F16), Color(0xFF171214), Color(0xFF1D1613)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -6,
            top: -34,
            child: Text(
              'DL',
              style: TextStyle(
                fontSize: 116,
                fontWeight: FontWeight.w900,
                letterSpacing: -4,
                color: Colors.white.withValues(alpha: 0.035),
                height: 1,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.copper,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Text(
                    'DEADLOCK',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.copper.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LiveDot(),
                        SizedBox(width: 6),
                        Text(
                          'OPEN API',
                          style: TextStyle(
                            color: AppColors.copper,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'TIER LIST',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  height: 1,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Мета героев · тиры по винрейту · пикрейт',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: AppColors.win,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _RecentHero extends StatelessWidget {
  const _RecentHero({required this.meta, required this.onOpen});

  final HeroMeta meta;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 16,
                color: AppColors.copper,
              ),
              const SizedBox(width: 8),
              const Text(
                'Недавний герой:',
                style: TextStyle(color: AppColors.muted, fontSize: 11.5),
              ),
              const SizedBox(width: 6),
              HeroAvatar(hero: meta.hero, size: 22),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  meta.hero.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Text(
                'Открыть',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: AppColors.gold,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.count,
    required this.enabled,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int count;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              enabled: enabled,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Поиск героя',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 40),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
