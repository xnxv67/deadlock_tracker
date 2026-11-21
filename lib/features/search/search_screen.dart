import 'dart:async';

import 'package:flutter/material.dart' hide Hero;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/hero.dart';
import '../../../domain/entities/item_meta.dart';
import '../../../domain/entities/steam_profile.dart';
import '../../../domain/repositories/hero_repository.dart';
import '../../../domain/repositories/items_repository.dart';
import '../../../domain/repositories/player_repository.dart';
import '../../../presentation/widgets/hero_avatar.dart';
import '../heroes/screens/hero_detail_screen.dart';
import '../items/screens/item_detail_screen.dart';
import '../players/screens/player_profile_screen.dart';
import 'bloc/hero_search_bloc.dart';
import 'bloc/hero_search_event.dart';
import 'bloc/hero_search_state.dart';

/// Экран поиска героев.
///
/// Содержит только функциональность (поле ввода + простые `ListTile`).
/// Карточки результатов будут оформлены отдельно.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HeroSearchBloc(context.read<HeroRepository>()),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Поиск героев')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Герой',
                hintText: 'Начни вводить имя',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                context.read<HeroSearchBloc>().add(
                  HeroSearchQueryChanged(value),
                );
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<HeroSearchBloc, HeroSearchState>(
              builder: (context, state) {
                return switch (state.status) {
                  HeroSearchStatus.initial => const _Placeholder(
                    icon: Icons.search,
                    text: 'Начни вводить имя героя',
                  ),
                  HeroSearchStatus.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  HeroSearchStatus.failure => _FailureView(state: state),
                  HeroSearchStatus.success => _ResultsView(state: state),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.state});

  final HeroSearchState state;

  @override
  Widget build(BuildContext context) {
    if (state.heroes.isEmpty) {
      return _Placeholder(
        icon: Icons.search_off,
        text: 'По запросу «${state.query}» ничего не найдено',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: state.heroes.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final hero = state.heroes[index];
        return ListTile(
          leading: hero.hasImage
              ? CircleAvatar(backgroundImage: NetworkImage(hero.imageUrl))
              : const CircleAvatar(child: Icon(Icons.sports_esports)),
          title: Text(hero.name),
          subtitle: hero.role.isEmpty ? null : Text(hero.role),
        );
      },
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.state});

  final HeroSearchState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(
              errorTitle(state.error),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorText(state.error),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                context.read<HeroSearchBloc>().add(
                  HeroSearchQueryChanged(state.query),
                );
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Глобальный поиск: герои, игроки Steam и предметы в одном окне.
class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;
  bool _loading = false;
  String _query = '';
  List<Hero> _heroes = const [];
  List<SteamProfile> _players = const [];
  List<ItemMeta> _items = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<T?> _safe<T>(Future<T> Function() task) async {
    try {
      return await task();
    } catch (_) {
      return null;
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _query = value);
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _loading = false;
        _heroes = const [];
        _players = const [];
        _items = const [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final requestId = ++_requestId;
    setState(() => _loading = true);

    final heroesFuture = _safe(
      () => context.read<HeroRepository>().searchHeroes(query),
    );
    final playersFuture = _safe(
      () => context.read<PlayerRepository>().searchSteam(query),
    );
    final itemsFuture = query.length >= 2
        ? _safe(() => context.read<ItemsRepository>().getItems())
        : Future<List<ItemMeta>?>.value(null);

    final heroes = await heroesFuture;
    final players = await playersFuture;
    final allItems = await itemsFuture;
    if (!mounted || requestId != _requestId) return;

    final lower = query.toLowerCase();
    setState(() {
      _heroes = heroes ?? const [];
      _players = players ?? const [];
      _items = (allItems ?? const [])
          .where((meta) => meta.item.name.toLowerCase().contains(lower))
          .take(8)
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Герой, игрок или предмет...',
                  isDense: true,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.muted,
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, child) {
                      if (value.text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(child: _results()),
          ],
        ),
      ),
    );
  }

  Widget _results() {
    if (_query.trim().isEmpty) {
      return const _SearchPlaceholder(
        icon: Icons.travel_explore_rounded,
        text: 'Поиск по героям, игрокам и предметам',
      );
    }
    if (_loading && _heroes.isEmpty && _players.isEmpty && _items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (_heroes.isEmpty && _players.isEmpty && _items.isEmpty) {
      return _SearchPlaceholder(
        icon: Icons.search_off_rounded,
        text: 'Ничего не найдено по запросу «${_query.trim()}»',
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        _section('Герои', Icons.sports_esports_rounded, [
          for (final hero in _heroes)
            ListTile(
              leading: HeroAvatar(hero: hero, size: 32),
              title: Text(hero.name),
              subtitle: hero.role.isEmpty ? null : Text(hero.role),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => HeroDetailScreen(hero: hero),
                  ),
                );
              },
            ),
        ]),
        _section('Игроки Steam', Icons.person_search_rounded, [
          for (final player in _players)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.surfaceLight,
                backgroundImage: player.avatarMedium.isEmpty
                    ? null
                    : NetworkImage(player.avatarMedium),
                child: player.avatarMedium.isEmpty
                    ? const Icon(Icons.person_rounded, size: 18)
                    : null,
              ),
              title: Text(player.personaName),
              subtitle: player.countryCode.isEmpty
                  ? Text('Steam ID: ${player.accountId}')
                  : Text('${player.countryCode} · ${player.accountId}'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlayerProfileScreen(
                      accountId: player.accountId,
                      personaName: player.personaName,
                      avatarUrl: player.avatarMedium,
                    ),
                  ),
                );
              },
            ),
        ]),
        _section('Предметы', Icons.inventory_2_rounded, [
          for (final meta in _items)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.surfaceLight,
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: 17,
                  color: AppColors.copper,
                ),
              ),
              title: Text(meta.item.name),
              subtitle: Text(
                'WR ${formatPercent(meta.winRate)} · ${formatCount(meta.matches)} матчей',
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ItemDetailScreen(item: meta),
                  ),
                );
              },
            ),
        ]),
      ],
    );
  }

  Widget _section(String title, IconData icon, List<Widget> tiles) {
    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(icon, size: 14, color: AppColors.copper),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        ...tiles,
      ],
    );
  }
}

class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppColors.muted),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
