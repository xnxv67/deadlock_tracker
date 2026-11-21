import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/hero_meta.dart';
import '../../../domain/repositories/hero_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/widgets/hero_avatar.dart';
import '../../../presentation/widgets/shimmer_skeleton.dart';
import '../../favorites/favorites_service.dart';
import '../../search/search_screen.dart';
import '../widgets/hero_card.dart';
import 'hero_detail_screen.dart';

/// Варианты сортировки списка героев.
enum HeroSort {
  meta('По мете'),
  name('По имени'),
  winRate('По винрейту'),
  pickRate('По пикрейту');

  const HeroSort(this.label);

  final String label;
}

int _tierRank(String tier) {
  const order = ['S', 'A', 'B', 'C'];
  final index = order.indexOf(tier.toUpperCase());
  return index < 0 ? order.length : index;
}

/// Фильтр по роли героя для главной сетки.
enum HeroRoleFilter {
  all('Все'),
  carry('Carry'),
  support('Support'),
  tank('Tank'),
  initiator('Initiator');

  const HeroRoleFilter(this.label);

  final String label;

  /// Deadlock API отдаёт разные формулировки ролей, поэтому
  /// сопоставляем по ключевым словам и синонимам.
  bool matches(String role) {
    final value = role.toLowerCase();
    switch (this) {
      case HeroRoleFilter.all:
        return true;
      case HeroRoleFilter.carry:
        return value.contains('carry') ||
            value.contains('marksman') ||
            value.contains('damage');
      case HeroRoleFilter.support:
        return value.contains('support') ||
            value.contains('healer') ||
            value.contains('utility');
      case HeroRoleFilter.tank:
        return value.contains('tank') ||
            value.contains('brawler') ||
            value.contains('durable');
      case HeroRoleFilter.initiator:
        return value.contains('initiator') ||
            value.contains('initiate') ||
            value.contains('brawler') ||
            value.contains('frontline');
    }
  }
}

/// Экран героев: тир-лист, поиск, фильтры, избранное и сортировка.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _favorites = {};
  final ScrollController _scrollController = ScrollController();
  bool _favoritesOnly = false;
  bool _showToTop = false;
  HeroMeta? _pick;
  bool _rolling = false;

  List<HeroMeta> _allMeta = const [];
  HeroSort _sort = HeroSort.meta;
  HeroRoleFilter _roleFilter = HeroRoleFilter.all;
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadMeta();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 400;
      if (show != _showToTop) {
        setState(() => _showToTop = show);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _showCompare() {
    if (_allMeta.isEmpty) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => _CompareDialog(heroes: _allMeta),
    );
  }

  void _showGlobalSearch() {
    showDialog<void>(
      context: context,
      builder: (_) => const GlobalSearchDialog(),
    );
  }

  void _rollPick() {
    final pool = _searchedMeta;
    if (pool.isEmpty || _rolling) {
      return;
    }
    setState(() => _rolling = true);
    Future<void>.delayed(const Duration(milliseconds: 620), () {
      if (!mounted) return;
      final topTier = pool.where((meta) => _tierRank(meta.tier) <= 1).toList();
      final candidates = topTier.isNotEmpty ? topTier : pool;
      final sorted = [...candidates]
        ..sort((a, b) => b.winRate.compareTo(a.winRate));
      final top = sorted.take(12).toList();
      setState(() {
        _pick = top[math.Random().nextInt(top.length)];
        _rolling = false;
      });
    });
  }

  void _openPick() {
    final pick = _pick;
    if (pick == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HeroDetailScreen(hero: pick.hero),
      ),
    );
  }

  Future<void> _loadFavorites() async {
    final ids = await _favoritesService.load();
    if (!mounted) return;
    setState(() {
      _favorites
        ..clear()
        ..addAll(ids);
    });
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final meta = await context.read<HeroRepository>().getMeta();
      if (!mounted) return;
      setState(() {
        _allMeta = meta;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить героев';
      });
    }
  }

  Future<void> _toggleFavorite(HeroMeta meta) async {
    final liked = await _favoritesService.toggle(meta.hero.id);
    if (!mounted) return;
    setState(() {
      if (liked) {
        _favorites.add(meta.hero.id);
      } else {
        _favorites.remove(meta.hero.id);
      }
    });
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            liked ? l10n.addedToFavorites : l10n.removedFromFavorites,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// Отсортированная мета до фильтрации по поиску и избранному.
  List<HeroMeta> get _sortedMeta {
    final sorted = [..._allMeta]
      ..sort((a, b) {
        switch (_sort) {
          case HeroSort.meta:
            final tierComparison = _tierRank(a.tier)
                .compareTo(_tierRank(b.tier));
            if (tierComparison != 0) {
              return tierComparison;
            }
            final winComparison = b.winRate.compareTo(a.winRate);
            if (winComparison != 0) {
              return winComparison;
            }
            return b.pickRate.compareTo(a.pickRate);
          case HeroSort.name:
            return a.hero.name.toLowerCase().compareTo(
              b.hero.name.toLowerCase(),
            );
          case HeroSort.winRate:
            return b.winRate.compareTo(a.winRate);
          case HeroSort.pickRate:
            return b.pickRate.compareTo(a.pickRate);
        }
      });
    return sorted;
  }

  /// Герои с учётом избранного, роли и строки поиска.
  List<HeroMeta> get _searchedMeta {
    final base = _favoritesOnly
        ? _sortedMeta
              .where((meta) => _favorites.contains(meta.hero.id))
              .toList()
        : _sortedMeta;
    final byRole = _roleFilter == HeroRoleFilter.all
        ? base
        : base.where((meta) => _roleFilter.matches(meta.hero.role)).toList();
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return byRole;
    }
    return byRole
        .where(
          (meta) =>
              meta.hero.name.toLowerCase().contains(query) ||
              meta.hero.role.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _showGlobalSearch,
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_favoritesOnly ? l10n.favoritesTab : l10n.heroesTab),
          actions: [
            IconButton(
              tooltip: _favoritesOnly
                  ? 'Показать всех героев'
                  : 'Только избранное',
              icon: Icon(
                _favoritesOnly
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              color: _favoritesOnly ? AppColors.gold : null,
              onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
            ),
            IconButton(
              tooltip: 'Глобальный поиск (Ctrl+K)',
              icon: const Icon(Icons.travel_explore_rounded),
              onPressed: _showGlobalSearch,
            ),
            IconButton(
              tooltip: 'Сравнить героев',
              icon: const Icon(Icons.compare_arrows_rounded),
              onPressed: _showCompare,
            ),
            PopupMenuButton<HeroSort>(
              tooltip: 'Сортировка',
              icon: const Icon(Icons.sort_rounded),
              initialValue: _sort,
              onSelected: (sort) => setState(() => _sort = sort),
              itemBuilder: (context) => [
                for (final sort in HeroSort.values)
                  PopupMenuItem<HeroSort>(
                    value: sort,
                    child: Row(
                      children: [
                        Icon(
                          sort == _sort
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: sort == _sort
                              ? AppColors.gold
                              : AppColors.muted,
                        ),
                        const SizedBox(width: 10),
                        Text(sort.label),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: _heroesTab(l10n),
        floatingActionButton: _showToTop
            ? FloatingActionButton.small(
                onPressed: _scrollToTop,
                tooltip: 'Наверх',
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.gold,
                child: const Icon(Icons.arrow_upward_rounded),
              )
            : null,
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
  }

  Widget _heroesTab(AppLocalizations l10n) {
    if (_loading) {
      return const _MetaGridSkeleton();
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadMeta);
    }
    final heroes = _searchedMeta;
    return Column(
      children: [
        _SearchField(
          controller: _searchController,
          onChanged: _onSearchChanged,
        ),
        _RoleFilterBar(
          selected: _roleFilter,
          onSelected: (role) => setState(() => _roleFilter = role),
        ),
        _PickRecommender(
          pick: _pick,
          rolling: _rolling,
          onRoll: _rollPick,
          onOpen: _openPick,
        ),
        if (heroes.isNotEmpty) _MetaSpotlight(heroes: heroes),
        Expanded(
          child: _TierLadder(
            controller: _scrollController,
            heroes: heroes,
            favorites: _favorites,
            onToggle: _toggleFavorite,
            emptyText: _favoritesOnly
                ? l10n.noFavorites
                : switch ((_query.trim().isEmpty, _roleFilter)) {
                    (true, HeroRoleFilter.all) => 'Нет героев',
                    (false, _) => 'Ничего не найдено',
                    (_, final role) => 'Нет героев с ролью ${role.label}',
                  },
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Поиск героя...',
          isDense: true,
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.muted,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PickRecommender extends StatelessWidget {
  const _PickRecommender({
    required this.pick,
    required this.rolling,
    required this.onRoll,
    required this.onOpen,
  });

  final HeroMeta? pick;
  final bool rolling;
  final VoidCallback onRoll;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.32)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 17,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: _recommendation(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                onTap: onRoll,
                borderRadius: BorderRadius.circular(9),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(
                    'ПОДОБРАТЬ',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendation() {
    if (rolling) {
      return const SizedBox(
        key: ValueKey('rolling'),
        height: 18,
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Ищем героя...',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      );
    }
    final meta = pick;
    if (meta == null) {
      return const Text(
        'Не знаете, кого взять?',
        key: ValueKey('idle'),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      );
    }
    return GestureDetector(
      key: ValueKey(meta.hero.id),
      onTap: onOpen,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroAvatar(hero: meta.hero, size: 26),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${meta.hero.name} · ${meta.tier}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'WR ${formatPercent(meta.winRate)} · ${formatCount(meta.matches)} матчей',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleFilterBar extends StatelessWidget {
  const _RoleFilterBar({required this.selected, required this.onSelected});

  final HeroRoleFilter selected;
  final ValueChanged<HeroRoleFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 5),
            child: Row(
              children: const [
                Icon(Icons.tune_rounded, size: 15, color: AppColors.copper),
                SizedBox(width: 5),
                Text(
                  'РОЛИ',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          for (final role in HeroRoleFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _RoleChip(
                role: role,
                selected: role == selected,
                onTap: () => onSelected(role),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final HeroRoleFilter role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? AppColors.copper.withValues(alpha: 0.2)
              : AppColors.surface,
          border: Border.all(
            color: selected
                ? AppColors.copper
                : AppColors.copper.withValues(alpha: 0.28),
          ),
        ),
        child: Text(
          role.label,
          style: TextStyle(
            color: selected ? AppColors.gold : AppColors.muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

/// Скелетон сетки героев, повторяющий форму карточек тирлиста.
class _MetaGridSkeleton extends StatelessWidget {
  const _MetaGridSkeleton();

  static const double _spacing = 10;
  static const double _minCardWidth = 140;
  static const int _maxColumns = 5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            ((constraints.maxWidth + _spacing) / (_minCardWidth + _spacing))
                .floor()
                .clamp(1, _maxColumns);
        final width =
            (constraints.maxWidth - _spacing * (columns - 1)) / columns;
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 26),
          child: Wrap(
            spacing: _spacing,
            runSpacing: _spacing,
            children: [
              for (var i = 0; i < 12; i++)
                SizedBox(
                  width: width,
                  height: 232,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ShimmerBox(
                          width: 36,
                          height: 36,
                          borderRadius: 10,
                        ),
                        const SizedBox(height: 14),
                        const ShimmerBox(width: 120, height: 12),
                        const SizedBox(height: 8),
                        const ShimmerBox(width: 80, height: 10),
                        const Spacer(),
                        const Row(
                          children: [
                            Expanded(child: ShimmerBox(height: 18)),
                            SizedBox(width: 10),
                            Expanded(child: ShimmerBox(height: 18)),
                          ],
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

/// Компактная сводка меты: лидеры по винрейту и средние показатели.
class _MetaSpotlight extends StatelessWidget {
  const _MetaSpotlight({required this.heroes});

  final List<HeroMeta> heroes;

  @override
  Widget build(BuildContext context) {
    final leaders = [...heroes]..sort((a, b) => b.winRate.compareTo(a.winRate));
    final top = leaders.take(3).toList(growable: false);
    final average = heroes.isEmpty
        ? 0.0
        : heroes.fold<double>(0, (sum, meta) => sum + meta.winRate) /
              heroes.length;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 10),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.copper.withValues(alpha: 0.32)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B0F16), Color(0xFF171214)],
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              size: 18,
              color: AppColors.gold,
            ),
            const SizedBox(width: 6),
            const Text(
              'ТОП МЕТЫ',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: top.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final meta = top[index];
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HeroAvatar(hero: meta.hero, size: 28),
                        const SizedBox(width: 5),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              meta.hero.name,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              formatPercent(meta.winRate),
                              style: TextStyle(
                                color: AppColors.winRateColor(meta.winRate),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${heroes.length} героев',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ср. WR ${formatPercent(average)}',
                  style: const TextStyle(
                    color: AppColors.copper,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Сравнение двух героев по ключевым метрикам меты.
class _CompareDialog extends StatefulWidget {
  const _CompareDialog({required this.heroes});

  final List<HeroMeta> heroes;

  @override
  State<_CompareDialog> createState() => _CompareDialogState();
}

class _CompareDialogState extends State<_CompareDialog> {
  late HeroMeta _left;
  late HeroMeta _right;

  @override
  void initState() {
    super.initState();
    final ranked = [...widget.heroes]
      ..sort((a, b) => b.winRate.compareTo(a.winRate));
    _left = ranked.first;
    _right = ranked.length > 1 ? ranked[1] : ranked.first;
  }

  List<DropdownMenuItem<HeroMeta>> get _items {
    final sorted = [...widget.heroes]
      ..sort(
        (a, b) =>
            a.hero.name.toLowerCase().compareTo(b.hero.name.toLowerCase()),
      );
    return [
      for (final meta in sorted)
        DropdownMenuItem<HeroMeta>(
          value: meta,
          child: Text(
            '${meta.hero.name} · ${meta.tier}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final maxMatches = _left.matches > _right.matches
        ? _left.matches.toDouble()
        : _right.matches.toDouble();

    return AlertDialog(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.compare_arrows_rounded, color: AppColors.gold, size: 20),
          SizedBox(width: 8),
          Text(
            'Сравнение героев',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<HeroMeta>(
                      value: _left,
                      isExpanded: true,
                      items: items,
                      onChanged: (value) =>
                          setState(() => _left = value ?? _left),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButton<HeroMeta>(
                      value: _right,
                      isExpanded: true,
                      items: items,
                      onChanged: (value) =>
                          setState(() => _right = value ?? _right),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _sideHero(_left)),
                  const SizedBox(width: 12),
                  const Text(
                    'VS',
                    style: TextStyle(
                      color: AppColors.copper,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _sideHero(_right)),
                ],
              ),
              const SizedBox(height: 12),
              _metric('ТИР', _left.tier, _right.tier),
              _metric(
                'ВИНРЕЙТ',
                formatPercent(_left.winRate),
                formatPercent(_right.winRate),
                leftValue: _left.winRate,
                rightValue: _right.winRate,
                leftColor: AppColors.winRateColor(_left.winRate),
                rightColor: AppColors.winRateColor(_right.winRate),
              ),
              _metric(
                'ПИКРЕЙТ',
                formatPercent(_left.pickRate),
                formatPercent(_right.pickRate),
                leftValue: _left.pickRate,
                rightValue: _right.pickRate,
                maxValue: 0.3,
                leftColor: AppColors.copper,
                rightColor: AppColors.copper,
              ),
              _metric(
                'МАТЧИ',
                formatCount(_left.matches),
                formatCount(_right.matches),
                leftValue: _left.matches.toDouble(),
                rightValue: _right.matches.toDouble(),
                maxValue: maxMatches,
                leftColor: AppColors.gold,
                rightColor: AppColors.gold,
              ),
              _metric(
                'МЕСТО',
                _left.winRateRank > 0 ? '#${_left.winRateRank}' : '—',
                _right.winRateRank > 0 ? '#${_right.winRateRank}' : '—',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  Widget _sideHero(HeroMeta meta) {
    return Column(
      children: [
        HeroAvatar(hero: meta.hero, size: 42),
        const SizedBox(height: 5),
        Text(
          meta.hero.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        Text(
          meta.hero.role,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
        ),
      ],
    );
  }

  Widget _metric(
    String label,
    String leftText,
    String rightText, {
    double? leftValue,
    double? rightValue,
    double maxValue = 1,
    Color? leftColor,
    Color? rightColor,
  }) {
    final leftStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w900,
      color: leftColor ?? AppColors.text,
    );
    final rightStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w900,
      color: rightColor ?? AppColors.text,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  leftText,
                  textAlign: TextAlign.right,
                  style: leftStyle,
                ),
              ),
              SizedBox(
                width: 76,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(child: Text(rightText, style: rightStyle)),
            ],
          ),
          if (leftValue != null && rightValue != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: _bar(leftValue / maxValue, leftColor)),
                const SizedBox(width: 76),
                Expanded(child: _bar(rightValue / maxValue, rightColor)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _bar(double value, Color? color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 4,
        backgroundColor: AppColors.surfaceLight,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.copper),
      ),
    );
  }
}

/// Лестница тиров: вертикальный список S/A/B/C, внутри каждого —
/// сетка карточек героев этого тира, автоматически переносящаяся по ширине.
class _TierLadder extends StatelessWidget {
  const _TierLadder({
    required this.heroes,
    required this.favorites,
    required this.onToggle,
    this.controller,
    this.emptyText,
  });

  final List<HeroMeta> heroes;
  final Set<int> favorites;
  final Future<void> Function(HeroMeta) onToggle;
  final ScrollController? controller;
  final String? emptyText;

  static const List<String> _tierOrder = ['S', 'A', 'B', 'C'];

  @override
  Widget build(BuildContext context) {
    if (heroes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border_rounded,
              size: 46,
              color: AppColors.muted,
            ),
            const SizedBox(height: 10),
            Text(
              emptyText ?? 'Пусто',
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    // Порядок героев внутри тира сохраняем: он уже отсортирован
    // выбранным режимом (мета / имя / винрейт / пикрейт).
    final groups = <String, List<HeroMeta>>{};
    for (final meta in heroes) {
      groups.putIfAbsent(meta.tier, () => <HeroMeta>[]).add(meta);
    }

    final tiers = _tierOrder
        .where((tier) => groups[tier]?.isNotEmpty ?? false)
        .toList(growable: false);

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 26),
      itemCount: tiers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final tier = tiers[index];
        final tierHeroes = groups[tier] ?? const <HeroMeta>[];
        return _TierRow(
          tier: tier,
          heroes: tierHeroes,
          favorites: favorites,
          onToggle: onToggle,
        );
      },
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({
    required this.tier,
    required this.heroes,
    required this.favorites,
    required this.onToggle,
  });

  final String tier;
  final List<HeroMeta> heroes;
  final Set<int> favorites;
  final Future<void> Function(HeroMeta) onToggle;

  static const double _minCardWidth = 140;
  static const double _cardHeight = 232;
  static const double _spacing = 10;
  static const int _maxColumns = 5;
  static const double _markerWidth = 56;
  static const double _markerGap = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth - _markerWidth - _markerGap;
        final columns = ((gridWidth + _spacing) / (_minCardWidth + _spacing))
            .floor()
            .clamp(1, _maxColumns);
        final cardWidth = (gridWidth - _spacing * (columns - 1)) / columns;
        final rows = (heroes.length / columns).ceil();
        final gridHeight = rows == 0
            ? _cardHeight
            : rows * (_cardHeight + _spacing) - _spacing;

        return SizedBox(
          height: gridHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TierMarker(tier: tier, count: heroes.length),
              const SizedBox(width: _markerGap),
              SizedBox(
                width: gridWidth,
                child: Wrap(
                  spacing: _spacing,
                  runSpacing: _spacing,
                  children: [
                    for (final meta in heroes)
                      SizedBox(
                        width: cardWidth,
                        height: _cardHeight,
                        child: RepaintBoundary(
                          child: HeroCard(
                            meta: meta,
                            isFavorite: favorites.contains(meta.hero.id),
                            onToggleFavorite: () => onToggle(meta),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Крупный контрастный маркер тира слева от карусели.
class _TierMarker extends StatelessWidget {
  const _TierMarker({required this.tier, required this.count});

  final String tier;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tier.toUpperCase()) {
      'S' => (const Color(0xFFC2313F), const Color(0xFF7C1F2D), Colors.white),
      'A' => (
        const Color(0xFFE08634),
        const Color(0xFF8C4A16),
        const Color(0xFF1B1008),
      ),
      'B' => (
        const Color(0xFFD9A441),
        const Color(0xFF8A6420),
        const Color(0xFF1B1408),
      ),
      _ => (AppColors.surfaceLight, const Color(0xFF241A1D), AppColors.muted),
    };

    return Container(
      width: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.$1, colors.$2],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: colors.$1.withValues(alpha: 0.4),
            blurRadius: 14,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            tier.toUpperCase(),
            style: TextStyle(
              color: colors.$3,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: colors.$3.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
