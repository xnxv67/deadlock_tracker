import 'package:equatable/equatable.dart';

/// Точка тренда винрейта героя за день.
class HeroTrendPoint extends Equatable {
  const HeroTrendPoint({
    required this.date,
    required this.winRate,
    required this.matches,
  });

  final DateTime date;
  final double winRate;
  final int matches;

  @override
  List<Object?> get props => [date, winRate, matches];
}

/// Тренд винрейта героя: точки по дням + дельта за последнюю неделю.
class HeroTrend extends Equatable {
  const HeroTrend({required this.points, required this.weekDelta});

  final List<HeroTrendPoint> points;

  /// Изменение винрейта за последнюю неделю (в долях, напр. -0.004).
  final double weekDelta;

  bool get hasData => points.length >= 2;

  @override
  List<Object?> get props => [points, weekDelta];
}
