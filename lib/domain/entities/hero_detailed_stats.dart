import 'package:equatable/equatable.dart';

/// Детальная статистика героя за патч (как на deadlocklabs.gg):
/// винрейт, пикрейт, KDA, средний урон, net worth, last hits.
class HeroDetailedStats extends Equatable {
  const HeroDetailedStats({
    required this.matches,
    required this.wins,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.netWorth,
    required this.playerDamage,
    required this.playerDamageTaken,
    required this.lastHits,
    required this.denies,
  });

  final int matches;
  final int wins;

  /// Средние значения на матч.
  final double kills;
  final double deaths;
  final double assists;
  final double netWorth;
  final double playerDamage;
  final double playerDamageTaken;
  final double lastHits;
  final double denies;

  double get winRate => matches == 0 ? 0 : wins / matches;

  /// KDA-ратио (kills+assists)/deaths.
  double get kdaRatio {
    final killsAssists = kills + assists;
    return deaths == 0 ? killsAssists : killsAssists / deaths;
  }

  bool get hasData => matches > 0;

  @override
  List<Object?> get props => [
    matches,
    wins,
    kills,
    deaths,
    assists,
    netWorth,
    playerDamage,
    playerDamageTaken,
    lastHits,
    denies,
  ];
}
