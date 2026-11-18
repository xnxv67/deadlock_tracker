import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../domain/repositories/leaderboard_repository.dart';
import 'leaderboard_event.dart';
import 'leaderboard_state.dart';

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  LeaderboardBloc(this._repository) : super(const LeaderboardState()) {
    on<LeaderboardRequested>(_onRequested);
    on<LeaderboardRefreshRequested>(_onRefresh);
    on<LeaderboardRegionChanged>(_onRegionChanged);
  }

  final LeaderboardRepository _repository;

  Future<void> _onRequested(
    LeaderboardRequested event,
    Emitter<LeaderboardState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _onRefresh(
    LeaderboardRefreshRequested event,
    Emitter<LeaderboardState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _onRegionChanged(
    LeaderboardRegionChanged event,
    Emitter<LeaderboardState> emit,
  ) async {
    if (state.region == event.region) return;
    // Старые строки другого региона не должны мелькать под новым выбором.
    emit(state.copyWith(region: event.region, players: const []));
    await _load(emit);
  }

  Future<void> _load(Emitter<LeaderboardState> emit) async {
    emit(state.copyWith(status: LeaderboardStatus.loading, clearError: true));

    try {
      final players = await _repository.getLeaderboard(region: state.region);
      emit(
        state.copyWith(
          status: LeaderboardStatus.success,
          players: players,
          clearError: true,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(status: LeaderboardStatus.failure, error: error.type),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: LeaderboardStatus.failure,
          error: AppErrorType.unknown,
        ),
      );
    }
  }
}
