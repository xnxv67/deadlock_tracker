import 'json_utils.dart';

/// Строка `/v1/analytics/lane-matchup-stats` с группировкой по линии.
class LaneMatchupDto {
  const LaneMatchupDto({
    required this.laneId,
    required this.wins,
    required this.matches,
    required this.sampleMatches,
    required this.sampleTimeSeconds,
    required this.netWorthDiff,
  });

  final int laneId;
  final int wins;
  final int matches;
  final int sampleMatches;
  final int sampleTimeSeconds;
  final double netWorthDiff;

  double get winRate => matches == 0 ? 0 : wins / matches;

  factory LaneMatchupDto.fromJson(Map<String, dynamic> json) {
    return LaneMatchupDto(
      laneId: jsonInt(json['assigned_lane']),
      wins: jsonInt(json['wins']),
      matches: jsonInt(json['matches_played']),
      sampleMatches: jsonInt(json['sample_matches']),
      sampleTimeSeconds: jsonInt(json['sample_time_s'], 600),
      netWorthDiff: jsonDouble(json['net_worth_diff']),
    );
  }
}
