import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../domain/repositories/items_repository.dart';
import 'items_event.dart';
import 'items_sort.dart';
import 'items_state.dart';

class ItemsBloc extends Bloc<ItemsEvent, ItemsState> {
  ItemsBloc(this._repository) : super(const ItemsState()) {
    on<ItemsRequested>(_onRequested);
    on<ItemsRefreshRequested>(_onRefresh);
    on<ItemsSortRequested>(_onSort);
  }

  final ItemsRepository _repository;

  Future<void> _onRequested(
    ItemsRequested event,
    Emitter<ItemsState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _onRefresh(
    ItemsRefreshRequested event,
    Emitter<ItemsState> emit,
  ) async {
    await _load(emit);
  }

  void _onSort(ItemsSortRequested event, Emitter<ItemsState> emit) {
    final sameField = state.sortField == event.field;
    final ascending = sameField
        ? !state.ascending
        : event.field == ItemSortField.name;

    emit(
      state.copyWith(
        items: sortItems(state.items, event.field, ascending),
        sortField: event.field,
        ascending: ascending,
      ),
    );
  }

  Future<void> _load(Emitter<ItemsState> emit) async {
    emit(state.copyWith(status: ItemsStatus.loading, clearError: true));

    try {
      final items = await _repository.getItems();
      emit(
        state.copyWith(
          status: ItemsStatus.success,
          items: sortItems(items, state.sortField, state.ascending),
          clearError: true,
        ),
      );
    } on AppException catch (error) {
      emit(state.copyWith(status: ItemsStatus.failure, error: error.type));
    } catch (_) {
      emit(
        state.copyWith(
          status: ItemsStatus.failure,
          error: AppErrorType.unknown,
        ),
      );
    }
  }
}
