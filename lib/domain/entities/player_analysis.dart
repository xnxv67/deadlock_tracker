/// Аналитика игрока из аналитических эндпоинтов Deadlock API.
class PlayerAnalysis {
  const PlayerAnalysis({
    required this.lanes,
    required this.soulCurve,
    required this.curve,
    required this.metrics,
  });

  final List<LanePerformance> lanes;
  final List<LaneSoulPoint> soulCurve;
  final List<PlayerCurvePoint> curve;
  final Map<String, MetricRange> metrics;

  bool get isEmpty =>
      lanes.isEmpty && soulCurve.isEmpty && curve.isEmpty && metrics.isEmpty;

  bool get hasLanes => lanes.isNotEmpty;

  bool get hasCurve => curve.isNotEmpty;

  bool get hasMetrics => metrics.isNotEmpty;
}

/// Итоговые показатели игрока на конкретной линии.
class LanePerformance {
  const LanePerformance({
    required this.laneId,
    required this.matches,
    required this.wins,
    required this.netWorthDiff,
  });

  final int laneId;
  final int matches;
  final int wins;
  final double netWorthDiff;

  double get winRate => matches == 0 ? 0 : wins / matches;

  int get losses => (matches - wins).clamp(0, matches);
}

/// Точка средней разницы душ на линии.
class LaneSoulPoint {
  const LaneSoulPoint({required this.seconds, required this.netWorthDiff});

  final int seconds;
  final double netWorthDiff;
}

/// Точка кривой средних показателей игрока по ходу матча.
class PlayerCurvePoint {
  const PlayerCurvePoint({
    required this.gameTime,
    required this.netWorth,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.playerDamage,
    required this.creepKills,
    required this.denies,
  });

  /// Процент матча (0–100) при `resolution=10`.
  final int gameTime;
  final double netWorth;
  final double kills;
  final double deaths;
  final double assists;
  final double playerDamage;
  final double creepKills;
  final double denies;
}

/// Разброс метрики по матчам игрока.
class MetricRange {
  const MetricRange({
    required this.key,
    required this.avg,
    required this.std,
    required this.p25,
    required this.p50,
    required this.p75,
  });

  final String key;
  final double avg;
  final double std;
  final double p25;
  final double p50;
  final double p75;
}
