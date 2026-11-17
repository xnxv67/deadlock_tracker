import 'package:equatable/equatable.dart';

import 'hero_builds_sort.dart';

abstract class HeroBuildsEvent extends Equatable {
  const HeroBuildsEvent();

  @override
  List<Object?> get props => [];
}

class HeroBuildsRequested extends HeroBuildsEvent {
  const HeroBuildsRequested(this.heroId);

  final int heroId;

  @override
  List<Object?> get props => [heroId];
}

class HeroBuildsRefreshRequested extends HeroBuildsEvent {
  const HeroBuildsRefreshRequested();
}

class HeroBuildsSortChanged extends HeroBuildsEvent {
  const HeroBuildsSortChanged(this.sort);

  final HeroBuildsSort sort;

  @override
  List<Object?> get props => [sort];
}
