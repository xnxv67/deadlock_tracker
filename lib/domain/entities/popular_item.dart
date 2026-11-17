import 'package:equatable/equatable.dart';

import 'item.dart';

/// Популярный предмет героя на стадии игры (early/mid/late).
class PopularItem extends Equatable {
  const PopularItem({
    required this.item,
    required this.pickPct,
    required this.winratePct,
  });

  final Item item;
  final double pickPct;
  final double winratePct;

  @override
  List<Object?> get props => [item, pickPct, winratePct];
}
