import 'package:flutter/material.dart' hide Hero;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/hero.dart';
import '../../../domain/entities/hero_meta.dart';
import '../../../domain/repositories/hero_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../favorites/favorites_service.dart';
import '../../search/bloc/hero_search_bloc.dart';
import '../../search/bloc/hero_search_event.dart';
import '../../search/bloc/hero_search_state.dart';
import '../widgets/hero_card.dart';

/// Варианты сортировки списка героев.
enum HeroSort {
  name('По имени'),
  winRate('По винрейту'),
  pickRate('По пикрейту');

  const HeroSort(this.label);

  final String label;
}

/// Главный экран с навигацией: Герои / Избранное и поиском.
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

  /// Все герои меты (для вкладки «Избранное» и стартового списка).
  List<HeroMeta> _allMeta = const [];
  HeroSort _sort = HeroSort.name;
  bool _loadingAll = true;

  /// Текущий отсортированный список героев.
  List<Hero> get _allHeroes {
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
    return sorted.map((m) => m.hero).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadAllHeroes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllHeroes() async {
    try {
      final meta = await context.read<HeroRepository>().getMeta();
      if (!mounted) return;
      setState(() {
        _allMeta = meta;
        _loadingAll = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAll = false);
    }
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

  Future<void> _toggleFavorite(Hero hero) async {
    final liked = await _favoritesService.toggle(hero.id);
    if (!mounted) return;
    setState(() {
      if (liked) {
        _favorites.add(hero.id);
      } else {
        _favorites.remove(hero.id);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.appTitle),
            Text(
              _tab == 0 ? l10n.heroesTab : l10n.favoritesTab,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
          if (_tab == 0) _SearchField(controller: _searchController),
          Expanded(child: _tab == 0 ? _heroesTab(l10n) : _favoritesTab(l10n)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (index) => setState(() => _tab = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.muted,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_alt_rounded),
            label: l10n.heroesTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_rounded),
            label: l10n.favoritesTab,
          ),
        ],
      ),
    );
  }

  Widget _heroesTab(AppLocalizations l10n) {
    return BlocBuilder<HeroSearchBloc, HeroSearchState>(
      builder: (context, state) {
        final hasQuery = state.query.trim().isNotEmpty;
        if (hasQuery) {
          if (state.status == HeroSearchStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return _HeroGrid(
            heroes: state.heroes,
            favorites: _favorites,
            onToggle: _toggleFavorite,
            emptyText: 'Ничего не найдено',
          );
        }
        if (_loadingAll) {
          return const Center(child: CircularProgressIndicator());
        }
        return _HeroGrid(
          heroes: _allHeroes,
          favorites: _favorites,
          onToggle: _toggleFavorite,
          emptyText: 'Нет героев',
        );
      },
    );
  }

  Widget _favoritesTab(AppLocalizations l10n) {
    final favoriteHeroes =
        _allHeroes.where((hero) => _favorites.contains(hero.id)).toList();
    return _HeroGrid(
      heroes: favoriteHeroes,
      favorites: _favorites,
      onToggle: _toggleFavorite,
      emptyText: l10n.noFavorites,
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: TextField(
        controller: controller,
        onChanged: (value) => context
            .read<HeroSearchBloc>()
            .add(HeroSearchQueryChanged(value)),
        decoration: InputDecoration(
          hintText: 'Поиск героя...',
          isDense: true,
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.muted,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    controller.clear();
                    context
                        .read<HeroSearchBloc>()
                        .add(const HeroSearchQueryChanged(''));
                  },
                ),
        ),
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

  final List<Hero> heroes;
  final Set<int> favorites;
  final Future<void> Function(Hero) onToggle;
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
            childAspectRatio: 0.72,
          ),
          itemCount: heroes.length,
          itemBuilder: (context, index) {
            final hero = heroes[index];
            return HeroCard(
              hero: hero,
              isFavorite: favorites.contains(hero.id),
              onToggleFavorite: () => onToggle(hero),
            );
          },
        );
      },
    );
  }
}
