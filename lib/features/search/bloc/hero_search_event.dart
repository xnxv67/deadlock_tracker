import 'package:equatable/equatable.dart';

sealed class HeroSearchEvent extends Equatable {
  const HeroSearchEvent();

  @override
  List<Object?> get props => const [];
}

/// Пользователь изменил строку поиска.
final class HeroSearchQueryChanged extends HeroSearchEvent {
  const HeroSearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
