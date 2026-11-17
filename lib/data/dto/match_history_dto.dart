import 'json_utils.dart';

/// Строка `/v1/players/{account_id}/match-history`.
class MatchHistoryDto {
  const MatchHistoryDto({
    required this.matchId,
    required this.heroId,
    required this.startTime,
    required this.isWin,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.durationSeconds,
    required this.abandonedTimeSeconds,
  });

  final int matchId;
  final int heroId;
  final int startTime;
  final bool isWin;
  final int kills;
  final int deaths;
  final int assists;
  final int durationSeconds;
  final int abandonedTimeSeconds;

  factory MatchHistoryDto.fromJson(Map<String, dynamic> json) {
    final playerTeam = jsonInt(json['player_team']);
    final matchResult = jsonInt(json['match_result']);

    return MatchHistoryDto(
      matchId: jsonInt(json['match_id']),
      heroId: jsonInt(json['hero_id']),
      startTime: jsonInt(json['start_time']),
      // Поле `player_match_outcome` заполнено не у всех матчей,
      // поэтому победа определяется сравнением команд.
      isWin: playerTeam == matchResult,
      kills: jsonInt(json['player_kills']),
      deaths: jsonInt(json['player_deaths']),
      assists: jsonInt(json['player_assists']),
      durationSeconds: jsonInt(json['match_duration_s']),
      abandonedTimeSeconds: jsonInt(json['abandoned_time_s']),
    );
  }

  Map<String, dynamic> toCompactJson() {
    return {
      'm': matchId,
      'h': heroId,
      't': startTime,
      'k': kills,
      'd': deaths,
      'a': assists,
      's': durationSeconds,
      'w': isWin ? 1 : 0,
    };
  }

  factory MatchHistoryDto.fromCompactJson(Map<String, dynamic> json) {
    return MatchHistoryDto(
      matchId: jsonInt(json['m']),
      heroId: jsonInt(json['h']),
      startTime: jsonInt(json['t']),
      isWin: jsonInt(json['w']) == 1,
      kills: jsonInt(json['k']),
      deaths: jsonInt(json['d']),
      assists: jsonInt(json['a']),
      durationSeconds: jsonInt(json['s']),
      abandonedTimeSeconds: 0,
    );
  }
}
