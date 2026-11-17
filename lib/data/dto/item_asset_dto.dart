import 'json_utils.dart';

/// Элемент `/v1/assets/items` (только предметы-апгрейды).
class ItemAssetDto {
  const ItemAssetDto({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.tier,
    required this.cost,
    required this.slotType,
  });

  final int id;
  final String name;
  final String imageUrl;
  final int tier;
  final int cost;
  final String slotType;

  factory ItemAssetDto.fromJson(Map<String, dynamic> json) {
    final image = jsonString(json['image'], jsonString(json['shop_image']));

    return ItemAssetDto(
      id: jsonInt(json['id']),
      name: jsonString(json['name'], "Item #${jsonInt(json['id'])}"),
      imageUrl: image,
      tier: jsonInt(json['item_tier']),
      cost: jsonInt(json['cost']),
      slotType: jsonString(json['item_slot_type']),
    );
  }

  Map<String, dynamic> toCompactJson() {
    return {
      'id': id,
      'name': name,
      'image': imageUrl,
      'tier': tier,
      'cost': cost,
      'slot': slotType,
    };
  }

  factory ItemAssetDto.fromCompactJson(Map<String, dynamic> json) {
    return ItemAssetDto(
      id: jsonInt(json['id']),
      name: jsonString(json['name'], "Item #${jsonInt(json['id'])}"),
      imageUrl: jsonString(json['image']),
      tier: jsonInt(json['tier']),
      cost: jsonInt(json['cost']),
      slotType: jsonString(json['slot']),
    );
  }
}
