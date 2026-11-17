import 'package:equatable/equatable.dart';

import 'meta_sort.dart';

abstract class MetaEvent extends Equatable {
  const MetaEvent();

  @override
  List<Object?> get props => [];
}

class MetaRequested extends MetaEvent {
  const MetaRequested();
}

class MetaRefreshRequested extends MetaEvent {
  const MetaRefreshRequested();
}

class MetaSortRequested extends MetaEvent {
  const MetaSortRequested(this.field);

  final MetaSortField field;

  @override
  List<Object?> get props => [field];
}
