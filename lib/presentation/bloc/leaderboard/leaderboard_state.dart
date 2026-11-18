import 'package:equatable/equatable.dart';

import '../../../core/error/app_exception.dart';
import '../../../domain/entities/leaderboard_player.dart';
import '../../../domain/repositories/leaderboard_repository.dart';

enum LeaderboardStatus { initial, loading, success, failure }

class LeaderboardState extends Equatable {
  const LeaderboardState({
    this.status = LeaderboardStatus.initial,
    this.players = const [],
    this.error,
    this.region = LeaderboardRegion.europe,
  });

  final LeaderboardStatus status;
  final List<LeaderboardPlayer> players;
  final AppErrorType? error;
  final LeaderboardRegion region;

  bool get hasData => players.isNotEmpty;

  LeaderboardState copyWith({
    LeaderboardStatus? status,
    List<LeaderboardPlayer>? players,
    AppErrorType? error,
    bool clearError = false,
    LeaderboardRegion? region,
  }) {
    return LeaderboardState(
      status: status ?? this.status,
      players: players ?? this.players,
      error: clearError ? null : (error ?? this.error),
      region: region ?? this.region,
    );
  }

  @override
  List<Object?> get props => [status, players, error, region];
}
