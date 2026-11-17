import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/error_messages.dart';
import '../../../domain/repositories/hero_repository.dart';
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
      create: (context) =>
          HeroSearchBloc(context.read<HeroRepository>()),
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
                  HeroSearchStatus.failure => _FailureView(
                    state: state,
                  ),
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
              ? CircleAvatar(
                  backgroundImage: NetworkImage(hero.imageUrl),
                )
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
