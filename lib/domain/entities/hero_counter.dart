import 'package:equatable/equatable.dart';

import 'hero.dart';

/// Матчап выбранного героя против конкретного противника.
class HeroCounter extends Equatable {
  const HeroCounter({
    required this.enemy,
    required this.matches,
    required this.wins,
  });

  final Hero enemy;
  final int matches;
  final int wins;

  double get winRate => matches == 0 ? 0 : wins / matches;
  int get losses => matches - wins;

  @override
  List<Object?> get props => [enemy, matches, wins];
}
