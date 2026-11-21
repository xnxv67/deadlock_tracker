import 'json_utils.dart';

/// Строка `/v1/analytics/lane-soul-curve`.
class LaneSoulCurveDto {
  const LaneSoulCurveDto({
    required this.laneId,
    required this.sampleTimes,
    required this.diffs,
    required this.sampleMatches,
    required this.matches,
  });

  final int laneId;
  final List<int> sampleTimes;
  final List<double> diffs;
  final List<int> sampleMatches;
  final int matches;

  factory LaneSoulCurveDto.fromJson(Map<String, dynamic> json) {
    return LaneSoulCurveDto(
      laneId: jsonInt(json['assigned_lane']),
      sampleTimes: jsonList(json['sample_times_s'])
          .map((value) => jsonInt(value))
          .toList(growable: false),
      diffs: jsonList(json['net_worth_diff'])
          .map((value) => jsonDouble(value))
          .toList(growable: false),
      sampleMatches: jsonList(json['sample_matches'])
          .map((value) => jsonInt(value))
          .toList(growable: false),
      matches: jsonInt(json['matches_played']),
    );
  }
}
