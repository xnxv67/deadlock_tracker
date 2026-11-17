import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../domain/entities/hero_counter.dart';
import '../../../domain/entities/hero_ability_path.dart';
import '../../../domain/entities/hero_detailed_stats.dart';
import '../../../domain/entities/hero_duration_stat.dart';
import '../../../domain/entities/hero_meta.dart';
import '../../../domain/entities/hero_synergy.dart';
import '../../../domain/entities/hero_trend.dart';
import '../../../domain/entities/popular_item.dart';
import '../../../domain/repositories/hero_repository.dart';
import 'hero_event.dart';
import 'hero_state.dart';

class HeroBloc extends Bloc<HeroEvent, HeroState> {
  HeroBloc(this._repository) : super(const HeroState()) {
    on<HeroRequested>(_onRequested);
    on<HeroRefreshRequested>(_onRefresh);
  }

  final HeroRepository _repository;

  Future<void> _onRequested(
    HeroRequested event,
    Emitter<HeroState> emit,
  ) async {
    await _load(event.meta, emit);
  }

  Future<void> _onRefresh(
    HeroRefreshRequested event,
    Emitter<HeroState> emit,
  ) async {
    final meta = state.meta;
    if (meta == null) {
      return;
    }
    await _load(meta, emit);
  }

  Future<void> _load(HeroMeta meta, Emitter<HeroState> emit) async {
    emit(
      state.copyWith(status: HeroStatus.loading, meta: meta, clearError: true),
    );

    final failures = <AppErrorType>[];

    final countersFuture = _safeList<HeroCounter>(
      () => _repository.getCounters(meta.hero.id),
      failures,
    );
    final durationsFuture = _safeList<HeroDurationStat>(
      () => _repository.getDurationStats(meta.hero.id),
      failures,
    );
    final synergiesFuture = _safeList<HeroSynergy>(
      () => _repository.getSynergies(meta.hero.id),
      failures,
    );
    final detailedFuture = _safeDetailed(
      () => _repository.getHeroDetailedStats(meta.hero.id),
    );
    final abilityPathFuture = _safeAbilityPath(
      () => _repository.getAbilityPath(meta.hero.id),
    );
    final popularItemsFuture = _safePopularItems(
      () => _repository.getPopularItems(meta.hero.id),
    );
    final trendFuture = _safeTrend(
      () => _repository.getHeroTrend(meta.hero.id),
    );

    final counters = await countersFuture;
    final durations = await durationsFuture;
    final synergies = await synergiesFuture;
    final detailed = await detailedFuture;
    final abilityPath = await abilityPathFuture;
    final popularItems = await popularItemsFuture;
    final trend = await trendFuture;

    final hasAny =
        counters.isNotEmpty || durations.isNotEmpty || synergies.isNotEmpty;

    if (!hasAny && failures.isNotEmpty) {
      emit(
        state.copyWith(
          status: HeroStatus.failure,
          counters: const [],
          durations: const [],
          synergies: const [],
          error: failures.first,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: HeroStatus.success,
        counters: counters,
        durations: durations,
        synergies: synergies,
        detailed: detailed,
        abilityPath: abilityPath,
        popularItems: popularItems,
        trend: trend,
        clearError: true,
      ),
    );
  }

  Future<HeroDetailedStats?> _safeDetailed(
    Future<HeroDetailedStats?> Function() action,
  ) async {
    try {
      return await action();
    } catch (_) {
      return null;
    }
  }

  Future<HeroAbilityPath?> _safeAbilityPath(
    Future<HeroAbilityPath?> Function() action,
  ) async {
    try {
      return await action();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, List<PopularItem>>> _safePopularItems(
    Future<Map<String, List<PopularItem>>> Function() action,
  ) async {
    try {
      return await action();
    } catch (_) {
      return const {};
    }
  }

  Future<HeroTrend?> _safeTrend(
    Future<HeroTrend?> Function() action,
  ) async {
    try {
      return await action();
    } catch (_) {
      return null;
    }
  }

  Future<List<T>> _safeList<T>(
    Future<List<T>> Function() action,
    List<AppErrorType> failures,
  ) async {
    try {
      return await action();
    } on AppException catch (error) {
      failures.add(error.type);
      return <T>[];
    } catch (_) {
      failures.add(AppErrorType.unknown);
      return <T>[];
    }
  }
}
