import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../favorites/favorites_service.dart';
import '../mock_hero.dart';
import '../widgets/hero_card.dart';
import '../screens/hero_detail_screen.dart';

/// Главный экран с навигацией: Герои / Избранное.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  final Set<int> _favorites = {};
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
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

  Future<void> _toggleFavorite(MockHero hero) async {
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
    final favoriteHeroes = MockHero.samples
        .where((hero) => _favorites.contains(hero.id))
        .toList();

    final body = _tab == 0
        ? _HeroGrid(
            heroes: MockHero.samples,
            favorites: _favorites,
            onToggle: _toggleFavorite,
          )
        : _HeroGrid(
            heroes: favoriteHeroes,
            favorites: _favorites,
            onToggle: _toggleFavorite,
            emptyText: l10n.noFavorites,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? l10n.heroesTab : l10n.favoritesTab),
      ),
      body: body,
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
}

class _HeroGrid extends StatelessWidget {
  const _HeroGrid({
    required this.heroes,
    required this.favorites,
    required this.onToggle,
    this.emptyText,
  });

  final List<MockHero> heroes;
  final Set<int> favorites;
  final Future<void> Function(MockHero) onToggle;
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
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HeroDetailScreen(hero: hero),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
