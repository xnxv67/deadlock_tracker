import 'package:equatable/equatable.dart';

import '../../../core/error/app_exception.dart';
import '../../../domain/entities/player_profile.dart';
import '../../../domain/entities/steam_profile.dart';

enum PlayerStatus { initial, loading, success, failure }

class PlayerState extends Equatable {
  const PlayerState({
    this.status = PlayerStatus.initial,
    this.accountId,
    this.profile,
    this.error,
    this.steamResults = const [],
    this.steamSearching = false,
  });

  final PlayerStatus status;
  final int? accountId;
  final PlayerProfile? profile;
  final AppErrorType? error;
  final List<SteamProfile> steamResults;
  final bool steamSearching;

  bool get hasData => profile != null && !profile!.isEmpty;

  PlayerState copyWith({
    PlayerStatus? status,
    int? accountId,
    PlayerProfile? profile,
    AppErrorType? error,
    bool clearError = false,
    bool clearProfile = false,
    List<SteamProfile>? steamResults,
    bool? steamSearching,
  }) {
    return PlayerState(
      status: status ?? this.status,
      accountId: accountId ?? this.accountId,
      profile: clearProfile ? null : (profile ?? this.profile),
      error: clearError ? null : (error ?? this.error),
      steamResults: steamResults ?? this.steamResults,
      steamSearching: steamSearching ?? this.steamSearching,
    );
  }

  @override
  List<Object?> get props => [status, accountId, profile, error, steamResults, steamSearching];
}
