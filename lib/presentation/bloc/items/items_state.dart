import 'package:equatable/equatable.dart';

import '../../../core/error/app_exception.dart';
import '../../../domain/entities/item_meta.dart';
import 'items_sort.dart';

enum ItemsStatus { initial, loading, success, failure }

class ItemsState extends Equatable {
  const ItemsState({
    this.status = ItemsStatus.initial,
    this.items = const [],
    this.error,
    this.sortField = ItemSortField.winRate,
    this.ascending = false,
  });

  final ItemsStatus status;
  final List<ItemMeta> items;
  final AppErrorType? error;
  final ItemSortField sortField;
  final bool ascending;

  bool get hasData => items.isNotEmpty;

  ItemsState copyWith({
    ItemsStatus? status,
    List<ItemMeta>? items,
    AppErrorType? error,
    bool clearError = false,
    ItemSortField? sortField,
    bool? ascending,
  }) {
    return ItemsState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
      sortField: sortField ?? this.sortField,
      ascending: ascending ?? this.ascending,
    );
  }

  @override
  List<Object?> get props => [status, items, error, sortField, ascending];
}
