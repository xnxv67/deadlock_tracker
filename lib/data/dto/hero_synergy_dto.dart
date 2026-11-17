import 'json_utils.dart';

/// Строка /v1/analytics/hero-synergy-stats.
class HeroSynergyDto {
  const HeroSynergyDto({
    required this.heroId1,
    required this.heroId2,
    required this.wins,
    required this.matches,
  });

  final int heroId1;
  final int heroId2;
  final int wins;
  final int matches;

  double get winRate => matches == 0 ? 0 : wins / matches;

  factory HeroSynergyDto.fromJson(Map<String, dynamic> json) {
    return HeroSynergyDto(
      heroId1: jsonInt(json['hero_id1']),
      heroId2: jsonInt(json['hero_id2']),
      wins: jsonInt(json['wins']),
      matches: jsonInt(json['matches_played'], jsonInt(json['matches'])),
    );
  }
}
