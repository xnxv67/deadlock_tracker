import 'json_utils.dart';

/// Популярный предмет на стадии игры из `/v1/assets/heroes/{id}`
/// (поле `popular_items`).
class PopularItemDto {
  const PopularItemDto({
    required this.itemId,
    required this.pickPct,
    required this.winratePct,
  });

  final int itemId;
  final double pickPct;
  final double winratePct;

  factory PopularItemDto.fromJson(Map<String, dynamic> json) {
    return PopularItemDto(
      itemId: jsonInt(json['item_id']),
      pickPct: jsonDouble(json['pick_pct']),
      winratePct: jsonDouble(json['winrate_pct']),
    );
  }
}
