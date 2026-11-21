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
    this.heroLevel = 0,
    this.matchMode = 0,
    this.gameMode = 0,
    this.rankedBadge,
    this.rankedDelta,
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

  /// Уровень героя к концу матча.
  final int heroLevel;

  /// Режим матча и режим игры из API.
  final int matchMode;
  final int gameMode;

  /// Ранговый бейдж после матча и изменение прогресса ранга.
  final int? rankedBadge;
  final int? rankedDelta;

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
      heroLevel: jsonInt(json['hero_level']),
      matchMode: jsonInt(json['match_mode']),
      gameMode: jsonInt(json['game_mode']),
      rankedBadge: _optionalInt(json['ranked_display_badge']),
      rankedDelta: _optionalInt(json['ranked_delta']),
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
      if (heroLevel > 0) 'hl': heroLevel,
      if (matchMode > 0) 'mm': matchMode,
      if (gameMode > 0) 'gm': gameMode,
      if (rankedBadge != null) 'rb': rankedBadge,
      if (rankedDelta != null) 'rd': rankedDelta,
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
      heroLevel: jsonInt(json['hl']),
      matchMode: jsonInt(json['mm']),
      gameMode: jsonInt(json['gm']),
      rankedBadge: _optionalInt(json['rb']),
      rankedDelta: _optionalInt(json['rd']),
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
