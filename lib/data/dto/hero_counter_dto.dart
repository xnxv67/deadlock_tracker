import 'json_utils.dart';

/// Строка /v1/analytics/hero-counter-stats.
class HeroCounterDto {
  const HeroCounterDto({
    required this.heroId,
    required this.enemyHeroId,
    required this.wins,
    required this.matches,
  });

  final int heroId;
  final int enemyHeroId;
  final int wins;
  final int matches;

  double get winRate => matches == 0 ? 0 : wins / matches;

  factory HeroCounterDto.fromJson(Map<String, dynamic> json) {
    return HeroCounterDto(
      heroId: jsonInt(json['hero_id']),
      enemyHeroId: jsonInt(json['enemy_hero_id']),
      wins: jsonInt(json['wins']),
      matches: jsonInt(json['matches_played'], jsonInt(json['matches'])),
    );
  }
}
