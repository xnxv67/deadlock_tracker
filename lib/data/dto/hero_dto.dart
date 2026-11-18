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
    this.backgroundUrl = '',
    required this.playerSelectable,
    required this.disabled,
  });

  final int id;
  final String name;
  final String role;
  final String imageUrl;
  final String cardUrl;

  /// Крупный арт высокого разрешения из `images.background_image`.
  final String backgroundUrl;
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
      backgroundUrl: jsonString(
        images['background_image'],
        jsonString(images['background_image_webp']),
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
      backgroundUrl: backgroundUrl,
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
      'bg': backgroundUrl,
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
      backgroundUrl: jsonString(json['bg']),
      playerSelectable: jsonBool(json['selectable'], true),
      disabled: jsonBool(json['disabled']),
    );
  }
}
