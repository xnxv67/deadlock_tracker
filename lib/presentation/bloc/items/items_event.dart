import 'package:equatable/equatable.dart';

import 'items_sort.dart';

abstract class ItemsEvent extends Equatable {
  const ItemsEvent();

  @override
  List<Object?> get props => [];
}

class ItemsRequested extends ItemsEvent {
  const ItemsRequested();
}

class ItemsRefreshRequested extends ItemsEvent {
  const ItemsRefreshRequested();
}

class ItemsSortRequested extends ItemsEvent {
  const ItemsSortRequested(this.field);

  final ItemSortField field;

  @override
  List<Object?> get props => [field];
}
