import 'package:equatable/equatable.dart';

import 'hero.dart';

/// Герой вместе с агрегированной статистикой меты.
class HeroMeta extends Equatable {
  const HeroMeta({
    required this.hero,
    required this.matches,
    required this.wins,
    required this.pickRate,
    this.winRateRank = 0,
    this.totalHeroes = 0,
    this.winRateDelta = 0,
  });

  final Hero hero;
  final int matches;
  final int wins;

  /// Доля пиков героя среди всех пиков, 0..1.
  final double pickRate;

  /// Место героя по винрейту (1 — лучший). 0 — не вычислено.
  final int winRateRank;

  /// Всего героев в выборке (для отображения «#N из M»).
  final int totalHeroes;

  /// Отклонение винрейта от среднего по мете (в долях, напр. -0.004).
  final double winRateDelta;

  double get winRate => matches == 0 ? 0 : wins / matches;
  int get losses => matches - wins;

  /// Tier по винрейту: S >54%, A >52%, B >50%, C ≤50%.
  String get tier {
    final wr = winRate;
    if (wr > 0.54) return 'S';
    if (wr > 0.52) return 'A';
    if (wr > 0.50) return 'B';
    return 'C';
  }

  int get tierRank {
    switch (tier) {
      case 'S':
        return 0;
      case 'A':
        return 1;
      case 'B':
        return 2;
      default:
        return 3;
    }
  }

  @override
  List<Object?> get props => [
    hero,
    matches,
    wins,
    pickRate,
    winRateRank,
    totalHeroes,
    winRateDelta,
  ];
}
