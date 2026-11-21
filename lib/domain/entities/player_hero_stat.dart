import 'package:equatable/equatable.dart';

import 'hero.dart';

/// Статистика героя у конкретного игрока.
class PlayerHeroStat extends Equatable {
  const PlayerHeroStat({
    required this.hero,
    required this.matches,
    required this.wins,
    required this.kills,
    required this.deaths,
    required this.assists,
    this.mvpFirst = 0,
    this.mvpSecond = 0,
    this.mvpThird = 0,
    this.mvpRatedMatches = 0,
    this.accuracy = 0,
    this.critShotRate = 0,
    this.netWorthPerMin = 0,
    this.lastHitsPerMin = 0,
    this.deniesPerMin = 0,
    this.damagePerMin = 0,
    this.permanentBuffs = 0,
    this.timePlayedSeconds = 0,
    this.lastPlayed = 0,
    this.endingLevel = 0,
  });

  final Hero hero;
  final int matches;
  final int wins;
  final int kills;
  final int deaths;
  final int assists;

  final int mvpFirst;
  final int mvpSecond;
  final int mvpThird;
  final int mvpRatedMatches;
  final double accuracy;
  final double critShotRate;
  final double netWorthPerMin;
  final double lastHitsPerMin;
  final double deniesPerMin;
  final double damagePerMin;
  final int permanentBuffs;
  final int timePlayedSeconds;
  final int lastPlayed;
  final double endingLevel;

  double get winRate => matches == 0 ? 0 : wins / matches;

  double get kda {
    if (deaths <= 0) {
      return (kills + assists).toDouble();
    }
    return (kills + assists) / deaths;
  }

  int get mvpTotal => mvpFirst + mvpSecond + mvpThird;

  @override
  List<Object?> get props => [
    hero,
    matches,
    wins,
    kills,
    deaths,
    assists,
    mvpFirst,
    mvpSecond,
    mvpThird,
    mvpRatedMatches,
    accuracy,
    critShotRate,
    netWorthPerMin,
    lastHitsPerMin,
    deniesPerMin,
    damagePerMin,
    permanentBuffs,
    timePlayedSeconds,
    lastPlayed,
    endingLevel,
  ];
}
