import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/hero_meta.dart';
import '../../../domain/repositories/hero_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../favorites/favorites_service.dart';
import '../../leaderboard/screens/leaderboard_screen.dart';
import '../../players/screens/player_search_screen.dart';
import '../widgets/hero_card.dart';

/// Варианты сортировки списка героев.
enum HeroSort {
  name('По имени'),
  winRate('По винрейту'),
  pickRate('По пикрейту');

  const HeroSort(this.label);

  final String label;
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

/// Главный экран с навигацией: Герои / Избранное, поиском и сортировкой.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _favorites = {};
  int _tab = 0;

  List<HeroMeta> _allMeta = const [];
  HeroSort _sort = HeroSort.name;
  HeroRoleFilter _roleFilter = HeroRoleFilter.all;
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadMeta();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final sorted = [..._allMeta]..sort((a, b) {
      switch (_sort) {
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

  /// Герои для вкладки «Герои» с учётом роли и строки поиска.
  List<HeroMeta> get _searchedMeta {
    final byRole = _roleFilter == HeroRoleFilter.all
        ? _sortedMeta
        : _sortedMeta
              .where((meta) => _roleFilter.matches(meta.hero.role))
              .toList();
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

  List<HeroMeta> get _favoriteMeta => _sortedMeta
      .where((meta) => _favorites.contains(meta.hero.id))
      .toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title(l10n)),
        actions: [
          if (_tab == 0)
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
      body: Column(
        children: [
          if (_tab == 0) ...[
            _SearchField(
              controller: _searchController,
              onChanged: _onSearchChanged,
            ),
            _RoleFilterBar(
              selected: _roleFilter,
              onSelected: (role) => setState(() => _roleFilter = role),
            ),
          ],
          Expanded(
            child: switch (_tab) {
              0 => _heroesTab(l10n),
              1 => _favoritesTab(l10n),
              2 => const LeaderboardScreen(),
              _ => const PlayerSearchScreen(),
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (index) => setState(() => _tab = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.muted,
        selectedFontSize: 10.5,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_alt_rounded),
            label: l10n.heroesTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_rounded),
            label: l10n.favoritesTab,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_rounded),
            label: 'Лидеры',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_search_rounded),
            label: 'Поиск игрока',
          ),
        ],
      ),
    );
  }

  String _title(AppLocalizations l10n) {
    return switch (_tab) {
      0 => l10n.heroesTab,
      1 => l10n.favoritesTab,
      2 => 'Лидеры',
      _ => 'Поиск игрока',
    };
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
  }

  Widget _heroesTab(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadMeta);
    }
    return _TierLadder(
      heroes: _searchedMeta,
      favorites: _favorites,
      onToggle: _toggleFavorite,
      emptyText: switch ((_query.trim().isEmpty, _roleFilter)) {
        (true, HeroRoleFilter.all) => 'Нет героев',
        (false, _) => 'Ничего не найдено',
        (_, final role) => 'Нет героев с ролью ${role.label}',
      },
    );
  }

  Widget _favoritesTab(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadMeta);
    }
    return _TierLadder(
      heroes: _favoriteMeta,
      favorites: _favorites,
      onToggle: _toggleFavorite,
      emptyText: l10n.noFavorites,
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
                Icon(
                  Icons.tune_rounded,
                  size: 15,
                  color: AppColors.copper,
                ),
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
          const Icon(
            Icons.cloud_off_rounded,
            size: 42,
            color: AppColors.muted,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

/// Лестница тиров: вертикальный список S/A/B/C, внутри каждого —
/// горизонтальная карусель карточек героев этого тира.
class _TierLadder extends StatelessWidget {
  const _TierLadder({
    required this.heroes,
    required this.favorites,
    required this.onToggle,
    this.emptyText,
  });

  final List<HeroMeta> heroes;
  final Set<int> favorites;
  final Future<void> Function(HeroMeta) onToggle;
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
    // выбранным режимом (имя / винрейт / пикрейт).
    final groups = <String, List<HeroMeta>>{};
    for (final meta in heroes) {
      groups.putIfAbsent(meta.tier, () => <HeroMeta>[]).add(meta);
    }

    final tiers = _tierOrder.where((tier) => groups[tier]?.isNotEmpty ?? false)
        .toList(growable: false);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 10, 0, 26),
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

  static const double _cardWidth = 172;
  static const double _rowHeight = 232;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TierMarker(tier: tier, count: heroes.length),
          const SizedBox(width: 12),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 14),
              itemCount: heroes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final meta = heroes[index];
                return SizedBox(
                  width: _cardWidth,
                  child: HeroCard(
                    meta: meta,
                    isFavorite: favorites.contains(meta.hero.id),
                    onToggleFavorite: () => onToggle(meta),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
