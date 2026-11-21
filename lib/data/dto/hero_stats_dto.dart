import 'json_utils.dart';

/// Ответ `/v1/analytics/hero-stats`.
///
/// Содержит не только wins/losses/matches, но и агрегированные
/// KDA, урон, net worth и прочие тоталы — из них считаются средние
/// значения на матч (как на deadlocklabs.gg).
class HeroStatsDto {
  const HeroStatsDto({
    required this.heroId,
    required this.wins,
    required this.losses,
    required this.matches,
    this.totalKills = 0,
    this.totalDeaths = 0,
    this.totalAssists = 0,
    this.totalNetWorth = 0,
    this.totalLastHits = 0,
    this.totalDenies = 0,
    this.totalPlayerDamage = 0,
    this.totalPlayerDamageTaken = 0,
  });

  final int heroId;
  final int wins;
  final int losses;
  final int matches;

  final int totalKills;
  final int totalDeaths;
  final int totalAssists;
  final int totalNetWorth;
  final int totalLastHits;
  final int totalDenies;
  final int totalPlayerDamage;
  final int totalPlayerDamageTaken;

  factory HeroStatsDto.fromJson(Map<String, dynamic> json) {
    final wins = jsonInt(json['wins']);
    final losses = jsonInt(json['losses']);
    final matches = jsonInt(json['matches'], wins + losses);

    return HeroStatsDto(
      heroId: jsonInt(json['hero_id']),
      wins: wins,
      losses: losses,
      matches: matches > 0 ? matches : wins + losses,
      totalKills: jsonInt(json['total_kills']),
      totalDeaths: jsonInt(json['total_deaths']),
      totalAssists: jsonInt(json['total_assists']),
      totalNetWorth: jsonInt(json['total_net_worth']),
      totalLastHits: jsonInt(json['total_last_hits']),
      totalDenies: jsonInt(json['total_denies']),
      totalPlayerDamage: jsonInt(json['total_player_damage']),
      totalPlayerDamageTaken: jsonInt(json['total_player_damage_taken']),
    );
  }

  double get winRate => matches == 0 ? 0 : wins / matches;

  /// Средние значения на матч.
  double get avgKills => matches == 0 ? 0 : totalKills / matches;
  double get avgDeaths => matches == 0 ? 0 : totalDeaths / matches;
  double get avgAssists => matches == 0 ? 0 : totalAssists / matches;
  double get avgNetWorth => matches == 0 ? 0 : totalNetWorth / matches;
  double get avgLastHits => matches == 0 ? 0 : totalLastHits / matches;
  double get avgDenies => matches == 0 ? 0 : totalDenies / matches;
  double get avgPlayerDamage => matches == 0 ? 0 : totalPlayerDamage / matches;
  double get avgPlayerDamageTaken =>
      matches == 0 ? 0 : totalPlayerDamageTaken / matches;

  /// KDA-ратио (kills+assists)/deaths с защитой от деления на ноль.
  double get kdaRatio {
    final killsAssists = avgKills + avgAssists;
    return avgDeaths == 0 ? killsAssists : killsAssists / avgDeaths;
  }
}
