import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../domain/repositories/hero_repository.dart';
import '../../../domain/entities/hero_build.dart';
import 'hero_builds_event.dart';
import 'hero_builds_sort.dart';
import 'hero_builds_state.dart';

class HeroBuildsBloc extends Bloc<HeroBuildsEvent, HeroBuildsState> {
  HeroBuildsBloc(this._repository) : super(const HeroBuildsState()) {
    on<HeroBuildsRequested>(_onRequested);
    on<HeroBuildsRefreshRequested>(_onRefresh);
    on<HeroBuildsSortChanged>(_onSortChanged);
  }

  final HeroRepository _repository;

  Future<void> _onRequested(
    HeroBuildsRequested event,
    Emitter<HeroBuildsState> emit,
  ) async {
    await _load(event.heroId, emit);
  }

  Future<void> _onRefresh(
    HeroBuildsRefreshRequested event,
    Emitter<HeroBuildsState> emit,
  ) async {
    final heroId = state.heroId;
    if (heroId == null) {
      return;
    }
    await _load(heroId, emit);
  }

  void _onSortChanged(
    HeroBuildsSortChanged event,
    Emitter<HeroBuildsState> emit,
  ) {
    emit(
      state.copyWith(
        sort: event.sort,
        builds: _sorted(state.builds, event.sort),
      ),
    );
  }

  List<HeroBuild> _sorted(List<HeroBuild> builds, HeroBuildsSort sort) {
    final list = [...builds];
    switch (sort) {
      case HeroBuildsSort.popularity:
        list.sort((a, b) => b.matches.compareTo(a.matches));
      case HeroBuildsSort.winRate:
        list.sort((a, b) {
          final cmp = b.winRate.compareTo(a.winRate);
          if (cmp != 0) {
            return cmp;
          }
          return b.matches.compareTo(a.matches);
        });
    }
    return list;
  }

  Future<void> _load(int heroId, Emitter<HeroBuildsState> emit) async {
    emit(
      state.copyWith(
        status: HeroBuildsStatus.loading,
        heroId: heroId,
        clearError: true,
      ),
    );

    try {
      final builds = await _repository.getBuilds(heroId);
      emit(
        state.copyWith(
          status: HeroBuildsStatus.success,
          builds: _sorted(builds, state.sort),
          clearError: true,
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(status: HeroBuildsStatus.failure, error: error.type));
    } catch (_) {
      emit(
        state.copyWith(
          status: HeroBuildsStatus.failure,
          error: AppErrorType.unknown,
        ),
      );
    }
  }
}
