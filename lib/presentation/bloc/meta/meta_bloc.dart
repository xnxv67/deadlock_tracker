import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../domain/repositories/hero_repository.dart';
import 'meta_event.dart';
import 'meta_sort.dart';
import 'meta_state.dart';

class MetaBloc extends Bloc<MetaEvent, MetaState> {
  MetaBloc(this._repository) : super(const MetaState()) {
    on<MetaRequested>(_onRequested);
    on<MetaRefreshRequested>(_onRefresh);
    on<MetaSortRequested>(_onSort);
  }

  final HeroRepository _repository;

  Future<void> _onRequested(
    MetaRequested event,
    Emitter<MetaState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _onRefresh(
    MetaRefreshRequested event,
    Emitter<MetaState> emit,
  ) async {
    await _load(emit);
  }

  void _onSort(MetaSortRequested event, Emitter<MetaState> emit) {
    final sameField = state.sortField == event.field;
    final ascending = sameField
        ? !state.ascending
        : event.field == MetaSortField.name;

    emit(
      state.copyWith(
        heroes: sortHeroes(state.heroes, event.field, ascending),
        sortField: event.field,
        ascending: ascending,
      ),
    );
  }

  Future<void> _load(Emitter<MetaState> emit) async {
    emit(state.copyWith(status: MetaStatus.loading, clearError: true));

    try {
      final heroes = await _repository.getMeta();
      emit(
        state.copyWith(
          status: MetaStatus.success,
          heroes: sortHeroes(heroes, state.sortField, state.ascending),
          clearError: true,
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(status: MetaStatus.failure, error: error.type));
    } catch (_) {
      emit(
        state.copyWith(status: MetaStatus.failure, error: AppErrorType.unknown),
      );
    }
  }
}
