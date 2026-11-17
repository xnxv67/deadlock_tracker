import 'package:equatable/equatable.dart';

import 'hero.dart';

/// Один матч из истории игрока.
class MatchRecord extends Equatable {
  const MatchRecord({
    required this.matchId,
    required this.hero,
    required this.isWin,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.durationSeconds,
    required this.startTime,
  });

  final int matchId;
  final Hero hero;
  final bool isWin;
  final int kills;
  final int deaths;
  final int assists;
  final int durationSeconds;
  final int startTime;

  double get kda {
    if (deaths <= 0) {
      return (kills + assists).toDouble();
    }
    return (kills + assists) / deaths;
  }

  @override
  List<Object?> get props => [
    matchId,
    hero,
    isWin,
    kills,
    deaths,
    assists,
    durationSeconds,
    startTime,
  ];
}
