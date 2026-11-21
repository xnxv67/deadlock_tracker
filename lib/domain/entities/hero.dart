import 'package:equatable/equatable.dart';

class Hero extends Equatable {
  const Hero({
    required this.id,
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.cardUrl,
    this.backgroundUrl = '',
  });

  final int id;
  final String name;

  /// Короткое амплуа из `description.role` в `/assets/heroes`.
  final String role;

  /// Маленький портрет для таблиц.
  final String imageUrl;

  /// Карточка героя для баннера.
  final String cardUrl;

  /// Большой арт высокого разрешения (`images.background_image`).
  final String backgroundUrl;

  bool get hasImage => imageUrl.isNotEmpty;
  bool get hasCard => cardUrl.isNotEmpty;
  bool get hasBackground => backgroundUrl.isNotEmpty;

  /// Лучшая картинка для баннера: большой арт → карточка → портрет.
  String get bannerUrl {
    if (backgroundUrl.isNotEmpty) {
      return backgroundUrl;
    }
    if (cardUrl.isNotEmpty) {
      return cardUrl;
    }
    return imageUrl;
  }

  @override
  List<Object?> get props => [id, name, role, imageUrl, cardUrl, backgroundUrl];
}
