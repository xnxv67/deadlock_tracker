import 'package:equatable/equatable.dart';

import 'item.dart';

/// Предмет вместе со статистикой покупок.
class ItemMeta extends Equatable {
  const ItemMeta({
    required this.item,
    required this.matches,
    required this.wins,
    required this.pickRate,
    this.avgBuyTimeS = 0,
  });

  final Item item;
  final int matches;
  final int wins;

  /// Среднее время покупки в секундах (0 — нет данных).
  final double avgBuyTimeS;

  /// Доля покупок предмета среди всех пиков героев, 0..1.
  final double pickRate;

  double get winRate => matches == 0 ? 0 : wins / matches;
  int get losses => matches - wins;

  @override
  List<Object?> get props => [item, matches, wins, pickRate, avgBuyTimeS];
}
