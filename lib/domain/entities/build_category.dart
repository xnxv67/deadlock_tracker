import 'package:equatable/equatable.dart';

import 'item.dart';

/// Категория предметов в билде с аннотациями автора.
class BuildCategory extends Equatable {
  const BuildCategory({
    required this.name,
    required this.items,
    required this.annotations,
  });

  final String name;
  final List<Item> items;

  /// Комментарий автора к предмету (по itemId).
  final Map<int, String> annotations;

  bool get isCore => name.toLowerCase().contains('early') ||
      name.toLowerCase().contains('mid') ||
      name.toLowerCase().contains('late');

  @override
  List<Object?> get props => [name, items, annotations];
}
