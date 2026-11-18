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
    this.accountId,
    this.wins,
  });

  final int position;
  final String name;
  final PlayerBadge? badge;
  final List<Hero> topHeroes;

  /// account_id, если API вернул однозначный вариант.
  final int? accountId;

  /// Суммарные победы по статистике героев, если удалось получить.
  final int? wins;

  bool get isTopThree => position <= 3;

  @override
  List<Object?> get props => [
    position,
    name,
    badge,
    topHeroes,
    accountId,
    wins,
  ];
}
