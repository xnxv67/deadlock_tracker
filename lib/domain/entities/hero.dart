import 'package:equatable/equatable.dart';

class Hero extends Equatable {
  const Hero({
    required this.id,
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.cardUrl,
  });

  final int id;
  final String name;

  /// Короткое амплуа из `description.role` в `/assets/heroes`.
  final String role;

  /// Маленький портрет для таблиц.
  final String imageUrl;

  /// Карточка героя для баннера.
  final String cardUrl;

  bool get hasImage => imageUrl.isNotEmpty;
  bool get hasCard => cardUrl.isNotEmpty;

  @override
  List<Object?> get props => [id, name, role, imageUrl, cardUrl];
}
