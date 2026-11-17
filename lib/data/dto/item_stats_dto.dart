import 'json_utils.dart';

/// Строка `/v1/analytics/item-stats`.
class ItemStatsDto {
  const ItemStatsDto({
    required this.itemId,
    required this.wins,
    required this.losses,
    required this.matches,
    this.avgBuyTimeS = 0,
  });

  final int itemId;
  final int wins;
  final int losses;
  final int matches;

  /// Среднее время покупки предмета в секундах (по всем матчам).
  final double avgBuyTimeS;

  factory ItemStatsDto.fromJson(Map<String, dynamic> json) {
    final wins = jsonInt(json['wins']);
    final losses = jsonInt(json['losses']);
    final matches = jsonInt(json['matches'], wins + losses);

    return ItemStatsDto(
      itemId: jsonInt(json['item_id']),
      wins: wins,
      losses: losses,
      matches: matches > 0 ? matches : wins + losses,
      avgBuyTimeS: jsonDouble(json['avg_buy_time_s']),
    );
  }

  double get winRate => matches == 0 ? 0 : wins / matches;
}
