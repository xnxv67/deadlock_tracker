import 'package:equatable/equatable.dart';

/// Винрейт героя в рамках длительности матча.
class HeroDurationStat extends Equatable {
  const HeroDurationStat({
    required this.label,
    required this.matches,
    required this.wins,
  });

  final String label;
  final int matches;
  final int wins;

  double get winRate => matches == 0 ? 0 : wins / matches;

  @override
  List<Object?> get props => [label, matches, wins];
}
