import 'package:equatable/equatable.dart';

import 'build_category.dart';
import 'item.dart';

/// Сборка героя с предметами и статистикой.
class HeroBuild extends Equatable {
  const HeroBuild({
    required this.buildId,
    required this.name,
    required this.items,
    required this.matches,
    required this.wins,
    this.buyTimes = const {},
    this.categories = const [],
  });

  final int buildId;
  final String name;
  final List<Item> items;
  final int matches;
  final int wins;

  /// Среднее время покупки предмета (секунды), по itemId.
  final Map<int, double> buyTimes;

  /// Категории предметов с аннотациями автора (если есть).
  final List<BuildCategory> categories;

  double get winRate => matches == 0 ? 0 : wins / matches;

  @override
  List<Object?> get props => [
    buildId,
    name,
    items,
    matches,
    wins,
    buyTimes,
    categories,
  ];
}
