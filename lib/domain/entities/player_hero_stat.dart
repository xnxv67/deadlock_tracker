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
  });

  final Hero hero;
  final int matches;
  final int wins;
  final int kills;
  final int deaths;
  final int assists;

  double get winRate => matches == 0 ? 0 : wins / matches;

  double get kda {
    if (deaths <= 0) {
      return (kills + assists).toDouble();
    }
    return (kills + assists) / deaths;
  }

  @override
  List<Object?> get props => [hero, matches, wins, kills, deaths, assists];
}
