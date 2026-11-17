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
import '../widgets/simple_table.dart';
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
                            title: 'Мета героев',
                            subtitle: 'Винрейт и пикрейт · клик по заголовку — сортировка',
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;
        final columns = [
          TableColumn(
            'Герой',
            flex: wide ? 6 : 7,
            onTap: () => _sort(MetaSortField.name),
            sorted: state.sortField == MetaSortField.name,
            ascending: state.ascending,
          ),
          TableColumn(
            'Tier',
            flex: 1,
            align: Alignment.center,
          ),
          if (wide)
            TableColumn(
              'Матчей',
              flex: 2,
              align: Alignment.centerRight,
              onTap: () => _sort(MetaSortField.matches),
              sorted: state.sortField == MetaSortField.matches,
              ascending: state.ascending,
            ),
          TableColumn(
            'Win%',
            flex: 2,
            align: Alignment.centerRight,
            onTap: () => _sort(MetaSortField.winRate),
            sorted: state.sortField == MetaSortField.winRate,
            ascending: state.ascending,
          ),
          if (wide)
            TableColumn(
              'Pick Rate',
              flex: 2,
              align: Alignment.centerRight,
              onTap: () => _sort(MetaSortField.pickRate),
              sorted: state.sortField == MetaSortField.pickRate,
              ascending: state.ascending,
            ),
        ];

        final rows = <TableRowData>[
          for (final meta in heroes)
            TableRowData(
              onTap: () => _openHero(meta),
              cells: [
                _HeroCell(meta: meta),
                _TierBadge(tier: meta.tier),
                if (wide)
                  Text(
                    formatCount(meta.matches),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
                Text(
                  formatPercent(meta.winRate),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.winRateColor(meta.winRate),
                  ),
                ),
                if (wide)
                  Text(
                    formatPercent(meta.pickRate),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
              ],
            ),
        ];

        return SimpleTable(columns: columns, rows: rows);
      },
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
                'TRACKER',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  height: 1,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Мета героев · винрейты · контр-пики',
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

class _HeroCell extends StatelessWidget {
  const _HeroCell({required this.meta});

  final HeroMeta meta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HeroAvatar(hero: meta.hero, size: 34),
        const SizedBox(width: 10),
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
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (meta.hero.role.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  meta.hero.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}


class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final String tier;

  Color get _color {
    switch (tier) {
      case 'S':
        return const Color(0xFFFF4D4D);
      case 'A':
        return const Color(0xFFFFA940);
      case 'B':
        return const Color(0xFF4DA6FF);
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _color.withValues(alpha: 0.55)),
        ),
        child: Text(
          tier,
          style: TextStyle(
            color: _color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
