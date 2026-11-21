import 'json_utils.dart';

/// Точка `/v1/analytics/player-performance-curve`.
class PerformanceCurveDto {
  const PerformanceCurveDto({
    required this.gameTime,
    required this.netWorth,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.playerDamage,
    required this.creepKills,
    required this.denies,
    required this.samples,
  });

  final int gameTime;
  final double netWorth;
  final double kills;
  final double deaths;
  final double assists;
  final double playerDamage;
  final double creepKills;
  final double denies;
  final int samples;

  factory PerformanceCurveDto.fromJson(Map<String, dynamic> json) {
    return PerformanceCurveDto(
      gameTime: jsonInt(json['game_time']),
      netWorth: jsonDouble(json['net_worth_avg']),
      kills: jsonDouble(json['kills_avg']),
      deaths: jsonDouble(json['deaths_avg']),
      assists: jsonDouble(json['assists_avg']),
      playerDamage: jsonDouble(json['player_damage_avg']),
      creepKills: jsonDouble(json['creep_kills_avg']),
      denies: jsonDouble(json['denies_avg']),
      samples: jsonInt(json['samples']),
    );
  }
}
