import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../domain/repositories/player_repository.dart';
import 'player_event.dart';
import 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  PlayerBloc(this._repository) : super(const PlayerState()) {
    on<PlayerSearchRequested>(_onSearch);
    on<PlayerRefreshRequested>(_onRefresh);
    on<PlayerResetRequested>(_onReset);
    on<PlayerSteamSearchRequested>(_onSteamSearch);
    on<PlayerSteamResultsCleared>(_onSteamCleared);
  }

  final PlayerRepository _repository;

  Future<void> _onSearch(
    PlayerSearchRequested event,
    Emitter<PlayerState> emit,
  ) async {
    if (event.accountId <= 0) {
      return;
    }
    if (state.status == PlayerStatus.loading &&
        state.accountId == event.accountId) {
      return;
    }
    await _load(event.accountId, emit);
  }

  Future<void> _onRefresh(
    PlayerRefreshRequested event,
    Emitter<PlayerState> emit,
  ) async {
    final accountId = state.accountId;
    if (accountId == null) {
      return;
    }
    await _load(accountId, emit);
  }

  Future<void> _onSteamSearch(
    PlayerSteamSearchRequested event,
    Emitter<PlayerState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(state.copyWith(steamResults: const [], steamSearching: false));
      return;
    }
    emit(state.copyWith(steamSearching: true));
    try {
      final results = await _repository.searchSteam(query);
      emit(state.copyWith(steamResults: results, steamSearching: false));
    } catch (_) {
      emit(state.copyWith(steamResults: const [], steamSearching: false));
    }
  }

  void _onSteamCleared(
    PlayerSteamResultsCleared event,
    Emitter<PlayerState> emit,
  ) {
    emit(state.copyWith(steamResults: const [], steamSearching: false));
  }

  void _onReset(PlayerResetRequested event, Emitter<PlayerState> emit) {
    emit(const PlayerState());
  }

  Future<void> _load(int accountId, Emitter<PlayerState> emit) async {
    emit(PlayerState(status: PlayerStatus.loading, accountId: accountId));

    try {
      final profile = await _repository.getProfile(accountId);
      emit(
        PlayerState(
          status: PlayerStatus.success,
          accountId: accountId,
          profile: profile,
        ),
      );
    } on AppException catch (error) {
      emit(
        PlayerState(
          status: PlayerStatus.failure,
          accountId: accountId,
          error: error.type,
        ),
      );
    } catch (_) {
      emit(
        PlayerState(
          status: PlayerStatus.failure,
          accountId: accountId,
          error: AppErrorType.unknown,
        ),
      );
    }
  }
}
