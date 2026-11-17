import 'json_utils.dart';

/// Строка `/v1/analytics/hero-build-stats/{hero_id}`.
class HeroBuildStatsDto {
  const HeroBuildStatsDto({
    required this.heroId,
    required this.buildId,
    required this.wins,
    required this.losses,
    required this.matches,
    required this.players,
    required this.avgBadge,
  });

  final int heroId;
  final int buildId;
  final int wins;
  final int losses;
  final int matches;
  final int players;
  final double avgBadge;

  factory HeroBuildStatsDto.fromJson(Map<String, dynamic> json) {
    final wins = jsonInt(json['wins']);
    final losses = jsonInt(json['losses']);
    final matches = jsonInt(json['matches'], wins + losses);

    return HeroBuildStatsDto(
      heroId: jsonInt(json['hero_id']),
      buildId: jsonInt(json['hero_build_id']),
      wins: wins,
      losses: losses,
      matches: matches > 0 ? matches : wins + losses,
      players: jsonInt(json['players']),
      avgBadge: jsonDouble(json['avg_average_badge']),
    );
  }

  double get winRate => matches == 0 ? 0 : wins / matches;
}
