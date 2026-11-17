import 'package:equatable/equatable.dart';

import 'hero.dart';

/// Лучшая связка героя с союзником.
class HeroSynergy extends Equatable {
  const HeroSynergy({
    required this.ally,
    required this.matches,
    required this.wins,
  });

  final Hero ally;
  final int matches;
  final int wins;

  double get winRate => matches == 0 ? 0 : wins / matches;

  @override
  List<Object?> get props => [ally, matches, wins];
}
