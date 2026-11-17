import 'json_utils.dart';

/// Способность из `/v1/assets/items?type=ability`.
class AbilityAssetDto {
  const AbilityAssetDto({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.heroId,
  });

  final int id;
  final String name;
  final String imageUrl;
  final int heroId;

  factory AbilityAssetDto.fromJson(Map<String, dynamic> json) {
    return AbilityAssetDto(
      id: jsonInt(json['id']),
      name: jsonString(json['name']),
      imageUrl: jsonString(
        json['image'],
        jsonString(json['image_webp']),
      ),
      heroId: jsonInt(json['hero']),
    );
  }

  Map<String, dynamic> toCompactJson() => {
    'id': id,
    'name': name,
    'image': imageUrl,
    'hero': heroId,
  };

  factory AbilityAssetDto.fromCompactJson(Map<String, dynamic> json) {
    return AbilityAssetDto(
      id: jsonInt(json['id']),
      name: jsonString(json['name']),
      imageUrl: jsonString(json['image']),
      heroId: jsonInt(json['hero']),
    );
  }
}
