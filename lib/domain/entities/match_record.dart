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
    this.heroDamage,
    this.buildingDamage,
    this.netWorth,
    this.lastHits,
    this.denies,
  });

  final int matchId;
  final Hero hero;
  final bool isWin;
  final int kills;
  final int deaths;
  final int assists;
  final int durationSeconds;
  final int startTime;

  /// Урон по героям. `null` — API не отдал поле.
  final int? heroDamage;

  /// Урон по строениям. `null` — API не отдал поле.
  final int? buildingDamage;

  /// Net worth, last hits и denies из истории матчей (если есть).
  final int? netWorth;
  final int? lastHits;
  final int? denies;

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
    heroDamage,
    buildingDamage,
    netWorth,
    lastHits,
    denies,
  ];
}
