import 'package:equatable/equatable.dart';

import 'hero.dart';
import 'player_badge.dart';

/// Строка таблицы лидеров.
class LeaderboardPlayer extends Equatable {
  const LeaderboardPlayer({
    required this.position,
    required this.name,
    required this.badge,
    required this.topHeroes,
  });

  final int position;
  final String name;
  final PlayerBadge? badge;
  final List<Hero> topHeroes;

  bool get isTopThree => position <= 3;

  @override
  List<Object?> get props => [position, name, badge, topHeroes];
}
