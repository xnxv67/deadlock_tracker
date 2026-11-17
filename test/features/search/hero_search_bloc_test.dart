import 'dart:async';

import 'package:deadlock_tracker/core/error/app_exception.dart';
import 'package:deadlock_tracker/data/models/hero.dart';
import 'package:deadlock_tracker/domain/repositories/hero_repository.dart';
import 'package:deadlock_tracker/features/search/bloc/hero_search_bloc.dart';
import 'package:deadlock_tracker/features/search/bloc/hero_search_event.dart';
import 'package:deadlock_tracker/features/search/bloc/hero_search_state.dart';
import 'package:flutter_test/flutter_test.dart';

const _abrams = Hero(
  id: 1,
  name: 'Abrams',
  role: 'Tank',
  imageUrl: '',
  cardUrl: '',
);

void main() {
  test('debounce склеивает быстрые события и ищет последний запрос', () async {
    final repository = _FakeHeroRepository(heroes: const [_abrams]);
    final bloc = HeroSearchBloc(repository);
    addTearDown(bloc.close);

    final statuses = <HeroSearchStatus>[];
    final success = Completer<HeroSearchState>();
    final subscription = bloc.stream.listen((state) {
      statuses.add(state.status);
      if (state.status == HeroSearchStatus.success && !success.isCompleted) {
        success.complete(state);
      }
    });
    addTearDown(subscription.cancel);

    bloc.add(const HeroSearchQueryChanged('a'));
    bloc.add(const HeroSearchQueryChanged('ab'));

    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(bloc.state.status, HeroSearchStatus.initial);

    final state = await success.future.timeout(const Duration(seconds: 2));
    expect(repository.queries, ['ab']);
    expect(statuses, [
      HeroSearchStatus.loading,
      HeroSearchStatus.success,
    ]);
    expect(state.heroes.single, _abrams);
  });

  test('ошибку репозитория отдаёт как failure с типом ошибки', () async {
    final repository = _FakeHeroRepository(
      error: const AppException(AppErrorType.timeout),
    );
    final bloc = HeroSearchBloc(repository);
    addTearDown(bloc.close);

    final failure = Completer<HeroSearchState>();
    final subscription = bloc.stream.listen((state) {
      if (state.status == HeroSearchStatus.failure && !failure.isCompleted) {
        failure.complete(state);
      }
    });
    addTearDown(subscription.cancel);

    bloc.add(const HeroSearchQueryChanged('haze'));

    final state = await failure.future.timeout(const Duration(seconds: 2));
    expect(state.error, AppErrorType.timeout);
    expect(state.heroes, isEmpty);
  });
}

class _FakeHeroRepository implements HeroRepository {
  _FakeHeroRepository({this.heroes = const [], this.error});

  final List<Hero> heroes;
  final Object? error;
  final List<String> queries = [];

  @override
  Future<List<Hero>> searchHeroes(String query) async {
    queries.add(query);
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return heroes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
