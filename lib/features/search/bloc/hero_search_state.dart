import 'package:equatable/equatable.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/hero.dart';

enum HeroSearchStatus { initial, loading, success, failure }

class HeroSearchState extends Equatable {
  const HeroSearchState({
    this.status = HeroSearchStatus.initial,
    this.query = '',
    this.heroes = const <Hero>[],
    this.error,
  });

  final HeroSearchStatus status;
  final String query;
  final List<Hero> heroes;
  final AppErrorType? error;

  HeroSearchState copyWith({
    HeroSearchStatus? status,
    String? query,
    List<Hero>? heroes,
    AppErrorType? error,
    bool clearError = false,
  }) {
    return HeroSearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      heroes: heroes ?? this.heroes,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, query, heroes, error];
}
