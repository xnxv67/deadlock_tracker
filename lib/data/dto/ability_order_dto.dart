import 'json_utils.dart';

/// Ответ `/v1/analytics/ability-order-stats` — массив путей прокачки.
///
/// Реальная структура элемента:
/// {
///   "abilities": [15 ability_id в порядке прокачки],
///   "avg_upgrade_times_s": [15 средних времён],
///   "wins": int, "losses": int, "matches": int, "players": int,
///   "total_kills": int, "total_deaths": int, "total_assists": int
/// }
class AbilityOrderDto {
  const AbilityOrderDto({
    required this.abilities,
    required this.avgUpgradeTimesS,
    required this.wins,
    required this.losses,
    required this.matches,
    required this.players,
  });

  final List<int> abilities;
  final List<double> avgUpgradeTimesS;
  final int wins;
  final int losses;
  final int matches;
  final int players;

  double get winRate => matches == 0 ? 0 : wins / matches;
  double get lossRate => matches == 0 ? 0 : losses / matches;

  /// Доля этого пути среди всех путей (pick rate, 0..1).
  /// Считается на уровне списка (см. AbilityOrderStats), здесь — сырой вес.
  factory AbilityOrderDto.fromJson(Map<String, dynamic> json) {
    final rawAbilities = jsonList(json['abilities']);
    final abilities = rawAbilities
        .map((e) => jsonInt(e))
        .where((id) => id > 0)
        .toList();

    final rawTimes = jsonList(json['avg_upgrade_times_s']);
    final times = rawTimes.map((e) => jsonDouble(e)).toList();

    final wins = jsonInt(json['wins']);
    final losses = jsonInt(json['losses']);
    var matches = jsonInt(json['matches']);
    if (matches == 0 && (wins > 0 || losses > 0)) {
      matches = wins + losses;
    }

    return AbilityOrderDto(
      abilities: abilities,
      avgUpgradeTimesS: times,
      wins: wins,
      losses: losses,
      matches: matches,
      players: jsonInt(json['players']),
    );
  }
}
