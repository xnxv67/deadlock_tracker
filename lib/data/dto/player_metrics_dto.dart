import 'json_utils.dart';

/// Распределение одной метрики игрока по матчам.
class MetricDistributionDto {
  const MetricDistributionDto({
    required this.avg,
    required this.std,
    required this.p25,
    required this.p50,
    required this.p75,
  });

  final double avg;
  final double std;
  final double p25;
  final double p50;
  final double p75;

  factory MetricDistributionDto.fromJson(Map<String, dynamic> json) {
    return MetricDistributionDto(
      avg: jsonDouble(json['avg']),
      std: jsonDouble(json['std']),
      p25: jsonDouble(json['percentile25']),
      p50: jsonDouble(json['percentile50']),
      p75: jsonDouble(json['percentile75']),
    );
  }
}

/// Ответ `/v1/analytics/player-stats/metrics` без bucket.
class PlayerMetricsDto {
  const PlayerMetricsDto(this.metrics);

  static const List<String> keys = [
    'kda',
    'kd',
    'kills',
    'deaths',
    'assists',
    'net_worth',
    'net_worth_per_min',
    'last_hits',
    'denies',
    'accuracy',
    'crit_shot_rate',
    'player_damage',
    'player_damage_per_min',
    'player_damage_taken_per_min',
  ];

  final Map<String, MetricDistributionDto> metrics;

  factory PlayerMetricsDto.fromJson(Map<String, dynamic> json) {
    final result = <String, MetricDistributionDto>{};
    for (final key in keys) {
      final map = jsonMap(json[key]);
      if (map.isNotEmpty) {
        result[key] = MetricDistributionDto.fromJson(map);
      }
    }
    return PlayerMetricsDto(result);
  }

  bool get isEmpty => metrics.isEmpty;
}
