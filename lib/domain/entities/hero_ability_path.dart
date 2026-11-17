import 'package:equatable/equatable.dart';

/// Один шаг пути прокачки: способность + порядок + среднее время открытия.
class AbilityPathStep extends Equatable {
  const AbilityPathStep({
    required this.order,
    required this.abilityName,
    required this.imageUrl,
    required this.timeSeconds,
  });

  final int order;
  final String abilityName;
  final String imageUrl;
  final double timeSeconds;

  String get timeLabel {
    if (timeSeconds <= 0) {
      return '';
    }
    final minutes = timeSeconds ~/ 60;
    final seconds = (timeSeconds % 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [order, abilityName, imageUrl, timeSeconds];
}

/// Полный путь прокачки способностей (топ по винрейту).
class HeroAbilityPath extends Equatable {
  const HeroAbilityPath({
    required this.steps,
    required this.matches,
    required this.wins,
    required this.players,
  });

  final List<AbilityPathStep> steps;
  final int matches;
  final int wins;
  final int players;

  double get winRate => matches == 0 ? 0 : wins / matches;

  @override
  List<Object?> get props => [steps, matches, wins, players];
}
