import 'json_utils.dart';

/// Строка `/v1/players/hero-stats?account_ids=...`.
class PlayerHeroStatsDto {
  const PlayerHeroStatsDto({
    required this.accountId,
    required this.heroId,
    required this.matches,
    required this.wins,
    required this.kills,
    required this.deaths,
    required this.assists,
  });

  final int accountId;
  final int heroId;
  final int matches;
  final int wins;
  final int kills;
  final int deaths;
  final int assists;

  factory PlayerHeroStatsDto.fromJson(Map<String, dynamic> json) {
    return PlayerHeroStatsDto(
      accountId: jsonInt(json['account_id']),
      heroId: jsonInt(json['hero_id']),
      matches: jsonInt(json['matches_played']),
      wins: jsonInt(json['wins']),
      kills: jsonInt(json['kills']),
      deaths: jsonInt(json['deaths']),
      assists: jsonInt(json['assists']),
    );
  }

  double get winRate => matches == 0 ? 0 : wins / matches;

  double get kda {
    if (deaths <= 0) {
      return (kills + assists).toDouble();
    }
    return (kills + assists) / deaths;
  }
}
