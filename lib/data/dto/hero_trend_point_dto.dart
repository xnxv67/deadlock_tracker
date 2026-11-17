import 'json_utils.dart';

/// Точка тренда винрейта героя за день из `/v1/analytics/hero-stats?bucket=start_time_day`.
class HeroTrendPointDto {
  const HeroTrendPointDto({
    required this.heroId,
    required this.timestamp,
    required this.wins,
    required this.losses,
    required this.matches,
  });

  final int heroId;
  final int timestamp;
  final int wins;
  final int losses;
  final int matches;

  double get winRate => matches == 0 ? 0 : wins / matches;

  factory HeroTrendPointDto.fromJson(Map<String, dynamic> json) {
    final wins = jsonInt(json['wins']);
    final losses = jsonInt(json['losses']);
    final matches = jsonInt(json['matches'], wins + losses);
    return HeroTrendPointDto(
      heroId: jsonInt(json['hero_id']),
      timestamp: jsonInt(json['bucket']),
      wins: wins,
      losses: losses,
      matches: matches > 0 ? matches : wins + losses,
    );
  }
}
