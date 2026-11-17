import 'package:equatable/equatable.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlayerSearchRequested extends PlayerEvent {
  const PlayerSearchRequested(this.accountId);

  final int accountId;

  @override
  List<Object?> get props => [accountId];
}

class PlayerRefreshRequested extends PlayerEvent {
  const PlayerRefreshRequested();
}

class PlayerSteamSearchRequested extends PlayerEvent {
  const PlayerSteamSearchRequested(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class PlayerSteamResultsCleared extends PlayerEvent {
  const PlayerSteamResultsCleared();
}

class PlayerResetRequested extends PlayerEvent {
  const PlayerResetRequested();
}
