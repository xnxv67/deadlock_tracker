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
    this.mvpFirst = 0,
    this.mvpSecond = 0,
    this.mvpThird = 0,
    this.mvpRatedMatches = 0,
    this.accuracy = 0,
    this.critShotRate = 0,
    this.netWorthPerMin = 0,
    this.lastHitsPerMin = 0,
    this.deniesPerMin = 0,
    this.damagePerMin = 0,
    this.permanentBuffs = 0,
    this.timePlayedSeconds = 0,
    this.lastPlayed = 0,
    this.endingLevel = 0,
  });

  final int accountId;
  final int heroId;
  final int matches;
  final int wins;
  final int kills;
  final int deaths;
  final int assists;

  final int mvpFirst;
  final int mvpSecond;
  final int mvpThird;
  final int mvpRatedMatches;
  final double accuracy;
  final double critShotRate;
  final double netWorthPerMin;
  final double lastHitsPerMin;
  final double deniesPerMin;
  final double damagePerMin;
  final int permanentBuffs;
  final int timePlayedSeconds;
  final int lastPlayed;
  final double endingLevel;

  factory PlayerHeroStatsDto.fromJson(Map<String, dynamic> json) {
    final mvpCounts = jsonList(json['mvp_rank_counts']);
    int mvpAt(int index) {
      if (index >= mvpCounts.length) {
        return 0;
      }
      return jsonInt(mvpCounts[index]);
    }

    return PlayerHeroStatsDto(
      accountId: jsonInt(json['account_id']),
      heroId: jsonInt(json['hero_id']),
      matches: jsonInt(json['matches_played']),
      wins: jsonInt(json['wins']),
      kills: jsonInt(json['kills']),
      deaths: jsonInt(json['deaths']),
      assists: jsonInt(json['assists']),
      mvpFirst: mvpAt(0),
      mvpSecond: mvpAt(1),
      mvpThird: mvpAt(2),
      mvpRatedMatches: jsonInt(json['mvp_rated_matches']),
      accuracy: jsonDouble(json['accuracy']),
      critShotRate: jsonDouble(json['crit_shot_rate']),
      netWorthPerMin: jsonDouble(json['networth_per_min']),
      lastHitsPerMin: jsonDouble(json['last_hits_per_min']),
      deniesPerMin: jsonDouble(json['denies_per_min']),
      damagePerMin: jsonDouble(json['damage_per_min']),
      permanentBuffs: jsonInt(json['permanent_buffs']),
      timePlayedSeconds: jsonInt(json['time_played']),
      lastPlayed: jsonInt(json['last_played']),
      endingLevel: jsonDouble(json['ending_level']),
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
