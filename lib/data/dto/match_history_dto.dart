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
    this.heroDamage,
    this.buildingDamage,
    this.netWorth,
    this.lastHits,
    this.denies,
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

  /// Урон по героям и строениям. В текущей версии match-history этих
  /// полей нет — тогда `null`, а UI покажет «Н/Д».
  final int? heroDamage;
  final int? buildingDamage;

  final int? netWorth;
  final int? lastHits;
  final int? denies;

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
      heroDamage: _optionalInt(
        json['player_damage'] ?? json['player_hero_damage'],
      ),
      buildingDamage: _optionalInt(
        json['player_damage_to_buildings'] ??
            json['player_damage_buildings'] ??
            json['player_objective_damage'],
      ),
      netWorth: _optionalInt(json['net_worth']),
      lastHits: _optionalInt(json['last_hits']),
      denies: _optionalInt(json['denies']),
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
      if (heroDamage != null) 'hd': heroDamage,
      if (buildingDamage != null) 'bd': buildingDamage,
      if (netWorth != null) 'nw': netWorth,
      if (lastHits != null) 'lh': lastHits,
      if (denies != null) 'dn': denies,
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
      heroDamage: _optionalInt(json['hd']),
      buildingDamage: _optionalInt(json['bd']),
      netWorth: _optionalInt(json['nw']),
      lastHits: _optionalInt(json['lh']),
      denies: _optionalInt(json['dn']),
    );
  }
}

/// Число или `null`: пустая строка и отсутствующее поле — не данные.
int? _optionalInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) {
      return null;
    }
    return int.tryParse(text) ?? double.tryParse(text)?.toInt();
  }
  return null;
}
