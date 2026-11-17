import 'package:equatable/equatable.dart';

import '../../../domain/repositories/leaderboard_repository.dart';

abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object?> get props => [];
}

class LeaderboardRequested extends LeaderboardEvent {
  const LeaderboardRequested();
}

class LeaderboardRefreshRequested extends LeaderboardEvent {
  const LeaderboardRefreshRequested();
}

class LeaderboardRegionChanged extends LeaderboardEvent {
  const LeaderboardRegionChanged(this.region);

  final LeaderboardRegion region;

  @override
  List<Object?> get props => [region];
}
