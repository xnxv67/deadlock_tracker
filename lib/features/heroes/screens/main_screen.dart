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

  /// Герои для вкладки «Герои» с учётом строки поиска.
  List<HeroMeta> get _searchedMeta {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _sortedMeta;
    }
    return _sortedMeta
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
          if (_tab == 0)
            _SearchField(
              controller: _searchController,
              onChanged: _onSearchChanged,
            ),
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
    return _HeroGrid(
      heroes: _searchedMeta,
      favorites: _favorites,
      onToggle: _toggleFavorite,
      emptyText: _query.trim().isEmpty ? 'Нет героев' : 'Ничего не найдено',
    );
  }

  Widget _favoritesTab(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadMeta);
    }
    return _HeroGrid(
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

class _HeroGrid extends StatelessWidget {
  const _HeroGrid({
    required this.heroes,
    required this.favorites,
    required this.onToggle,
    this.emptyText,
  });

  final List<HeroMeta> heroes;
  final Set<int> favorites;
  final Future<void> Function(HeroMeta) onToggle;
  final String? emptyText;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 180).floor().clamp(2, 6);
        return GridView.builder(
          padding: const EdgeInsets.all(14),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: heroes.length,
          itemBuilder: (context, index) {
            final meta = heroes[index];
            return HeroCard(
              meta: meta,
              isFavorite: favorites.contains(meta.hero.id),
              onToggleFavorite: () => onToggle(meta),
            );
          },
        );
      },
    );
  }
}
