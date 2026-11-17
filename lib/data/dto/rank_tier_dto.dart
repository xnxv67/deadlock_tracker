import 'json_utils.dart';

/// Элемент `/v1/assets/ranks`.
class RankTierDto {
  const RankTierDto({
    required this.tier,
    required this.name,
    required this.colorHex,
  });

  final int tier;
  final String name;
  final String colorHex;

  factory RankTierDto.fromJson(Map<String, dynamic> json) {
    return RankTierDto(
      tier: jsonInt(json['tier']),
      name: jsonString(json['name'], 'Rank ${jsonInt(json['tier'])}'),
      colorHex: jsonString(json['color']),
    );
  }
}
