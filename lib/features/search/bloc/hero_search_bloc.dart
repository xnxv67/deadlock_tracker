import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_event_debouncer/bloc_event_debouncer.dart';

import '../../../core/error/app_exception.dart';
import '../../../domain/repositories/hero_repository.dart';
import 'hero_search_event.dart';
import 'hero_search_state.dart';

/// BLoC поиска героев с debounce 300 мс.
///
/// События ввода склеиваются: запрос уходит только после паузы в наборе,
/// поэтому API не получает запрос на каждую букву.
class HeroSearchBloc extends Bloc<HeroSearchEvent, HeroSearchState> {
  HeroSearchBloc(this._repository) : super(const HeroSearchState()) {
    on<HeroSearchQueryChanged>(
      _onQueryChanged,
      transformer: debounce(const Duration(milliseconds: 300)),
    );
  }

  final HeroRepository _repository;

  /// Идентификатор актуального запроса для защиты от устаревших ответов.
  int _requestId = 0;

  Future<void> _onQueryChanged(
    HeroSearchQueryChanged event,
    Emitter<HeroSearchState> emit,
  ) async {
    final query = event.query.trim();
    final requestId = ++_requestId;

    if (query.isEmpty) {
      emit(const HeroSearchState());
      return;
    }

    emit(
      state.copyWith(
        status: HeroSearchStatus.loading,
        query: query,
        heroes: const [],
        clearError: true,
      ),
    );

    try {
      final heroes = await _repository.searchHeroes(query);
      if (isClosed || requestId != _requestId) {
        return;
      }
      emit(
        state.copyWith(
          status: HeroSearchStatus.success,
          query: query,
          heroes: heroes,
          clearError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed || requestId != _requestId) {
        return;
      }
      emit(
        state.copyWith(
          status: HeroSearchStatus.failure,
          query: query,
          heroes: const [],
          error: error.type,
        ),
      );
    } catch (_) {
      if (isClosed || requestId != _requestId) {
        return;
      }
      emit(
        state.copyWith(
          status: HeroSearchStatus.failure,
          query: query,
          heroes: const [],
          error: AppErrorType.unknown,
        ),
      );
    }
  }
}
