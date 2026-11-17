import '../../domain/entities/hero.dart';
import 'json_utils.dart';

/// Ответ `/v1/assets/heroes`.
class HeroDto {
  const HeroDto({
    required this.id,
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.cardUrl,
    required this.playerSelectable,
    required this.disabled,
  });

  final int id;
  final String name;
  final String role;
  final String imageUrl;
  final String cardUrl;
  final bool playerSelectable;
  final bool disabled;

  factory HeroDto.fromJson(Map<String, dynamic> json) {
    final description = jsonMap(json['description']);
    final images = jsonMap(json['images']);

    return HeroDto(
      id: jsonInt(json['id']),
      name: jsonString(json['name'], 'Hero ${jsonInt(json['id'])}'),
      role: jsonString(description['role']),
      imageUrl: jsonString(
        images['icon_image_small'],
        jsonString(images['icon_hero_card']),
      ),
      cardUrl: jsonString(
        images['icon_hero_card'],
        jsonString(images['icon_image_small']),
      ),
      playerSelectable: jsonBool(json['player_selectable'], true),
      disabled: jsonBool(json['disabled']),
    );
  }

  Hero toEntity() {
    return Hero(
      id: id,
      name: name,
      role: role,
      imageUrl: imageUrl,
      cardUrl: cardUrl,
    );
  }

  /// Компактное представление для кэша в SharedPreferences.
  Map<String, dynamic> toCompactJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'image': imageUrl,
      'card': cardUrl,
      'selectable': playerSelectable,
      'disabled': disabled,
    };
  }

  factory HeroDto.fromCompactJson(Map<String, dynamic> json) {
    final id = jsonInt(json['id']);
    return HeroDto(
      id: id,
      name: jsonString(json['name'], 'Hero $id'),
      role: jsonString(json['role']),
      imageUrl: jsonString(json['image']),
      cardUrl: jsonString(json['card']),
      playerSelectable: jsonBool(json['selectable'], true),
      disabled: jsonBool(json['disabled']),
    );
  }
}
