import 'package:equatable/equatable.dart';

import '../../../core/error/app_exception.dart';
import '../../../domain/entities/hero_build.dart';
import 'hero_builds_sort.dart';

enum HeroBuildsStatus { initial, loading, success, failure }

class HeroBuildsState extends Equatable {
  const HeroBuildsState({
    this.status = HeroBuildsStatus.initial,
    this.heroId,
    this.builds = const [],
    this.sort = HeroBuildsSort.popularity,
    this.error,
  });

  final HeroBuildsStatus status;
  final int? heroId;
  final List<HeroBuild> builds;
  final HeroBuildsSort sort;
  final AppErrorType? error;

  bool get hasData => builds.isNotEmpty;

  HeroBuildsState copyWith({
    HeroBuildsStatus? status,
    int? heroId,
    List<HeroBuild>? builds,
    HeroBuildsSort? sort,
    AppErrorType? error,
    bool clearError = false,
  }) {
    return HeroBuildsState(
      status: status ?? this.status,
      heroId: heroId ?? this.heroId,
      builds: builds ?? this.builds,
      sort: sort ?? this.sort,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, heroId, builds, sort, error];
}
