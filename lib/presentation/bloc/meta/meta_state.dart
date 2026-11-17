import 'package:equatable/equatable.dart';

import '../../../core/error/app_exception.dart';
import '../../../domain/entities/hero_meta.dart';
import 'meta_sort.dart';

enum MetaStatus { initial, loading, success, failure }

class MetaState extends Equatable {
  const MetaState({
    this.status = MetaStatus.initial,
    this.heroes = const [],
    this.error,
    this.sortField = MetaSortField.winRate,
    this.ascending = false,
  });

  final MetaStatus status;
  final List<HeroMeta> heroes;
  final AppErrorType? error;
  final MetaSortField sortField;
  final bool ascending;

  bool get hasData => heroes.isNotEmpty;

  MetaState copyWith({
    MetaStatus? status,
    List<HeroMeta>? heroes,
    AppErrorType? error,
    bool clearError = false,
    MetaSortField? sortField,
    bool? ascending,
  }) {
    return MetaState(
      status: status ?? this.status,
      heroes: heroes ?? this.heroes,
      error: clearError ? null : (error ?? this.error),
      sortField: sortField ?? this.sortField,
      ascending: ascending ?? this.ascending,
    );
  }

  @override
  List<Object?> get props => [status, heroes, error, sortField, ascending];
}
